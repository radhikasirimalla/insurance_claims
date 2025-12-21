{{ config(materialized='view', schema='bronze') }}

SELECT
    DATA:policy_number::string     AS policy_number,
    DATA:member_id::string         AS member_id,
    DATA:policy_type::string       AS policy_type,
    DATA:product_code::string      AS product_code,
    DATA:effective_date::date      AS effective_date,
    DATA:expiration_date::date     AS expiration_date,
    DATA:premium_amount::number(12,2) AS premium_amount,
    DATA:deductible::number(12,2)      AS deductible,
    DATA:coverage_limits::number(12,2) AS coverage_limits,
    DATA:agent_id::string          AS agent_id,
    DATA:region::string            AS region,

    -- ingestion metadata
    DATA:ingestion_timestamp::timestamp AS source_ingestion_ts,
    DATA:source_file::string            AS source_file_from_json,

    -- snowpipe metadata
    INGEST_TS,
    FILE_NAME,
    FILE_ROW_NUMBER,

    CURRENT_TIMESTAMP() AS bronze_processed_at

FROM {{ source('raw_insurance', 'policies_raw') }}
WHERE DATA IS NOT NULL
