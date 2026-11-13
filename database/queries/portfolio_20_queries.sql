-- ============================================================================
-- Query Portfolio: 20 Advanced SQL Queries (Phase 8 Deliverable)
-- Course: DBMS CSL0311 – Problem-Based & Project-Based Learning
-- Project: AI-Assisted Blood Bank and Donor Matching System (ITM University Gwalior)
-- Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
-- ============================================================================

-- ============================================================================
-- SECTION A: OPERATIONAL REPORTS (Queries 1 - 5)
-- ============================================================================

-- Query 01: [Operational Report 1] Real-Time Usable Blood Inventory by Group and Cold Freezer
-- Technique: Multi-table Inner Join, Aggregation, Date Filtering
SELECT 
    loc.storage_code,
    loc.facility_zone,
    u.blood_group,
    u.component_type,
    COUNT(u.unit_id) AS total_usable_units,
    ROUND(SUM(u.volume_ml) / 1000.0, 2) AS total_volume_liters,
    MIN(u.expiry_date) AS earliest_expiring_unit
FROM blood_units u
JOIN inventory_locations loc ON u.location_id = loc.location_id
WHERE u.status = 'Available'
  AND u.expiry_date > NOW()
GROUP BY loc.storage_code, loc.facility_zone, u.blood_group, u.component_type
ORDER BY loc.storage_code, u.blood_group;

-- Query 02: [Operational Report 2] Daily Diagnostic Screening Triage Queue
-- Technique: Outer Join, Conditional CASE expression, Priority Ordering
SELECT 
    u.unit_barcode,
    u.blood_group,
    u.component_type,
    u.collection_date,
    t.test_id,
    COALESCE(t.hiv_status, 'Unscheduled') AS hiv_status,
    COALESCE(t.hbsag_status, 'Unscheduled') AS hbsag_status,
    COALESCE(t.overall_result, 'Pending') AS test_status,
    tech.full_name AS assigned_technologist
FROM blood_units u
LEFT JOIN laboratory_tests t ON u.unit_id = t.unit_id
LEFT JOIN technicians tech ON t.tested_by_tech_id = tech.tech_id
WHERE u.status = 'Quarantined'
ORDER BY u.collection_date ASC;

-- Query 03: [Operational Report 3] Active Unfulfilled Emergency Requisitions & Transit Deadlines
-- Technique: Inner Join, Interval Math, Priority Filtering
SELECT 
    r.request_code,
    h.hospital_name,
    h.emergency_phone,
    r.patient_ref_code,
    r.blood_group,
    r.component_type,
    r.requested_qty,
    r.allocated_qty,
    (r.requested_qty - r.allocated_qty) AS units_deficit,
    ROUND(EXTRACT(EPOCH FROM (r.required_by_date - NOW())) / 60.0, 0) AS minutes_remaining,
    r.priority
FROM blood_requests r
JOIN hospitals h ON r.hospital_id = h.hospital_id
WHERE r.request_status IN ('Pending', 'Partially_Allocated')
  AND r.priority IN ('Emergency', 'Urgent')
ORDER BY r.required_by_date ASC;

-- Query 04: [Operational Report 4] Phlebotomist Collection Yield & Quality Audit
-- Technique: Join, Aggregate, HAVING filter
SELECT 
    tech.tech_id,
    tech.full_name,
    tech.role,
    COUNT(d.donation_id) AS total_donations_collected,
    SUM(d.volume_ml) AS total_volume_ml,
    COUNT(CASE WHEN d.collection_status = 'Successful' THEN 1 END) AS successful_collections,
    COUNT(CASE WHEN d.collection_status = 'Incomplete' THEN 1 END) AS aborted_collections
FROM technicians tech
JOIN donations d ON tech.tech_id = d.collected_by_tech_id
GROUP BY tech.tech_id, tech.full_name, tech.role
HAVING COUNT(d.donation_id) >= 10
ORDER BY successful_collections DESC;

-- Query 05: [Operational Report 5] Blood Units Issued in Past 24 Hours with Receiving Transfusion Officers
-- Technique: Multi-table 4-way Join, Date Interval Filter
SELECT 
    u.unit_barcode,
    u.blood_group,
    u.component_type,
    h.hospital_name,
    r.request_code,
    a.allocated_at,
    a.issued_at,
    tech.full_name AS issuing_officer
