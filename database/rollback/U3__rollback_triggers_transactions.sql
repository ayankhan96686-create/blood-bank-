-- Rollback: U3__rollback_triggers_transactions.sql
DROP TRIGGER IF EXISTS trg_donor_eligibility_90days ON donations;
DROP FUNCTION IF EXISTS fn_enforce_donor_eligibility_90days();

DROP TRIGGER IF EXISTS trg_enforce_test_clearance ON laboratory_tests;
DROP FUNCTION IF EXISTS fn_enforce_test_clearance();

DROP TRIGGER IF EXISTS trg_cold_chain_breach ON cold_chain_events;
DROP FUNCTION IF EXISTS fn_cold_chain_breach();

DROP TRIGGER IF EXISTS trg_audit_blood_unit_custody ON blood_units;
DROP FUNCTION IF EXISTS fn_audit_blood_unit_custody();

DROP TRIGGER IF EXISTS trg_audit_anti_delete ON audit_logs;
DROP TRIGGER IF EXISTS trg_transfusion_anti_delete ON transfusions;
DROP FUNCTION IF EXISTS fn_prevent_regulatory_hard_delete();

DELETE FROM schema_versions WHERE version_id = 3;

