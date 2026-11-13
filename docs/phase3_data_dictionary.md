# Phase 3: Comprehensive Data Dictionary, PHI Classification & Storage Estimation
**Course:** DBMS CSL0311 – Problem-Based & Project-Based Learning  
**Project:** AI-Assisted Blood Bank and Donor Matching System (ITM University Gwalior)  
**Authors:** Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith  

---

## 1. Data Profiling & Dictionary (14 Tables)

### Table 1: `schema_versions`
Tracks schema evolutions (V1 to V6), checksums, and deployment metadata.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `version_id` | INT | PRIMARY KEY | NO | Incremental migration version (e.g. 1, 2, ... 6) |
| `version_tag` | VARCHAR(32) | UNIQUE | NO | Flyway-style tag (e.g. 'V1__core_tables') |
| `description` | VARCHAR(255) | — | NO | Migration purpose and boundary description |
| `checksum` | VARCHAR(64) | — | NO | SHA-256 hash of migration script |
| `applied_by` | VARCHAR(64) | — | NO | Author or migration agent name |
| `applied_at` | TIMESTAMPTZ | DEFAULT NOW() | NO | Timestamp of execution |

### Table 2: `technicians`
Maintains phlebotomists, lab technologists, and supervisory hierarchy.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `tech_id` | SERIAL | PRIMARY KEY | NO | Unique internal surrogate identifier |
| `full_name` | VARCHAR(120) | — | NO | Official technician name |
| `license_no` | VARCHAR(64) | UNIQUE | NO | State Medical Council registration ID |
| `role` | VARCHAR(40) | CHECK IN ('Phlebotomist', 'Lab_Technologist', 'Supervisor', 'Director') | NO | Operational duty designation |
| `supervisor_id`| INT | FOREIGN KEY -> technicians(tech_id) | YES | **Recursive relationship** to supervising senior |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | NO | Record creation timestamp |

### Table 3: `inventory_locations`
Physical cold-storage freezers, refrigerators, and platelet agitators.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `location_id` | SERIAL | PRIMARY KEY | NO | Primary key for storage equipment |
| `storage_code` | VARCHAR(32) | UNIQUE | NO | Equipment barcode/label (e.g., 'FRZ-RBC-01') |
| `facility_zone`| VARCHAR(64) | — | NO | Physical room or wing (e.g., 'Cold Room A') |
| `component_type`| VARCHAR(32)| CHECK IN ('Whole Blood', 'Packed RBC', 'Fresh Frozen Plasma', 'Platelets') | NO | Designated component compatibility |
| `min_temp_c` | NUMERIC(4,1)| — | NO | Lower safety temperature threshold (°C) |
| `max_temp_c` | NUMERIC(4,1)| CHECK (max_temp_c >= min_temp_c) | NO | Upper safety temperature threshold (°C) |
| `capacity_units`| INT | CHECK (capacity_units > 0) | NO | Max unit holding capacity |
| `current_temp_c`| NUMERIC(4,1)| — | NO | Latest live sensor temperature reading |

### Table 4: `donors`
Voluntary and replacement donor registry with medical fitness parameters.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `donor_id` | SERIAL | PRIMARY KEY | NO | Internal donor identifier |
| `donor_code` | VARCHAR(32) | UNIQUE | NO | Public donor code (e.g., 'DNR-GWL-1001') |
| `full_name` | VARCHAR(120) | — | NO | Full legal donor name |
| `date_of_birth`| DATE | — | NO | Used for dynamic age validation (18–65) |
| `gender` | VARCHAR(10) | CHECK IN ('Male', 'Female', 'Other') | NO | Biological gender |
| `blood_group` | VARCHAR(5) | CHECK IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') | NO | Verified donor blood group |
| `weight_kg` | NUMERIC(5,2)| CHECK (weight_kg >= 45.0) | NO | Mandatory minimum body weight in kg |
| `hemoglobin_g_dl`| NUMERIC(4,2)| CHECK (hemoglobin_g_dl >= 12.5) | NO | Mandatory minimum hemoglobin level |
| `phone_masked`| VARCHAR(20) | — | NO | Masked phone for clinical UI ('XXXXXX4321') |
| `phone_encrypted`| VARCHAR(255)| — | NO | Encrypted/hashed contact for privacy |
| `city` | VARCHAR(64) | DEFAULT 'Gwalior' | NO | Donor residential city |
| `pincode` | VARCHAR(10) | — | NO | Postal pin code (e.g., '474001') |
| `last_donation_date`| DATE | — | YES | Date of most recent whole-blood donation |
| `is_eligible` | BOOLEAN | DEFAULT TRUE | NO | Eligibility flag updated by health criteria |
| `deferral_reason`| VARCHAR(255)| — | YES | Specific deferral cause if ineligible |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | NO | Registration timestamp |

