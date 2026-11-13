# ADR 002: Architectural Justification for Hybrid Relational-JSONB Audit Trails and Vector-Ready Analytics
**Status:** Approved  
**Date:** 2026-11-11  
**Deciders:** Diya Motwani (Architecture Lead), Ayan Khan (AI Lead)  
**Course:** DBMS CSL0311 – Phase 6 & Phase 8 Implementation  

---

## 1. Context and Problem Statement
Traditional relational schema designs handle auditing by either duplicating entire tables with `_history` suffixes or relying on application-level event logs. However, in blood banking:
1. Every physical state transition of a blood unit (`Quarantined` -> `Available` -> `Allocated` -> `Issued` -> `Transfused`) contains variable diagnostic metadata, technician signatures, and storage temperature snapshots.
2. Changes across multiple entities (e.g., test updates, temperature alerts, allocation cancellations) must be consolidated in a single central regulatory ledger.
3. Machine learning models require donor recency-frequency features and shortage risk forecasts to be stored without requiring schema migrations every time model hyper-parameters evolve.

---

## 2. Decision: Hybrid Relational + JSONB Architecture
We adopt a **Hybrid Relational-JSONB Pattern** within PostgreSQL:
- **Core Entities in 3NF / BCNF:** Structured relational tables (`donors`, `donations`, `blood_units`, `blood_requests`, `allocations`, `transfusions`) with strict foreign keys, check constraints, and typed columns.
- **Audit Ledger via JSONB:** The `audit_logs` table stores the pre-image and post-image of every mutated row using native PostgreSQL `JSONB`:
  ```sql
  CREATE TABLE audit_logs (
      audit_id BIGSERIAL PRIMARY KEY,
      table_name VARCHAR(64) NOT NULL,
      record_id VARCHAR(64) NOT NULL,
      operation_type VARCHAR(10) NOT NULL CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
      previous_state JSONB,
      new_state JSONB,
      location_snapshot JSONB,
      changed_by VARCHAR(64) NOT NULL,
      changed_at TIMESTAMPTZ DEFAULT NOW()
  );
  ```
- **GIN Indexing:** A Generalized Inverted Index (`gin (new_state)`) is created on `audit_logs` to enable sub-millisecond querying of specific field diffs across millions of audit records.
- **AI Analytics Extension:** The `ai_shortage_forecasts` table records both structured predictions (`predicted_shortage_units`, `confidence_score`) and extensible JSON feature vectors representing the 7-day trailing demand window.

---

## 3. Justification & Benefits
1. **Schema Evolution Resilience:** Regulatory reporting frequently requests new audit attributes (e.g., RFID badge ID, GPS transit coordinates). Using JSONB for audit payloads avoids breaking changes and continuous ALTER TABLE migrations.
2. **Forensic Reconstruction:** With JSONB snapshot diffs, an auditor can reconstruct the exact state of any blood unit at any microsecond in history without locking operational tables.
3. **Storage & Speed:** PostgreSQL stores JSONB in decomposed binary format, eliminating serialization parsing costs during queries.

---

## 4. Compliance Verification
This pattern complies directly with FDA 21 CFR Part 11, HIPAA Security Rule § 164.312(b) (Audit Controls), and Drugs & Cosmetics Act, 1940 (Schedule F, Part XII-B Blood Bank Standards).