FROM allocations a
JOIN blood_units u ON a.unit_id = u.unit_id
JOIN blood_requests r ON a.request_id = r.request_id
JOIN hospitals h ON r.hospital_id = h.hospital_id
JOIN technicians tech ON a.allocated_by_tech_id = tech.tech_id
WHERE a.allocation_status = 'Issued'
  AND a.issued_at >= (NOW() - INTERVAL '24 hours')
ORDER BY a.issued_at DESC;


-- ============================================================================
-- SECTION B: MANAGEMENT & STRATEGIC REPORTS (Queries 6 - 10)
-- ============================================================================

-- Query 06: [Strategic Management 1] Hospital Service-Level Agreement (SLA) Fulfillment Analysis
-- Technique: Correlated Subquery, Grouping, Percentage Calculations
SELECT 
    h.hospital_id,
    h.hospital_name,
    h.city,
    COUNT(r.request_id) AS total_requisitions,
    SUM(r.requested_qty) AS units_requested,
    SUM(r.allocated_qty) AS units_fulfilled,
    ROUND((SUM(r.allocated_qty)::NUMERIC / NULLIF(SUM(r.requested_qty), 0)) * 100.0, 2) AS overall_fulfillment_pct,
    (
        SELECT ROUND(AVG(EXTRACT(EPOCH FROM (a.issued_at - r2.requested_at)) / 3600.0), 1)
        FROM blood_requests r2
        JOIN allocations a ON r2.request_id = a.request_id
        WHERE r2.hospital_id = h.hospital_id AND a.issued_at IS NOT NULL
    ) AS avg_delivery_turnaround_hours
FROM hospitals h
LEFT JOIN blood_requests r ON h.hospital_id = r.hospital_id
GROUP BY h.hospital_id, h.hospital_name, h.city
ORDER BY total_requisitions DESC;

-- Query 07: [Strategic Management 2] Blood Wastage by Cause: Expiry vs. Reactive Biohazard
-- Technique: CTE (Common Table Expression), Aggregation, Conditional Ratio
WITH component_wastage AS (
    SELECT 
        component_type,
        COUNT(unit_id) AS total_units,
        COUNT(CASE WHEN status = 'Expired' THEN 1 END) AS expired_count,
        COUNT(CASE WHEN status = 'Biohazard_Quarantined' THEN 1 END) AS biohazard_count,
        COUNT(CASE WHEN status = 'Transfused' THEN 1 END) AS utilized_count
    FROM blood_units
    GROUP BY component_type
)
SELECT 
    component_type,
    total_units,
    utilized_count,
    expired_count,
    biohazard_count,
    ROUND((expired_count::NUMERIC / total_units) * 100.0, 2) AS expiry_wastage_rate_pct,
    ROUND((biohazard_count::NUMERIC / total_units) * 100.0, 2) AS biohazard_discard_rate_pct
FROM component_wastage
ORDER BY expiry_wastage_rate_pct DESC;

-- Query 08: [Strategic Management 3] Top Repeat Donors Ranked by Lifetime Yield (DENSE_RANK)
-- Technique: Window Function (DENSE_RANK), Multi-table Join, Aggregation
SELECT 
    d.donor_id,
    d.donor_code,
    d.blood_group,
    d.city,
    COUNT(dn.donation_id) AS lifetime_donations,
    SUM(dn.volume_ml) AS lifetime_volume_ml,
    DENSE_RANK() OVER (ORDER BY COUNT(dn.donation_id) DESC, SUM(dn.volume_ml) DESC) AS donor_honor_rank
FROM donors d
JOIN donations dn ON d.donor_id = dn.donor_id
WHERE dn.collection_status = 'Successful'
GROUP BY d.donor_id, d.donor_code, d.blood_group, d.city
ORDER BY donor_honor_rank ASC
LIMIT 15;

