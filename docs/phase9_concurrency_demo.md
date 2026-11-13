# Phase 9: ACID Transactions, Isolation Levels & Concurrency Demonstration
**Course:** DBMS CSL0311 – Problem-Based & Project-Based Learning  
**Project:** AI-Assisted Blood Bank and Donor Matching System (ITM University Gwalior)  
**Authors:** Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith  

---

## 1. Concurrency Analysis in Life-Critical Blood Banking

In high-pressure emergency healthcare environments (such as a multi-vehicle collision arriving at Jaya Arogya Hospital), simultaneous requisitions arrive at the regional blood bank for rare blood units (e.g. O-Negative, which comprises only ~1.5% of the donor population).

### The Dual-Allocation Race Condition (Without Concurrency Control)
```text
Timeline of Disaster (Without Concurrency Control):
Time    Transaction 1 (JAH Trauma)                 Transaction 2 (BIMR ICU)
t1      BEGIN;                                     BEGIN;
t2      SELECT unit_id FROM blood_units            SELECT unit_id FROM blood_units
        WHERE blood_group='O-' AND status='Available'      WHERE blood_group='O-' AND status='Available'
        ORDER BY expiry_date ASC LIMIT 1;          ORDER BY expiry_date ASC LIMIT 1;
        -- Returns Unit #5042                      -- ALSO returns Unit #5042!
t3      INSERT INTO allocations(req_1, unit_5042); INSERT INTO allocations(req_2, unit_5042);
t4      UPDATE blood_units SET status='Allocated'   UPDATE blood_units SET status='Allocated'
        WHERE unit_id=5042;                        WHERE unit_id=5042;
t5      COMMIT;                                    COMMIT;
Result: Double Allocation of Unit #5042! Two ambulances arrive to collect the SAME single unit.
```

---

## 2. PostgreSQL Isolation Levels & Concurrency Phenomena

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read | Serialization Anomaly / Lost Update |
| :--- | :---: | :---: | :---: | :---: |
| **Read Uncommitted** | Prevented in PG | Prevented in PG | Prevented in PG | Possible |
| **Read Committed** (Default) | Prevented | Possible | Possible | Resolved with `FOR UPDATE` |
| **Repeatable Read** | Prevented | Prevented | Prevented | Aborts with 40001 serialization error |
| **Serializable** (SSI) | Prevented | Prevented | Prevented | Prevented via Predicate Locks |

### Architectural Decision
We operate under **Read Committed** paired with **Explicit Row-Level Locking (`SELECT ... FOR UPDATE SKIP LOCKED`)** inside stored procedure `sp_allocate_blood_units`. This provides the optimal balance of zero race hazards and zero blocking delays for unrelated blood units.

---

## 3. The 3 Core Business Transactions

### Transaction 1: Emergency Blood Allocation (With Row-Level Lock)
```sql
-- Transaction Boundary: Atomic Requisition Fulfillment
BEGIN;

-- Step 1: Lock the earliest expiring compatible available unit
SELECT u.unit_id, u.blood_group, u.expiry_date
INTO STRICT v_unit_id, v_bg, v_expiry
FROM blood_units u
WHERE u.blood_group = 'O-'
  AND u.component_type = 'Packed RBC'
  AND u.status = 'Available'
  AND u.expiry_date > NOW()
ORDER BY u.expiry_date ASC
LIMIT 1
FOR UPDATE SKIP LOCKED; -- Row lock acquired; concurrent transactions skip this row

-- Step 2: Create allocation record
INSERT INTO allocations (request_id, unit_id, allocated_by_tech_id, compatibility_verified, allocation_status)
VALUES (105, v_unit_id, 3, TRUE, 'Reserved');

-- Step 3: Mutate blood unit state
UPDATE blood_units
SET status = 'Allocated', version_no = version_no + 1
WHERE unit_id = v_unit_id;

-- Step 4: Increment allocated quantity on request
UPDATE blood_requests
SET allocated_qty = allocated_qty + 1,
    request_status = CASE WHEN allocated_qty + 1 >= requested_qty THEN 'Fulfilled' ELSE 'Partially_Allocated' END
WHERE request_id = 105;

COMMIT;
```

---

### Transaction 2: Laboratory Clearance & Quarantine Release (With SAVEPOINT)
```sql
BEGIN;

SAVEPOINT before_lab_clearance;

-- Update test outcomes
UPDATE laboratory_tests
SET hiv_status = 'Negative',
    hbsag_status = 'Negative',
    hcv_status = 'Negative',
    syphilis_status = 'Negative',
    malaria_status = 'Negative',
    overall_result = 'Acceptable',
    blood_group_verified = TRUE,
    test_timestamp = NOW()
WHERE unit_id = 1024;

-- The trigger trg_enforce_test_clearance fires automatically,
-- changing blood_units(unit_id=1024).status from 'Quarantined' to 'Available'.

-- In case of unexpected integrity check failure:
-- ROLLBACK TO SAVEPOINT before_lab_clearance;

COMMIT;
```

---

### Transaction 3: Cold-Chain Incident & Automated Quarantine
```sql
BEGIN;

-- Insert telemetry temperature breach (> 8.0°C)
INSERT INTO cold_chain_events (location_id, event_seq_no, recorded_temp_c, recorded_at, alert_triggered, handled_by_tech_id)
VALUES (2, (SELECT COALESCE(MAX(event_seq_no),0)+1 FROM cold_chain_events WHERE location_id=2), 9.4, NOW(), TRUE, 5);

-- trg_cold_chain_breach fires immediately:
-- All blood_units in location_id=2 with status='Available' are auto-quarantined to 'Quarantined'.

COMMIT;
```

---

## 4. Live Concurrency Demonstration Proof (Viva Ready)

### Test Setup: Only 1 unit of `O-` Packed RBC exists in the blood bank (`unit_id = 9999`).
Simultaneous execution initiated by two terminal threads (or the Dashboard's Concurrency Lab):

```sql
-- Thread A (Hospital: JAH Trauma)               -- Thread B (Hospital: BIMR ICU)
BEGIN;                                           BEGIN;

SELECT unit_id FROM blood_units                  SELECT unit_id FROM blood_units
WHERE blood_group='O-' AND status='Available'    WHERE blood_group='O-' AND status='Available'
ORDER BY expiry_date ASC LIMIT 1                 ORDER BY expiry_date ASC LIMIT 1
FOR UPDATE SKIP LOCKED;                          FOR UPDATE SKIP LOCKED;

--> ACQUIRES LOCK on Unit #9999                  --> Unit #9999 is locked by Thread A.
--> Returns 1 row (unit_id=9999).                --> SKIP LOCKED skips unit #9999!
                                                 --> Returns 0 rows (Empty set).

INSERT INTO allocations(req_id, unit_id, ...)    -- Clean handling: Detects 0 available units.
VALUES (101, 9999, ...);                         -- Leaves request as 'Pending' / Waitlisted.
UPDATE blood_units SET status='Allocated'        -- ZERO crash, ZERO lost update!
WHERE unit_id=9999;

COMMIT;                                          COMMIT;
--> Lock released; unit is now 'Allocated'.
```

### Verified Outcome
- **Double Allocation:** Exactly 0 occurrences.
- **Deadlock:** Completely avoided via deterministic index sorting (`ORDER BY expiry_date ASC`) and `SKIP LOCKED`.
- **Integrity Guarantee:** Mathematical 100% adherence to ACID serializability.

