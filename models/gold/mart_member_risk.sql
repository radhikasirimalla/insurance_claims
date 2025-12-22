{{ config(
    materialized = 'table',
    schema = 'gold'
) }}

SELECT
    member_id,
    member_name,
    member_gender,
    member_risk_score,

    COUNT(DISTINCT claim_id) AS total_claims,
    SUM(total_charges) AS total_claim_amount,
    AVG(total_charges) AS avg_claim_amount,

    CASE
        WHEN member_risk_score >= 0.7 THEN 'HIGH'
        WHEN member_risk_score >= 0.3 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS risk_category

FROM {{ ref('fact_claims_final') }}
GROUP BY
    member_id,
    member_name,
    member_gender,
    member_risk_score
