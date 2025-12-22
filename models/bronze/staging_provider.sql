{{ config(materialized='view', schema='bronze') }}

WITH src AS (
    SELECT
        DATA,
        INGEST_TS,
        FILE_NAME,
        FILE_ROW_NUMBER
    FROM {{ source('raw_insurance', 'providers_raw') }}
    WHERE DATA IS NOT NULL
),

normalized AS (

    /* ---------- CASE 1: DATA is ARRAY ---------- */
    SELECT
        f.value              AS provider,
        INGEST_TS,
        FILE_NAME,
        FILE_ROW_NUMBER
    FROM src,
         LATERAL FLATTEN(input => DATA) f
    WHERE TYPEOF(DATA) = 'ARRAY'

    UNION ALL

    /* ---------- CASE 2: DATA is OBJECT ---------- */
    SELECT
        DATA                 AS provider,
        INGEST_TS,
        FILE_NAME,
        FILE_ROW_NUMBER
    FROM src
    WHERE TYPEOF(DATA) = 'OBJECT'
)

SELECT
    provider:provider_id::STRING           AS provider_id,
    provider:provider_name::STRING         AS provider_name,
    provider:provider_type::STRING         AS provider_type,
    provider:specialty::STRING             AS specialty,
    provider:address::STRING               AS address,
    provider:city::STRING                  AS city,
    provider:state::STRING                 AS state,
    provider:zip_code::STRING              AS zip_code,
    provider:accreditation_score::NUMBER(5,2) AS accreditation_score,
    provider:fraud_risk_score::NUMBER(5,2)    AS fraud_risk_score,

    /* JSON metadata */
    provider:ingestion_timestamp::TIMESTAMP AS source_ingestion_ts,
    provider:source_file::STRING             AS source_file_from_json,

    /* Snowpipe metadata */
    INGEST_TS        AS snowpipe_ingest_ts,
    FILE_NAME        AS snowpipe_file_name,
    FILE_ROW_NUMBER AS snowpipe_row_number,

    CURRENT_TIMESTAMP() AS bronze_processed_at

FROM normalized
