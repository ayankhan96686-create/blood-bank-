-- Trigger File: trg_enforce_test_clearance.sql
-- Enforces mandatory 5-test infectious screening before releasing units to Available.

CREATE OR REPLACE FUNCTION fn_enforce_test_clearance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.hiv_status = 'Reactive' OR NEW.hbsag_status = 'Reactive' OR
       NEW.hcv_status = 'Reactive' OR NEW.syphilis_status = 'Reactive' OR
       NEW.malaria_status = 'Reactive' OR NEW.overall_result = 'Reactive' THEN
       
        UPDATE blood_units
        SET status = 'Biohazard_Quarantined',
            version_no = version_no + 1
        WHERE unit_id = NEW.unit_id;
        
        NEW.overall_result := 'Reactive';
        RETURN NEW;
    END IF;

    IF NEW.hiv_status = 'Negative' AND NEW.hbsag_status = 'Negative' AND
       NEW.hcv_status = 'Negative' AND NEW.syphilis_status = 'Negative' AND
       NEW.malaria_status = 'Negative' AND NEW.blood_group_verified = TRUE THEN
       
        NEW.overall_result := 'Acceptable';

        UPDATE blood_units
        SET status = 'Available',
            version_no = version_no + 1
        WHERE unit_id = NEW.unit_id
          AND status = 'Quarantined';
    ELSE
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

