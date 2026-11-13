# AI-Assisted Blood Bank and Donor Matching System
**Course:** Database Management Systems (CSL0311) — Problem-Based & Project-Based Learning (PbBL)  
**Institution:** ITM University Gwalior, Department of Computer Science & Applications (CSA)  
**Academic Target:** 23 / 20 Marks (20 Core Evaluation Marks + 3 DevOps Bonus Marks)  
**Faculty Supervisor:** Mr. Suraj Sharma, Assistant Professor, Dept. of CSA  

---

## 👥 Student Development Team
| Student Name | Enrollment / Roll No. | Core Ownership & Role |
| :--- | :--- | :--- |
| **Diya Motwani** (Lead) | `BETN1AI25137` | System Architecture, Schema Design, BCNF Normalization & Triggers |
| **Gaurav Agrawal** | `BETN1AI25099` | Transaction Engineering, ACID Concurrency & Lock Testing |
| **Ayan Khan** | `BETN1AI25138` | ML Shortage Forecaster, UCI Dataset Integration & NL-to-SQL |
| **Ch. Mohith** | `BETN1AI25149` | Database DevOps, RBAC Security, Audit Trail & Viva Dashboard |

---

## 🎯 Executive Overview & Driving Question
> *"How can a secure, scalable, maintainable, and AI-ready database be designed and implemented for a real-world healthcare organization using contemporary industry practices?"*

The **AI-Assisted Blood Bank and Donor Matching System** is an enterprise-grade, relational database solution engineered to eliminate blood wastage, enforce mandatory donor health regulations, prevent dual-allocation during medical emergencies, and predict future blood shortages across hospitals in the Gwalior & Madhya Pradesh regional health corridor.

### 🌟 Key Distinctions
- **Database-First Business Enforcement:** All 15 operational business rules are enforced **inside PostgreSQL** using PL/pgSQL triggers, CHECK constraints, composite UNIQUE keys, and stored procedures. Client-side code does not bypass database validation.
- **BCNF Certified Relational Schema:** 14 normalized tables completely eliminating Insertion, Update, and Deletion anomalies across 10,800+ seeded records.
- **ACID Row-Level Concurrency:** Zero lost updates or race hazards on rare blood units (e.g., O-Negative) using `SELECT ... FOR UPDATE SKIP LOCKED` inside serializable/read-committed boundaries.
- **Machine Learning Integration:** Scikit-Learn `RandomForestRegressor` trained on historical blood requests combined with the **UCI Blood Transfusion Service Center Dataset** to forecast 7-day inventory shortfalls and rank eligible donors.
- **4 Live Viva Demonstration Buttons:** One-click interactive triggers in the web dashboard that purposely execute illegal transactions to demonstrate live PostgreSQL constraint errors (`SQLSTATE 'P0001'`), cold-chain emergency rollbacks, and anti-tamper delete guards before the examiner.

---

## 🏗️ Repository Architecture
```text
blood-bank-dbms/
├── README.md                           # Master Project Guide & Viva Manual
├── docker-compose.yml                  # PostgreSQL 16 + pgAdmin + Backend + Frontend
├── docs/                               # Academic Deliverables (Phases 1 - 10)
│   ├── adr/                            # Architecture Decision Records
│   │   ├── 001-rdbms-selection-postgresql-vs-mysql-mongodb.md
│   │   └── 002-hybrid-jsonb-vector-audit-justification.md
│   ├── phase1_2_requirements.md        # 4 Stakeholders, 12 FRs, 8 NFRs, 15 Rules, 8 User Stories
│   ├── phase3_data_dictionary.md       # Full profiling, PHI classification, storage math
│   ├── phase4_5_er_and_bcnf.md         # Conceptual + Physical ER (Mermaid) & BCNF proofs
│   ├── phase9_concurrency_demo.md      # Concurrency tests, Lock graph, Deadlock proofs
│   └── phase10_performance.md          # EXPLAIN ANALYZE before/after index benchmarks
├── ai-log/
│   ├── ai_usage_log.md                 # Date, Stage, AI Tool, Prompt, Validation, Changes
│   └── ai_output_audit.md              # Deep audit of AI trigger with bug identification & fix
├── database/
│   ├── schema/full_schema.sql          # Unified production DDL
│   ├── migrations/                     # Versioned forward migrations (V1 - V6)
│   ├── rollback/                       # Reversible down migrations (U1 - U6)
│   ├── procedures/sp_allocate_blood_units.sql
│   ├── functions/fn_check_compatibility.sql
│   ├── triggers/                       # 4 PL/pgSQL business triggers
│   ├── views/all_views.sql             # 5 clinical, exception & materialized views
│   ├── queries/portfolio_20_queries.sql# 20 advanced SQL queries (CTEs, Window, JSONB)
│   ├── security/rbac_roles.sql         # 4 RBAC roles with least privilege
│   ├── seed/
│   │   ├── download_uci_dataset.py     # UCI Machine Learning dataset downloader
│   │   └── generate_10k_seed.py        # 10,800+ realistic Gwalior/MP rows
│   ├── tests/pgtap_and_sql_tests.sql   # Automated pgTAP & SQL validation suite
│   └── backup/backup_restore_demo.sh   # pg_dump / pg_restore integrity proof
├── backend/                            # FastAPI REST API + ML Pipeline
└── frontend/                           # React 19 + Tailwind CSS + Lucide Dashboard
```

