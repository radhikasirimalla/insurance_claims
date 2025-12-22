{{ config(
    materialized = 'incremental',
    schema = 'silver',
    unique_key = 'claim_id'
) }}

SELECT
    claim_id,
    policy_number,
    member_id,
    provider_id,
    claim_type,
    status,
    claim_date,
    received_date,
    total_charges,

    -- Keep arrays as-is
    diagnosis_codes,
    procedure_codes,

    source_ingestion_ts,
    bronze_processed_at,
    CURRENT_TIMESTAMP() AS silver_processed_at

FROM {{ ref('staging_claim') }}

{% if is_incremental() %}
WHERE source_ingestion_ts >
      (SELECT COALESCE(MAX(source_ingestion_ts), '1900-01-01') FROM {{ this }})
{% endif %}
