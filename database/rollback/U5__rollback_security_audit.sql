-- Rollback: U5__rollback_security_audit.sql
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM clinical_staff, lab_staff, blood_bank_admin, regulatory_auditor;
DROP ROLE IF EXISTS clinical_staff;
DROP ROLE IF EXISTS lab_staff;
DROP ROLE IF EXISTS blood_bank_admin;
DROP ROLE IF EXISTS regulatory_auditor;
DELETE FROM schema_versions WHERE version_id = 5;

