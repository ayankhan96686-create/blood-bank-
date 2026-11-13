-- Rollback: U2__rollback_constraints.sql
-- Drop Foreign Keys
ALTER TABLE technicians DROP CONSTRAINT IF EXISTS fk_tech_supervisor;
ALTER TABLE donations DROP CONSTRAINT IF EXISTS fk_donation_donor;
ALTER TABLE donations DROP CONSTRAINT IF EXISTS fk_donation_technician;
ALTER TABLE blood_units DROP CONSTRAINT IF EXISTS fk_unit_donation;
ALTER TABLE blood_units DROP CONSTRAINT IF EXISTS fk_unit_location;
ALTER TABLE laboratory_tests DROP CONSTRAINT IF EXISTS fk_test_unit;
ALTER TABLE laboratory_tests DROP CONSTRAINT IF EXISTS fk_test_technician;
ALTER TABLE cold_chain_events DROP CONSTRAINT IF EXISTS fk_event_location;
ALTER TABLE cold_chain_events DROP CONSTRAINT IF EXISTS fk_event_technician;
ALTER TABLE blood_requests DROP CONSTRAINT IF EXISTS fk_req_hospital;
ALTER TABLE allocations DROP CONSTRAINT IF EXISTS fk_alloc_request;
ALTER TABLE allocations DROP CONSTRAINT IF EXISTS fk_alloc_unit;
ALTER TABLE allocations DROP CONSTRAINT IF EXISTS fk_alloc_technician;
ALTER TABLE transfusions DROP CONSTRAINT IF EXISTS fk_transfusion_alloc;
ALTER TABLE transfusions DROP CONSTRAINT IF EXISTS fk_transfusion_hospital;

-- Drop Check Constraints
ALTER TABLE donors DROP CONSTRAINT IF EXISTS chk_donor_gender;
ALTER TABLE donors DROP CONSTRAINT IF EXISTS chk_donor_blood_group;
ALTER TABLE donors DROP CONSTRAINT IF EXISTS chk_donor_weight;
ALTER TABLE donors DROP CONSTRAINT IF EXISTS chk_donor_hb;
ALTER TABLE donations DROP CONSTRAINT IF EXISTS chk_donation_volume;
ALTER TABLE donations DROP CONSTRAINT IF EXISTS chk_donation_status;
ALTER TABLE inventory_locations DROP CONSTRAINT IF EXISTS chk_location_temp;
ALTER TABLE inventory_locations DROP CONSTRAINT IF EXISTS chk_location_capacity;
ALTER TABLE blood_units DROP CONSTRAINT IF EXISTS chk_unit_status;
ALTER TABLE blood_units DROP CONSTRAINT IF EXISTS chk_unit_component;
ALTER TABLE blood_units DROP CONSTRAINT IF EXISTS chk_unit_expiry;
ALTER TABLE laboratory_tests DROP CONSTRAINT IF EXISTS chk_test_hiv;
ALTER TABLE laboratory_tests DROP CONSTRAINT IF EXISTS chk_test_hbsag;
ALTER TABLE laboratory_tests DROP CONSTRAINT IF EXISTS chk_test_hcv;
ALTER TABLE laboratory_tests DROP CONSTRAINT IF EXISTS chk_test_syphilis;
ALTER TABLE laboratory_tests DROP CONSTRAINT IF EXISTS chk_test_malaria;
ALTER TABLE laboratory_tests DROP CONSTRAINT IF EXISTS chk_test_overall;
ALTER TABLE blood_requests DROP CONSTRAINT IF EXISTS chk_patient_age;
ALTER TABLE blood_requests DROP CONSTRAINT IF EXISTS chk_request_qty;
ALTER TABLE blood_requests DROP CONSTRAINT IF EXISTS chk_alloc_ceiling;
ALTER TABLE blood_requests DROP CONSTRAINT IF EXISTS chk_request_priority;
ALTER TABLE blood_requests DROP CONSTRAINT IF EXISTS chk_request_status;
ALTER TABLE allocations DROP CONSTRAINT IF EXISTS chk_alloc_status;
ALTER TABLE audit_logs DROP CONSTRAINT IF EXISTS chk_audit_operation;
ALTER TABLE ai_shortage_forecasts DROP CONSTRAINT IF EXISTS chk_ai_confidence;
ALTER TABLE ai_shortage_forecasts DROP CONSTRAINT IF EXISTS chk_ai_risk_level;
ALTER TABLE ai_shortage_forecasts DROP CONSTRAINT IF EXISTS chk_ai_pred_demand;
ALTER TABLE ai_shortage_forecasts DROP CONSTRAINT IF EXISTS chk_ai_curr_avail;

DELETE FROM schema_versions WHERE version_id = 2;