---

## ⚡ Quick Start Guide

### Repository Clone & Setup
```bash
git clone https://github.com/ayankhan96686-create/blood-bank-.git
cd blood-bank-
```

### Option A: Local Full-Stack Launch (Zero-Prerequisites Mode)
1. **Run Database Seed & Model Training:**
   ```bash
   cd e:\blood\blood-bank-dbms
   python database\seed\download_uci_dataset.py
   python database\seed\generate_10k_seed.py
   ```
2. **Start Backend API:**
   ```bash
   cd e:\blood\blood-bank-dbms\backend
   python main.py
   # API runs at http://localhost:8000 (Swagger docs at http://localhost:8000/docs)
   ```
3. **Start Executive Dashboard:**
   ```bash
   cd e:\blood\blood-bank-dbms\frontend
   npm install
   npm run dev
   # Dashboard runs at http://localhost:5173
   ```

### Option B: Docker Compose (Production Multi-Container)
```bash
docker-compose up --build -d
# pgAdmin: http://localhost:5050
# API:     http://localhost:8000
# Web UI:  http://localhost:5173
```

---

## 🎓 19-Step Viva Demonstration Protocol (CSL0311 Section 19)
During the viva examination with Professor Suraj Sharma, follow this exact sequence:

1. **Architecture & Scope (Tab 1):** Present the 14-table BCNF schema, 4 stakeholder personas, and regional Gwalior healthcare corridor.
2. **ER Model & Relationships (`docs/phase4_5_er_and_bcnf.md`):** Explain the recursive technician supervisor hierarchy, weak entity `cold_chain_events`, and associative `allocations`.
3. **Database as Code (`database/`):** Demonstrate V1–V6 forward migrations and U1–U6 rollback scripts.
4. **Viva Demo Button 1 (Tab 2):** Click **"Force <90-Day Donation Violation"** to attempt a donation 25 days after the last. Witness the live PostgreSQL trigger raise error:
   ```text
   ERROR: ELIGIBILITY_VIOLATION: Mandatory 90-day recovery interval not met.
   Days elapsed: 25. Next eligible donation date: 2026-12-16. (SQLSTATE P0001)
   ```
5. **Viva Demo Button 2 (Tab 3):** Click **"Simulate Freezer Temp Breach (>8.0°C)"**. Observe `trg_cold_chain_breach` instantly transition all affected units from `Available` to `Quarantined`.
6. **Viva Demo Button 3 (Tab 4):** Click **"Simulate Emergency Race Condition (2 Hospitals Requesting Last O-ve Unit)"**. Witness Transaction A acquire row lock `SELECT ... FOR UPDATE` and commit, while Transaction B rolls back and waitlists without double allocation.
7. **Viva Demo Button 4 (Tab 6):** Click **"Attempt Hard Delete on Audit Log"**. Observe the database block with:
   ```text
   ERROR: AUDIT_PROTECTION: Hard deletion prohibited by regulatory compliance. (SQLSTATE P0002)
   ```
8. **AI Shortage Forecasting (Tab 5):** Inspect the Scikit-Learn Random Forest 7-day shortage predictions and human-in-the-loop approval workflow.
9. **NL-to-SQL Studio (Tab 5):** Type natural English queries (e.g. *"Show all B+ blood units expiring within 3 days in JAH"*) to view the parameterized SQL query and live tabular output.
10. **Benchmark Performance (`docs/phase10_performance.md`):** Review the `EXPLAIN (ANALYZE, BUFFERS)` execution plans demonstrating 88% speedup after V4 indexing.

