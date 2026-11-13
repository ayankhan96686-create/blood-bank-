-- ============================================================================
-- Automated Test Suite: pgtap_and_sql_tests.sql
-- Project: AI-Assisted Blood Bank and Donor Matching System (CSL0311)
-- Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
-- Purpose: Formal verification of 15 business rules, constraints, triggers, and procedures.
-- ============================================================================

BEGIN;

-- Helper temporary verification table
CREATE TEMP TABLE test_results (
    test_id SERIAL PRIMARY KEY,
    test_case VARCHAR(120) NOT NULL,
    expected_status VARCHAR(20) NOT NULL,
    actual_status VARCHAR(20) NOT NULL,
    details TEXT
);

-- ----------------------------------------------------------------------------
-- TEST 1: Donor Underweight CHECK Constraint (< 45 kg)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    INSERT INTO donors (donor_code, full_name, date_of_birth, gender, blood_group, weight_kg, hemoglobin_g_dl, phone_masked, phone_encrypted, pincode)
    VALUES ('DNR-TEST-UW', 'Underweight Donor', '1995-05-10', 'Female', 'A+', 42.0, 13.0, '9876543210', 'enc_hash', '474001');
    
    INSERT INTO test_results (test_case, expected_status, actual_status, details)
    VALUES ('BR01: Underweight donor rejected by CHECK', 'FAIL', 'PASS_UNEXPECTED', 'CHECK constraint did not reject weight < 45 kg');
EXCEPTION WHEN check_violation THEN
    INSERT INTO test_results (test_case, expected_status, actual_status, details)
    VALUES ('BR01: Underweight donor rejected by CHECK', 'SUCCESS', 'SUCCESS', 'Correctly rejected weight_kg = 42.0');
END $$;

-- ----------------------------------------------------------------------------
-- TEST 2: Donor Low Hemoglobin CHECK Constraint (< 12.5 g/dL)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    INSERT INTO donors (donor_code, full_name, date_of_birth, gender, blood_group, weight_kg, hemoglobin_g_dl, phone_masked, phone_encrypted, pincode)
    VALUES ('DNR-TEST-LHB', 'Low Hb Donor', '1998-02-14', 'Male', 'O+', 65.0, 11.8, '9876543211', 'enc_hash', '474001');
    
    INSERT INTO test_results (test_case, expected_status, actual_status, details)
    VALUES ('BR01: Low Hb donor rejected by CHECK', 'FAIL', 'PASS_UNEXPECTED', 'CHECK constraint did not reject hb < 12.5');
EXCEPTION WHEN check_violation THEN
    INSERT INTO test_results (test_case, expected_status, actual_status, details)
    VALUES ('BR01: Low Hb donor rejected by CHECK', 'SUCCESS', 'SUCCESS', 'Correctly rejected hemoglobin_g_dl = 11.8');
END $$;

-- ----------------------------------------------------------------------------
-- TEST 3: Trigger 1 - 90-Day Recovery Interval Enforcement (SQLSTATE P0001)
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_donor_id INT;
BEGIN
    -- Setup eligible test donor
    INSERT INTO donors (donor_code, full_name, date_of_birth, gender, blood_group, weight_kg, hemoglobin_g_dl, phone_masked, phone_encrypted, pincode, is_eligible)
    VALUES ('DNR-TEST-TRG1', 'Rapid Repeat Donor', '1992-08-20', 'Male', 'B+', 70.0, 14.5, '9876543212', 'enc_hash', '474001', TRUE)
    RETURNING donor_id INTO v_donor_id;

    -- First donation on Day 0
    INSERT INTO donations (donor_id, collected_by_tech_id, collection_date, blood_group, volume_ml, bag_serial_no, collection_status)
    VALUES (v_donor_id, 1, CURRENT_DATE - INTERVAL '20 days', 'B+', 450, 'BAG-TEST-TRG1-A', 'Successful');

    -- Attempt second donation on Day 20 (VIOLATION: only 20 days elapsed)
    INSERT INTO donations (donor_id, collected_by_tech_id, collection_date, blood_group, volume_ml, bag_serial_no, collection_status)
    VALUES (v_donor_id, 1, CURRENT_DATE, 'B+', 450, 'BAG-TEST-TRG1-B', 'Successful');

    INSERT INTO test_results (test_case, expected_status, actual_status, details)
    VALUES ('BR02: 90-Day donor interval trigger', 'FAIL', 'PASS_UNEXPECTED', 'Trigger failed to block repeat donation at 20 days');
