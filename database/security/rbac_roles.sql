-- ============================================================================
-- Security & RBAC Configuration: rbac_roles.sql
-- Project: AI-Assisted Blood Bank and Donor Matching System (CSL0311)
-- Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
-- ============================================================================

-- Create Roles
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

-- 1. clinical_staff
GRANT SELECT ON donors TO clinical_staff;
GRANT INSERT, UPDATE (weight_kg, hemoglobin_g_dl, city, pincode, is_eligible, deferral_reason) ON donors TO clinical_staff;
GRANT SELECT, INSERT ON donations TO clinical_staff;
GRANT SELECT ON blood_units TO clinical_staff;
GRANT SELECT, INSERT, UPDATE ON blood_requests TO clinical_staff;
GRANT SELECT, INSERT, UPDATE ON allocations TO clinical_staff;
GRANT SELECT, INSERT ON transfusions TO clinical_staff;
GRANT SELECT ON hospitals TO clinical_staff;
GRANT SELECT ON inventory_locations TO clinical_staff;
GRANT SELECT ON vw_live_blood_inventory TO clinical_staff;
GRANT SELECT ON vw_donor_masked_clinical TO clinical_staff;
GRANT SELECT ON vw_hospital_fulfillment_sla TO clinical_staff;

-- 2. lab_staff
GRANT SELECT ON blood_units TO lab_staff;
GRANT SELECT, INSERT, UPDATE ON laboratory_tests TO lab_staff;
GRANT SELECT, INSERT ON cold_chain_events TO lab_staff;
GRANT SELECT, UPDATE (current_temp_c) ON inventory_locations TO lab_staff;
GRANT SELECT ON technicians TO lab_staff;
GRANT SELECT ON vw_live_blood_inventory TO lab_staff;
GRANT SELECT ON vw_expiring_units_7days TO lab_staff;

-- 3. blood_bank_admin
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO blood_bank_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO blood_bank_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO blood_bank_admin;

-- 4. regulatory_auditor
GRANT SELECT ON ALL TABLES IN SCHEMA public TO regulatory_auditor;
GRANT SELECT ON ALL VIEWS IN SCHEMA public TO regulatory_auditor;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA public FROM regulatory_auditor;