### Table 5: `donations`
Individual blood donation sessions.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `donation_id` | SERIAL | PRIMARY KEY | NO | Donation session identifier |
| `donor_id` | INT | FOREIGN KEY -> donors(donor_id) | NO | Donor reference |
| `collected_by_tech_id`| INT | FOREIGN KEY -> technicians(tech_id) | NO | Phlebotomist reference |
| `collection_date`| DATE | DEFAULT CURRENT_DATE | NO | Date of collection session |
| `blood_group` | VARCHAR(5) | — | NO | Confirmed blood group |
| `volume_ml` | INT | CHECK (volume_ml BETWEEN 350 AND 500) | NO | Volume collected in mL (standard 350/450) |
| `bag_serial_no`| VARCHAR(64) | UNIQUE | NO | Pre-printed manufacturer bag serial |
| `collection_status`| VARCHAR(32)| CHECK IN ('Successful', 'Incomplete', 'Adverse_Donor_Event') | NO | Session outcome |
| `notes` | TEXT | — | YES | Clinical observations |

### Table 6: `blood_units`
Separated biological blood products in inventory.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `unit_id` | SERIAL | PRIMARY KEY | NO | Primary surrogate key |
| `unit_barcode` | VARCHAR(64) | UNIQUE | NO | ISBT 128 / national format barcode |
| `donation_id` | INT | FOREIGN KEY -> donations(donation_id) | NO | Source donation session |
| `blood_group` | VARCHAR(5) | — | NO | Unit blood group |
| `component_type`| VARCHAR(32)| CHECK IN ('Whole Blood', 'Packed RBC', 'Fresh Frozen Plasma', 'Platelets') | NO | Biological component classification |
| `volume_ml` | INT | CHECK (volume_ml > 0) | NO | Net component volume |
| `collection_date`| DATE | — | NO | Collection date for shelf-life reference |
| `expiry_date` | TIMESTAMPTZ | CHECK (expiry_date > collection_date) | NO | Precise expiration timestamp |
| `status` | VARCHAR(32) | CHECK IN ('Quarantined', 'Available', 'Allocated', 'Issued', 'Transfused', 'Expired', 'Discarded', 'Biohazard_Quarantined') | NO | Current inventory lifecycle status |
| `location_id` | INT | FOREIGN KEY -> inventory_locations(location_id) | NO | Assigned cold-storage equipment |
| `version_no` | INT | DEFAULT 1 | NO | Optimistic concurrency control version |

