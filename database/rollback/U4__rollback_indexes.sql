-- Rollback: U4__rollback_indexes.sql
DROP INDEX IF EXISTS idx_units_avail_bg_comp_exp;
DROP INDEX IF EXISTS idx_donations_donor_date;
DROP INDEX IF EXISTS idx_requests_priority_status_date;
DROP INDEX IF EXISTS idx_audit_jsonb_gin;
DROP INDEX IF EXISTS idx_tests_pending_queue;
DROP INDEX IF EXISTS idx_units_donation_fk;
DROP INDEX IF EXISTS idx_units_location_fk;
DROP INDEX IF EXISTS idx_allocations_request_fk;
DROP INDEX IF EXISTS idx_allocations_tech_fk;
DROP INDEX IF EXISTS idx_transfusions_hospital_fk;
DROP INDEX IF EXISTS idx_cold_chain_event_time;
DELETE FROM schema_versions WHERE version_id = 4;