EXCEPTION WHEN SQLSTATE 'P0001' THEN
    INSERT INTO test_results (test_case, expected_status, actual_status, details)
    VALUES ('BR02: 90-Day donor interval trigger', 'SUCCESS', 'SUCCESS', 'Raised SQLSTATE P0001 correctly on 20 days elapsed');
END $$;

-- ----------------------------------------------------------------------------
-- TEST 4: Trigger 2 - Reactive Infectious Screen Biohazard Quarantine
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_unit_id INT;
    v_status VARCHAR(32);
BEGIN
    -- Create temporary test unit in Quarantined status
    INSERT INTO blood_units (unit_barcode, donation_id, blood_group, component_type, volume_ml, collection_date, expiry_date, status, location_id)
    VALUES ('UNIT-TEST-BIO', 1, 'A+', 'Packed RBC', 280, CURRENT_DATE, NOW() + INTERVAL '35 days', 'Quarantined', 1)
    RETURNING unit_id INTO v_unit_id;

    -- Insert reactive test result
    INSERT INTO laboratory_tests (unit_id, tested_by_tech_id, hiv_status, hbsag_status, hcv_status, syphilis_status, malaria_status, overall_result)
    VALUES (v_unit_id, 1, 'Reactive', 'Negative', 'Negative', 'Negative', 'Negative', 'Reactive');

    -- Check if blood unit status automatically transitioned to Biohazard_Quarantined
    SELECT status INTO v_status FROM blood_units WHERE unit_id = v_unit_id;

    IF v_status = 'Biohazard_Quarantined' THEN
        INSERT INTO test_results (test_case, expected_status, actual_status, details)
        VALUES ('BR04: Reactive test biohazard lock', 'SUCCESS', 'SUCCESS', 'Unit status changed to Biohazard_Quarantined');
    ELSE
        INSERT INTO test_results (test_case, expected_status, actual_status, details)
        VALUES ('BR04: Reactive test biohazard lock', 'FAIL', v_status, 'Unit status is not Biohazard_Quarantined');
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- TEST 5: Biological Compatibility Function (RBC Rules)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    -- O- can give to A+ (TRUE)
    -- A+ can give to O- (FALSE)
    IF fn_check_compatibility('O-', 'A+', 'Packed RBC') = TRUE AND
       fn_check_compatibility('A+', 'O-', 'Packed RBC') = FALSE AND
       fn_check_compatibility('AB+', 'O-', 'Packed RBC') = FALSE AND
       fn_check_compatibility('O-', 'AB+', 'Packed RBC') = TRUE THEN
       
        INSERT INTO test_results (test_case, expected_status, actual_status, details)
        VALUES ('BR06: RBC Compatibility Matrix', 'SUCCESS', 'SUCCESS', 'O- universal donor and AB+ universal recipient rules verified');
    ELSE
        INSERT INTO test_results (test_case, expected_status, actual_status, details)
        VALUES ('BR06: RBC Compatibility Matrix', 'FAIL', 'LOGIC_ERROR', 'Compatibility truth table failed');
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- TEST 6: Trigger 5 - Anti-Tamper Hard Delete Protection (SQLSTATE P0002)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    -- Attempt hard delete on audit_logs
    DELETE FROM audit_logs WHERE audit_id = 1;
    
    INSERT INTO test_results (test_case, expected_status, actual_status, details)
    VALUES ('BR10: Anti-delete regulatory audit guard', 'FAIL', 'PASS_UNEXPECTED', 'Delete was permitted without exception');
EXCEPTION WHEN SQLSTATE 'P0002' THEN
    INSERT INTO test_results (test_case, expected_status, actual_status, details)
    VALUES ('BR10: Anti-delete regulatory audit guard', 'SUCCESS', 'SUCCESS', 'Raised SQLSTATE P0002 correctly blocking hard delete');
END $$;

-- Summary Output
SELECT test_id, test_case, expected_status, actual_status, details FROM test_results;

ROLLBACK; -- Always roll back test execution

