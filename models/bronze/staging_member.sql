{{ config(materialized='view', schema='bronze') }}

WITH src AS (
    SELECT
        DATA,
        INGEST_TS,
        FILE_NAME,
        FILE_ROW_NUMBER
    FROM {{ source('raw_insurance', 'members_raw') }}
    WHERE DATA IS NOT NULL
),

normalized AS (

    /* ---------- CASE 1: DATA is ARRAY ---------- */
    SELECT
        f.value              AS member,
        INGEST_TS,
        FILE_NAME,
        FILE_ROW_NUMBER
    FROM src,
         LATERAL FLATTEN(input => DATA) f
    WHERE TYPEOF(DATA) = 'ARRAY'

    UNION ALL

    /* ---------- CASE 2: DATA is OBJECT ---------- */
    SELECT
        DATA                 AS member,
        INGEST_TS,
        FILE_NAME,
        FILE_ROW_NUMBER
    FROM src
    WHERE TYPEOF(DATA) = 'OBJECT'
)

SELECT
    member:member_id::STRING          AS member_id,
    member:first_name::STRING         AS first_name,
    member:last_name::STRING          AS last_name,
    member:date_of_birth::DATE        AS date_of_birth,
    member:gender::STRING             AS gender,
    member:address_line1::STRING      AS address_line1,
    member:city::STRING               AS city,
    member:state::STRING              AS state,
    member:zip_code::STRING           AS zip_code,
    member:email::STRING              AS email,
    member:phone::STRING              AS phone,
    member:membership_start_date::DATE AS membership_start_date,
    member:risk_score::NUMBER(5,2)    AS risk_score,

    /* JSON metadata */
    member:ingestion_timestamp::TIMESTAMP AS source_ingestion_ts,
    member:source_file::STRING             AS source_file_from_json,

    /* Snowpipe metadata */
    INGEST_TS        AS snowpipe_ingest_ts,
    FILE_NAME        AS snowpipe_file_name,
    FILE_ROW_NUMBER AS snowpipe_row_number,

    CURRENT_TIMESTAMP() AS bronze_processed_at

FROM normalized