-- Query 09: [Strategic Management 4] Recursive Supervisory Chain of Blood Bank Staff
-- Technique: Recursive CTE (Common Table Expression) modeling recursive technician hierarchy
WITH RECURSIVE tech_hierarchy AS (
    -- Anchor member: Technicians with no supervisor (Directors/Chiefs)
    SELECT 
        tech_id,
        full_name,
        role,
        supervisor_id,
        1 AS org_level,
        full_name::VARCHAR(255) AS management_chain
    FROM technicians
    WHERE supervisor_id IS NULL

    UNION ALL

    -- Recursive member: Subordinates
    SELECT 
        t.tech_id,
        t.full_name,
        t.role,
        t.supervisor_id,
        th.org_level + 1 AS org_level,
        CONCAT(th.management_chain, ' -> ', t.full_name)::VARCHAR(255) AS management_chain
    FROM technicians t
    JOIN tech_hierarchy th ON t.supervisor_id = th.tech_id
)
SELECT 
    tech_id,
    full_name,
    role,
    org_level,
    management_chain
FROM tech_hierarchy
ORDER BY org_level, tech_id;

-- Query 10: [Strategic Management 5] End-to-End Vein-to-Vein Unit Custody Traceability
-- Technique: Deep Multi-table Join connecting Donor -> Donation -> Unit -> Test -> Allocation -> Hospital -> Transfusion
SELECT 
    d.donor_code,
    d.blood_group AS donor_bg,
    dn.bag_serial_no,
    dn.collection_date,
    u.unit_barcode,
    u.component_type,
    t.overall_result AS infectious_screen,
    t.test_timestamp,
    r.request_code,
    r.patient_ref_code,
    h.hospital_name AS treating_hospital,
    a.allocated_at,
    tr.transfused_at,
    tr.adverse_reaction,
    COALESCE(tr.reaction_notes, 'None') AS reaction_notes
FROM blood_units u
JOIN donations dn ON u.donation_id = dn.donation_id
JOIN donors d ON dn.donor_id = d.donor_id
JOIN laboratory_tests t ON u.unit_id = t.unit_id
JOIN allocations a ON u.unit_id = a.unit_id
JOIN blood_requests r ON a.request_id = r.request_id
JOIN hospitals h ON r.hospital_id = h.hospital_id
LEFT JOIN transfusions tr ON a.allocation_id = tr.allocation_id
WHERE tr.transfusion_id IS NOT NULL
ORDER BY tr.transfused_at DESC
LIMIT 10;


-- ============================================================================
-- SECTION C: TREND-ANALYSIS REPORTS (Queries 11 - 13)
-- ============================================================================

-- Query 11: [Trend Analysis 1] Month-over-Month Blood Shortage Demand Growth (LAG Window Function)
-- Technique: Window Function LAG(), Subquery, Date Truncation
WITH monthly_demand AS (
    SELECT 
        DATE_TRUNC('month', requested_at) AS request_month,
        blood_group,
        SUM(requested_qty) AS total_demanded
    FROM blood_requests
    GROUP BY DATE_TRUNC('month', requested_at), blood_group
)
SELECT 
    TO_CHAR(request_month, 'YYYY-MM') AS month_label,
    blood_group,
    total_demanded,
    LAG(total_demanded, 1) OVER (PARTITION BY blood_group ORDER BY request_month) AS prev_month_demanded,
    ROUND(
        (total_demanded - LAG(total_demanded, 1) OVER (PARTITION BY blood_group ORDER BY request_month))::NUMERIC /
        NULLIF(LAG(total_demanded, 1) OVER (PARTITION BY blood_group ORDER BY request_month), 0) * 100.0, 
        1
    ) AS mom_growth_pct
FROM monthly_demand
ORDER BY blood_group, request_month DESC;

