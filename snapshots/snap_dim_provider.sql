{% snapshot snap_dim_provider %}

{{ config(
    target_schema='snapshots',
    unique_key='provider_id',
    strategy='timestamp',
    updated_at='source_ingestion_ts'
) }}

SELECT
    provider_id,
    provider_name,
    provider_type,
    specialty,
    address,
    city,
    state,
    zip_code,
    accreditation_score,
    fraud_risk_score,
    source_ingestion_ts
FROM {{ ref('dim_provider') }}

{% endsnapshot %}
