"""
10,000+ Row High-Fidelity Seeder for Blood Bank DBMS
Course: DBMS CSL0311 (ITM University Gwalior)
Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
Context: Gwalior Regional Blood Transfusion Center (GRBTC) & Madhya Pradesh Healthcare Corridor
"""

import os
import sqlite3
import random
import json
from datetime import datetime, date, timedelta

SEED_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(os.path.dirname(SEED_DIR))
DB_PATH = os.path.join(PROJECT_DIR, "backend", "blood_bank.db")
SQL_EXPORT_PATH = os.path.join(SEED_DIR, "seed_10k_postgres.sql")

random.seed(42)

# Indian First & Last Names
FIRST_NAMES_MALE = [
    "Rajesh", "Amit", "Vikram", "Sunil", "Pradeep", "Alok", "Manoj", "Sanjay", "Anil", "Deepak",
    "Rahul", "Rohan", "Suresh", "Mahesh", "Dinesh", "Gaurav", "Ayan", "Mohith", "Karan", "Arjun",
    "Naveen", "Pankaj", "Vikas", "Harish", "Neeraj", "Sachin", "Manish", "Tarun", "Ajay", "Vijay"
]
FIRST_NAMES_FEMALE = [
    "Pooja", "Sunita", "Anjali", "Diya", "Priya", "Sneha", "Kavita", "Ritu", "Rekha", "Meena",
    "Neha", "Swati", "Preeti", "Suman", "Shweta", "Divya", "Anita", "Geeta", "Seema", "Asha",
    "Deepika", "Komal", "Shikha", "Jyoti", "Nisha", "Rashmi", "Varsha", "Mamta", "Radha", "Arti"
]
LAST_NAMES = [
    "Sharma", "Verma", "Agrawal", "Gupta", "Mishra", "Pandey", "Tiwari", "Tomar", "Chauhan", "Singh",
    "Yadav", "Jain", "Bhardwaj", "Dubey", "Shrivastava", "Tripathi", "Saxena", "Kushwah", "Rajput", "Rathore",
    "Khan", "Qureshi", "Malhotra", "Bhatnagar", "Dixit", "Pathak", "Soni", "Chaurasia", "Patel", "Joshi"
]

# Blood groups with Indian population probability distribution
BLOOD_GROUPS = ['O+', 'B+', 'A+', 'AB+', 'O-', 'B-', 'A-', 'AB-']
BG_WEIGHTS = [38.0, 32.0, 22.0, 6.0, 1.5, 1.0, 0.5, 0.2]

COMPONENTS = ['Whole Blood', 'Packed RBC', 'Fresh Frozen Plasma', 'Platelets']
COMPONENT_SHELF_LIFE = {
    'Whole Blood': 35,
    'Packed RBC': 42,
    'Fresh Frozen Plasma': 365,
    'Platelets': 5
}

GWALIOR_HOSPITALS = [
    ("HOSP-JAH-01", "Jaya Arogya Hospital (JAH) - Super Speciality & Trauma Center", "Gwalior", "Gwalior", "Dr. R.K. Sikarwar", "+91-751-2403000", 3.2),
    ("HOSP-GRMC-02", "Gajra Raja Medical College & Associated Hospitals", "Gwalior", "Gwalior", "Dr. Sunita Tomar", "+91-751-2403100", 3.5),
    ("HOSP-BIMR-03", "BIMR Hospitals (Birla Institute of Medical Research)", "Gwalior", "Gwalior", "Dr. V.P. Agrawal", "+91-751-2405600", 6.8),
    ("HOSP-CHRI-04", "Cancer Hospital & Research Institute (CHRI)", "Gwalior", "Gwalior", "Dr. B.R. Shrivastava", "+91-751-2336502", 4.1),
    ("HOSP-DH-MORAR-05", "Civil District Hospital Morar", "Gwalior", "Gwalior", "Dr. Manoj Sharma", "+91-751-2368200", 7.4),
    ("HOSP-APOLLO-06", "Apollo Spectra Hospital Gwalior", "Gwalior", "Gwalior", "Dr. Neha Gupta", "+91-751-4000100", 5.2),
    ("HOSP-REGENCY-07", "Regency Hospital & Heart Centre", "Gwalior", "Gwalior", "Dr. Alok Mishra", "+91-751-2442200", 4.8),
    ("HOSP-KALYAN-08", "Kalyan Memorial Hospital", "Gwalior", "Gwalior", "Dr. Rajesh Jain", "+91-751-2321450", 5.9),
    ("HOSP-SAHARA-09", "Sahara Comprehensive Care Hospital", "Gwalior", "Gwalior", "Dr. P.K. Dubey", "+91-751-2489000", 8.2),
    ("HOSP-ASG-10", "ASG Eye and Surgical Hospital Gwalior", "Gwalior", "Gwalior", "Dr. Sachin Saxena", "+91-751-4078900", 6.1),
    ("HOSP-DIST-MORENA-11", "District Hospital Morena", "Morena", "Morena", "Dr. Ramvir Singh", "+91-7532-224500", 38.5),
    ("HOSP-DIST-BHIND-12", "District Hospital Bhind", "Bhind", "Bhind", "Dr. S.K. Rathore", "+91-7534-233100", 75.0),
    ("HOSP-DIST-DATIA-13", "Government Medical College Hospital Datia", "Datia", "Datia", "Dr. Dinesh Tiwari", "+91-7566-234200", 72.0),
    ("HOSP-DIST-SHIVPURI-14", "District Hospital Shivpuri", "Shivpuri", "Shivpuri", "Dr. Ajay Rajput", "+91-7492-223400", 115.0),
    ("HOSP-DIST-SHEOPUR-15", "District Hospital Sheopur", "Sheopur", "Sheopur", "Dr. Harish Khan", "+91-7530-221200", 210.0),
    ("HOSP-CHAMBAL-16", "Chambal Surgical & Maternity Hospital", "Morena", "Morena", "Dr. Ritu Chauhan", "+91-7532-245600", 42.0),
    ("HOSP-NAVJEEVAN-17", "Navjeevan Multi-Speciality Clinic", "Gwalior", "Gwalior", "Dr. Deepak Verma", "+91-751-2341122", 6.5),
    ("HOSP-MAX-CARE-18", "Max Care Trauma & Critical Care", "Gwalior", "Gwalior", "Dr. Priya Agrawal", "+91-751-2389900", 5.0),
    ("HOSP-SANJEEVANI-19", "Sanjeevani Children & Mother Hospital", "Gwalior", "Gwalior", "Dr. Kavita Pathak", "+91-751-2455500", 4.3),
    ("HOSP-CITY-LIFE-20", "City Life Hospital Lashkar", "Gwalior", "Gwalior", "Dr. Sanjay Tomar", "+91-751-2412345", 3.8),
    ("HOSP-PARAS-21", "Paras Emergency & Cardiac Care", "Gwalior", "Gwalior", "Dr. Tarun Soni", "+91-751-2467890", 7.1),
    ("HOSP-JYOTI-22", "Jyoti Hospital & Laparoscopy Centre", "Gwalior", "Gwalior", "Dr. Jyoti Sharma", "+91-751-2423344", 4.9),
    ("HOSP-AMRIT-23", "Amrit Health & Trauma Centre", "Gwalior", "Gwalior", "Dr. Vikram Singh", "+91-751-2434455", 8.0),
    ("HOSP-GLOBAL-24", "Global Care Hospital Thatipur", "Gwalior", "Gwalior", "Dr. Pooja Mishra", "+91-751-2345678", 5.4),
    ("HOSP-AYUSH-25", "Ayushmaan Multi-Speciality Hospital", "Gwalior", "Gwalior", "Dr. Anil Tiwari", "+91-751-2378901", 6.2),
    ("HOSP-LIFE-LINE-26", "Life Line Super Speciality", "Gwalior", "Gwalior", "Dr. Sunil Gupta", "+91-751-2390123", 9.1),
    ("HOSP-METRO-27", "Metro Hospital & Heart Institute", "Gwalior", "Gwalior", "Dr. Rahul Dubey", "+91-751-2401234", 5.7),
    ("HOSP-FORTIS-LIAISON-28", "Fortis Escorts Referral Centre Gwalior", "Gwalior", "Gwalior", "Dr. Swati Saxena", "+91-751-2412389", 4.6),
    ("HOSP-RAILWAY-29", "Divisional Railway Hospital Gwalior", "Gwalior", "Gwalior", "Dr. Suresh Chaurasia", "+91-751-2432200", 2.8),
    ("HOSP-BSF-30", "BSF Composite Hospital Tekanpur", "Tekanpur", "Gwalior", "Dr. Col. V.K. Joshi", "+91-751-2751000", 32.0)
]

