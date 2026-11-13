-- ============================================================================
-- Migration: V2__integrity_constraints.sql
-- Project: AI-Assisted Blood Bank and Donor Matching System (CSL0311)
-- Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
-- Purpose: Adds all Foreign Key relationships, CHECK constraints, and Domain Integrity.
-- ============================================================================

-- 1. FOREIGN KEY CONSTRAINTS (Referential Integrity)

-- Technicians supervisor hierarchy (Recursive)
ALTER TABLE technicians 
    ADD CONSTRAINT fk_tech_supervisor 
    FOREIGN KEY (supervisor_id) REFERENCES technicians(tech_id) 
    ON DELETE SET NULL;

-- Donations to Donors & Technicians
ALTER TABLE donations 
    ADD CONSTRAINT fk_donation_donor 
    FOREIGN KEY (donor_id) REFERENCES donors(donor_id) 
    ON DELETE RESTRICT,
    ADD CONSTRAINT fk_donation_technician 
    FOREIGN KEY (collected_by_tech_id) REFERENCES technicians(tech_id) 
    ON DELETE RESTRICT;

-- Blood Units to Donations & Storage Locations
ALTER TABLE blood_units 
    ADD CONSTRAINT fk_unit_donation 
    FOREIGN KEY (donation_id) REFERENCES donations(donation_id) 
    ON DELETE RESTRICT,
    ADD CONSTRAINT fk_unit_location 
    FOREIGN KEY (location_id) REFERENCES inventory_locations(location_id) 
    ON DELETE RESTRICT;

-- Laboratory Tests to Blood Units & Technicians
ALTER TABLE laboratory_tests 
    ADD CONSTRAINT fk_test_unit 
    FOREIGN KEY (unit_id) REFERENCES blood_units(unit_id) 
    ON DELETE CASCADE,
    ADD CONSTRAINT fk_test_technician 
    FOREIGN KEY (tested_by_tech_id) REFERENCES technicians(tech_id) 
    ON DELETE RESTRICT;

-- Cold Chain Events to Storage Locations & Handled Technicians (Weak Entity FK)
ALTER TABLE cold_chain_events 
    ADD CONSTRAINT fk_event_location 
    FOREIGN KEY (location_id) REFERENCES inventory_locations(location_id) 
    ON DELETE CASCADE,
    ADD CONSTRAINT fk_event_technician 
    FOREIGN KEY (handled_by_tech_id) REFERENCES technicians(tech_id) 
    ON DELETE SET NULL;

-- Blood Requests to Hospitals
ALTER TABLE blood_requests 
    ADD CONSTRAINT fk_req_hospital 
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id) 
    ON DELETE RESTRICT;

-- Allocations to Requests, Units & Technicians (Associative Entity FKs)
ALTER TABLE allocations 
    ADD CONSTRAINT fk_alloc_request 
    FOREIGN KEY (request_id) REFERENCES blood_requests(request_id) 
    ON DELETE RESTRICT,
    ADD CONSTRAINT fk_alloc_unit 
    FOREIGN KEY (unit_id) REFERENCES blood_units(unit_id) 
    ON DELETE RESTRICT,
    ADD CONSTRAINT fk_alloc_technician 
    FOREIGN KEY (allocated_by_tech_id) REFERENCES technicians(tech_id) 
    ON DELETE RESTRICT;

-- Transfusions to Allocations & Hospitals
ALTER TABLE transfusions 
    ADD CONSTRAINT fk_transfusion_alloc 
    FOREIGN KEY (allocation_id) REFERENCES allocations(allocation_id) 
    ON DELETE RESTRICT,
    ADD CONSTRAINT fk_transfusion_hospital 
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id) 
    ON DELETE RESTRICT;


-- 2. CHECK CONSTRAINTS (Domain & Business Integrity)

-- Donors Health & Physical Parameters
ALTER TABLE donors
    ADD CONSTRAINT chk_donor_gender 
        CHECK (gender IN ('Male', 'Female', 'Other')),
    ADD CONSTRAINT chk_donor_blood_group 
        CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    ADD CONSTRAINT chk_donor_weight 
        CHECK (weight_kg >= 45.0),
    ADD CONSTRAINT chk_donor_hb 
        CHECK (hemoglobin_g_dl >= 12.5);

