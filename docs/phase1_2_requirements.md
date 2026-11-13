# Phase 1 & 2: Project Charter, Stakeholder Analysis & Requirements Specification
**Course:** DBMS CSL0311 – Problem-Based & Project-Based Learning  
**Project:** AI-Assisted Blood Bank and Donor Matching System (ITM University Gwalior)  
**Authors:** Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith  

---

## 1. Project Charter & Problem Identification
### 1.1 Organizational Profile
The **Gwalior Regional Blood Transfusion Center (GRBTC)** serves as the tertiary blood supply authority catering to major healthcare institutions across northern Madhya Pradesh, including:
- **Jaya Arogya Hospital (JAH)** & **Gajra Raja Medical College (GRMC)** (Super-speciality trauma center)
- **Cancer Hospital & Research Institute (CHRI)** (High-volume platelet demand)
- **District Hospital Morar** and 25+ private multi-speciality hospitals.

### 1.2 Problem Statement & Current Bottlenecks
Under manual or fragmented digital records, GRBTC faces four critical vulnerabilities:
1. **Transfusion Wastage via Expiry:** Blood components (especially Platelets with 5-day shelf-life) expire in storage due to non-enforced First-Expired First-Out (FEFO) allocation.
2. **Donor Deferral & Interval Violations:** Donors attempting repeat donation before the mandatory 90-day whole-blood interval are inadvertently accepted when checking manual registers.
3. **Emergency Dual-Allocation Race Conditions:** During mass-casualty trauma cases, multiple hospital staff request the same rare unit (e.g., O-Negative), resulting in double-booking or delayed allocation.
4. **Audit Trail Vulnerability:** Historical movement across cold storage units is unrecorded, complicating investigation of temperature breaches.

### 1.3 Project Driving Question
> *"How can a secure, scalable, maintainable, and AI-ready database be designed and implemented for a real-world healthcare organization using contemporary industry practices?"*

---

## 2. Stakeholder Analysis (4 Categories)

| Stakeholder Persona | Responsibilities & Needs | System Touchpoints |
| :--- | :--- | :--- |
| **1. Donor & Public Member** | Register personal details, verify donation eligibility, receive notification of critical blood shortages. | `donors`, `donations`, PHI-masked directory. |
| **2. Phlebotomy & Lab Technician** | Collect blood, record volumes, execute 5 mandatory screening tests (HIV, HBsAg, HCV, VDRL, Malaria), monitor cold-chain temperatures. | `donations`, `blood_units`, `laboratory_tests`, `cold_chain_events`. |
| **3. Hospital Transfusion Officer** | Submit emergency and routine blood requests, verify ABO/Rh compatibility, receive allocated units, log adverse transfusion reactions. | `hospitals`, `blood_requests`, `allocations`, `transfusions`. |
| **4. Blood Bank Director & Auditor** | Review 16 management reports, monitor wastage trends, approve AI shortage outreach campaigns, verify immutable compliance logs. | `all_views`, `audit_logs`, `ai_shortage_forecasts`, `schema_versions`. |

---

## 3. Functional Requirements (12 FRs)
- **FR01: Donor Onboarding & Unique Identification:** System shall register donors with unique `donor_code`, government ID hash, and demographic parameters.
- **FR02: 90-Day Donation Interval Enforcement:** System shall reject any new donation entry if the donor's previous donation was within 90 days.
- **FR03: Component Separation & Barcode Generation:** System shall split whole blood donations into components (`Whole Blood`, `Packed RBC`, `Fresh Frozen Plasma`, `Platelets`) with unique barcodes and component-specific shelf-life calculations.
- **FR04: Mandatory Five-Panel Diagnostic Clearance:** Units must remain in `Quarantined` status until negative test results for HIV-1/2, HBsAg, HCV, Syphilis, and Malaria are committed.
- **FR05: Biohazard Quarantine Lockdown:** Any reactive test result shall automatically mark the blood unit as `Biohazard_Quarantined` and block any allocation.
- **FR06: Hospital Emergency Request Registration:** System shall record hospital blood requests with priority levels (`Emergency`, `Urgent`, `Routine`) and required-by deadlines.
- **FR07: ABO & Rh Compatibility Matrix:** System shall validate donor-to-recipient biological compatibility rules for red cells and plasma components before allocation.
- **FR08: FEFO Automated Unit Allocation:** System shall allocate the oldest non-expired safe compatible unit to minimize inventory expiry wastage.
- **FR09: Strict ACID Row-Lock Allocation:** System shall lock target blood units using row-level locks during concurrent allocation attempts to prevent double issuance.
- **FR10: Cold-Chain Monitoring & Auto-Quarantine:** System shall log refrigerator temperatures and trigger automatic quarantine if temperatures breach safety thresholds.
- **FR11: Adverse Transfusion Logging:** System shall record transfusion outcomes, adverse reactions, and attending physician details.
- **FR12: AI Shortage Forecasting & Smart Outreach:** System shall predict 7-day shortage risks per blood group and recommend eligible repeat donors for recruitment.

