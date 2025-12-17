{{ config(materialized='view', schema='bronze') }}

WITH flattened_claims AS (
    {{ flatten_json_array(source('raw_insurance', 'claims_raw')) }}
)

SELECT
    flattened_record:claim_id::string        AS claim_id,
    flattened_record:policy_number::string   AS policy_number,
    flattened_record:member_id::string       AS member_id,
    flattened_record:provider_id::string     AS provider_id,
    flattened_record:claim_type::string      AS claim_type,
    flattened_record:status::string          AS status,
    flattened_record:claim_date::timestamp   AS claim_date,
    flattened_record:received_date::timestamp AS received_date,
    flattened_record:total_charges::number(12,2) AS total_charges,
    flattened_record:diagnosis_codes           AS diagnosis_codes,
    flattened_record:procedure_codes           AS procedure_codes,
    flattened_record:ingestion_timestamp::timestamp AS source_ingestion_ts,
    flattened_record:source_file::string            AS source_file_from_json,
    flattened_record:batch_id::string               AS batch_id,
    INGEST_TS        AS snowpipe_ingest_ts,
    FILE_NAME        AS snowpipe_file_name,
    FILE_ROW_NUMBER  AS snowpipe_row_number,
    CURRENT_TIMESTAMP() AS bronze_processed_at

FROM flattened_claims
WHERE flattened_record IS NOT NULL;
