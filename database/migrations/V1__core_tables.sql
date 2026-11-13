-- ============================================================================
-- Migration: V1__core_tables.sql
-- Project: AI-Assisted Blood Bank and Donor Matching System (CSL0311)
-- Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
-- Purpose: Defines the 14 core relational tables satisfying 3NF/BCNF requirements.
-- ============================================================================

-- Table 1: Schema Migration Version Registry
CREATE TABLE IF NOT EXISTS schema_versions (
    version_id INT PRIMARY KEY,
    version_tag VARCHAR(32) NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL,
    checksum VARCHAR(64) NOT NULL,
    applied_by VARCHAR(64) NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table 2: Technicians & Supervisory Hierarchy (Recursive Relationship)
CREATE TABLE IF NOT EXISTS technicians (
    tech_id SERIAL PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    license_no VARCHAR(64) NOT NULL UNIQUE,
    role VARCHAR(40) NOT NULL,
    supervisor_id INT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table 3: Cold-Chain Storage Equipment & Freezers
CREATE TABLE IF NOT EXISTS inventory_locations (
    location_id SERIAL PRIMARY KEY,
    storage_code VARCHAR(32) NOT NULL UNIQUE,
    facility_zone VARCHAR(64) NOT NULL,
    component_type VARCHAR(32) NOT NULL,
    min_temp_c NUMERIC(4,1) NOT NULL,
    max_temp_c NUMERIC(4,1) NOT NULL,
    capacity_units INT NOT NULL,
    current_temp_c NUMERIC(4,1) NOT NULL
);

-- Table 4: Donors Registry (Demographics & Medical Fitness Parameters)
CREATE TABLE IF NOT EXISTS donors (
    donor_id SERIAL PRIMARY KEY,
    donor_code VARCHAR(32) NOT NULL UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10) NOT NULL,
    blood_group VARCHAR(5) NOT NULL,
    weight_kg NUMERIC(5,2) NOT NULL,
    hemoglobin_g_dl NUMERIC(4,2) NOT NULL,
    phone_masked VARCHAR(20) NOT NULL,
    phone_encrypted VARCHAR(255) NOT NULL,
    city VARCHAR(64) NOT NULL DEFAULT 'Gwalior',
    pincode VARCHAR(10) NOT NULL,
    last_donation_date DATE,
    is_eligible BOOLEAN NOT NULL DEFAULT TRUE,
    deferral_reason VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table 5: Blood Donation Sessions
CREATE TABLE IF NOT EXISTS donations (
    donation_id SERIAL PRIMARY KEY,
    donor_id INT NOT NULL,
    collected_by_tech_id INT NOT NULL,
    collection_date DATE NOT NULL DEFAULT CURRENT_DATE,
    blood_group VARCHAR(5) NOT NULL,
    volume_ml INT NOT NULL,
    bag_serial_no VARCHAR(64) NOT NULL UNIQUE,
    collection_status VARCHAR(32) NOT NULL,
    notes TEXT
);

-- Table 6: Separated Blood Units & Inventory Items
CREATE TABLE IF NOT EXISTS blood_units (
    unit_id SERIAL PRIMARY KEY,
    unit_barcode VARCHAR(64) NOT NULL UNIQUE,
    donation_id INT NOT NULL,
    blood_group VARCHAR(5) NOT NULL,
    component_type VARCHAR(32) NOT NULL,
    volume_ml INT NOT NULL,
    collection_date DATE NOT NULL,
    expiry_date TIMESTAMPTZ NOT NULL,
    status VARCHAR(32) NOT NULL,
    location_id INT NOT NULL,
    version_no INT NOT NULL DEFAULT 1
);

-- Table 7: Laboratory Screening Tests (1:1 with Blood Units)
CREATE TABLE IF NOT EXISTS laboratory_tests (
    test_id SERIAL PRIMARY KEY,
    unit_id INT NOT NULL UNIQUE,
    tested_by_tech_id INT NOT NULL,
    test_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    hiv_status VARCHAR(16) NOT NULL,
    hbsag_status VARCHAR(16) NOT NULL,
    hcv_status VARCHAR(16) NOT NULL,
    syphilis_status VARCHAR(16) NOT NULL,
    malaria_status VARCHAR(16) NOT NULL,
    blood_group_verified BOOLEAN NOT NULL DEFAULT FALSE,
    overall_result VARCHAR(20) NOT NULL,
    remarks TEXT
);

-- Table 8: Cold-Chain Telemetry Events (Weak Entity with Composite PK)
CREATE TABLE IF NOT EXISTS cold_chain_events (
    location_id INT NOT NULL,
    event_seq_no BIGINT NOT NULL,
    recorded_temp_c NUMERIC(4,1) NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    alert_triggered BOOLEAN NOT NULL DEFAULT FALSE,
    handled_by_tech_id INT,
    PRIMARY KEY (location_id, event_seq_no)
);

-- Table 9: Hospitals & Healthcare Facilities Directory
CREATE TABLE IF NOT EXISTS hospitals (
    hospital_id SERIAL PRIMARY KEY,
    hospital_code VARCHAR(32) NOT NULL UNIQUE,
    hospital_name VARCHAR(150) NOT NULL,
    city VARCHAR(64) NOT NULL DEFAULT 'Gwalior',
    district VARCHAR(64) NOT NULL DEFAULT 'Gwalior',
    contact_person VARCHAR(100) NOT NULL,
    emergency_phone VARCHAR(20) NOT NULL,
    distance_km_from_bank NUMERIC(5,2) NOT NULL,
    license_verified BOOLEAN NOT NULL DEFAULT TRUE
);

-- Table 10: Blood Requests & Hospital Requisitions
CREATE TABLE IF NOT EXISTS blood_requests (
    request_id SERIAL PRIMARY KEY,
    request_code VARCHAR(32) NOT NULL UNIQUE,
    hospital_id INT NOT NULL,
    patient_ref_code VARCHAR(64) NOT NULL,
    patient_age INT NOT NULL,
    clinical_diagnosis VARCHAR(255) NOT NULL,
    blood_group VARCHAR(5) NOT NULL,
    component_type VARCHAR(32) NOT NULL,
    requested_qty INT NOT NULL,
    allocated_qty INT NOT NULL DEFAULT 0,
    priority VARCHAR(16) NOT NULL,
    request_status VARCHAR(32) NOT NULL,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    required_by_date TIMESTAMPTZ NOT NULL
);

-- Table 11: Blood Allocations (Associative Entity resolving M:N)
CREATE TABLE IF NOT EXISTS allocations (
    allocation_id SERIAL PRIMARY KEY,
    request_id INT NOT NULL,
    unit_id INT NOT NULL UNIQUE,
    allocated_by_tech_id INT NOT NULL,
    compatibility_verified BOOLEAN NOT NULL DEFAULT TRUE,
    allocated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    issued_at TIMESTAMPTZ,
    allocation_status VARCHAR(32) NOT NULL
);

-- Table 12: Transfusions & Hemovigilance
CREATE TABLE IF NOT EXISTS transfusions (
    transfusion_id SERIAL PRIMARY KEY,
    allocation_id INT NOT NULL UNIQUE,
    hospital_id INT NOT NULL,
    transfused_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    adverse_reaction BOOLEAN NOT NULL DEFAULT FALSE,
    reaction_notes TEXT,
    reported_by_doctor VARCHAR(120) NOT NULL
);

-- Table 13: Immutable Regulatory Audit Logs with JSONB Snapshots
CREATE TABLE IF NOT EXISTS audit_logs (
    audit_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(64) NOT NULL,
    record_id VARCHAR(64) NOT NULL,
    operation_type VARCHAR(10) NOT NULL,
    previous_state JSONB,
    new_state JSONB,
    location_snapshot JSONB,
    changed_by VARCHAR(64) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table 14: AI Shortage Forecasts & Predictive Demands
CREATE TABLE IF NOT EXISTS ai_shortage_forecasts (
    forecast_id SERIAL PRIMARY KEY,
    forecast_date DATE NOT NULL DEFAULT CURRENT_DATE,
    blood_group VARCHAR(5) NOT NULL,
    component_type VARCHAR(32) NOT NULL,
    predicted_demand_units INT NOT NULL,
    current_available_units INT NOT NULL,
    predicted_shortage_units INT NOT NULL,
    risk_level VARCHAR(16) NOT NULL,
    confidence_score NUMERIC(4,3) NOT NULL,
    model_version VARCHAR(32) NOT NULL DEFAULT 'RF-v1.2',
    recommended_donor_outreach_count INT NOT NULL DEFAULT 0,
    human_approved BOOLEAN NOT NULL DEFAULT FALSE,
    approved_by VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Record Migration V1 in registry
INSERT INTO schema_versions (version_id, version_tag, description, checksum, applied_by)
VALUES (1, 'V1__core_tables', 'Initial creation of 14 BCNF core relational tables', 'sha256_v1_csl0311_core', 'Diya Motwani')
ON CONFLICT (version_id) DO NOTHING;