---

## 4. Non-Functional Requirements (8 NFRs)
- **NFR01: Data Integrity & ACID Compliance:** All inventory state mutations must execute in atomic transactions with strict referential integrity.
- **NFR02: Concurrency & Lock Latency:** Row-level allocation under `SELECT ... FOR UPDATE` shall resolve within < 50 milliseconds without deadlock.
- **NFR03: Security & RBAC:** Access restricted into 4 distinct database roles (`clinical_staff`, `lab_staff`, `blood_bank_admin`, `regulatory_auditor`).
- **NFR04: Privacy & PHI Masking:** Donor contact details and infectious disease outcomes must be masked on non-administrative query views.
- **NFR05: Audit Immutability:** Regulatory audit logs must be write-once, read-many (WORM); all DELETE operations must be rejected by database triggers.
- **NFR06: Query Performance:** Strategic dashboard queries over 10,000+ records must execute in < 20 milliseconds after indexing.
- **NFR07: Regulatory Archival Retention:** System shall retain donor and transfusion records permanently with zero physical deletion.
- **NFR08: Database DevOps:** Complete database state must be deployable via versioned migrations (V1–V6) with tested rollback scripts (U1–U6).

---

## 5. Traceability Matrix: 15 Core & PBL Business Rules to SQL Enforcements

| Rule # | Business Rule Description | Database Enforcement Mechanism | SQL Object Name |
| :---: | :--- | :--- | :--- |
| **BR01** | Unique Donor & Health Eligibility (Age 18-65, Wt >= 45kg, Hb >= 12.5 g/dL) | Column CHECK constraints & UNIQUE constraint on `donor_code` | `chk_donor_age`, `chk_donor_weight`, `chk_donor_hb` in `donors` |
| **BR02** | Mandatory 90-Day Whole Blood Donation Interval | PL/pgSQL `BEFORE INSERT` Trigger raising custom SQLSTATE `'P0001'` | `trg_donor_eligibility_90days` on `donations` |
| **BR03** | Donation-to-Component Traceability & Unique Barcodes | Foreign Key referencing `donations(donation_id)` and UNIQUE on `unit_barcode` | `fk_unit_donation`, `uq_unit_barcode` in `blood_units` |
| **BR04** | Mandatory 5-Test Screening Gatekeeper (HIV, HBV, HCV, Syphilis, Malaria) | PL/pgSQL `AFTER UPDATE` Trigger checking all 5 test flags before releasing to `Available` | `trg_enforce_test_clearance` on `laboratory_tests` |
| **BR05** | Strict Issue Lock on Unsafe Units (Expired, Reactive, Quarantined) | CHECK constraint on `blood_units.status` & Stored Procedure validation | `chk_unit_status`, `sp_allocate_blood_units` |
| **BR06** | Component Biological Compatibility (RBC vs Plasma Rules) | Stored PL/pgSQL Function implementing ABO/Rh truth tables | `fn_check_compatibility(donor_bg, recip_bg, comp_type)` |
| **BR07** | Hospital Request Specification & Valid Quantities | CHECK constraint (`requested_qty > 0`) & Foreign Key to `hospitals` | `chk_request_qty`, `fk_req_hospital` in `blood_requests` |
| **BR08** | Stock & Allocation Ceiling Enforcement | CHECK constraint (`allocated_qty <= requested_qty`) | `chk_alloc_ceiling` in `blood_requests` |
| **BR09** | Custody, Location & State History Logging | PL/pgSQL `AFTER UPDATE` Trigger capturing JSONB old/new state | `trg_audit_blood_unit_custody` on `blood_units` |
| **BR10** | Anti-Tamper Regulatory WORM Audit Protection | PL/pgSQL `BEFORE DELETE` Trigger raising `RAISE EXCEPTION` on core/audit tables | `trg_audit_anti_delete` on `audit_logs` & `transfusions` |
| **BR11** | Cold-Chain Temperature Breach Auto-Quarantine (>6°C for RBC, >-20°C Plasma) | PL/pgSQL `AFTER INSERT` Trigger on `cold_chain_events` updating `blood_units` | `trg_cold_chain_breach` on `cold_chain_events` |
| **BR12** | First-Expired First-Out (FEFO) Allocation Order | Stored Procedure ordering candidate units by `expiry_date ASC` | `sp_allocate_blood_units` |
| **BR13** | ACID Concurrency Locking for High-Demand Units | Transaction block with `SELECT ... FOR UPDATE SKIP LOCKED` | In `sp_allocate_blood_units` |
| **BR14** | PHI Data Masking for Clinical Views | SQL Views utilizing string substring and masking functions | `vw_donor_masked_clinical` |
| **BR15** | AI Human-in-the-Loop Governance & Audit | Relational table storing model version, prediction, and human approval flag | `ai_shortage_forecasts` & `ai_decision_logs` |