### Table 7: `laboratory_tests`
Five-panel infectious disease screening and immunohematology.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `test_id` | SERIAL | PRIMARY KEY | NO | Test record identifier |
| `unit_id` | INT | FOREIGN KEY -> blood_units(unit_id) UNIQUE | NO | Linked blood unit (1:1 screening) |
| `tested_by_tech_id`| INT | FOREIGN KEY -> technicians(tech_id) | NO | Testing technologist |
| `test_timestamp`| TIMESTAMPTZ| DEFAULT NOW() | NO | Assay completion timestamp |
| `hiv_status` | VARCHAR(16) | CHECK IN ('Pending', 'Negative', 'Reactive') | NO | HIV-1/2 antibody & p24 antigen |
| `hbsag_status` | VARCHAR(16) | CHECK IN ('Pending', 'Negative', 'Reactive') | NO | Hepatitis B surface antigen |
| `hcv_status` | VARCHAR(16) | CHECK IN ('Pending', 'Negative', 'Reactive') | NO | Hepatitis C antibody |
| `syphilis_status`| VARCHAR(16) | CHECK IN ('Pending', 'Negative', 'Reactive') | NO | VDRL / TPHA serology |
| `malaria_status` | VARCHAR(16) | CHECK IN ('Pending', 'Negative', 'Reactive') | NO | Rapid diagnostic / smear assay |
| `blood_group_verified`| BOOLEAN | DEFAULT FALSE | NO | Forward & reverse grouping confirmation |
| `overall_result`| VARCHAR(20) | CHECK IN ('Pending', 'Acceptable', 'Reactive', 'Inconclusive') | NO | Composite safety clearance |
| `remarks` | TEXT | — | YES | Diagnostic technician remarks |

### Table 8: `cold_chain_events`
**Weak Entity** dependent on `inventory_locations`. Continuous temperature log.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `location_id` | INT | FOREIGN KEY -> inventory_locations(location_id) | NO | Storage unit reference (Composite PK part 1) |
| `event_seq_no` | BIGINT | — | NO | Sequence counter per location (Composite PK part 2) |
| `recorded_temp_c`| NUMERIC(4,1)| — | NO | Sensor reading in Celsius |
| `recorded_at` | TIMESTAMPTZ | DEFAULT NOW() | NO | Timestamp of telemetry packet |
| `alert_triggered`| BOOLEAN | DEFAULT FALSE | NO | True if outside min/max threshold |
| `handled_by_tech_id`| INT | FOREIGN KEY -> technicians(tech_id) | YES | Technician resolving temperature alarm |

### Table 9: `hospitals`
Registered client hospitals and medical colleges in Gwalior and Madhya Pradesh.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `hospital_id` | SERIAL | PRIMARY KEY | NO | Hospital primary key |
| `hospital_code` | VARCHAR(32) | UNIQUE | NO | Short institutional code (e.g. 'HOSP-JAH-01') |
| `hospital_name` | VARCHAR(150) | — | NO | Official healthcare facility name |
| `city` | VARCHAR(64) | DEFAULT 'Gwalior' | NO | City location |
| `district` | VARCHAR(64) | DEFAULT 'Gwalior' | NO | Administrative district |
| `contact_person`| VARCHAR(100) | — | NO | Transfusion in-charge / Blood bank liaison |
| `emergency_phone`| VARCHAR(20) | — | NO | 24x7 emergency helpline |
| `distance_km_from_bank`| NUMERIC(5,2)| CHECK (distance_km_from_bank >= 0) | NO | Transit distance for delivery SLA |
| `license_verified`| BOOLEAN | DEFAULT TRUE | NO | Drug Controller regulatory approval status |

