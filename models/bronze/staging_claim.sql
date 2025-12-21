{{ config(materialized='view', schema='bronze') }}

SELECT
    DATA:claim_id::string        AS claim_id,
    DATA:policy_number::string   AS policy_number,
    DATA:member_id::string       AS member_id,
    DATA:provider_id::string     AS provider_id,
    DATA:claim_type::string      AS claim_type,
    DATA:status::string          AS status,
    DATA:claim_date::timestamp   AS claim_date,
    DATA:received_date::timestamp AS received_date,
    DATA:total_charges::number(12,2) AS total_charges,

    -- arrays stay as VARIANT in Bronze
    DATA:diagnosis_codes         AS diagnosis_codes,
    DATA:procedure_codes         AS procedure_codes,

    DATA:ingestion_timestamp::timestamp AS source_ingestion_ts,
    DATA:source_file::string            AS source_file_from_json,
    DATA:batch_id::string               AS batch_id,

    INGEST_TS        AS snowpipe_ingest_ts,
    FILE_NAME        AS snowpipe_file_name,
    FILE_ROW_NUMBER  AS snowpipe_row_number,

    CURRENT_TIMESTAMP() AS bronze_processed_at

FROM {{ source('raw_insurance', 'claims_raw') }}
WHERE DATA IS NOT NULL
