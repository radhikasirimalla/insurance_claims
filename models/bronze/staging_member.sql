{{ config(materialized='view', schema='bronze') }}

SELECT
    DATA:member_id::string        AS member_id,
    DATA:first_name::string       AS first_name,
    DATA:last_name::string        AS last_name,
    DATA:date_of_birth::date      AS date_of_birth,
    DATA:gender::string           AS gender,
    DATA:address_line1::string    AS address_line1,
    DATA:city::string             AS city,
    DATA:state::string            AS state,
    DATA:zip_code::string         AS zip_code,
    DATA:email::string            AS email,
    DATA:phone::string            AS phone,
    DATA:membership_start_date::date AS membership_start_date,
    DATA:risk_score::number(5,2)  AS risk_score,

    -- ingestion metadata
    DATA:ingestion_timestamp::timestamp AS source_ingestion_ts,
    DATA:source_file::string            AS source_file_from_json,

    -- snowpipe metadata
    INGEST_TS,
    FILE_NAME,
    FILE_ROW_NUMBER,

    CURRENT_TIMESTAMP() AS bronze_processed_at

FROM {{ source('raw_insurance', 'members_raw') }}
WHERE DATA IS NOT NULL
