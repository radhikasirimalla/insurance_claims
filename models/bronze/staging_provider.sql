{{ config(
    materialized='view',
    schema='bronze'
) }}

WITH flattened_provider AS (
    {{ flatten_json_array(source('raw_insurance', 'providers_raw')) }}
)

SELECT
    provider_record:provider_id::string     AS provider_id,
    provider_record:provider_name::string   AS provider_name,
    provider_record:provider_type::string   AS provider_type,
    provider_record:specialty::string       AS specialty,
    provider_record:address::string         AS address,
    provider_record:city::string            AS city,
    provider_record:state::string           AS state,
    provider_record:zip_code::string        AS zip_code,
    provider_record:accreditation_score::number(5,2) AS accreditation_score,
    provider_record:fraud_risk_score::number(5,2)   AS fraud_risk_score,

    -- Ingestion metadata
    provider_record:ingestion_timestamp::timestamp AS source_ingestion_ts,
    provider_record:source_file::string            AS source_file_from_json,

    -- Snowpipe metadata
    INGEST_TS        AS snowpipe_ingest_ts,
    FILE_NAME        AS snowpipe_file_name,
    FILE_ROW_NUMBER  AS snowpipe_row_number,

    CURRENT_TIMESTAMP() AS bronze_processed_at

FROM flattened_provider
WHERE provider_record IS NOT NULL;
