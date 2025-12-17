{{ config(
    materialized='view',
    schema='bronze'
) }}

WITH flattened_member AS (
    {{ flatten_json_array(source('raw_insurance', 'members_raw')) }}
)

SELECT
    member_record:member_id::string        AS member_id,
    member_record:first_name::string       AS first_name,
    member_record:last_name::string        AS last_name,
    member_record:date_of_birth::date      AS date_of_birth,
    member_record:gender::string           AS gender,
    member_record:address_line1::string    AS address_line1,
    member_record:city::string             AS city,
    member_record:state::string            AS state,
    member_record:zip_code::string         AS zip_code,
    member_record:email::string            AS email,
    member_record:phone::string            AS phone,
    member_record:membership_start_date::date AS membership_start_date,
    member_record:risk_score::number(5,2) AS risk_score,

    -- Ingestion metadata
    member_record:ingestion_timestamp::timestamp AS source_ingestion_ts,
    member_record:source_file::string            AS source_file_from_json,

    -- Snowpipe metadata
    INGEST_TS        AS snowpipe_ingest_ts,
    FILE_NAME        AS snowpipe_file_name,
    FILE_ROW_NUMBER  AS snowpipe_row_number,

    CURRENT_TIMESTAMP() AS bronze_processed_at

FROM flattened_member
WHERE member_record IS NOT NULL;
