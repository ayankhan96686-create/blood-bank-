-- ============================================================================
-- Views & Materialized Analytics: all_views.sql
-- Project: AI-Assisted Blood Bank and Donor Matching System (CSL0311)
-- Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
-- Purpose: Defines 4 real-time views and 1 materialized analytical reporting view.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- View 1: Real-Time Available Blood Inventory (Excludes Quarantined/Expired)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_live_blood_inventory AS
SELECT 
    u.blood_group,
    u.component_type,
    loc.storage_code,
    loc.facility_zone,
    loc.current_temp_c,
    COUNT(u.unit_id) AS available_units,
    ROUND(SUM(u.volume_ml) / 1000.0, 2) AS total_liters,
    MIN(u.expiry_date) AS earliest_expiry,
    MAX(u.expiry_date) AS latest_expiry
FROM blood_units u
JOIN inventory_locations loc ON u.location_id = loc.location_id
WHERE u.status = 'Available'
  AND u.expiry_date > NOW()
GROUP BY 
    u.blood_group,
    u.component_type,
    loc.storage_code,
    loc.facility_zone,
    loc.current_temp_c
ORDER BY u.blood_group, u.component_type;


-- ----------------------------------------------------------------------------
-- View 2: Critical Expiry Exception Monitor (Units Expiring Within 7 Days)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_expiring_units_7days AS
SELECT 
    u.unit_id,
    u.unit_barcode,
    u.blood_group,
    u.component_type,
    u.volume_ml,
    u.collection_date,
    u.expiry_date,
    ROUND(EXTRACT(EPOCH FROM (u.expiry_date - NOW())) / 3600.0, 1) AS hours_until_expiry,
    ROUND(EXTRACT(EPOCH FROM (u.expiry_date - NOW())) / 86400.0, 1) AS days_until_expiry,
    u.status,
    loc.storage_code,
    loc.facility_zone
FROM blood_units u
JOIN inventory_locations loc ON u.location_id = loc.location_id
WHERE u.status IN ('Available', 'Quarantined')
  AND u.expiry_date BETWEEN NOW() AND (NOW() + INTERVAL '7 days')
ORDER BY u.expiry_date ASC;


-- ----------------------------------------------------------------------------
-- View 3: PHI-Masked Donor Directory for Clinical Staff (DPDPA / HIPAA Compliance)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_donor_masked_clinical AS
SELECT 
    d.donor_id,
    d.donor_code,
    -- Mask Name as 'R. Sharma' or 'Firstname S.'
    CONCAT(SUBSTRING(d.full_name FROM 1 FOR 1), '. ', SPLIT_PART(d.full_name, ' ', 2)) AS clinical_donor_alias,
    d.gender,
    d.blood_group,
    d.weight_kg,
    d.hemoglobin_g_dl,
    d.city,
    d.pincode,
    -- Mask phone showing only last 4 digits
    CONCAT('XXXXXX', RIGHT(d.phone_masked, 4)) AS masked_phone,
    d.last_donation_date,
    CASE 
        WHEN d.last_donation_date IS NULL THEN 999
        ELSE (CURRENT_DATE - d.last_donation_date)
    END AS days_since_last_donation,
    d.is_eligible,
    d.deferral_reason
FROM donors d;


-- ----------------------------------------------------------------------------
-- View 4: Hospital Request Fulfillment & SLA Performance
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_hospital_fulfillment_sla AS
SELECT 
    h.hospital_id,
    h.hospital_name,
    h.city,
    h.distance_km_from_bank,
    COUNT(r.request_id) AS total_requests_placed,
    SUM(r.requested_qty) AS total_units_demanded,
    SUM(r.allocated_qty) AS total_units_fulfilled,
    ROUND((SUM(r.allocated_qty)::NUMERIC / NULLIF(SUM(r.requested_qty), 0)) * 100.0, 1) AS fulfillment_rate_pct,
    COUNT(CASE WHEN r.priority = 'Emergency' THEN 1 END) AS emergency_requests_count,
    COUNT(CASE WHEN r.priority = 'Emergency' AND r.request_status = 'Fulfilled' THEN 1 END) AS emergency_fulfilled_count,
    ROUND(AVG(CASE 
        WHEN r.priority = 'Emergency' 
        THEN EXTRACT(EPOCH FROM (r.required_by_date - r.requested_at)) / 60.0 
    END), 1) AS avg_emergency_lead_time_mins
FROM hospitals h
LEFT JOIN blood_requests r ON h.hospital_id = r.hospital_id
GROUP BY h.hospital_id, h.hospital_name, h.city, h.distance_km_from_bank
ORDER BY total_requests_placed DESC;


-- ----------------------------------------------------------------------------
-- View 5: Materialized Analytics: Monthly Supply, Wastage & Discard Trends
-- ----------------------------------------------------------------------------
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_supply_wastage_trends AS
SELECT 
    TO_CHAR(u.collection_date, 'YYYY-MM') AS report_month,
    u.blood_group,
    u.component_type,
    COUNT(u.unit_id) AS total_collected_units,
    COUNT(CASE WHEN u.status = 'Transfused' THEN 1 END) AS transfused_units,
    COUNT(CASE WHEN u.status = 'Expired' THEN 1 END) AS expired_waste_units,
    COUNT(CASE WHEN u.status = 'Biohazard_Quarantined' OR u.status = 'Discarded' THEN 1 END) AS reactive_discard_units,
    ROUND((COUNT(CASE WHEN u.status = 'Expired' THEN 1 END)::NUMERIC / NULLIF(COUNT(u.unit_id), 0)) * 100.0, 2) AS expiry_wastage_pct,
    ROUND((COUNT(CASE WHEN u.status = 'Biohazard_Quarantined' THEN 1 END)::NUMERIC / NULLIF(COUNT(u.unit_id), 0)) * 100.0, 2) AS reactive_infection_rate_pct
FROM blood_units u
GROUP BY TO_CHAR(u.collection_date, 'YYYY-MM'), u.blood_group, u.component_type
ORDER BY report_month DESC, u.blood_group;

-- Unique index for concurrent refreshing of materialized view
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_supply_month_bg_comp 
ON mv_monthly_supply_wastage_trends (report_month, blood_group, component_type);

