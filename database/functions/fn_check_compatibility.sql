-- ============================================================================
-- Function: fn_check_compatibility.sql
-- Project: AI-Assisted Blood Bank and Donor Matching System (CSL0311)
-- Authors: Diya Motwani, Gaurav Agrawal, Ayan Khan, Ch. Mohith
-- Purpose: Evaluates ABO and Rh compatibility truth tables for Red Cells and Plasma.
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_check_compatibility(
    p_donor_bg VARCHAR(5),
    p_recipient_bg VARCHAR(5),
    p_component_type VARCHAR(32) DEFAULT 'Packed RBC'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_donor_abo VARCHAR(2);
    v_donor_rh CHAR(1);
    v_recip_abo VARCHAR(2);
    v_recip_rh CHAR(1);
BEGIN
    -- Standardize input
    p_donor_bg := UPPER(TRIM(p_donor_bg));
    p_recipient_bg := UPPER(TRIM(p_recipient_bg));

    -- Extract ABO and Rh factors
    v_donor_rh := RIGHT(p_donor_bg, 1);
    v_donor_abo := SUBSTRING(p_donor_bg FROM 1 FOR LENGTH(p_donor_bg) - 1);
    
    v_recip_rh := RIGHT(p_recipient_bg, 1);
    v_recip_abo := SUBSTRING(p_recipient_bg FROM 1 FOR LENGTH(p_recipient_bg) - 1);

    -- 1. Red Blood Cells (Packed RBC & Whole Blood) Compatibility
    IF p_component_type IN ('Packed RBC', 'Whole Blood') THEN
        -- Rh Rule: Rh-negative can donate to Rh+ or Rh-; Rh-positive can ONLY donate to Rh+
        IF v_donor_rh = '+' AND v_recip_rh = '-' THEN
            RETURN FALSE;
        END IF;

        -- ABO Rules for Red Cells:
        -- Donor O: Universal red cell donor (can give to O, A, B, AB)
        IF v_donor_abo = 'O' THEN
            RETURN TRUE;
        -- Donor A: Can give to A, AB
        ELSIF v_donor_abo = 'A' AND v_recip_abo IN ('A', 'AB') THEN
            RETURN TRUE;
        -- Donor B: Can give to B, AB
        ELSIF v_donor_abo = 'B' AND v_recip_abo IN ('B', 'AB') THEN
            RETURN TRUE;
        -- Donor AB: Can only give to AB
        ELSIF v_donor_abo = 'AB' AND v_recip_abo = 'AB' THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;

    -- 2. Fresh Frozen Plasma (FFP) Compatibility (Reverse ABO Rules)
    ELSIF p_component_type = 'Fresh Frozen Plasma' THEN
        -- Rh factor is clinically ignored in standard plasma infusions
        -- ABO Rules for Plasma:
        -- Donor AB: Universal plasma donor (has no anti-A or anti-B antibodies; can give to O, A, B, AB)
        IF v_donor_abo = 'AB' THEN
            RETURN TRUE;
        -- Donor A: Can give to A, O
        ELSIF v_donor_abo = 'A' AND v_recip_abo IN ('A', 'O') THEN
            RETURN TRUE;
        -- Donor B: Can give to B, O
        ELSIF v_donor_abo = 'B' AND v_recip_abo IN ('B', 'O') THEN
            RETURN TRUE;
        -- Donor O: Can only give to O
        ELSIF v_donor_abo = 'O' AND v_recip_abo = 'O' THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;

    -- 3. Platelets (Preferred ABO identical or RBC rules)
    ELSIF p_component_type = 'Platelets' THEN
        IF p_donor_bg = p_recipient_bg THEN
            RETURN TRUE;
        ELSIF v_donor_abo = 'O' AND (v_donor_rh = '-' OR v_recip_rh = '+') THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END IF;

    RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

