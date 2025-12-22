{{ config(
    materialized = 'table',
    schema = 'silver'
) }}

SELECT
    fc.claim_id,
    fc.policy_number,
    fc.member_id,
    m.full_name        AS member_name,
    m.gender           AS member_gender,
    m.risk_score       AS member_risk_score,

    fc.provider_id,
    p.provider_name,
    p.provider_type,
    p.fraud_risk_score,

    pol.policy_type,
    pol.product_code,

    fc.claim_type,
    fc.status,
    fc.claim_date,
    fc.received_date,
    fc.total_charges,

    -- ARRAYS PRESERVED
    fc.diagnosis_codes,
    fc.procedure_codes,

    fc.source_ingestion_ts,
    fc.bronze_processed_at,
    fc.silver_processed_at,
    CURRENT_TIMESTAMP() AS silver_final_processed_at

FROM {{ ref('fact_claims') }} fc
LEFT JOIN {{ ref('dim_member') }}   m   ON fc.member_id     = m.member_id
LEFT JOIN {{ ref('dim_provider') }} p   ON fc.provider_id   = p.provider_id
LEFT JOIN {{ ref('dim_policy') }}   pol ON fc.policy_number = pol.policy_number