DIAGNOSES = [
    "Severe Polytrauma & Hemorrhagic Shock", "Acute Dengue with Severe Thrombocytopenia",
    "Post-Partum Hemorrhage (PPH)", "Elective Coronary Artery Bypass Graft (CABG)",
    "Acute Lymphoblastic Leukemia (ALL)", "Thalassemia Major Regular Transfusion",
    "Gastrointestinal Bleeding / Peptic Ulcer", "Major Orthopedic Pelvic Reconstruction",
    "Aplastic Anemia Platelet Support", "Neonatal Hyperbilirubinemia Exchange Transfusion"
]

def generate_random_name():
    gender = random.choice(["Male", "Female"])
    first = random.choice(FIRST_NAMES_MALE if gender == "Male" else FIRST_NAMES_FEMALE)
    last = random.choice(LAST_NAMES)
    return f"{first} {last}", gender

def init_sqlite_db(conn):
    cur = conn.cursor()
    # Create tables
    cur.executescript("""
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS schema_versions (
        version_id INTEGER PRIMARY KEY,
        version_tag TEXT NOT NULL UNIQUE,
        description TEXT NOT NULL,
        checksum TEXT NOT NULL,
        applied_by TEXT NOT NULL,
        applied_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS technicians (
        tech_id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        license_no TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL CHECK (role IN ('Phlebotomist', 'Lab_Technologist', 'Supervisor', 'Director')),
        supervisor_id INTEGER REFERENCES technicians(tech_id) ON DELETE SET NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS inventory_locations (
        location_id INTEGER PRIMARY KEY AUTOINCREMENT,
        storage_code TEXT NOT NULL UNIQUE,
        facility_zone TEXT NOT NULL,
        component_type TEXT NOT NULL CHECK (component_type IN ('Whole Blood', 'Packed RBC', 'Fresh Frozen Plasma', 'Platelets')),
        min_temp_c REAL NOT NULL,
        max_temp_c REAL NOT NULL CHECK (max_temp_c >= min_temp_c),
        capacity_units INTEGER NOT NULL CHECK (capacity_units > 0),
        current_temp_c REAL NOT NULL
    );

    CREATE TABLE IF NOT EXISTS donors (
        donor_id INTEGER PRIMARY KEY AUTOINCREMENT,
        donor_code TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        date_of_birth TEXT NOT NULL,
        gender TEXT NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
        blood_group TEXT NOT NULL CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
        weight_kg REAL NOT NULL CHECK (weight_kg >= 45.0),
        hemoglobin_g_dl REAL NOT NULL CHECK (hemoglobin_g_dl >= 12.5),
        phone_masked TEXT NOT NULL,
        phone_encrypted TEXT NOT NULL,
        city TEXT NOT NULL DEFAULT 'Gwalior',
        pincode TEXT NOT NULL,
        last_donation_date TEXT,
        is_eligible INTEGER NOT NULL DEFAULT 1,
        deferral_reason TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS donations (
        donation_id INTEGER PRIMARY KEY AUTOINCREMENT,
        donor_id INTEGER NOT NULL REFERENCES donors(donor_id) ON DELETE RESTRICT,
        collected_by_tech_id INTEGER NOT NULL REFERENCES technicians(tech_id) ON DELETE RESTRICT,
        collection_date TEXT NOT NULL DEFAULT (date('now')),
        blood_group TEXT NOT NULL CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
        volume_ml INTEGER NOT NULL CHECK (volume_ml BETWEEN 350 AND 500),
        bag_serial_no TEXT NOT NULL UNIQUE,
        collection_status TEXT NOT NULL CHECK (collection_status IN ('Successful', 'Incomplete', 'Adverse_Donor_Event')),
        notes TEXT
    );

    CREATE TABLE IF NOT EXISTS blood_units (
        unit_id INTEGER PRIMARY KEY AUTOINCREMENT,
        unit_barcode TEXT NOT NULL UNIQUE,
        donation_id INTEGER NOT NULL REFERENCES donations(donation_id) ON DELETE RESTRICT,
        blood_group TEXT NOT NULL CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
        component_type TEXT NOT NULL CHECK (component_type IN ('Whole Blood', 'Packed RBC', 'Fresh Frozen Plasma', 'Platelets')),
        volume_ml INTEGER NOT NULL CHECK (volume_ml > 0),
        collection_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('Quarantined', 'Available', 'Allocated', 'Issued', 'Transfused', 'Expired', 'Discarded', 'Biohazard_Quarantined')),
        location_id INTEGER NOT NULL REFERENCES inventory_locations(location_id) ON DELETE RESTRICT,
        version_no INTEGER NOT NULL DEFAULT 1
    );

    CREATE TABLE IF NOT EXISTS laboratory_tests (
        test_id INTEGER PRIMARY KEY AUTOINCREMENT,
        unit_id INTEGER NOT NULL UNIQUE REFERENCES blood_units(unit_id) ON DELETE CASCADE,
        tested_by_tech_id INTEGER NOT NULL REFERENCES technicians(tech_id) ON DELETE RESTRICT,
        test_timestamp TEXT NOT NULL DEFAULT (datetime('now')),
        hiv_status TEXT NOT NULL CHECK (hiv_status IN ('Pending', 'Negative', 'Reactive')),
        hbsag_status TEXT NOT NULL CHECK (hbsag_status IN ('Pending', 'Negative', 'Reactive')),
        hcv_status TEXT NOT NULL CHECK (hcv_status IN ('Pending', 'Negative', 'Reactive')),
        syphilis_status TEXT NOT NULL CHECK (syphilis_status IN ('Pending', 'Negative', 'Reactive')),
        malaria_status TEXT NOT NULL CHECK (malaria_status IN ('Pending', 'Negative', 'Reactive')),
        blood_group_verified INTEGER NOT NULL DEFAULT 0,
        overall_result TEXT NOT NULL CHECK (overall_result IN ('Pending', 'Acceptable', 'Reactive', 'Inconclusive')),
        remarks TEXT
    );

    CREATE TABLE IF NOT EXISTS cold_chain_events (
        location_id INTEGER NOT NULL REFERENCES inventory_locations(location_id) ON DELETE CASCADE,
        event_seq_no INTEGER NOT NULL,
        recorded_temp_c REAL NOT NULL,
        recorded_at TEXT NOT NULL DEFAULT (datetime('now')),
        alert_triggered INTEGER NOT NULL DEFAULT 0,
        handled_by_tech_id INTEGER REFERENCES technicians(tech_id) ON DELETE SET NULL,
        PRIMARY KEY (location_id, event_seq_no)
    );

    CREATE TABLE IF NOT EXISTS hospitals (
        hospital_id INTEGER PRIMARY KEY AUTOINCREMENT,
        hospital_code TEXT NOT NULL UNIQUE,
        hospital_name TEXT NOT NULL,
        city TEXT NOT NULL DEFAULT 'Gwalior',
        district TEXT NOT NULL DEFAULT 'Gwalior',
        contact_person TEXT NOT NULL,
        emergency_phone TEXT NOT NULL,
        distance_km_from_bank REAL NOT NULL CHECK (distance_km_from_bank >= 0),
        license_verified INTEGER NOT NULL DEFAULT 1
    );

    CREATE TABLE IF NOT EXISTS blood_requests (
        request_id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_code TEXT NOT NULL UNIQUE,
        hospital_id INTEGER NOT NULL REFERENCES hospitals(hospital_id) ON DELETE RESTRICT,
        patient_ref_code TEXT NOT NULL,
        patient_age INTEGER NOT NULL CHECK (patient_age BETWEEN 0 AND 125),
        clinical_diagnosis TEXT NOT NULL,
        blood_group TEXT NOT NULL CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
        component_type TEXT NOT NULL CHECK (component_type IN ('Whole Blood', 'Packed RBC', 'Fresh Frozen Plasma', 'Platelets')),
        requested_qty INTEGER NOT NULL CHECK (requested_qty > 0),
        allocated_qty INTEGER NOT NULL DEFAULT 0 CHECK (allocated_qty <= requested_qty),
        priority TEXT NOT NULL CHECK (priority IN ('Emergency', 'Urgent', 'Routine')),
        request_status TEXT NOT NULL CHECK (request_status IN ('Pending', 'Partially_Allocated', 'Fulfilled', 'Cancelled')),
        requested_at TEXT NOT NULL DEFAULT (datetime('now')),
        required_by_date TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS allocations (
        allocation_id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id INTEGER NOT NULL REFERENCES blood_requests(request_id) ON DELETE RESTRICT,
        unit_id INTEGER NOT NULL UNIQUE REFERENCES blood_units(unit_id) ON DELETE RESTRICT,
        allocated_by_tech_id INTEGER NOT NULL REFERENCES technicians(tech_id) ON DELETE RESTRICT,
        compatibility_verified INTEGER NOT NULL DEFAULT 1,
        allocated_at TEXT NOT NULL DEFAULT (datetime('now')),
        issued_at TEXT,
        allocation_status TEXT NOT NULL CHECK (allocation_status IN ('Reserved', 'Issued', 'Transfused', 'Returned', 'Cancelled'))
    );

    CREATE TABLE IF NOT EXISTS transfusions (
        transfusion_id INTEGER PRIMARY KEY AUTOINCREMENT,
        allocation_id INTEGER NOT NULL UNIQUE REFERENCES allocations(allocation_id) ON DELETE RESTRICT,
        hospital_id INTEGER NOT NULL REFERENCES hospitals(hospital_id) ON DELETE RESTRICT,
        transfused_at TEXT NOT NULL DEFAULT (datetime('now')),
        adverse_reaction INTEGER NOT NULL DEFAULT 0,
        reaction_notes TEXT,
        reported_by_doctor TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS audit_logs (
        audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation_type TEXT NOT NULL CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
        previous_state TEXT,
        new_state TEXT,
        location_snapshot TEXT,
        changed_by TEXT NOT NULL,
        changed_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS ai_shortage_forecasts (
        forecast_id INTEGER PRIMARY KEY AUTOINCREMENT,
        forecast_date TEXT NOT NULL DEFAULT (date('now')),
        blood_group TEXT NOT NULL CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
        component_type TEXT NOT NULL CHECK (component_type IN ('Whole Blood', 'Packed RBC', 'Fresh Frozen Plasma', 'Platelets')),
        predicted_demand_units INTEGER NOT NULL CHECK (predicted_demand_units >= 0),
        current_available_units INTEGER NOT NULL CHECK (current_available_units >= 0),
        predicted_shortage_units INTEGER NOT NULL,
        risk_level TEXT NOT NULL CHECK (risk_level IN ('Low', 'Moderate', 'High', 'Critical')),
        confidence_score REAL NOT NULL CHECK (confidence_score BETWEEN 0.0 AND 1.0),
        model_version TEXT NOT NULL DEFAULT 'RF-v1.2',
        recommended_donor_outreach_count INTEGER NOT NULL DEFAULT 0,
        human_approved INTEGER NOT NULL DEFAULT 0,
        approved_by TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS ai_decision_logs (
        decision_id INTEGER PRIMARY KEY AUTOINCREMENT,
        feature_name TEXT NOT NULL,
        model_version TEXT NOT NULL,
        input_features TEXT NOT NULL,
        prediction_output TEXT NOT NULL,
        confidence_score REAL NOT NULL,
        human_approved INTEGER NOT NULL DEFAULT 0,
        reviewed_by_tech_id INTEGER REFERENCES technicians(tech_id) ON DELETE SET NULL,
        decision_timestamp TEXT NOT NULL DEFAULT (datetime('now')),
        rejection_reason TEXT
    );
    """)
    conn.commit()
    print("[+] SQLite schema tables initialized.")

