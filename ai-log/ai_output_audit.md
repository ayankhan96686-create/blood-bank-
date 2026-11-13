# Formal AI Output Audit: Donor Eligibility & Recovery Interval Trigger
**Course:** DBMS CSL0311 – Section 11 Mandatory Deliverable  
**Audited Artifact:** PL/pgSQL Trigger `trg_donor_eligibility_90days`  
**Auditor:** Diya Motwani (Architecture Lead) & Ch. Mohith (DevOps/QA)  
**Date of Audit:** 2026-11-09  

---

## 1. Original Prompt Given to AI
> *"Write a PostgreSQL PL/pgSQL trigger function and trigger on the `donations` table that prevents a donor from donating blood if their previous whole-blood donation was within the last 90 days. Raise an exception if violated."*

---

## 2. Initial AI-Generated Output (Flawed Version)
```sql
-- AI Generated Trigger (Unchecked Initial Draft)
CREATE OR REPLACE FUNCTION fn_check_donor_interval()
RETURNS TRIGGER AS $$
DECLARE
    last_date DATE;
BEGIN
    SELECT MAX(collection_date) INTO last_date
    FROM donations
    WHERE donor_id = NEW.donor_id;

    IF last_date IS NOT NULL THEN
        -- Bug 1: Checks months instead of exact calendar days
        -- Bug 2: Fails to check if the last donation was successful or cancelled
        -- Bug 3: Raises generic exception with no custom SQLSTATE code
        IF AGE(NEW.collection_date, last_date) < INTERVAL '3 months' THEN
            RAISE EXCEPTION 'Donor cannot donate within 3 months!';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_donor_interval
BEFORE INSERT ON donations
FOR EACH ROW
EXECUTE FUNCTION fn_check_donor_interval();
```

---

## 3. Errors, Omissions & Edge Cases Identified During Peer Review

1. **Incorrect Duration Calculation (`INTERVAL '3 months'` vs. Exact 90 Days):**
   - In medical transfusion guidelines (National Blood Transfusion Council - NBTC India & WHO), whole-blood recovery is mandated as an exact minimum of **90 calendar days**.
   - `INTERVAL '3 months'` in PostgreSQL evaluates dynamically based on the month lengths (e.g. February has 28 days, July has 31 days). A donor donating on February 1st and attempting on April 28th would have 86 days elapsed, which `INTERVAL '3 months'` might permit or miscalculate!
2. **Failure to Filter by Collection Outcome:**
   - The AI query `SELECT MAX(collection_date) FROM donations WHERE donor_id = NEW.donor_id` did not filter for `collection_status = 'Successful'`.
   - If a previous session was aborted due to vasovagal syncope or vein collapse (`collection_status = 'Incomplete'` with only 20 mL collected), the donor is not barred by the 90-day whole-blood red cell depletion rule.
3. **No Specific SQLSTATE or Actionable Error Payload:**
   - The AI raised an unclassified exception (`RAISE EXCEPTION`).
   - The application frontend cannot programmatically distinguish this business validation error from an internal syntax error. A custom `SQLSTATE 'P0001'` with the exact elapsed days and next eligible date is required for clinical UI banners.
4. **Missing Self-Row Exclusion on Updates:**
   - If a donation record is updated for clerical corrections, checking `WHERE donor_id = NEW.donor_id` without `AND donation_id != NEW.donation_id` would compare the row against itself and trigger a false-positive violation.

---

