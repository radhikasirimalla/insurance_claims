{{ config(
    materialized = 'table',
    schema = 'silver'
) }}

WITH base_claim AS (
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
        diagnosis_codes,
        procedure_codes,
        source_ingestion_ts,
        bronze_processed_at
    FROM {{ ref('staging_claim') }}
),

-- Flatten diagnosis codes
diagnosis_flatten AS (
    SELECT
        bc.*,
        diag.value::string AS diagnosis_code
    FROM base_claim bc,
         LATERAL FLATTEN(input => bc.diagnosis_codes) diag
),

-- Flatten procedure codes
procedure_flatten AS (
    SELECT
        df.*,
        proc.value::string AS procedure_code
    FROM diagnosis_flatten df,
         LATERAL FLATTEN(input => df.procedure_codes) proc
)

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

    diagnosis_code,
    procedure_code,

    source_ingestion_ts,
    bronze_processed_at,
    CURRENT_TIMESTAMP() AS silver_processed_at

FROM procedure_flatten
