{{ config(
    materialized = 'table',
    schema = 'gold'
) }}

SELECT
    DATE_TRUNC('month', claim_date) AS claim_month,
    claim_type,
    status,

    COUNT(DISTINCT claim_id) AS total_claims,
    SUM(total_charges) AS total_claim_amount,
    AVG(total_charges) AS avg_claim_amount

FROM {{ ref('fact_claims_final') }}
GROUP BY 1, 2, 3
