-- Trigger File: trg_cold_chain_breach.sql
-- Automatically quarantines inventory units stored in equipment experiencing temperature breach.

CREATE OR REPLACE FUNCTION fn_cold_chain_breach()
RETURNS TRIGGER AS $$
DECLARE
    v_min_temp NUMERIC(4,1);
    v_max_temp NUMERIC(4,1);
    v_code VARCHAR(32);
    v_units_affected INT;
BEGIN
    SELECT storage_code, min_temp_c, max_temp_c
    INTO v_code, v_min_temp, v_max_temp
    FROM inventory_locations
    WHERE location_id = NEW.location_id;

    IF NEW.recorded_temp_c > v_max_temp OR NEW.recorded_temp_c < v_min_temp THEN
        NEW.alert_triggered := TRUE;

        UPDATE blood_units
        SET status = 'Quarantined',
            version_no = version_no + 1
        WHERE location_id = NEW.location_id
          AND status = 'Available';

        GET DIAGNOSTICS v_units_affected = ROW_COUNT;

        UPDATE inventory_locations
        SET current_temp_c = NEW.recorded_temp_c
        WHERE location_id = NEW.location_id;

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

