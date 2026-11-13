-- Rollback: U6__rollback_ai_extension.sql
DROP VIEW IF EXISTS vw_ai_active_shortages;
DROP TABLE IF EXISTS ai_decision_logs CASCADE;
DELETE FROM schema_versions WHERE version_id = 6;

