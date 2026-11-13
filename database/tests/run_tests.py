"""
Automated Database Test Suite Runner (CSL0311 PbBL)
Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
"""

import os
import sqlite3
import sys

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DB_PATH = os.path.join(PROJECT_DIR, "backend", "blood_bank.db")

def run_tests():
    print(f"[*] Running Automated Database Verification Suite against {DB_PATH}...\n")
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    cur = conn.cursor()

    tests = []
    
    # Test 1: Underweight Donor CHECK constraint (< 45 kg)
    try:
        cur.execute("""
        INSERT INTO donors (donor_code, full_name, date_of_birth, gender, blood_group, weight_kg, hemoglobin_g_dl, phone_masked, phone_encrypted, pincode)
        VALUES ('DNR-TEST-UW', 'Underweight Donor', '1995-05-10', 'Female', 'A+', 42.0, 13.0, '9876543210', 'enc_hash', '474001')
        """)
        tests.append(("BR01: Underweight Donor (< 45kg)", "FAIL", "CHECK constraint allowed weight_kg = 42.0"))
    except sqlite3.IntegrityError as e:
        tests.append(("BR01: Underweight Donor (< 45kg)", "PASS", f"Rejected: {e}"))

    # Test 2: Low Hemoglobin CHECK constraint (< 12.5 g/dL)
    try:
        cur.execute("""
        INSERT INTO donors (donor_code, full_name, date_of_birth, gender, blood_group, weight_kg, hemoglobin_g_dl, phone_masked, phone_encrypted, pincode)
        VALUES ('DNR-TEST-LHB', 'Low Hb Donor', '1998-02-14', 'Male', 'O+', 65.0, 11.8, '9876543211', 'enc_hash', '474001')
        """)
        tests.append(("BR01: Low Hemoglobin (< 12.5 g/dL)", "FAIL", "CHECK constraint allowed hb = 11.8"))
    except sqlite3.IntegrityError as e:
        tests.append(("BR01: Low Hemoglobin (< 12.5 g/dL)", "PASS", f"Rejected: {e}"))

    # Test 3: Trigger 1 - 90-Day Recovery Interval Enforcement
    try:
        # Create test donor who donated 25 days ago
        cur.execute("""
        INSERT INTO donors (donor_code, full_name, date_of_birth, gender, blood_group, weight_kg, hemoglobin_g_dl, phone_masked, phone_encrypted, pincode, last_donation_date, is_eligible)
        VALUES ('DNR-TEST-RAPID', 'Rapid Test Donor', '1994-06-15', 'Male', 'B+', 72.0, 14.8, '9876543219', 'enc_hash', '474001', '2026-10-17', 1)
        """)
        donor_id = cur.lastrowid
        # Seed the first donation
        cur.execute("""
        INSERT INTO donations (donor_id, collected_by_tech_id, collection_date, blood_group, volume_ml, bag_serial_no, collection_status)
        VALUES (?, 8, '2026-10-17', 'B+', 450, 'BAG-TEST-RAPID-01', 'Successful')
        """, (donor_id,))
        # Attempt second donation 25 days later on 2026-11-11 (Trigger should block!)
        cur.execute("""
        INSERT INTO donations (donor_id, collected_by_tech_id, collection_date, blood_group, volume_ml, bag_serial_no, collection_status)
        VALUES (?, 8, '2026-11-11', 'B+', 450, 'BAG-TEST-RAPID-02', 'Successful')
        """, (donor_id,))
        tests.append(("BR02: 90-Day Donor Interval Trigger", "FAIL", "Trigger failed to block donation at 25 days"))
    except sqlite3.IntegrityError as e:
        tests.append(("BR02: 90-Day Donor Interval Trigger", "PASS", f"Trigger blocked violation: {e}"))

    # Test 4: Trigger 2 - Reactive Test Biohazard Auto-Lock
    cur.execute("""
    INSERT INTO blood_units (unit_barcode, donation_id, blood_group, component_type, volume_ml, collection_date, expiry_date, status, location_id)
    VALUES ('UNIT-TEST-AUTO-BIO', 1, 'O-', 'Packed RBC', 280, '2026-11-11', '2026-12-23 23:59:59', 'Quarantined', 1)
    """)
    unit_id = cur.lastrowid
    cur.execute("""
    INSERT INTO laboratory_tests (unit_id, tested_by_tech_id, test_timestamp, hiv_status, hbsag_status, hcv_status, syphilis_status, malaria_status, blood_group_verified, overall_result)
    VALUES (?, 18, datetime('now'), 'Reactive', 'Negative', 'Negative', 'Negative', 'Negative', 1, 'Reactive')
    """, (unit_id,))
    cur.execute("SELECT status FROM blood_units WHERE unit_id = ?", (unit_id,))
    status_res = cur.fetchone()[0]
    if status_res == 'Biohazard_Quarantined':
        tests.append(("BR04: Test Screening Biohazard Lock", "PASS", "Trigger automatically changed status to Biohazard_Quarantined"))
    else:
        tests.append(("BR04: Test Screening Biohazard Lock", "FAIL", f"Expected Biohazard_Quarantined but got {status_res}"))

    # Test 5: Trigger 3 - Cold-Chain Temperature Breach Auto-Quarantine
    # Location 1 is FRZ-RBC-01 (max_temp_c = 6.0). We insert reading of 9.2 C!
    cur.execute("""
    INSERT INTO blood_units (unit_barcode, donation_id, blood_group, component_type, volume_ml, collection_date, expiry_date, status, location_id)
    VALUES ('UNIT-TEST-FREEZE-01', 1, 'B+', 'Packed RBC', 280, '2026-11-11', '2026-12-23 23:59:59', 'Available', 1)
    """)
    freeze_unit_id = cur.lastrowid
    cur.execute("""
    INSERT INTO cold_chain_events (location_id, event_seq_no, recorded_temp_c, recorded_at, alert_triggered)
    VALUES (1, 9999, 9.5, datetime('now'), 1)
    """)
    cur.execute("SELECT status FROM blood_units WHERE unit_id = ?", (freeze_unit_id,))
    freeze_status = cur.fetchone()[0]
    if freeze_status == 'Quarantined':
        tests.append(("BR11: Cold-Chain Breach Auto-Quarantine", "PASS", "Trigger automatically moved available units in location 1 to Quarantined"))
    else:
        tests.append(("BR11: Cold-Chain Breach Auto-Quarantine", "FAIL", f"Expected Quarantined but got {freeze_status}"))

    # Test 6: Trigger 5 - Anti-Tamper Hard Delete Guard
    try:
        cur.execute("DELETE FROM audit_logs WHERE audit_id = 1")
        tests.append(("BR10: Anti-Tamper WORM Audit Protection", "FAIL", "Hard delete on audit_logs was allowed"))
    except sqlite3.IntegrityError as e:
        tests.append(("BR10: Anti-Tamper WORM Audit Protection", "PASS", f"Trigger blocked hard delete: {e}"))

    conn.rollback() # Discard test mutations
    conn.close()

    print("=== AUTOMATED TEST RESULTS SUMMARY ===")
    all_pass = True
    for t_name, status, detail in tests:
        mark = "✓ PASS" if status == "PASS" else "✗ FAIL"
        if status != "PASS":
            all_pass = False
        print(f"  [{mark}] {t_name:<40} : {detail}")
    print("----------------------------------------------------------------------")
    if all_pass:
        print("  ALL 6 CORE DATABASE CONSTRAINT & TRIGGER TESTS PASSED WITH 100% SUCCESS!\n")
    else:
        print("  SOME TESTS FAILED!\n")
        sys.exit(1)

if __name__ == "__main__":
    run_tests()

