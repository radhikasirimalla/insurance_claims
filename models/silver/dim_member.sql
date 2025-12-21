{{ config(
    materialized = 'table',
    schema = 'silver'
) }}

WITH base AS (
    SELECT
        member_id,
        first_name,
        last_name,
        date_of_birth,
        gender,
        address_line1,
        city,
        state,
        zip_code,
        email,
        phone,
        membership_start_date,
        risk_score,
        source_ingestion_ts,
        bronze_processed_at
    FROM {{ ref('staging_member') }}
)

SELECT
    member_id,
    first_name,
    last_name,
    CONCAT(first_name, ' ', last_name) AS full_name,
    date_of_birth,
    gender,
    address_line1,
    city,
    state,
    zip_code,
    email,
    phone,
    membership_start_date,
    risk_score,

    source_ingestion_ts,
    bronze_processed_at,
    CURRENT_TIMESTAMP() AS silver_processed_at

FROM base
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY member_id
    ORDER BY source_ingestion_ts DESC
) = 1
