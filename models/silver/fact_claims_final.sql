{{ config(
    materialized = 'incremental',
    schema = 'silver',
    unique_key = 'claim_id',
    cluster_by = ['claim_date', 'member_id', 'provider_id', 'claim_status']
) }}


WITH base_claims AS (

    SELECT
        c.claim_id,
        c.policy_number,
        c.member_id,
        c.provider_id,
        c.claim_type,
        c.status                  AS claim_status,
        c.claim_date,
        c.received_date,
        c.total_charges,
        c.diagnosis_codes,
        c.procedure_codes,
        c.source_ingestion_ts,
        c.bronze_processed_at,
        c.silver_processed_at,

        -- Member dimension
        m.full_name,
        m.date_of_birth,
        m.gender,
        m.state                   AS member_state,
        m.city                    AS member_city,
        m.zip_code                AS member_zip,
        m.risk_score              AS member_risk_score,
        m.membership_start_date,

        -- Policy dimension
        p.policy_type,
        p.product_code,
        p.effective_date          AS policy_effective_date,
        p.expiration_date         AS policy_expiration_date,
        p.premium_amount,
        p.deductible,
        p.coverage_limits,
        p.agent_id,
        p.region                  AS policy_region,

        -- Provider dimension
        pr.provider_name,
        pr.provider_type,
        pr.specialty,
        pr.address                AS provider_address,
        pr.city                   AS provider_city,
        pr.state                  AS provider_state,
        pr.zip_code               AS provider_zip,
        pr.accreditation_score,
        pr.fraud_risk_score

    FROM {{ ref('fact_claims') }} c
    LEFT JOIN {{ ref('dim_member') }}   m ON c.member_id     = m.member_id
    LEFT JOIN {{ ref('dim_policy') }}   p ON c.policy_number = p.policy_number
    LEFT JOIN {{ ref('dim_provider') }} pr ON c.provider_id  = pr.provider_id

    {% if is_incremental() %}
WHERE c.source_ingestion_ts >
      (SELECT COALESCE(MAX(source_ingestion_ts), '1900-01-01') FROM {{ this }})
{% endif %}
),

enriched_claims AS (

    SELECT
        *,

        /* ---------------- Date Metrics ---------------- */
        DATEDIFF('day', membership_start_date, claim_date)
            AS days_since_membership_start,

        FLOOR(
            DATEDIFF('day', date_of_birth, claim_date) / 365.25
        ) AS member_age_at_claim,

        DATEDIFF('day', claim_date, received_date)
            AS days_to_submit,

        EXTRACT(YEAR    FROM claim_date) AS claim_year,
        EXTRACT(MONTH   FROM claim_date) AS claim_month,
        EXTRACT(QUARTER FROM claim_date) AS claim_quarter,
        DAYOFWEEK(claim_date)            AS claim_day_of_week,

        /* ---------------- Financial Metrics ---------------- */
        CASE
            WHEN deductible > 0
            THEN LEAST(total_charges, deductible)
            ELSE 0
        END AS deductible_portion,

        CASE
            WHEN deductible > 0 AND total_charges > deductible
            THEN total_charges - deductible
            ELSE total_charges
        END AS post_deductible_amount,

        /* ---------------- Categorization ---------------- */
        CASE
            WHEN total_charges < 1000 THEN 'Small (<$1k)'
            WHEN total_charges BETWEEN 1000 AND 10000 THEN 'Medium ($1k-$10k)'
            WHEN total_charges BETWEEN 10001 AND 50000 THEN 'Large ($10k-$50k)'
            ELSE 'Very Large (>$50k)'
        END AS claim_size_category,

        CASE
            WHEN accreditation_score >= 90 THEN 'Excellent'
            WHEN accreditation_score >= 80 THEN 'Good'
            WHEN accreditation_score >= 70 THEN 'Fair'
            ELSE 'Poor'
        END AS provider_accreditation_tier,

        CASE
            WHEN member_risk_score >= 7 THEN 'High Risk'
            WHEN member_risk_score >= 4 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS member_risk_tier,

        CASE
            WHEN fraud_risk_score >= 7 THEN 'High Risk'
            WHEN fraud_risk_score >= 4 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS provider_fraud_risk_tier,

        /* ---------------- Policy Validation ---------------- */
        CASE
            WHEN policy_effective_date IS NOT NULL
                 AND claim_date < policy_effective_date
            THEN TRUE ELSE FALSE
        END AS is_claim_before_policy_start,

        CASE
            WHEN policy_expiration_date IS NOT NULL
                 AND claim_date > policy_expiration_date
            THEN TRUE ELSE FALSE
        END AS is_claim_after_policy_end,

        /* ---------------- Status Flags ---------------- */
        claim_status IN ('DENIED', 'REJECTED') AS is_denied_claim,
        claim_status = 'PAID'                  AS is_paid_claim,

        /* ---------------- Array Metrics ---------------- */
        ARRAY_SIZE(COALESCE(diagnosis_codes, ARRAY_CONSTRUCT()))
            AS diagnosis_code_count,

        ARRAY_SIZE(COALESCE(procedure_codes, ARRAY_CONSTRUCT()))
            AS procedure_code_count

    FROM base_claims
)

SELECT
    -- Claim
    claim_id,
    policy_number,
    member_id,
    provider_id,
    claim_type,
    claim_status,

    -- Dates
    claim_date,
    received_date,
    claim_year,
    claim_month,
    claim_quarter,
    claim_day_of_week,

    -- Financials
    total_charges,
    claim_size_category,
    deductible_portion,
    post_deductible_amount,

    -- Member
    full_name,
    date_of_birth,
    gender,
    member_state,
    member_city,
    member_zip,
    member_risk_score,
    member_risk_tier,
    membership_start_date,
    member_age_at_claim,
    days_since_membership_start,

    -- Policy
    policy_type,
    product_code,
    policy_effective_date,
    policy_expiration_date,
    premium_amount,
    deductible,
    coverage_limits,
    agent_id,
    policy_region,

    -- Provider
    provider_name,
    provider_type,
    specialty,
    provider_address,
    provider_city,
    provider_state,
    provider_zip,
    accreditation_score,
    provider_accreditation_tier,
    fraud_risk_score,
    provider_fraud_risk_tier,

    -- Claim Details
    diagnosis_codes,
    diagnosis_code_count,
    procedure_codes,
    procedure_code_count,

    -- Timing
    days_to_submit,
    is_claim_before_policy_start,
    is_claim_after_policy_end,

    -- Status
    is_denied_claim,
    is_paid_claim,

    -- Audit
    source_ingestion_ts,
    bronze_processed_at,
    silver_processed_at,
    CURRENT_TIMESTAMP() AS fact_final_processed_at

FROM enriched_claims