---

## 6. User Stories & Acceptance Criteria (8 Stories)
1. **US01 (Phlebotomist):** *"As a phlebotomist, I want the system to reject repeat donors under 90 days so that donor health is safeguarded."*  
   *Acceptance Criteria:* Attempting donation at 89 days raises `SQLSTATE P0001` and aborts transaction.
2. **US02 (Lab Technician):** *"As a lab technician, I want blood units to stay quarantined until all 5 infectious screening tests pass, so unsafe blood is never issued."*  
   *Acceptance Criteria:* Unit status remains `Quarantined`; transitions to `Available` only when all 5 tests are `Negative`.
3. **US03 (Hospital Doctor):** *"As an emergency physician, I want to request 2 units of O-Negative blood and guarantee immediate reservation without race conditions."*  
   *Acceptance Criteria:* Atomic allocation locks units via `FOR UPDATE`; concurrent requests receive clean waitlist or distinct units.
4. **US04 (Cold Chain Specialist):** *"As a storage manager, I want refrigerator temperature spikes above 8°C to instantly quarantine all stored units."*  
   *Acceptance Criteria:* Temperature breach trigger updates all units in that location to `Quarantined`.
5. **US05 (Blood Bank Director):** *"As a director, I want to see a real-time dashboard of 7-day expiry risks and monthly wastage trends."*  
   *Acceptance Criteria:* Views `vw_expiring_units_7days` and `mv_monthly_supply_wastage_trends` load instantly.
6. **US06 (Compliance Auditor):** *"As a regulatory auditor, I want proof that audit logs cannot be altered or deleted."*  
   *Acceptance Criteria:* `DELETE FROM audit_logs` fails with `P0002` exception.
7. **US07 (Outreach Coordinator):** *"As an outreach coordinator, I want ML-generated donor call lists for predicted shortage blood groups."*  
   *Acceptance Criteria:* System displays top-ranked eligible donors based on UCI Recency-Frequency scores.
8. **US08 (Database Administrator):** *"As a DBA, I want all schema changes version-controlled from V1 to V6 with rollback scripts."*  
   *Acceptance Criteria:* Migrations and rollbacks execute cleanly and maintain `schema_versions`.

---

## 7. CRUD Matrix across 14 Relational Tables

| Table Name | Clinical Staff | Lab Staff | Blood Bank Admin | Regulatory Auditor |
| :--- | :---: | :---: | :---: | :---: |
| `schema_versions` | R | R | R | R |
| `technicians` | R | R | C, R, U | R |
| `inventory_locations`| R | R, U | C, R, U | R |
| `donors` | C, R, U | R | C, R, U | R (Masked) |
| `donations` | C, R | R | C, R, U | R |
| `blood_units` | R | C, R, U | C, R, U | R |
| `laboratory_tests` | R | C, R, U | C, R, U | R |
| `cold_chain_events` | R | C, R | C, R | R |
| `hospitals` | R | R | C, R, U | R |
| `blood_requests` | C, R, U | R | C, R, U | R |
| `allocations` | C, R, U | R | C, R, U | R |
| `transfusions` | C, R | R | C, R, U | R |
| `audit_logs` | R | R | R | R (Immutable) |
| `ai_shortage_forecasts`| R | R | C, R, U | R |

*(Legend: C = Create/Insert, R = Read/Select, U = Update, D = Hard Delete — Prohibited on all core and audit entities).*

