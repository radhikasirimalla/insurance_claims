{{ config(materialized='view', schema='bronze') }}

WITH src AS (
    SELECT
        DATA,
        INGEST_TS,
        FILE_NAME,
        FILE_ROW_NUMBER
    FROM {{ source('raw_insurance', 'policies_raw') }}
    WHERE DATA IS NOT NULL
),

normalized AS (

    /* ---------- CASE 1: DATA is ARRAY ---------- */
    SELECT
        f.value              AS policy,
        INGEST_TS,
        FILE_NAME,
        FILE_ROW_NUMBER
    FROM src,
         LATERAL FLATTEN(input => DATA) f
    WHERE TYPEOF(DATA) = 'ARRAY'

    UNION ALL

    /* ---------- CASE 2: DATA is OBJECT ---------- */
    SELECT
        DATA                 AS policy,
        INGEST_TS,
        FILE_NAME,
        FILE_ROW_NUMBER
    FROM src
    WHERE TYPEOF(DATA) = 'OBJECT'
)

SELECT
    policy:policy_number::STRING        AS policy_number,
    policy:member_id::STRING            AS member_id,
    policy:policy_type::STRING          AS policy_type,
    policy:product_code::STRING         AS product_code,
    policy:effective_date::DATE         AS effective_date,
    policy:expiration_date::DATE        AS expiration_date,
    policy:premium_amount::NUMBER(12,2) AS premium_amount,
    policy:deductible::NUMBER(12,2)     AS deductible,
    policy:coverage_limits::NUMBER(12,2) AS coverage_limits,
    policy:agent_id::STRING             AS agent_id,
    policy:region::STRING               AS region,

    /* JSON metadata */
    policy:ingestion_timestamp::TIMESTAMP AS source_ingestion_ts,
    policy:source_file::STRING             AS source_file_from_json,

    /* Snowpipe metadata */
    INGEST_TS        AS snowpipe_ingest_ts,
    FILE_NAME        AS snowpipe_file_name,
    FILE_ROW_NUMBER AS snowpipe_row_number,

    CURRENT_TIMESTAMP() AS bronze_processed_at

FROM normalized
