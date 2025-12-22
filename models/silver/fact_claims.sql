{{ config(
    materialized = 'table',
    schema = 'silver'
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

    -- KEEP ARRAYS AS-IS
    diagnosis_codes,
    procedure_codes,

    source_ingestion_ts,
    bronze_processed_at,
    CURRENT_TIMESTAMP() AS silver_processed_at

FROM {{ ref('staging_claim') }}
