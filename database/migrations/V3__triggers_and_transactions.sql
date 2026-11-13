-- ============================================================================
-- Migration: V3__triggers_and_transactions.sql
-- Project: AI-Assisted Blood Bank and Donor Matching System (CSL0311)
-- Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
-- Purpose: Implements PL/pgSQL business rules triggers, audit ledger, and anti-delete guards.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Trigger 1: Mandatory 90-Day Recovery Interval & Donor Fitness Gate
-- ----------------------------------------------------------------------------
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
    -- 1. Query donor medical and deferral status
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

    -- 2. Query last successful donation date
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

    -- 3. Update donor's latest donation date
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


-- ----------------------------------------------------------------------------
-- Trigger 2: Mandatory 5-Test Screening Gatekeeper & Biohazard Lockdown
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_enforce_test_clearance()
RETURNS TRIGGER AS $$
BEGIN
    -- If any test is Reactive, lock unit as Biohazard_Quarantined immediately
    IF NEW.hiv_status = 'Reactive' OR NEW.hbsag_status = 'Reactive' OR
       NEW.hcv_status = 'Reactive' OR NEW.syphilis_status = 'Reactive' OR
       NEW.malaria_status = 'Reactive' OR NEW.overall_result = 'Reactive' THEN
       
        UPDATE blood_units
        SET status = 'Biohazard_Quarantined',
            version_no = version_no + 1
        WHERE unit_id = NEW.unit_id;
        
        -- Also flag overall_result
        NEW.overall_result := 'Reactive';
        RETURN NEW;
    END IF;

    -- If all 5 tests are Negative and blood group is verified, release to Available
    IF NEW.hiv_status = 'Negative' AND NEW.hbsag_status = 'Negative' AND
       NEW.hcv_status = 'Negative' AND NEW.syphilis_status = 'Negative' AND
       NEW.malaria_status = 'Negative' AND NEW.blood_group_verified = TRUE THEN
       
        NEW.overall_result := 'Acceptable';

        -- Release unit if not already allocated, issued or discarded
        UPDATE blood_units
        SET status = 'Available',
            version_no = version_no + 1
        WHERE unit_id = NEW.unit_id
          AND status = 'Quarantined';
    ELSE
        -- If any test is pending, ensure unit stays Quarantined
        NEW.overall_result := 'Pending';
        UPDATE blood_units
        SET status = 'Quarantined',
            version_no = version_no + 1
        WHERE unit_id = NEW.unit_id
          AND status NOT IN ('Allocated', 'Issued', 'Transfused', 'Discarded');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enforce_test_clearance ON laboratory_tests;
CREATE TRIGGER trg_enforce_test_clearance
BEFORE INSERT OR UPDATE ON laboratory_tests
FOR EACH ROW
EXECUTE FUNCTION fn_enforce_test_clearance();


-- ----------------------------------------------------------------------------
-- Trigger 3: Cold-Chain Temperature Breach Auto-Quarantine
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_cold_chain_breach()
RETURNS TRIGGER AS $$
DECLARE
    v_min_temp NUMERIC(4,1);
    v_max_temp NUMERIC(4,1);
    v_code VARCHAR(32);
    v_units_affected INT;
BEGIN
    -- Query equipment temperature bounds
    SELECT storage_code, min_temp_c, max_temp_c
    INTO v_code, v_min_temp, v_max_temp
    FROM inventory_locations
    WHERE location_id = NEW.location_id;

    -- Check for temperature breach
    IF NEW.recorded_temp_c > v_max_temp OR NEW.recorded_temp_c < v_min_temp THEN
        -- Mark event alert
        NEW.alert_triggered := TRUE;

        -- Automatically quarantine all Available units currently stored in this equipment
        UPDATE blood_units
        SET status = 'Quarantined',
            version_no = version_no + 1
        WHERE location_id = NEW.location_id
          AND status = 'Available';

        GET DIAGNOSTICS v_units_affected = ROW_COUNT;

        -- Update current reading on location equipment
        UPDATE inventory_locations
        SET current_temp_c = NEW.recorded_temp_c
        WHERE location_id = NEW.location_id;

        -- Log emergency event in audit ledger
        INSERT INTO audit_logs (table_name, record_id, operation_type, previous_state, new_state, location_snapshot, changed_by)
        VALUES (
            'inventory_locations',
            NEW.location_id::VARCHAR,
            'UPDATE',
            json_build_object('event', 'SAFE_TEMPERATURE', 'max_temp', v_max_temp, 'min_temp', v_min_temp)::jsonb,
            json_build_object('event', 'TEMPERATURE_BREACH', 'recorded_temp', NEW.recorded_temp_c, 'units_quarantined', v_units_affected)::jsonb,
            json_build_object('storage_code', v_code, 'location_id', NEW.location_id)::jsonb,
            'SYSTEM_COLD_CHAIN_DAEMON'
        );
    ELSE
        -- Update safe current reading
        UPDATE inventory_locations
        SET current_temp_c = NEW.recorded_temp_c
        WHERE location_id = NEW.location_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cold_chain_breach ON cold_chain_events;
CREATE TRIGGER trg_cold_chain_breach
BEFORE INSERT ON cold_chain_events
FOR EACH ROW
EXECUTE FUNCTION fn_cold_chain_breach();


-- ----------------------------------------------------------------------------
-- Trigger 4: Immutable Custody & Status Audit Trail (JSONB Snapshots)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_audit_blood_unit_custody()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.status IS DISTINCT FROM NEW.status) OR 
       (OLD.location_id IS DISTINCT FROM NEW.location_id) THEN
        
        INSERT INTO audit_logs (
            table_name,
            record_id,
            operation_type,
            previous_state,
            new_state,
            location_snapshot,
            changed_by
        )
        VALUES (
            'blood_units',
            NEW.unit_id::VARCHAR,
            'UPDATE',
            to_jsonb(OLD),
            to_jsonb(NEW),
            json_build_object('old_location', OLD.location_id, 'new_location', NEW.location_id)::jsonb,
            CURRENT_USER
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_blood_unit_custody ON blood_units;
CREATE TRIGGER trg_audit_blood_unit_custody
AFTER UPDATE ON blood_units
FOR EACH ROW
EXECUTE FUNCTION fn_audit_blood_unit_custody();


-- ----------------------------------------------------------------------------
-- Trigger 5: Anti-Tamper WORM Regulatory Delete Guard
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_prevent_regulatory_hard_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'AUDIT_PROTECTION: Hard deletion prohibited by regulatory compliance standards (FDA 21 CFR Part 11 / Schedule F).'
        USING ERRCODE = 'P0002',
              HINT = 'Historical transfusion and custody audit records must be retained permanently.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_anti_delete ON audit_logs;
CREATE TRIGGER trg_audit_anti_delete
BEFORE DELETE ON audit_logs
FOR EACH ROW
EXECUTE FUNCTION fn_prevent_regulatory_hard_delete();

DROP TRIGGER IF EXISTS trg_transfusion_anti_delete ON transfusions;
CREATE TRIGGER trg_transfusion_anti_delete
BEFORE DELETE ON transfusions
FOR EACH ROW
EXECUTE FUNCTION fn_prevent_regulatory_hard_delete();

-- Record Migration V3 in registry
INSERT INTO schema_versions (version_id, version_tag, description, checksum, applied_by)
VALUES (3, 'V3__triggers_and_transactions', 'Deployment of 5 PL/pgSQL triggers, audit ledger, and anti-delete guards', 'sha256_v3_csl0311_triggers', 'Diya Motwani')
ON CONFLICT (version_id) DO NOTHING;

