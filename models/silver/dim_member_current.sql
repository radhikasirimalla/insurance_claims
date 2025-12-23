{{ config(
    materialized = 'table',
    schema = 'silver'
) }}

SELECT
    member_id,
    first_name,
    last_name,
    full_name,
    date_of_birth,
    gender,
    address_line1,
    city,
    state,
    zip_code,
    email,
    phone,
    membership_start_date,
    risk_score
FROM {{ ref('dim_member') }}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY member_id
    ORDER BY source_ingestion_ts DESC
) = 1
