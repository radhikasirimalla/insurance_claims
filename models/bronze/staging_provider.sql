{{ config(materialized='view', schema='bronze') }}

SELECT
    DATA:provider_id::string       AS provider_id,
    DATA:provider_name::string     AS provider_name,
    DATA:provider_type::string     AS provider_type,
    DATA:specialty::string         AS specialty,
    DATA:address::string           AS address,
    DATA:city::string              AS city,
    DATA:state::string             AS state,
    DATA:zip_code::string          AS zip_code,
    DATA:accreditation_score::number(5,2) AS accreditation_score,
    DATA:fraud_risk_score::number(5,2)    AS fraud_risk_score,

    -- ingestion metadata
    DATA:ingestion_timestamp::timestamp AS source_ingestion_ts,
    DATA:source_file::string            AS source_file_from_json,

    -- snowpipe metadata
    INGEST_TS,
    FILE_NAME,
    FILE_ROW_NUMBER,

    CURRENT_TIMESTAMP() AS bronze_processed_at

FROM {{ source('raw_insurance', 'providers_raw') }}
WHERE DATA IS NOT NULL
