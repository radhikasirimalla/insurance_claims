{% snapshot snap_dim_policy %}

{{ config(
    target_schema='snapshots',
    unique_key='policy_number',
    strategy='timestamp',
    updated_at='source_ingestion_ts'
) }}

SELECT
    policy_number,
    member_id,
    policy_type,
    product_code,
    effective_date,
    expiration_date,
    premium_amount,
    deductible,
    coverage_limits,
    agent_id,
    region,
    source_ingestion_ts
FROM {{ ref('dim_policy') }}

{% endsnapshot %}