### Table 10: `blood_requests`
Inpatient and emergency blood requisitions.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `request_id` | SERIAL | PRIMARY KEY | NO | Requisition identifier |
| `request_code` | VARCHAR(32) | UNIQUE | NO | Public requisition number ('REQ-2026-001') |
| `hospital_id` | INT | FOREIGN KEY -> hospitals(hospital_id) | NO | Requesting hospital |
| `patient_ref_code`| VARCHAR(64) | — | NO | De-identified patient MRN (Masked PHI) |
| `patient_age` | INT | CHECK (patient_age BETWEEN 0 AND 125) | NO | Clinical patient age |
| `clinical_diagnosis`| VARCHAR(255)| — | NO | Clinical indication (e.g. 'Severe Trauma', 'Post-Partum Hemorrhage') |
| `blood_group` | VARCHAR(5) | — | NO | Patient blood group requested |
| `component_type`| VARCHAR(32)| — | NO | Requested component |
| `requested_qty` | INT | CHECK (requested_qty > 0) | NO | Number of units requested |
| `allocated_qty` | INT | DEFAULT 0, CHECK (allocated_qty <= requested_qty) | NO | Units currently allocated |
| `priority` | VARCHAR(16) | CHECK IN ('Emergency', 'Urgent', 'Routine') | NO | Clinical priority triage |
| `request_status`| VARCHAR(32) | CHECK IN ('Pending', 'Partially_Allocated', 'Fulfilled', 'Cancelled') | NO | Current order status |
| `requested_at` | TIMESTAMPTZ | DEFAULT NOW() | NO | Order entry timestamp |
| `required_by_date`| TIMESTAMPTZ| — | NO | Critical deadline for patient infusion |

### Table 11: `allocations`
**Associative Entity** resolving M:N between `blood_units` and `blood_requests`.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `allocation_id` | SERIAL | PRIMARY KEY | NO | Allocation event identifier |
| `request_id` | INT | FOREIGN KEY -> blood_requests(request_id) | NO | Requisition reference |
| `unit_id` | INT | FOREIGN KEY -> blood_units(unit_id) UNIQUE | NO | Blood unit assigned (UNIQUE ensures 1 active unit alloc) |
| `allocated_by_tech_id`| INT | FOREIGN KEY -> technicians(tech_id) | NO | Attending technician |
| `compatibility_verified`| BOOLEAN | DEFAULT TRUE | NO | Cross-match biological verification flag |
| `allocated_at` | TIMESTAMPTZ | DEFAULT NOW() | NO | Reservation timestamp |
| `issued_at` | TIMESTAMPTZ | — | YES | Dispatch timestamp to ambulance/courier |
| `allocation_status`| VARCHAR(32) | CHECK IN ('Reserved', 'Issued', 'Transfused', 'Returned', 'Cancelled') | NO | Custody progress |

### Table 12: `transfusions`
Transfusion outcome and hemovigilance reporting.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `transfusion_id` | SERIAL | PRIMARY KEY | NO | Transfusion report key |
| `allocation_id` | INT | FOREIGN KEY -> allocations(allocation_id) UNIQUE | NO | Associated allocation session |
| `hospital_id` | INT | FOREIGN KEY -> hospitals(hospital_id) | NO | Treating hospital facility |
| `transfused_at` | TIMESTAMPTZ | DEFAULT NOW() | NO | Infusion completion timestamp |
| `adverse_reaction`| BOOLEAN | DEFAULT FALSE | NO | True if febrile/hemolytic reaction noted |
| `reaction_notes`| TEXT | — | YES | Hemovigilance investigation details |
| `reported_by_doctor`| VARCHAR(120) | — | NO | Attending physician signature |

### Table 13: `audit_logs`
Write-once, read-many regulatory ledger with JSONB state snapshots.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `audit_id` | BIGSERIAL | PRIMARY KEY | NO | Monotonic audit sequence number |
| `table_name` | VARCHAR(64) | — | NO | Mutated entity name |
| `record_id` | VARCHAR(64) | — | NO | Key of altered record |
| `operation_type`| VARCHAR(10) | CHECK IN ('INSERT', 'UPDATE', 'DELETE') | NO | DML action type |
| `previous_state`| JSONB | — | YES | Row snapshot before mutation |
| `new_state` | JSONB | — | YES | Row snapshot after mutation |
| `location_snapshot`| JSONB | — | YES | Storage location context at time of change |
| `changed_by` | VARCHAR(64) | — | NO | Database user or authenticated technician |
| `changed_at` | TIMESTAMPTZ | DEFAULT NOW() | NO | Immutable timestamp |

