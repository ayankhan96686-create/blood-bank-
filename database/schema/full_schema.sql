-- ============================================================================
-- Complete Master Schema: full_schema.sql
-- Project: AI-Assisted Blood Bank and Donor Matching System (CSL0311)
-- Institution: ITM University Gwalior
-- Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
-- Target: PostgreSQL 16 (Full BCNF Relational Specification)
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Schema Versions Registry
CREATE TABLE IF NOT EXISTS schema_versions (
    version_id INT PRIMARY KEY,
    version_tag VARCHAR(32) NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL,
    checksum VARCHAR(64) NOT NULL,
    applied_by VARCHAR(64) NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Technicians (Recursive Supervisor Hierarchy)
CREATE TABLE IF NOT EXISTS technicians (
    tech_id SERIAL PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    license_no VARCHAR(64) NOT NULL UNIQUE,
    role VARCHAR(40) NOT NULL CHECK (role IN ('Phlebotomist', 'Lab_Technologist', 'Supervisor', 'Director')),
    supervisor_id INT REFERENCES technicians(tech_id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Cold-Chain Storage Equipment
CREATE TABLE IF NOT EXISTS inventory_locations (
    location_id SERIAL PRIMARY KEY,
    storage_code VARCHAR(32) NOT NULL UNIQUE,
    facility_zone VARCHAR(64) NOT NULL,
    component_type VARCHAR(32) NOT NULL CHECK (component_type IN ('Whole Blood', 'Packed RBC', 'Fresh Frozen Plasma', 'Platelets')),
    min_temp_c NUMERIC(4,1) NOT NULL,
    max_temp_c NUMERIC(4,1) NOT NULL CHECK (max_temp_c >= min_temp_c),
    capacity_units INT NOT NULL CHECK (capacity_units > 0),
    current_temp_c NUMERIC(4,1) NOT NULL
);

-- 4. Donors Registry
CREATE TABLE IF NOT EXISTS donors (
    donor_id SERIAL PRIMARY KEY,
    donor_code VARCHAR(32) NOT NULL UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
    blood_group VARCHAR(5) NOT NULL CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    weight_kg NUMERIC(5,2) NOT NULL CHECK (weight_kg >= 45.0),
    hemoglobin_g_dl NUMERIC(4,2) NOT NULL CHECK (hemoglobin_g_dl >= 12.5),
    phone_masked VARCHAR(20) NOT NULL,
    phone_encrypted VARCHAR(255) NOT NULL,
    city VARCHAR(64) NOT NULL DEFAULT 'Gwalior',
    pincode VARCHAR(10) NOT NULL,
    last_donation_date DATE,
    is_eligible BOOLEAN NOT NULL DEFAULT TRUE,
    deferral_reason VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Donations
CREATE TABLE IF NOT EXISTS donations (
    donation_id SERIAL PRIMARY KEY,
    donor_id INT NOT NULL REFERENCES donors(donor_id) ON DELETE RESTRICT,
    collected_by_tech_id INT NOT NULL REFERENCES technicians(tech_id) ON DELETE RESTRICT,
    collection_date DATE NOT NULL DEFAULT CURRENT_DATE,
    blood_group VARCHAR(5) NOT NULL CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    volume_ml INT NOT NULL CHECK (volume_ml BETWEEN 350 AND 500),
    bag_serial_no VARCHAR(64) NOT NULL UNIQUE,
    collection_status VARCHAR(32) NOT NULL CHECK (collection_status IN ('Successful', 'Incomplete', 'Adverse_Donor_Event')),
    notes TEXT
);

-- 6. Blood Units
CREATE TABLE IF NOT EXISTS blood_units (
    unit_id SERIAL PRIMARY KEY,
    unit_barcode VARCHAR(64) NOT NULL UNIQUE,
    donation_id INT NOT NULL REFERENCES donations(donation_id) ON DELETE RESTRICT,
    blood_group VARCHAR(5) NOT NULL CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    component_type VARCHAR(32) NOT NULL CHECK (component_type IN ('Whole Blood', 'Packed RBC', 'Fresh Frozen Plasma', 'Platelets')),
    volume_ml INT NOT NULL CHECK (volume_ml > 0),
    collection_date DATE NOT NULL,
    expiry_date TIMESTAMPTZ NOT NULL CHECK (expiry_date > collection_date),
    status VARCHAR(32) NOT NULL CHECK (status IN ('Quarantined', 'Available', 'Allocated', 'Issued', 'Transfused', 'Expired', 'Discarded', 'Biohazard_Quarantined')),
    location_id INT NOT NULL REFERENCES inventory_locations(location_id) ON DELETE RESTRICT,
    version_no INT NOT NULL DEFAULT 1
);

-- 7. Laboratory Screening Tests
CREATE TABLE IF NOT EXISTS laboratory_tests (
    test_id SERIAL PRIMARY KEY,
    unit_id INT NOT NULL UNIQUE REFERENCES blood_units(unit_id) ON DELETE CASCADE,
    tested_by_tech_id INT NOT NULL REFERENCES technicians(tech_id) ON DELETE RESTRICT,
    test_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    hiv_status VARCHAR(16) NOT NULL CHECK (hiv_status IN ('Pending', 'Negative', 'Reactive')),
    hbsag_status VARCHAR(16) NOT NULL CHECK (hbsag_status IN ('Pending', 'Negative', 'Reactive')),
    hcv_status VARCHAR(16) NOT NULL CHECK (hcv_status IN ('Pending', 'Negative', 'Reactive')),
    syphilis_status VARCHAR(16) NOT NULL CHECK (syphilis_status IN ('Pending', 'Negative', 'Reactive')),
    malaria_status VARCHAR(16) NOT NULL CHECK (malaria_status IN ('Pending', 'Negative', 'Reactive')),
    blood_group_verified BOOLEAN NOT NULL DEFAULT FALSE,
    overall_result VARCHAR(20) NOT NULL CHECK (overall_result IN ('Pending', 'Acceptable', 'Reactive', 'Inconclusive')),
    remarks TEXT
);

-- 8. Cold Chain Events (Weak Entity)
CREATE TABLE IF NOT EXISTS cold_chain_events (
    location_id INT NOT NULL REFERENCES inventory_locations(location_id) ON DELETE CASCADE,
    event_seq_no BIGINT NOT NULL,
    recorded_temp_c NUMERIC(4,1) NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    alert_triggered BOOLEAN NOT NULL DEFAULT FALSE,
    handled_by_tech_id INT REFERENCES technicians(tech_id) ON DELETE SET NULL,
    PRIMARY KEY (location_id, event_seq_no)
);

-- 9. Hospitals Directory
CREATE TABLE IF NOT EXISTS hospitals (
    hospital_id SERIAL PRIMARY KEY,
    hospital_code VARCHAR(32) NOT NULL UNIQUE,
    hospital_name VARCHAR(150) NOT NULL,
    city VARCHAR(64) NOT NULL DEFAULT 'Gwalior',
    district VARCHAR(64) NOT NULL DEFAULT 'Gwalior',
    contact_person VARCHAR(100) NOT NULL,
    emergency_phone VARCHAR(20) NOT NULL,
    distance_km_from_bank NUMERIC(5,2) NOT NULL CHECK (distance_km_from_bank >= 0),
    license_verified BOOLEAN NOT NULL DEFAULT TRUE
);

-- 10. Blood Requests
CREATE TABLE IF NOT EXISTS blood_requests (
    request_id SERIAL PRIMARY KEY,
    request_code VARCHAR(32) NOT NULL UNIQUE,
    hospital_id INT NOT NULL REFERENCES hospitals(hospital_id) ON DELETE RESTRICT,
    patient_ref_code VARCHAR(64) NOT NULL,
    patient_age INT NOT NULL CHECK (patient_age BETWEEN 0 AND 125),
    clinical_diagnosis VARCHAR(255) NOT NULL,
    blood_group VARCHAR(5) NOT NULL CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    component_type VARCHAR(32) NOT NULL CHECK (component_type IN ('Whole Blood', 'Packed RBC', 'Fresh Frozen Plasma', 'Platelets')),
    requested_qty INT NOT NULL CHECK (requested_qty > 0),
    allocated_qty INT NOT NULL DEFAULT 0 CHECK (allocated_qty <= requested_qty),
    priority VARCHAR(16) NOT NULL CHECK (priority IN ('Emergency', 'Urgent', 'Routine')),
    request_status VARCHAR(32) NOT NULL CHECK (request_status IN ('Pending', 'Partially_Allocated', 'Fulfilled', 'Cancelled')),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    required_by_date TIMESTAMPTZ NOT NULL
);

-- 11. Allocations (Associative Entity)
CREATE TABLE IF NOT EXISTS allocations (
    allocation_id SERIAL PRIMARY KEY,
    request_id INT NOT NULL REFERENCES blood_requests(request_id) ON DELETE RESTRICT,
    unit_id INT NOT NULL UNIQUE REFERENCES blood_units(unit_id) ON DELETE RESTRICT,
    allocated_by_tech_id INT NOT NULL REFERENCES technicians(tech_id) ON DELETE RESTRICT,
    compatibility_verified BOOLEAN NOT NULL DEFAULT TRUE,
    allocated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    issued_at TIMESTAMPTZ,
    allocation_status VARCHAR(32) NOT NULL CHECK (allocation_status IN ('Reserved', 'Issued', 'Transfused', 'Returned', 'Cancelled'))
);

-- 12. Transfusions
CREATE TABLE IF NOT EXISTS transfusions (
    transfusion_id SERIAL PRIMARY KEY,
    allocation_id INT NOT NULL UNIQUE REFERENCES allocations(allocation_id) ON DELETE RESTRICT,
    hospital_id INT NOT NULL REFERENCES hospitals(hospital_id) ON DELETE RESTRICT,
    transfused_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    adverse_reaction BOOLEAN NOT NULL DEFAULT FALSE,
    reaction_notes TEXT,
    reported_by_doctor VARCHAR(120) NOT NULL
);

-- 13. Audit Logs (Immutable Ledger)
CREATE TABLE IF NOT EXISTS audit_logs (
    audit_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(64) NOT NULL,
    record_id VARCHAR(64) NOT NULL,
    operation_type VARCHAR(10) NOT NULL CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
    previous_state JSONB,
    new_state JSONB,
    location_snapshot JSONB,
    changed_by VARCHAR(64) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 14. AI Shortage Forecasts
CREATE TABLE IF NOT EXISTS ai_shortage_forecasts (
    forecast_id SERIAL PRIMARY KEY,
    forecast_date DATE NOT NULL DEFAULT CURRENT_DATE,
    blood_group VARCHAR(5) NOT NULL CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    component_type VARCHAR(32) NOT NULL CHECK (component_type IN ('Whole Blood', 'Packed RBC', 'Fresh Frozen Plasma', 'Platelets')),
    predicted_demand_units INT NOT NULL CHECK (predicted_demand_units >= 0),
    current_available_units INT NOT NULL CHECK (current_available_units >= 0),
    predicted_shortage_units INT NOT NULL,
    risk_level VARCHAR(16) NOT NULL CHECK (risk_level IN ('Low', 'Moderate', 'High', 'Critical')),
    confidence_score NUMERIC(4,3) NOT NULL CHECK (confidence_score BETWEEN 0.000 AND 1.000),
    model_version VARCHAR(32) NOT NULL DEFAULT 'RF-v1.2',
    recommended_donor_outreach_count INT NOT NULL DEFAULT 0,
    human_approved BOOLEAN NOT NULL DEFAULT FALSE,
    approved_by VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- AI Decision Logs
CREATE TABLE IF NOT EXISTS ai_decision_logs (
    decision_id SERIAL PRIMARY KEY,
    feature_name VARCHAR(64) NOT NULL,
    model_version VARCHAR(32) NOT NULL,
    input_features JSONB NOT NULL,
    prediction_output JSONB NOT NULL,
    confidence_score NUMERIC(4,3) NOT NULL,
    human_approved BOOLEAN NOT NULL DEFAULT FALSE,
    reviewed_by_tech_id INT REFERENCES technicians(tech_id) ON DELETE SET NULL,
    decision_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    rejection_reason VARCHAR(255)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_units_avail_bg_comp_exp ON blood_units (blood_group, component_type, expiry_date ASC) WHERE status = 'Available';
CREATE INDEX IF NOT EXISTS idx_donations_donor_date ON donations (donor_id, collection_date DESC);
CREATE INDEX IF NOT EXISTS idx_requests_priority_status_date ON blood_requests (required_by_date ASC, priority) WHERE request_status IN ('Pending', 'Partially_Allocated');
CREATE INDEX IF NOT EXISTS idx_audit_jsonb_gin ON audit_logs USING GIN (new_state);
CREATE INDEX IF NOT EXISTS idx_tests_pending_queue ON laboratory_tests (test_timestamp ASC) WHERE overall_result = 'Pending';

