-- ============================================================================
-- Migration: V6__ai_analytics_extension.sql
-- Project: AI-Assisted Blood Bank and Donor Matching System (CSL0311)
-- Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
-- Purpose: Adds AI decision logging, governance metadata, and feature vectors.
-- ============================================================================

-- Table: AI Decision & Human-in-the-Loop Governance Audit
CREATE TABLE IF NOT EXISTS ai_decision_logs (
    decision_id SERIAL PRIMARY KEY,
    feature_name VARCHAR(64) NOT NULL,
    model_version VARCHAR(32) NOT NULL,
    input_features JSONB NOT NULL,
    prediction_output JSONB NOT NULL,
    confidence_score NUMERIC(4,3) NOT NULL,
    human_approved BOOLEAN NOT NULL DEFAULT FALSE,
    reviewed_by_tech_id INT REFERENCES technicians(tech_id) ON DELETE SET NULL,
    decision_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    rejection_reason VARCHAR(255)
);

-- Index for querying recent AI decisions
CREATE INDEX IF NOT EXISTS idx_ai_decision_date 
ON ai_decision_logs (decision_timestamp DESC);

-- View: AI Shortage Forecasts with Human Review Status
CREATE OR REPLACE VIEW vw_ai_active_shortages AS
SELECT 
    f.forecast_id,
    f.forecast_date,
    f.blood_group,
    f.component_type,
    f.predicted_demand_units,
    f.current_available_units,
    f.predicted_shortage_units,
    f.risk_level,
    f.confidence_score,
    f.model_version,
    f.recommended_donor_outreach_count,
    f.human_approved,
    f.approved_by,
    f.created_at
FROM ai_shortage_forecasts f
WHERE f.predicted_shortage_units > 0
ORDER BY 
    CASE f.risk_level 
        WHEN 'Critical' THEN 1 
        WHEN 'High' THEN 2 
        WHEN 'Moderate' THEN 3 
        ELSE 4 
    END,
    f.predicted_shortage_units DESC;

-- Record Migration V6 in registry
INSERT INTO schema_versions (version_id, version_tag, description, checksum, applied_by)
VALUES (6, 'V6__ai_analytics_extension', 'Deployment of AI governance ledger and predictive shortage views', 'sha256_v6_csl0311_ai', 'Ayan Khan')
ON CONFLICT (version_id) DO NOTHING;

