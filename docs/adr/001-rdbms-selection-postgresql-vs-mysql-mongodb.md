# ADR 001: Selection of Relational DBMS Engine (PostgreSQL vs. MySQL vs. MongoDB)
**Status:** Approved  
**Date:** 2026-11-11  
**Deciders:** Diya Motwani (Architecture Lead), Gaurav Agrawal, Ayan Khan, Ch. Mohith  
**Course:** DBMS CSL0311 – Phase 6 DBMS Selection  

---

## 1. Context and Problem Statement
A life-critical blood bank and donor matching system requires strict ACID transactional guarantees, zero risk of double allocation during concurrent emergency requests, robust regulatory audit preservation, fine-grained role-based access control (RBAC), and support for hybrid semi-structured data (JSON audit diffs) and mathematical vector rankings.

We must select the optimal primary database management system among three industry candidates:
1. **PostgreSQL 16** (Advanced Object-Relational DBMS)
2. **MySQL 8.4** (Popular Relational DBMS)
3. **MongoDB 7.0** (Document-Oriented NoSQL)

---

## 2. Decision Matrix & Evaluation Criteria
Weights are assigned from 1 (lowest) to 5 (critical):

| Evaluation Criterion | Weight | PostgreSQL 16 (Score 1-5) | MySQL 8.4 (Score 1-5) | MongoDB 7.0 (Score 1-5) |
| :--- | :---: | :---: | :---: | :---: |
| **ACID & Strict Serializability** | 5 | 5 (SSI + Row-level locking) | 4 (InnoDB repeatable read) | 2 (Multi-doc ACID is heavy) |
| **Declarative Constraints & Triggers** | 5 | 5 (PL/pgSQL, CHECK, Deferrable) | 3 (Trigger limitations, no CHECK on views) | 1 (Schema validation only, no triggers) |
| **Row-Level Locking Concurrency (`FOR UPDATE`)** | 5 | 5 (`SKIP LOCKED`, `NOWAIT`) | 4 (Supported, but index gap locking nuances) | 1 (Document-level locks) |
| **Hybrid JSONB / Unstructured Indexing** | 4 | 5 (Binary JSONB + GIN index) | 3 (JSON column, functional index) | 5 (Native document BSON) |
| **Extensibility & Vector/AI Readiness** | 4 | 5 (`pgvector`, custom types, CTEs) | 2 (Limited vector capability) | 3 (Atlas Vector Search requires cloud) |
| **Data Integrity & Immutability Auditing** | 5 | 5 (Row security, `BEFORE DELETE` triggers) | 3 (Workarounds required) | 2 (Soft enforcement in app layer) |
| **Cost & Open-Source Governance** | 3 | 5 (100% Free PostgreSQL License) | 4 (GPL + Oracle Commercial) | 3 (SSPL licensing restrictions) |
| **Weighted Total (out of 155)** | — | **150 / 155 (96.8%)** | **109 / 155 (70.3%)** | **78 / 155 (50.3%)** |

---

## 3. Detailed Justification for PostgreSQL 16
1. **Concurrency Without Race Conditions:** During an emergency request for the last available `O-` unit, two hospitals must not receive the same unit. PostgreSQL's `SELECT ... FOR UPDATE SKIP LOCKED` allows the allocation engine to acquire exclusive row locks deterministically, while allowing non-conflicting allocations to proceed without blocking.
2. **Declarative Business Rules in Database:** The CSL0311 specification mandates that business rules (such as the mandatory 90-day donation interval and cold-chain quarantine) be enforced inside the DBMS engine. PostgreSQL's PL/pgSQL procedural language allows fine-grained `BEFORE INSERT` and `AFTER UPDATE` triggers with custom SQLSTATE exceptions (`P0001`).
3. **Audit Trail Immutability:** Medical compliance (FDA / DGHS / NABH) forbids hard deletion of transfusion records. PostgreSQL allows `BEFORE DELETE` triggers that cleanly raise `RAISE EXCEPTION` to guarantee 100% immutable audit retention.
4. **Native JSONB Storage for State Diffs:** Audit logs record `previous_state` and `new_state` as binary JSON (`JSONB`), queryable with GIN indexes at native speed.

---

## 4. Consequences & Risks
- **Positive:** Maximum data integrity; absolute protection against human or application logic bypass; clean support for complex analytical CTEs and window functions.
- **Negative:** Slightly higher memory footprint than basic MySQL installations; requires careful vacuum tuning in high-throughput production environments (mitigated with auto-vacuum configuration).