def create_triggers(conn):
    cur = conn.cursor()
    cur.executescript("""
    -- Trigger 1: 90-Day Donor Interval Enforcement
    CREATE TRIGGER IF NOT EXISTS trg_donor_eligibility_90days
    BEFORE INSERT ON donations
    FOR EACH ROW
    BEGIN
        SELECT
            CASE
                WHEN (
                    SELECT is_eligible FROM donors WHERE donor_id = NEW.donor_id
                ) = 0 THEN
                    RAISE(ABORT, 'ELIGIBILITY_VIOLATION: Donor is currently deferred from blood donation.')
                WHEN (
                    SELECT weight_kg FROM donors WHERE donor_id = NEW.donor_id
                ) < 45.0 THEN
                    RAISE(ABORT, 'ELIGIBILITY_VIOLATION: Donor weight is below legal minimum (45 kg).')
                WHEN (
                    SELECT hemoglobin_g_dl FROM donors WHERE donor_id = NEW.donor_id
                ) < 12.5 THEN
                    RAISE(ABORT, 'ELIGIBILITY_VIOLATION: Donor hemoglobin is below legal threshold (12.5 g/dL).')
                WHEN (
                    SELECT CAST(julianday(NEW.collection_date) - julianday(MAX(collection_date)) AS INT)
                    FROM donations
                    WHERE donor_id = NEW.donor_id AND collection_status = 'Successful'
                ) < 90 THEN
                    RAISE(ABORT, 'ELIGIBILITY_VIOLATION: Mandatory 90-day recovery interval not met for donor.')
            END;
    END;

    -- Trigger 1b: Update Donor's last_donation_date on successful donation
    CREATE TRIGGER IF NOT EXISTS trg_donor_update_last_date
    AFTER INSERT ON donations
    FOR EACH ROW
    WHEN NEW.collection_status = 'Successful'
    BEGIN
        UPDATE donors
        SET last_donation_date = NEW.collection_date
        WHERE donor_id = NEW.donor_id;
    END;

    -- Trigger 2: Test Clearance Gatekeeper
    CREATE TRIGGER IF NOT EXISTS trg_enforce_test_clearance_reactive
    AFTER INSERT ON laboratory_tests
    FOR EACH ROW
    WHEN NEW.hiv_status = 'Reactive' OR NEW.hbsag_status = 'Reactive' OR
         NEW.hcv_status = 'Reactive' OR NEW.syphilis_status = 'Reactive' OR
         NEW.malaria_status = 'Reactive' OR NEW.overall_result = 'Reactive'
    BEGIN
        UPDATE blood_units
        SET status = 'Biohazard_Quarantined', version_no = version_no + 1
        WHERE unit_id = NEW.unit_id;
    END;

    CREATE TRIGGER IF NOT EXISTS trg_enforce_test_clearance_acceptable
    AFTER INSERT ON laboratory_tests
    FOR EACH ROW
    WHEN NEW.hiv_status = 'Negative' AND NEW.hbsag_status = 'Negative' AND
         NEW.hcv_status = 'Negative' AND NEW.syphilis_status = 'Negative' AND
         NEW.malaria_status = 'Negative' AND NEW.blood_group_verified = 1
    BEGIN
        UPDATE blood_units
        SET status = 'Available', version_no = version_no + 1
        WHERE unit_id = NEW.unit_id AND status = 'Quarantined';
    END;

    -- Trigger 3: Cold-Chain Breach Auto-Quarantine
    CREATE TRIGGER IF NOT EXISTS trg_cold_chain_breach
    AFTER INSERT ON cold_chain_events
    FOR EACH ROW
    WHEN NEW.recorded_temp_c > (SELECT max_temp_c FROM inventory_locations WHERE location_id = NEW.location_id)
      OR NEW.recorded_temp_c < (SELECT min_temp_c FROM inventory_locations WHERE location_id = NEW.location_id)
    BEGIN
        UPDATE blood_units
        SET status = 'Quarantined', version_no = version_no + 1
        WHERE location_id = NEW.location_id AND status = 'Available';

        UPDATE inventory_locations
        SET current_temp_c = NEW.recorded_temp_c
        WHERE location_id = NEW.location_id;
    END;

    -- Trigger 5: Anti-Tamper Hard Delete Protection
    CREATE TRIGGER IF NOT EXISTS trg_audit_anti_delete
    BEFORE DELETE ON audit_logs
    FOR EACH ROW
    BEGIN
        SELECT RAISE(ABORT, 'AUDIT_PROTECTION: Hard deletion prohibited by regulatory compliance standards (FDA 21 CFR Part 11 / Schedule F).');
    END;
    """)
    conn.commit()
    print("[+] SQLite triggers attached successfully after seed.")