-- Donations Session Rules
ALTER TABLE donations
    ADD CONSTRAINT chk_donation_volume 
        CHECK (volume_ml BETWEEN 350 AND 500),
    ADD CONSTRAINT chk_donation_status 
        CHECK (collection_status IN ('Successful', 'Incomplete', 'Adverse_Donor_Event'));

-- Inventory Locations Safe Temperature Range
ALTER TABLE inventory_locations
    ADD CONSTRAINT chk_location_temp 
        CHECK (max_temp_c >= min_temp_c),
    ADD CONSTRAINT chk_location_capacity 
        CHECK (capacity_units > 0);

-- Blood Units Status & Expiration Validity
ALTER TABLE blood_units
    ADD CONSTRAINT chk_unit_status 
        CHECK (status IN ('Quarantined', 'Available', 'Allocated', 'Issued', 'Transfused', 'Expired', 'Discarded', 'Biohazard_Quarantined')),
    ADD CONSTRAINT chk_unit_component 
        CHECK (component_type IN ('Whole Blood', 'Packed RBC', 'Fresh Frozen Plasma', 'Platelets')),
    ADD CONSTRAINT chk_unit_expiry 
        CHECK (expiry_date > collection_date);

-- Laboratory Tests Screening Domains
ALTER TABLE laboratory_tests
    ADD CONSTRAINT chk_test_hiv 
        CHECK (hiv_status IN ('Pending', 'Negative', 'Reactive')),
    ADD CONSTRAINT chk_test_hbsag 
        CHECK (hbsag_status IN ('Pending', 'Negative', 'Reactive')),
    ADD CONSTRAINT chk_test_hcv 
        CHECK (hcv_status IN ('Pending', 'Negative', 'Reactive')),
    ADD CONSTRAINT chk_test_syphilis 
        CHECK (syphilis_status IN ('Pending', 'Negative', 'Reactive')),
    ADD CONSTRAINT chk_test_malaria 
        CHECK (malaria_status IN ('Pending', 'Negative', 'Reactive')),
    ADD CONSTRAINT chk_test_overall 
        CHECK (overall_result IN ('Pending', 'Acceptable', 'Reactive', 'Inconclusive'));

-- Hospital Blood Requisitions Limits & Ceilings
ALTER TABLE blood_requests
    ADD CONSTRAINT chk_patient_age 
        CHECK (patient_age BETWEEN 0 AND 125),
    ADD CONSTRAINT chk_request_qty 
        CHECK (requested_qty > 0),
    ADD CONSTRAINT chk_alloc_ceiling 
        CHECK (allocated_qty <= requested_qty),
    ADD CONSTRAINT chk_request_priority 
        CHECK (priority IN ('Emergency', 'Urgent', 'Routine')),
    ADD CONSTRAINT chk_request_status 
        CHECK (request_status IN ('Pending', 'Partially_Allocated', 'Fulfilled', 'Cancelled'));

-- Allocations Workflow Status
ALTER TABLE allocations
    ADD CONSTRAINT chk_alloc_status 
        CHECK (allocation_status IN ('Reserved', 'Issued', 'Transfused', 'Returned', 'Cancelled'));

-- Audit Operation Types
ALTER TABLE audit_logs
    ADD CONSTRAINT chk_audit_operation 
        CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE'));

-- AI Forecast Confidence & Risk Range
ALTER TABLE ai_shortage_forecasts
    ADD CONSTRAINT chk_ai_confidence 
        CHECK (confidence_score BETWEEN 0.000 AND 1.000),
    ADD CONSTRAINT chk_ai_risk_level 
        CHECK (risk_level IN ('Low', 'Moderate', 'High', 'Critical')),
    ADD CONSTRAINT chk_ai_pred_demand 
        CHECK (predicted_demand_units >= 0),
    ADD CONSTRAINT chk_ai_curr_avail 
        CHECK (current_available_units >= 0);

-- Record Migration V2 in registry
INSERT INTO schema_versions (version_id, version_tag, description, checksum, applied_by)
VALUES (2, 'V2__integrity_constraints', 'Application of 15 FK constraints and 20 CHECK constraints', 'sha256_v2_csl0311_constraints', 'Diya Motwani')
ON CONFLICT (version_id) DO NOTHING;