### Table 14: `ai_shortage_forecasts`
Machine learning demand forecasts and human-in-the-loop decisions.
| Column | Type | Constraints | Nullable | Description |
| :--- | :--- | :--- | :---: | :--- |
| `forecast_id` | SERIAL | PRIMARY KEY | NO | Forecast run identifier |
| `forecast_date` | DATE | DEFAULT CURRENT_DATE | NO | Date for which prediction is projected |
| `blood_group` | VARCHAR(5) | — | NO | Target blood group |
| `component_type`| VARCHAR(32)| — | NO | Target component |
| `predicted_demand_units`| INT | CHECK (predicted_demand_units >= 0) | NO | Model projected 7-day hospital demand |
| `current_available_units`| INT | CHECK (current_available_units >= 0) | NO | Safe inventory at forecast generation |
| `predicted_shortage_units`| INT | — | NO | Net projected deficit (Demand - Available) |
| `risk_level` | VARCHAR(16) | CHECK IN ('Low', 'Moderate', 'High', 'Critical') | NO | Triage priority for donor outreach |
| `confidence_score`| NUMERIC(4,3)| CHECK (confidence_score BETWEEN 0.000 AND 1.000) | NO | Model statistical confidence ($R^2$ / probability) |
| `model_version` | VARCHAR(32) | DEFAULT 'RF-v1.2' | NO | ML pipeline version |
| `recommended_donor_outreach_count`| INT| DEFAULT 0 | NO | Number of eligible donors to alert |
| `human_approved`| BOOLEAN | DEFAULT FALSE | NO | Human-in-the-loop director signoff |
| `approved_by` | VARCHAR(64) | — | YES | Director name who authorized outreach |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | NO | Prediction timestamp |

---

## 2. PHI Classification & Data Governance

Under the **Indian Digital Personal Data Protection Act (DPDPA 2023)** and **HIPAA Security Rule § 164.514**:

| Classification Tier | Fields Protected | Exposure Policy | Masking Technique |
| :--- | :--- | :--- | :--- |
| **Tier 1: Direct Identifiers (Strict PHI)** | `donors.full_name`, `phone_encrypted`, `patient_ref_code` | Restricted to `blood_bank_admin`. Never exposed in clinical views. | Phone masked as `XXXXXX4321`. MRN hashed. |
| **Tier 2: Sensitive Medical Status** | `laboratory_tests.hiv_status`, `hbsag_status`, `hcv_status`, `overall_result` | Restricted to `lab_staff` and Medical Director. | Masked as `'REDACTED_CONFIDENTIAL'` in general clinical views. |
| **Tier 3: Operational Logistics** | `blood_units.blood_group`, `component_type`, `expiry_date`, `location_id` | Open to `clinical_staff` and hospital requesters. | Cleartext display for real-time inventory matching. |

---

## 3. Storage Estimation & Capacity Planning
Based on typical Gwalior regional blood center operations:
- Average Daily Donations: 15–25 units (~7,500 units/year).
- Average Daily Hospital Requests: 10–18 requisitions (~5,000 requests/year).

### Sizing Mathematics
- **Average Row Widths:**
  - `donors`: 240 bytes
  - `donations`: 120 bytes
  - `blood_units`: 160 bytes
  - `laboratory_tests`: 180 bytes
  - `cold_chain_events`: 64 bytes
  - `blood_requests`: 180 bytes
  - `allocations`: 96 bytes
  - `audit_logs`: 520 bytes (includes JSONB snapshots)

### Volume Projections:
- **At Current Seed (~10,800 rows):** ~5.4 MB data + ~3.8 MB indexes = **~9.2 MB**.
- **At 1 Year Production (~100,000 rows):** ~48 MB data + ~32 MB indexes = **~80 MB**.
- **At 5 Years Regulatory Archival (~600,000 rows):** ~310 MB data + ~210 MB indexes = **~520 MB**.
- **Hardware Requirement:** Minimum 4 GB RAM, 20 GB SSD with weekly `pg_dump` snapshotting is more than adequate for 10+ years of uninterrupted regional operations.

