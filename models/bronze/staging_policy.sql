{{ config(
    materialized='view',
    schema='bronze'
) }}

WITH flattened_policy AS (
    {{ flatten_json_array(source('raw_insurance', 'policies_raw')) }}
)

SELECT
    policy_record:policy_number::string   AS policy_number,
    policy_record:member_id::string       AS member_id,
    policy_record:policy_type::string     AS policy_type,
    policy_record:product_code::string    AS product_code,
    policy_record:effective_date::date    AS effective_date,
    policy_record:expiration_date::date   AS expiration_date,
    policy_record:premium_amount::number(12,2) AS premium_amount,
    policy_record:deductible::number(12,2)    AS deductible,
    policy_record:coverage_limits::number(12,2) AS coverage_limits,
    policy_record:agent_id::string         AS agent_id,
    policy_record:region::string           AS region,

    -- Ingestion metadata
    policy_record:ingestion_timestamp::timestamp AS source_ingestion_ts,
    policy_record:source_file::string            AS source_file_from_json,

    -- Snowpipe metadata
    INGEST_TS        AS snowpipe_ingest_ts,
    FILE_NAME        AS snowpipe_file_name,
    FILE_ROW_NUMBER  AS snowpipe_row_number,

    CURRENT_TIMESTAMP() AS bronze_processed_at

FROM flattened_policy
WHERE policy_record IS NOT NULL;
