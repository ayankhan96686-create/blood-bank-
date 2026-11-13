-- Trigger File: trg_audit_blood_unit_custody.sql
-- Records immutable JSONB audit log on blood unit status/location modifications.

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

