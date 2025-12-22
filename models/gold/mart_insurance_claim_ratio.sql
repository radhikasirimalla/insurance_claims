{{ config(
    materialized = 'table',
    schema = 'gold',
    cluster_by = ['claim_year', 'claim_month', 'policy_region', 'product_code']
) }}

WITH base AS (

    SELECT
        claim_year,
        claim_month,
        policy_region,
        product_code,
        policy_type,

        member_risk_tier,
        provider_fraud_risk_tier,

        total_charges,
        premium_amount,

        is_paid_claim,
        is_denied_claim

    FROM {{ ref('fact_claims_final') }}
),

aggregated AS (

    SELECT
        claim_year,
        claim_month,
        policy_region,
        product_code,
        policy_type,

        /* ---------------- Volumes ---------------- */
        COUNT(*)                                   AS total_claims,
        COUNT_IF(is_paid_claim)                   AS paid_claims,
        COUNT_IF(is_denied_claim)                 AS denied_claims,

        /* ---------------- Financials ---------------- */
        SUM(total_charges)                        AS total_claim_amount,
        SUM(CASE WHEN is_paid_claim THEN total_charges ELSE 0 END)
                                                   AS total_paid_claim_amount,
        SUM(premium_amount)                       AS total_premium_amount,

        /* ---------------- Risk Segments ---------------- */
        COUNT_IF(member_risk_tier = 'High Risk')  AS high_risk_member_claims,
        COUNT_IF(provider_fraud_risk_tier = 'High Risk')
                                                   AS high_fraud_provider_claims

    FROM base
    GROUP BY
        claim_year,
        claim_month,
        policy_region,
        product_code,
        policy_type
)

SELECT
    claim_year,
    claim_month,
    policy_region,
    product_code,
    policy_type,

    /* ---------------- Claim Volumes ---------------- */
    total_claims,
    paid_claims,
    denied_claims,

    ROUND(denied_claims / NULLIF(total_claims, 0), 4)
        AS denial_rate,

    /* ---------------- Financial Metrics ---------------- */
    total_claim_amount,
    total_paid_claim_amount,
    total_premium_amount,

    ROUND(
        total_paid_claim_amount / NULLIF(total_premium_amount, 0),
        4
    ) AS claim_ratio,

    ROUND(
        total_claim_amount / NULLIF(total_premium_amount, 0),
        4
    ) AS gross_claim_ratio,

    /* ---------------- Risk Indicators ---------------- */
    high_risk_member_claims,
    high_fraud_provider_claims,

    CURRENT_TIMESTAMP() AS gold_processed_at

FROM aggregated
ORDER BY
    claim_year,
    claim_month,
    policy_region,
    product_code
