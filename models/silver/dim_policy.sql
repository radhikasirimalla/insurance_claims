{{ config(
    materialized = 'table',
    schema = 'silver'
) }}

WITH base AS (
    SELECT
        policy_number,
        member_id,
        policy_type,
        product_code,
        effective_date,
        expiration_date,
        premium_amount,
        deductible,
        coverage_limits,
        agent_id,
        region,
        source_ingestion_ts,
        bronze_processed_at
    FROM {{ ref('staging_policy') }}
)

SELECT
    policy_number,
    member_id,
    policy_type,
    product_code,
    effective_date,
    expiration_date,
    premium_amount,
    deductible,
    coverage_limits,
    agent_id,
    region,

    source_ingestion_ts,
    bronze_processed_at,
    CURRENT_TIMESTAMP() AS silver_processed_at

FROM base
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY policy_number
    ORDER BY source_ingestion_ts DESC
) = 1
