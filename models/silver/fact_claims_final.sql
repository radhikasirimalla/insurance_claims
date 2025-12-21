{{ config(
    materialized = 'table',
    schema = 'silver'
) }}

WITH base_claim AS (
    SELECT *
    FROM {{ ref('fact_claims') }}
),

-- Join with Member dimension
member_enriched AS (
    SELECT
        bc.*,
        m.full_name AS member_name,
        m.gender AS member_gender,
        m.risk_score AS member_risk_score
    FROM base_claim bc
    LEFT JOIN {{ ref('dim_member') }} m
        ON bc.member_id = m.member_id
),

-- Join with Provider dimension
provider_enriched AS (
    SELECT
        me.*,
        p.provider_name,
        p.provider_type,
        p.fraud_risk_score
    FROM member_enriched me
    LEFT JOIN {{ ref('dim_provider') }} p
        ON me.provider_id = p.provider_id
),

-- Join with Policy dimension
policy_enriched AS (
    SELECT
        pe.*,
        pol.policy_type,
        pol.product_code
    FROM provider_enriched pe
    LEFT JOIN {{ ref('dim_policy') }} pol
        ON pe.policy_number = pol.policy_number
)

SELECT
    claim_id,
    policy_number,
    member_id,
    member_name,
    member_gender,
    member_risk_score,
    provider_id,
    provider_name,
    provider_type,
    fraud_risk_score,
    policy_type,
    product_code,
    claim_type,
    status,
    claim_date,
    received_date,
    total_charges,
    diagnosis_code,
    procedure_code,
    source_ingestion_ts,
    bronze_processed_at,
    silver_processed_at,
    CURRENT_TIMESTAMP() AS silver_final_processed_at

FROM policy_enriched