-- Query 12: [Trend Analysis 2] 7-Day Rolling Average Requisition Volume by Blood Group
-- Technique: Window Function AVG() OVER (ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
WITH daily_requisitions AS (
    SELECT 
        CAST(requested_at AS DATE) AS req_date,
        blood_group,
        SUM(requested_qty) AS daily_units
    FROM blood_requests
    GROUP BY CAST(requested_at AS DATE), blood_group
)
SELECT 
    req_date,
    blood_group,
    daily_units,
    ROUND(
        AVG(daily_units) OVER (
            PARTITION BY blood_group 
            ORDER BY req_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 
        2
    ) AS rolling_7day_avg_demand
FROM daily_requisitions
ORDER BY req_date DESC, blood_group;

-- Query 13: [Trend Analysis 3] Monthly Collection vs. Transfusion Yield Comparison (UNION ALL & Pivot)
-- Technique: Set Operation (UNION ALL), Date Formatting, Conditional Sum Aggregation
SELECT 
    event_month,
    SUM(CASE WHEN metric_type = 'Collection' THEN unit_count ELSE 0 END) AS units_collected,
    SUM(CASE WHEN metric_type = 'Transfusion' THEN unit_count ELSE 0 END) AS units_transfused,
    ROUND(
        SUM(CASE WHEN metric_type = 'Transfusion' THEN unit_count ELSE 0 END)::NUMERIC /
        NULLIF(SUM(CASE WHEN metric_type = 'Collection' THEN unit_count ELSE 0 END), 0) * 100.0,
        1
    ) AS collection_to_transfusion_ratio_pct
FROM (
    SELECT TO_CHAR(collection_date, 'YYYY-MM') AS event_month, 'Collection' AS metric_type, COUNT(unit_id) AS unit_count
    FROM blood_units
    GROUP BY TO_CHAR(collection_date, 'YYYY-MM')
    
    UNION ALL
    
    SELECT TO_CHAR(transfused_at, 'YYYY-MM') AS event_month, 'Transfusion' AS metric_type, COUNT(transfusion_id) AS unit_count
    FROM transfusions
    GROUP BY TO_CHAR(transfused_at, 'YYYY-MM')
) combined_trends
GROUP BY event_month
ORDER BY event_month DESC;


-- ============================================================================
-- SECTION D: EXCEPTION & INTEGRITY REPORTS (Queries 14 - 15)
-- ============================================================================

-- Query 14: [Exception Report 1] Critical Expiry Alert: Units Expiring in 48 Hours Unallocated
-- Technique: Timestamp Delta Arithmetic, Exception Status Filtering
SELECT 
    u.unit_id,
    u.unit_barcode,
    u.blood_group,
    u.component_type,
    loc.storage_code,
    loc.facility_zone,
    u.expiry_date,
    ROUND(EXTRACT(EPOCH FROM (u.expiry_date - NOW())) / 3600.0, 1) AS hours_left_to_expire
FROM blood_units u
JOIN inventory_locations loc ON u.location_id = loc.location_id
WHERE u.status = 'Available'
  AND u.expiry_date BETWEEN NOW() AND (NOW() + INTERVAL '48 hours')
ORDER BY u.expiry_date ASC;

-- Query 15: [Exception Report 2] Cold Storage Equipment Temperature Anomalies & Breach Count
-- Technique: Subquery, Outer Join, Aggregate Filter
SELECT 
    loc.location_id,
    loc.storage_code,
    loc.facility_zone,
    loc.component_type,
    loc.min_temp_c,
    loc.max_temp_c,
    loc.current_temp_c,
    COUNT(cce.event_seq_no) AS total_breach_events,
    MAX(cce.recorded_temp_c) AS max_temp_recorded,
    MAX(cce.recorded_at) AS latest_breach_timestamp
FROM inventory_locations loc
JOIN cold_chain_events cce ON loc.location_id = cce.location_id
WHERE cce.alert_triggered = TRUE
GROUP BY loc.location_id, loc.storage_code, loc.facility_zone, loc.component_type, loc.min_temp_c, loc.max_temp_c, loc.current_temp_c
HAVING COUNT(cce.event_seq_no) > 0
ORDER BY total_breach_events DESC;


-- ============================================================================
-- SECTION E: ADVANCED ANALYTICAL & AUDIT LEDGER QUERIES (Queries 16 - 20)
-- ============================================================================

-- Query 16: [Set Operation] Donors Who Donated Whole Blood but Have Never Given Platelets
-- Technique: Set Operation EXCEPT (Relational Difference)
SELECT d.donor_id, d.donor_code, d.full_name, d.blood_group
FROM donors d
JOIN donations dn ON d.donor_id = dn.donor_id
JOIN blood_units u ON dn.donation_id = u.donation_id
WHERE u.component_type = 'Whole Blood'

EXCEPT

SELECT d.donor_id, d.donor_code, d.full_name, d.blood_group
FROM donors d
JOIN donations dn ON d.donor_id = dn.donor_id
JOIN blood_units u ON dn.donation_id = u.donation_id
WHERE u.component_type = 'Platelets'
ORDER BY donor_id;

-- Query 17: [JSONB Forensic Audit] Tracking All Units Transitioned to 'Biohazard_Quarantined'
-- Technique: PostgreSQL JSONB Containment Operator (@>)
SELECT 
    audit_id,
    record_id AS unit_id,
    operation_type,
    new_state->>'blood_group' AS blood_group,
    new_state->>'component_type' AS component_type,
    location_snapshot->>'storage_code' AS equipment_code,
    changed_by,
    changed_at
FROM audit_logs
WHERE table_name = 'blood_units'
  AND new_state @> '{"status": "Biohazard_Quarantined"}'::jsonb
ORDER BY changed_at DESC;

-- Query 18: [AI Feature Vector] 12-Month Historical Donor Recency-Frequency Profile for ML Forecaster
-- Technique: Grouping, Date Math, Aggregate Metrics for Model Feature Extraction
SELECT 
    d.donor_id,
    d.blood_group,
    (CURRENT_DATE - COALESCE(d.last_donation_date, d.created_at::DATE)) AS recency_days,
    COUNT(dn.donation_id) AS frequency_donations,
    COALESCE(SUM(dn.volume_ml), 0) AS monetary_volume_ml,
    (CURRENT_DATE - d.created_at::DATE) AS time_since_first_donation_days,
    CASE 
        WHEN d.is_eligible = TRUE AND (d.last_donation_date IS NULL OR (CURRENT_DATE - d.last_donation_date) >= 90) 
        THEN 1 ELSE 0 
    END AS target_eligible_flag
FROM donors d
LEFT JOIN donations dn ON d.donor_id = dn.donor_id AND dn.collection_status = 'Successful'
GROUP BY d.donor_id, d.blood_group, d.last_donation_date, d.created_at, d.is_eligible
ORDER BY frequency_donations DESC;

-- Query 19: [Correlated Subquery] Hospitals Whose Average Emergency Demand Exceeds Regional Mean
-- Technique: Correlated Subquery with Comparison against Global Aggregate
SELECT 
    h.hospital_name,
    h.district,
    ROUND(AVG(r.requested_qty), 2) AS hospital_avg_emergency_qty
FROM hospitals h
JOIN blood_requests r ON h.hospital_id = r.hospital_id
WHERE r.priority = 'Emergency'
GROUP BY h.hospital_id, h.hospital_name, h.district
HAVING AVG(r.requested_qty) > (
    SELECT AVG(requested_qty) 
    FROM blood_requests 
    WHERE priority = 'Emergency'
)
ORDER BY hospital_avg_emergency_qty DESC;

-- Query 20: [Executive Summary Report] Complete Regional Executive KPI Cockpit
-- Technique: Single Cross-Domain Summary Aggregation over All Relational Entities
SELECT 
    (SELECT COUNT(*) FROM blood_units WHERE status = 'Available' AND expiry_date > NOW()) AS total_safe_available_units,
    (SELECT COUNT(*) FROM blood_units WHERE status = 'Quarantined') AS total_quarantined_units,
    (SELECT COUNT(*) FROM blood_units WHERE expiry_date <= NOW() AND status != 'Discarded') AS total_expired_unusable_units,
    (SELECT COUNT(*) FROM blood_requests WHERE request_status IN ('Pending', 'Partially_Allocated') AND priority = 'Emergency') AS active_emergencies,
    (SELECT COUNT(*) FROM donors WHERE is_eligible = TRUE AND (last_donation_date IS NULL OR (CURRENT_DATE - last_donation_date) >= 90)) AS total_outreach_eligible_donors,
    (SELECT COUNT(*) FROM transfusions WHERE adverse_reaction = TRUE) AS total_adverse_reactions_reported;