def seed_database():
    print(f"[*] Seeding ~10,800+ records into {DB_PATH}...")
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    conn = sqlite3.connect(DB_PATH)
    init_sqlite_db(conn)
    cur = conn.cursor()

    # 1. Schema Versions (6 rows)
    versions = [
        (1, 'V1__core_tables', 'Initial creation of 14 BCNF core relational tables', 'sha256_v1_csl0311_core', 'Diya Motwani', '2026-10-15 10:00:00'),
        (2, 'V2__integrity_constraints', 'Application of 15 FK constraints and 20 CHECK constraints', 'sha256_v2_csl0311_constraints', 'Diya Motwani', '2026-10-20 11:30:00'),
        (3, 'V3__triggers_and_transactions', 'Deployment of 5 PL/pgSQL triggers, audit ledger, and anti-delete guards', 'sha256_v3_csl0311_triggers', 'Diya Motwani', '2026-10-28 14:15:00'),
        (4, 'V4__performance_indexes', 'Creation of 5 specialized partial/composite/GIN performance indexes', 'sha256_v4_csl0311_indexes', 'Ch. Mohith', '2026-11-02 16:45:00'),
        (5, 'V5__security_rbac_and_audit', 'Definition of 4 RBAC roles and least-privilege security matrix', 'sha256_v5_csl0311_security', 'Ch. Mohith', '2026-11-06 09:20:00'),
        (6, 'V6__ai_analytics_extension', 'Deployment of AI governance ledger and predictive shortage views', 'sha256_v6_csl0311_ai', 'Ayan Khan', '2026-11-10 17:00:00')
    ]
    cur.executemany("INSERT INTO schema_versions VALUES (?, ?, ?, ?, ?, ?)", versions)

    # 2. Technicians (25 rows) - 2 Directors, 5 Supervisors, 10 Phlebotomists, 8 Lab Technologists
    tech_data = [
        ("Dr. Arvind Shrivastava", "MPMC-DIR-101", "Director", None),
        ("Dr. Manisha Bhardwaj", "MPMC-DIR-102", "Director", None),
        ("Vikramaditya Parmar", "MP-SUP-201", "Supervisor", 1),
        ("Sunita Saxena", "MP-SUP-202", "Supervisor", 1),
        ("Pradeep Kushwah", "MP-SUP-203", "Supervisor", 2),
        ("Meenakshi Dubey", "MP-SUP-204", "Supervisor", 2),
        ("Ramesh Chandra Jain", "MP-SUP-205", "Supervisor", 1)
    ]
    # Phlebotomists (id 8-17)
    for i in range(10):
        name, _ = generate_random_name()
        sup = random.choice([3, 4, 5, 6, 7])
        tech_data.append((name, f"PHLEB-GWL-{300+i}", "Phlebotomist", sup))
    # Lab Technologists (id 18-25)
    for i in range(8):
        name, _ = generate_random_name()
        sup = random.choice([3, 4, 5, 6, 7])
        tech_data.append((name, f"LAB-TECH-{400+i}", "Lab_Technologist", sup))

    cur.executemany("INSERT INTO technicians (full_name, license_no, role, supervisor_id) VALUES (?, ?, ?, ?)", tech_data)

    # 3. Inventory Locations (20 equipment rows)
    # RBC Refrigerators (2 to 6 C), FFP Freezers (-35 to -20 C), Platelet Agitators (20 to 24 C), Whole Blood (2 to 6 C)
    locations = [
        ("FRZ-RBC-01", "Cold Room Alpha", "Packed RBC", 2.0, 6.0, 400, 4.2),
        ("FRZ-RBC-02", "Cold Room Alpha", "Packed RBC", 2.0, 6.0, 400, 3.8),
        ("FRZ-RBC-03", "Cold Room Beta", "Packed RBC", 2.0, 6.0, 350, 4.5),
        ("FRZ-RBC-04", "Emergency Trauma Stock", "Packed RBC", 2.0, 6.0, 200, 4.0),
        ("FRZ-FFP-01", "Deep Freeze Zone 1", "Fresh Frozen Plasma", -35.0, -20.0, 500, -28.4),
        ("FRZ-FFP-02", "Deep Freeze Zone 1", "Fresh Frozen Plasma", -35.0, -20.0, 500, -29.1),
        ("FRZ-FFP-03", "Deep Freeze Zone 2", "Fresh Frozen Plasma", -35.0, -20.0, 450, -27.5),
        ("FRZ-FFP-04", "Deep Freeze Zone 2", "Fresh Frozen Plasma", -35.0, -20.0, 400, -26.8),
        ("AGT-PLT-01", "Platelet Agitator Bay A", "Platelets", 20.0, 24.0, 150, 22.1),
        ("AGT-PLT-02", "Platelet Agitator Bay A", "Platelets", 20.0, 24.0, 150, 21.8),
        ("AGT-PLT-03", "Platelet Agitator Bay B", "Platelets", 20.0, 24.0, 120, 22.4),
        ("FRZ-WB-01", "Primary Quarantine Bay", "Whole Blood", 2.0, 6.0, 300, 4.1),
        ("FRZ-WB-02", "Primary Quarantine Bay", "Whole Blood", 2.0, 6.0, 300, 4.3),
        ("FRZ-WB-03", "Reserve Quarantine Room", "Whole Blood", 2.0, 6.0, 250, 3.9),
        ("FRZ-RBC-05", "Chambal Reserve Bay", "Packed RBC", 2.0, 6.0, 300, 4.4),
        ("FRZ-FFP-05", "Cryo Preservation Unit", "Fresh Frozen Plasma", -40.0, -25.0, 300, -32.0),
        ("AGT-PLT-04", "Emergency Agitator Mobile", "Platelets", 20.0, 24.0, 80, 22.0),
        ("FRZ-RBC-06", "Pediatric Blood Refrigerator", "Packed RBC", 2.0, 6.0, 150, 4.0),
        ("FRZ-WB-04", "Mobile Blood Van Storage 1", "Whole Blood", 2.0, 6.0, 120, 4.6),
        ("FRZ-WB-05", "Mobile Blood Van Storage 2", "Whole Blood", 2.0, 6.0, 120, 4.5)
    ]
    cur.executemany("INSERT INTO inventory_locations (storage_code, facility_zone, component_type, min_temp_c, max_temp_c, capacity_units, current_temp_c) VALUES (?, ?, ?, ?, ?, ?, ?)", locations)

    # 4. Hospitals (30 rows)
    cur.executemany("INSERT INTO hospitals (hospital_code, hospital_name, city, district, contact_person, emergency_phone, distance_km_from_bank) VALUES (?, ?, ?, ?, ?, ?, ?)", GWALIOR_HOSPITALS)

    # 5. Donors (600 rows)
    donors = []
    today = date(2026, 11, 11)
    for i in range(1, 601):
        name, gender = generate_random_name()
        code = f"DNR-GWL-{1000+i}"
        # Age between 18 and 62
        age_years = random.randint(19, 60)
        dob = today - timedelta(days=age_years*365 + random.randint(0, 300))
        bg = random.choices(BLOOD_GROUPS, weights=BG_WEIGHTS)[0]
        wt = round(random.uniform(48.0, 88.0), 1)
        hb = round(random.uniform(12.6, 16.8), 1)
        phone_raw = f"9{random.randint(100000000, 999999999)}"
        phone_masked = phone_raw[:6] + "XXXX"
        phone_encrypted = f"sha256_enc_{phone_raw}"
        pincode = random.choice(["474001", "474002", "474003", "474004", "474005", "474006", "474009", "474011", "474020"])
        city = random.choices(["Gwalior", "Morena", "Bhind", "Datia", "Shivpuri"], weights=[70, 10, 8, 6, 6])[0]

        # 75% are eligible, some donated >90 days ago, some <90 days (for trigger testing), some never
        is_elig = 1
        def_reason = None
        if i in [15, 42, 89, 134]: # A few explicitly deferred
            is_elig = 0
            def_reason = "Recent Dental Surgery / Antibiotic Course"

        # Last donation date
        rand_profile = random.random()
        if rand_profile < 0.20:
            last_don_date = None # First time donor
        elif rand_profile < 0.70:
            # Donated > 90 days ago (eligible)
            days_ago = random.randint(95, 700)
            last_don_date = str(today - timedelta(days=days_ago))
        else:
            # Donated < 90 days ago (ineligible for immediate donation)
            days_ago = random.randint(10, 85)
            last_don_date = str(today - timedelta(days=days_ago))

        created_dt = str(today - timedelta(days=random.randint(100, 1000))) + " 09:00:00"
        donors.append((code, name, str(dob), gender, bg, wt, hb, phone_masked, phone_encrypted, city, pincode, last_don_date, is_elig, def_reason, created_dt))

    cur.executemany("""
    INSERT INTO donors (donor_code, full_name, date_of_birth, gender, blood_group, weight_kg, hemoglobin_g_dl, phone_masked, phone_encrypted, city, pincode, last_donation_date, is_eligible, deferral_reason, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, donors)

    # 6. Donations (1,500 rows)
    # Generated historically from our donors
    donations = []
    cur.execute("PRAGMA foreign_keys = OFF") # Temporarily disable trigger check during bulk historical seed
    for d_id in range(1, 1501):
        donor_id = random.randint(1, 600)
        # Fetch donor blood group
        tech_id = random.randint(8, 17) # Phlebotomist
        don_date = today - timedelta(days=random.randint(1, 650))
        bg = random.choices(BLOOD_GROUPS, weights=BG_WEIGHTS)[0]
        vol = random.choice([350, 450, 450, 450, 350])
        bag_no = f"BAG-GWL-{2024 + (d_id % 3)}-{100000 + d_id}"
        stat = random.choices(["Successful", "Incomplete", "Adverse_Donor_Event"], weights=[96, 3, 1])[0]
        notes = "Standard phlebotomy session." if stat == "Successful" else "Early termination due to dizziness."
        donations.append((donor_id, tech_id, str(don_date), bg, vol, bag_no, stat, notes))

    cur.executemany("""
    INSERT INTO donations (donor_id, collected_by_tech_id, collection_date, blood_group, volume_ml, bag_serial_no, collection_status, notes)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, donations)

    # 7. Blood Units (2,200 rows)
    # Split from successful donations
    blood_units = []
    lab_tests = []
    unit_counter = 1
    for don_id in range(1, 1501):
        # Each whole blood donation produces either Whole Blood or components (RBC + FFP + Platelets)
        num_components = 1 if random.random() < 0.35 else 2
        for c_idx in range(num_components):
            if unit_counter > 2200:
                break
            barcode = f"ISBT-IND-GWL-{20250000 + unit_counter}"
            bg = random.choices(BLOOD_GROUPS, weights=BG_WEIGHTS)[0]
            comp = random.choice(COMPONENTS)
            vol = 280 if comp == 'Packed RBC' else 200 if comp == 'Fresh Frozen Plasma' else 60 if comp == 'Platelets' else 450
            
            # Collection date and Expiry calculation
            don_days_ago = random.randint(1, 300)
            col_date = today - timedelta(days=don_days_ago)
            shelf_days = COMPONENT_SHELF_LIFE[comp]
            exp_date = col_date + timedelta(days=shelf_days)
            exp_str = f"{exp_date} 23:59:59"

            # Assign location based on component (integer location_id 1..20)
            loc_candidates = [idx + 1 for idx, l in enumerate(locations) if l[2] == comp]
            loc_id = random.choice(loc_candidates) if loc_candidates else 1

            # Determine status based on expiration and random operational factors
            is_expired = (exp_date < today)
            if is_expired:
                status = random.choices(["Expired", "Discarded", "Transfused"], weights=[40, 20, 40])[0]
            else:
                # Active unit
                status = random.choices(["Available", "Quarantined", "Allocated", "Issued", "Biohazard_Quarantined"], weights=[65, 12, 12, 8, 3])[0]

            # Special viva feature: ensure at least 35 units expire within the next 48 hours for Exception Report 1
            if unit_counter <= 35:
                status = "Available"
                exp_date_near = today + timedelta(hours=random.randint(6, 46))
                exp_str = exp_date_near.strftime("%Y-%m-%d %H:%M:%S")

            blood_units.append((barcode, don_id, bg, comp, vol, str(col_date), exp_str, status, loc_id, 1))

            # 8. Laboratory Test for this unit (1:1)
            # HIV, HBsAg, HCV, Syphilis, Malaria
            tech_id = random.randint(18, 25) # Lab Tech
            test_ts = f"{col_date} 14:30:00"
            if status == "Biohazard_Quarantined":
                # One marker is reactive
                hiv = random.choice(["Negative", "Negative", "Reactive", "Negative"])
                hbsag = "Reactive" if hiv == "Negative" else "Negative"
                hcv = "Negative"
                syph = "Negative"
                mal = "Negative"
                overall = "Reactive"
            elif status == "Quarantined":
                hiv = "Pending"
                hbsag = "Pending"
                hcv = "Negative"
                syph = "Negative"
                mal = "Negative"
                overall = "Pending"
            else:
                hiv = "Negative"
                hbsag = "Negative"
                hcv = "Negative"
                syph = "Negative"
                mal = "Negative"
                overall = "Acceptable"

            lab_tests.append((unit_counter, tech_id, test_ts, hiv, hbsag, hcv, syph, mal, 1 if overall == "Acceptable" else 0, overall, "Screening complete."))
            unit_counter += 1

    cur.executemany("""
    INSERT INTO blood_units (unit_barcode, donation_id, blood_group, component_type, volume_ml, collection_date, expiry_date, status, location_id, version_no)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, blood_units)

    cur.executemany("""
    INSERT INTO laboratory_tests (unit_id, tested_by_tech_id, test_timestamp, hiv_status, hbsag_status, hcv_status, syphilis_status, malaria_status, blood_group_verified, overall_result, remarks)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, lab_tests)

    # 9. Cold Chain Events (Weak Entity) (1,200 rows)
    events = []
    for loc_id in range(1, 21):
        loc_info = locations[loc_id - 1]
        min_t, max_t = loc_info[3], loc_info[4]
        for seq in range(1, 61):
            ts = datetime(2026, 10, 1) + timedelta(hours=seq * 12)
            # Mostly safe temperature
            is_breach = (random.random() < 0.05)
            if is_breach:
                temp = round(max_t + random.uniform(1.2, 5.0), 1)
                alert = 1
                handled_tech = random.randint(18, 25)
            else:
                temp = round(random.uniform(min_t + 0.5, max_t - 0.5), 1)
                alert = 0
                handled_tech = None
            events.append((loc_id, seq, temp, ts.strftime("%Y-%m-%d %H:%M:%S"), alert, handled_tech))

    cur.executemany("""
    INSERT INTO cold_chain_events (location_id, event_seq_no, recorded_temp_c, recorded_at, alert_triggered, handled_by_tech_id)
    VALUES (?, ?, ?, ?, ?, ?)
    """, events)

    # 10. Blood Requests (1,100 rows)
    requests = []
    for req_id in range(1, 1101):
        hosp_id = random.randint(1, 30)
        code = f"REQ-GWL-{2025000 + req_id}"
        mrn = f"PT-{10000 + req_id}"
        age = random.randint(1, 88)
        diag = random.choice(DIAGNOSES)
        bg = random.choices(BLOOD_GROUPS, weights=BG_WEIGHTS)[0]
        comp = random.choice(COMPONENTS)
        qty = random.choices([1, 2, 3, 4, 6], weights=[45, 30, 15, 7, 3])[0]
        priority = random.choices(["Emergency", "Urgent", "Routine"], weights=[25, 45, 30])[0]
        
        req_ts = datetime(2026, 8, 1) + timedelta(hours=req_id * 2.1)
        lead_hours = 2 if priority == "Emergency" else 6 if priority == "Urgent" else 24
        req_by = req_ts + timedelta(hours=lead_hours)

        # Status & Allocation quantity
        if req_ts < datetime(2026, 11, 8):
            # Older requests mostly fulfilled
            status = random.choices(["Fulfilled", "Partially_Allocated", "Cancelled"], weights=[88, 8, 4])[0]
            alloc_qty = qty if status == "Fulfilled" else max(0, qty - 1) if status == "Partially_Allocated" else 0
        else:
            # Recent active requests
            status = random.choices(["Pending", "Partially_Allocated", "Fulfilled"], weights=[50, 30, 20])[0]
            alloc_qty = 0 if status == "Pending" else 1 if status == "Partially_Allocated" else qty

        requests.append((code, hosp_id, mrn, age, diag, bg, comp, qty, alloc_qty, priority, status, req_ts.strftime("%Y-%m-%d %H:%M:%S"), req_by.strftime("%Y-%m-%d %H:%M:%S")))

    cur.executemany("""
    INSERT INTO blood_requests (request_code, hospital_id, patient_ref_code, patient_age, clinical_diagnosis, blood_group, component_type, requested_qty, allocated_qty, priority, request_status, requested_at, required_by_date)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, requests)

    # 11. Allocations & Transfusions (1,200 allocations, 600 transfusions)
    allocations = []
    transfusions = []
    # Pick units that are Allocated, Issued, or Transfused
    cur.execute("SELECT unit_id, status FROM blood_units WHERE status IN ('Allocated', 'Issued', 'Transfused') LIMIT 1200")
    eligible_units = cur.fetchall()

    for idx, (u_id, u_status) in enumerate(eligible_units, start=1):
        req_id = random.randint(1, 1000)
        tech_id = random.randint(8, 17)
        alloc_status = "Transfused" if u_status == "Transfused" else "Issued" if u_status == "Issued" else "Reserved"
        alloc_ts = f"2026-10-15 {random.randint(10, 18)}:30:00"
        issue_ts = f"2026-10-15 {random.randint(19, 21)}:00:00" if alloc_status in ["Issued", "Transfused"] else None

        allocations.append((req_id, u_id, tech_id, 1, alloc_ts, issue_ts, alloc_status))

        if alloc_status == "Transfused" and len(transfusions) < 600:
            hosp_id = random.randint(1, 30)
            trans_ts = f"2026-10-16 {random.randint(1, 8)}:00:00"
            adverse = 1 if random.random() < 0.02 else 0 # 2% adverse reactions
            notes = "Mild febrile non-hemolytic reaction managed with paracetamol." if adverse else None
            doctor = random.choice(["Dr. Alok Mishra", "Dr. V.P. Agrawal", "Dr. Sunita Tomar", "Dr. B.R. Shrivastava"])
            transfusions.append((idx, hosp_id, trans_ts, adverse, notes, doctor))

    cur.executemany("""
    INSERT INTO allocations (request_id, unit_id, allocated_by_tech_id, compatibility_verified, allocated_at, issued_at, allocation_status)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    """, allocations)

    cur.executemany("""
    INSERT INTO transfusions (allocation_id, hospital_id, transfused_at, adverse_reaction, reaction_notes, reported_by_doctor)
    VALUES (?, ?, ?, ?, ?, ?)
    """, transfusions)

    # 12. Audit Logs (1,000+ rows)
    audit_logs = []
    for a_id in range(1, 1050):
        tbl = random.choice(["blood_units", "laboratory_tests", "allocations", "inventory_locations"])
        rec_id = str(random.randint(1, 2000))
        op = random.choice(["INSERT", "UPDATE"])
        prev_s = json.dumps({"status": "Quarantined", "location": 1})
        new_s = json.dumps({"status": "Available", "location": 1}) if a_id % 2 == 0 else json.dumps({"status": "Biohazard_Quarantined", "location": 2})
        loc_s = json.dumps({"storage_code": "FRZ-RBC-01", "temp": 4.2})
        actor = random.choice(["phleb_user", "lab_technologist", "system_daemon", "dr_shrivastava"])
        ts = f"2026-11-0{(a_id % 9) + 1} 12:00:00"
        audit_logs.append((tbl, rec_id, op, prev_s, new_s, loc_s, actor, ts))

    cur.executemany("""
    INSERT INTO audit_logs (table_name, record_id, operation_type, previous_state, new_state, location_snapshot, changed_by, changed_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, audit_logs)

    # 13. AI Shortage Forecasts (32 rows = 8 blood groups x 4 components)
    ai_forecasts = []
    f_id = 1
    for bg in BLOOD_GROUPS:
        for comp in COMPONENTS:
            pred_demand = random.randint(15, 95)
            # Get actual available count in DB
            cur.execute("SELECT COUNT(*) FROM blood_units WHERE blood_group = ? AND component_type = ? AND status = 'Available'", (bg, comp))
            curr_avail = cur.fetchone()[0]
            shortage = max(0, pred_demand - curr_avail)
            
            if shortage > 25:
                risk = "Critical"
            elif shortage > 10:
                risk = "High"
            elif shortage > 0:
                risk = "Moderate"
            else:
                risk = "Low"

            conf = round(random.uniform(0.85, 0.96), 3)
            outreach_cnt = max(0, shortage * 3) # Recommend calling 3x donors for every short unit
            approved = 1 if f_id in [1, 2, 5, 8] else 0
            approver = "Dr. Arvind Shrivastava" if approved else None

            ai_forecasts.append((str(today), bg, comp, pred_demand, curr_avail, shortage, risk, conf, "RF-v1.2", outreach_cnt, approved, approver))
            f_id += 1

    cur.executemany("""
    INSERT INTO ai_shortage_forecasts (forecast_date, blood_group, component_type, predicted_demand_units, current_available_units, predicted_shortage_units, risk_level, confidence_score, model_version, recommended_donor_outreach_count, human_approved, approved_by)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, ai_forecasts)

    conn.commit()
    create_triggers(conn)
    cur.execute("PRAGMA foreign_keys = ON")

    # Count total rows
    tables = [
        "schema_versions", "technicians", "inventory_locations", "donors", "donations",
        "blood_units", "laboratory_tests", "cold_chain_events", "hospitals",
        "blood_requests", "allocations", "transfusions", "audit_logs", "ai_shortage_forecasts"
    ]
    total_rows = 0
    print("\n=== SEEDING SUMMARY (PHASE 3 AUDIT) ===")
    for t in tables:
        cur.execute(f"SELECT COUNT(*) FROM {t}")
        cnt = cur.fetchone()[0]
        total_rows += cnt
        print(f"  • {t:<25} : {cnt:>6} rows")
    print(f"-------------------------------------------")
    print(f"  TOTAL DATABASE ROWS POPULATED : {total_rows:>6} rows\n")
    conn.close()

if __name__ == "__main__":
    seed_database()
