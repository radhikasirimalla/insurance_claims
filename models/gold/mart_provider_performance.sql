{{ config(
    materialized = 'table',
    schema = 'gold'
) }}

SELECT
    provider_id,
    provider_name,
    provider_type,
    fraud_risk_score,

    COUNT(DISTINCT claim_id) AS total_claims,
    SUM(total_charges) AS total_billed_amount,
    AVG(total_charges) AS avg_claim_amount,

    CASE
        WHEN fraud_risk_score >= 0.7 THEN 'HIGH_RISK'
        WHEN fraud_risk_score >= 0.3 THEN 'MEDIUM_RISK'
        ELSE 'LOW_RISK'
    END AS fraud_risk_category

FROM {{ ref('fact_claims_final') }}
GROUP BY
    provider_id,
    provider_name,
    provider_type,
    fraud_risk_score
