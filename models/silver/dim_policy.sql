{{ config(
    materialized = 'incremental',
    schema = 'silver',
    unique_key = 'policy_number',
    incremental_strategy = 'merge'
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

    {% if is_incremental() %}
      -- Only pull new or updated records
      WHERE source_ingestion_ts >
            (SELECT COALESCE(MAX(source_ingestion_ts), '1900-01-01')
             FROM {{ this }})
    {% endif %}
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