## 4. Corrected & Hardened Production Version
```sql
-- Production Certified Trigger (V3__triggers_and_transactions.sql)
CREATE OR REPLACE FUNCTION fn_enforce_donor_eligibility_90days()
RETURNS TRIGGER AS $$
DECLARE
    v_last_donation_date DATE;
    v_days_elapsed INT;
    v_next_eligible_date DATE;
    v_donor_name VARCHAR(120);
    v_is_eligible BOOLEAN;
    v_weight NUMERIC(5,2);
    v_hb NUMERIC(4,2);
BEGIN
    -- 1. Verify Donor General Medical Fitness
    SELECT full_name, is_eligible, weight_kg, hemoglobin_g_dl
    INTO v_donor_name, v_is_eligible, v_weight, v_hb
    FROM donors
    WHERE donor_id = NEW.donor_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'DONOR_NOT_FOUND: Donor ID % does not exist in registry.', NEW.donor_id
            USING ERRCODE = 'P0003';
    END IF;

    IF v_is_eligible = FALSE THEN
        RAISE EXCEPTION 'ELIGIBILITY_VIOLATION: Donor % is currently deferred from blood donation.', v_donor_name
            USING ERRCODE = 'P0001';
    END IF;

    IF v_weight < 45.0 THEN
        RAISE EXCEPTION 'ELIGIBILITY_VIOLATION: Donor % weight (% kg) is below legal minimum (45 kg).', v_donor_name, v_weight
            USING ERRCODE = 'P0001';
    END IF;

    IF v_hb < 12.5 THEN
        RAISE EXCEPTION 'ELIGIBILITY_VIOLATION: Donor % hemoglobin (% g/dL) is below legal threshold (12.5 g/dL).', v_donor_name, v_hb
            USING ERRCODE = 'P0001';
    END IF;

    -- 2. Verify Exact 90-Day Elapsed Interval on Successful Donations
    SELECT MAX(collection_date)
    INTO v_last_donation_date
    FROM donations
    WHERE donor_id = NEW.donor_id
      AND collection_status = 'Successful'
      AND (TG_OP = 'INSERT' OR donation_id != NEW.donation_id);

    IF v_last_donation_date IS NOT NULL THEN
        v_days_elapsed := (NEW.collection_date - v_last_donation_date);
        IF v_days_elapsed < 90 THEN
            v_next_eligible_date := v_last_donation_date + INTERVAL '90 days';
            RAISE EXCEPTION 'ELIGIBILITY_VIOLATION: Mandatory 90-day recovery interval not met for %. Days elapsed: %. Next eligible donation date: %.',
                v_donor_name, v_days_elapsed, v_next_eligible_date
                USING ERRCODE = 'P0001',
                      HINT = 'Whole blood donation requires 90 days for full erythrocyte regeneration.';
        END IF;
    END IF;

    -- 3. Update Donor's Last Donation Date on Successful Validation
    UPDATE donors
    SET last_donation_date = NEW.collection_date
    WHERE donor_id = NEW.donor_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_donor_eligibility_90days
BEFORE INSERT OR UPDATE ON donations
FOR EACH ROW
EXECUTE FUNCTION fn_enforce_donor_eligibility_90days();
```

---

## 5. Test Cases and Validation Evidence

### Test Case 1: Donation Attempt at 25 Days (Expected: REJECT with P0001)
```sql
-- Donor #12 donated on 2026-10-15.
-- Attempting new donation on 2026-11-09 (25 days elapsed):
INSERT INTO donations (donor_id, collected_by_tech_id, collection_date, blood_group, volume_ml, bag_serial_no, collection_status)
VALUES (12, 2, '2026-11-09', 'B+', 450, 'BAG-TEST-ERR-01', 'Successful');

-- Output:
-- ERROR: ELIGIBILITY_VIOLATION: Mandatory 90-day recovery interval not met for Rajesh Sharma. Days elapsed: 25. Next eligible donation date: 2027-01-13.
-- SQLSTATE: P0001
-- RESULT: PASS (Properly rejected).
```

### Test Case 2: Donation Attempt at 91 Days (Expected: ACCEPT)
```sql
-- Attempting new donation on 2027-01-15 (92 days elapsed):
INSERT INTO donations (donor_id, collected_by_tech_id, collection_date, blood_group, volume_ml, bag_serial_no, collection_status)
VALUES (12, 2, '2027-01-15', 'B+', 450, 'BAG-TEST-OK-01', 'Successful');

-- Output:
-- INSERT 0 1
-- RESULT: PASS (Successfully recorded).
```

---

## 6. Lessons Learned About AI Reliability in Database Engineering
1. **Never Assume Domain Fidelity:** AI assistants default to general calendar math (`INTERVAL '3 months'`) instead of statutory medical criteria (exact 90-day red cell life cycles).
2. **Context-Blind Querying:** AI routinely misses operational edge cases (e.g. excluding aborted/incomplete donation sessions or excluding `NEW.donation_id` on updates).
3. **Structured Error Codes Are Vital:** AI code typically lacks specific `ERRCODE` mappings, which makes automated frontend UI exception handling impossible without human refactoring.

