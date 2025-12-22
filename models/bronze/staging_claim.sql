{{ config(materialized='view', schema='bronze') }}

WITH src AS (
    SELECT
        DATA,
        INGEST_TS,
        FILE_NAME,
        FILE_ROW_NUMBER
    FROM {{ source('raw_insurance', 'claims_raw') }}
    WHERE DATA IS NOT NULL
),

normalized AS (

    /* ---------- CASE 1: DATA is ARRAY ---------- */
    SELECT
        f.value              AS claim,
        INGEST_TS,
        FILE_NAME,
        FILE_ROW_NUMBER
    FROM src,
         LATERAL FLATTEN(input => DATA) f
    WHERE TYPEOF(DATA) = 'ARRAY'

    UNION ALL

    /* ---------- CASE 2: DATA is OBJECT ---------- */
    SELECT
        DATA                 AS claim,
        INGEST_TS,
        FILE_NAME,
        FILE_ROW_NUMBER
    FROM src
    WHERE TYPEOF(DATA) = 'OBJECT'
)

SELECT
    claim:claim_id::STRING             AS claim_id,
    claim:policy_number::STRING        AS policy_number,
    claim:member_id::STRING            AS member_id,
    claim:provider_id::STRING          AS provider_id,
    claim:claim_type::STRING           AS claim_type,
    claim:status::STRING               AS status,
    claim:claim_date::TIMESTAMP        AS claim_date,
    claim:received_date::TIMESTAMP     AS received_date,
    claim:total_charges::NUMBER(12,2)  AS total_charges,

    /* Arrays preserved */
    claim:diagnosis_codes              AS diagnosis_codes,
    claim:procedure_codes              AS procedure_codes,

    /* Metadata from JSON */
    claim:ingestion_timestamp::TIMESTAMP AS source_ingestion_ts,
    claim:source_file::STRING             AS source_file_from_json,
    claim:batch_id::STRING                AS batch_id,

    /* Snowpipe metadata */
    INGEST_TS        AS snowpipe_ingest_ts,
    FILE_NAME        AS snowpipe_file_name,
    FILE_ROW_NUMBER AS snowpipe_row_number,

    CURRENT_TIMESTAMP() AS bronze_processed_at

FROM normalized
