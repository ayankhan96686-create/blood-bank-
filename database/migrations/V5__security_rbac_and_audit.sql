-- ============================================================================
-- Migration: V5__security_rbac_and_audit.sql
-- Project: AI-Assisted Blood Bank and Donor Matching System (CSL0311)
-- Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
-- Purpose: Defines Role-Based Access Control (4 roles) and grants principle of least privilege.
-- ============================================================================

-- Create 4 Specialized Security Roles
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'clinical_staff') THEN
        CREATE ROLE clinical_staff;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'lab_staff') THEN
        CREATE ROLE lab_staff;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'blood_bank_admin') THEN
        CREATE ROLE blood_bank_admin;
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'regulatory_auditor') THEN
        CREATE ROLE regulatory_auditor;
    END IF;
END $$;

-- Revoke default public table privileges
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

-- 1. Role: clinical_staff (Phlebotomy & Patient Care Liaisons)
GRANT SELECT ON donors TO clinical_staff;
GRANT INSERT, UPDATE (weight_kg, hemoglobin_g_dl, city, pincode, is_eligible, deferral_reason) ON donors TO clinical_staff;
GRANT SELECT, INSERT ON donations TO clinical_staff;
GRANT SELECT ON blood_units TO clinical_staff;
GRANT SELECT, INSERT, UPDATE ON blood_requests TO clinical_staff;
GRANT SELECT, INSERT, UPDATE ON allocations TO clinical_staff;
GRANT SELECT, INSERT ON transfusions TO clinical_staff;
GRANT SELECT ON hospitals TO clinical_staff;
GRANT SELECT ON inventory_locations TO clinical_staff;

-- 2. Role: lab_staff (Diagnostic Technicians & Cold-Chain Officers)
GRANT SELECT ON blood_units TO lab_staff;
GRANT SELECT, INSERT, UPDATE ON laboratory_tests TO lab_staff;
GRANT SELECT, INSERT ON cold_chain_events TO lab_staff;
GRANT SELECT, UPDATE (current_temp_c) ON inventory_locations TO lab_staff;
GRANT SELECT ON technicians TO lab_staff;

-- 3. Role: blood_bank_admin (Chief Medical Officers & Operational Directors)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO blood_bank_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO blood_bank_admin;

-- 4. Role: regulatory_auditor (Independent Government & Accreditation Auditors)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO regulatory_auditor;
-- Explicitly revoke write capabilities for regulatory_auditor
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA public FROM regulatory_auditor;

-- Record Migration V5 in registry
INSERT INTO schema_versions (version_id, version_tag, description, checksum, applied_by)
VALUES (5, 'V5__security_rbac_and_audit', 'Definition of 4 RBAC roles and least-privilege security matrix', 'sha256_v5_csl0311_security', 'Ch. Mohith')
ON CONFLICT (version_id) DO NOTHING;

