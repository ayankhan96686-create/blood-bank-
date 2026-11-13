-- ============================================================================
-- Stored Procedure: sp_allocate_blood_units.sql
-- Project: AI-Assisted Blood Bank and Donor Matching System (CSL0311)
-- Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
-- Purpose: Executes atomic FEFO allocation with ACID row locking (SELECT ... FOR UPDATE SKIP LOCKED).
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_allocate_blood_units(
    p_request_id INT,
    p_tech_id INT,
    INOUT p_allocated_count INT DEFAULT 0,
    INOUT p_status_message VARCHAR(255) DEFAULT ''
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_req RECORD;
    v_needed_qty INT;
    v_unit RECORD;
    v_units_allocated_this_run INT := 0;
BEGIN
    -- 1. Fetch and validate blood request
    SELECT request_id, hospital_id, blood_group, component_type, requested_qty, allocated_qty, priority, request_status
    INTO v_req
    FROM blood_requests
    WHERE request_id = p_request_id
    FOR UPDATE; -- Lock request row

    IF NOT FOUND THEN
        p_allocated_count := 0;
        p_status_message := 'ERROR: Request ID does not exist.';
        RETURN;
    END IF;

    IF v_req.request_status IN ('Fulfilled', 'Cancelled') THEN
        p_allocated_count := 0;
        p_status_message := 'WARNING: Request is already ' || v_req.request_status || '.';
        RETURN;
    END IF;

    v_needed_qty := v_req.requested_qty - v_req.allocated_qty;
    IF v_needed_qty <= 0 THEN
        p_allocated_count := 0;
        p_status_message := 'NOTICE: Requested quantity is already fully allocated.';
        RETURN;
    END IF;

    -- 2. Iterate through compatible, safe Available units using FEFO order
    -- Using FOR UPDATE SKIP LOCKED to prevent lock-wait / deadlocks between concurrent requests
    FOR v_unit IN
        SELECT u.unit_id, u.unit_barcode, u.blood_group, u.expiry_date
        FROM blood_units u
        WHERE u.component_type = v_req.component_type
          AND u.status = 'Available'
          AND u.expiry_date > NOW()
          AND fn_check_compatibility(u.blood_group, v_req.blood_group, v_req.component_type) = TRUE
        ORDER BY u.expiry_date ASC
        LIMIT v_needed_qty
        FOR UPDATE SKIP LOCKED
    LOOP
        -- Create active allocation record
        INSERT INTO allocations (
            request_id,
            unit_id,
            allocated_by_tech_id,
            compatibility_verified,
            allocated_at,
            allocation_status
        )
        VALUES (
            v_req.request_id,
            v_unit.unit_id,
            p_tech_id,
            TRUE,
            NOW(),
            'Reserved'
        );

        -- Update blood unit status to Allocated
        UPDATE blood_units
        SET status = 'Allocated',
            version_no = version_no + 1
        WHERE unit_id = v_unit.unit_id;

        v_units_allocated_this_run := v_units_allocated_this_run + 1;
    END LOOP;

    -- 3. Update request status
    IF v_units_allocated_this_run > 0 THEN
        UPDATE blood_requests
        SET allocated_qty = allocated_qty + v_units_allocated_this_run,
            request_status = CASE 
                WHEN allocated_qty + v_units_allocated_this_run >= requested_qty THEN 'Fulfilled'
                ELSE 'Partially_Allocated'
            END
        WHERE request_id = v_req.request_id;
    END IF;

    p_allocated_count := v_units_allocated_this_run;
    IF v_units_allocated_this_run = v_needed_qty THEN
        p_status_message := 'SUCCESS: Requisition fully fulfilled (' || v_units_allocated_this_run || ' units allocated).';
    ELSIF v_units_allocated_this_run > 0 THEN
        p_status_message := 'PARTIAL: Allocated ' || v_units_allocated_this_run || ' units. Remaining ' || (v_needed_qty - v_units_allocated_this_run) || ' units waitlisted.';
    ELSE
        p_status_message := 'DEFICIT: Zero compatible safe units available in stock. Initiating AI donor outreach alert.';
    END IF;

END;
$$;

