{{ config(
    materialized = 'incremental',
    schema = 'silver',
    unique_key = 'provider_id',
    incremental_strategy = 'merge'
) }}

WITH base AS (
    SELECT
        provider_id,
        provider_name,
        provider_type,
        specialty,
        address,
        city,
        state,
        zip_code,
        accreditation_score,
        fraud_risk_score,
        source_ingestion_ts,
        bronze_processed_at
    FROM {{ ref('staging_provider') }}

    {% if is_incremental() %}
      -- Only pull new or updated records
      WHERE source_ingestion_ts >
            (SELECT COALESCE(MAX(source_ingestion_ts), '1900-01-01')
             FROM {{ this }})
    {% endif %}
)

SELECT
    provider_id,
    provider_name,
    provider_type,
    specialty,
    address,
    city,
    state,
    zip_code,
    accreditation_score,
    fraud_risk_score,

    source_ingestion_ts,
    bronze_processed_at,
    CURRENT_TIMESTAMP() AS silver_processed_at

FROM base
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY provider_id
    ORDER BY source_ingestion_ts DESC
) = 1
