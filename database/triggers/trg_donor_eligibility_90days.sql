-- Trigger File: trg_donor_eligibility_90days.sql
-- Enforces 90-day recovery interval and donor health qualifications.

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
            USING ERRCODE = 'P0001',
                  HINT = 'Check donor registry deferral reason.';
    END IF;

    IF v_weight < 45.0 THEN
        RAISE EXCEPTION 'ELIGIBILITY_VIOLATION: Donor % weight (% kg) is below legal minimum (45 kg).', v_donor_name, v_weight
            USING ERRCODE = 'P0001';
    END IF;

    IF v_hb < 12.5 THEN
        RAISE EXCEPTION 'ELIGIBILITY_VIOLATION: Donor % hemoglobin (% g/dL) is below legal threshold (12.5 g/dL).', v_donor_name, v_hb
            USING ERRCODE = 'P0001';
    END IF;

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

    UPDATE donors
    SET last_donation_date = NEW.collection_date
    WHERE donor_id = NEW.donor_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_donor_eligibility_90days ON donations;
CREATE TRIGGER trg_donor_eligibility_90days
BEFORE INSERT OR UPDATE ON donations
FOR EACH ROW
EXECUTE FUNCTION fn_enforce_donor_eligibility_90days();

