{% snapshot snap_dim_member %}

{{ config(
    target_schema='snapshots',
    unique_key='member_id',
    strategy='check',
    check_cols=[
        'first_name',
        'last_name',
        'full_name',
        'date_of_birth',
        'gender',
        'address_line1',
        'city',
        'state',
        'zip_code',
        'email',
        'phone',
        'membership_start_date',
        'risk_score'
    ]
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
FROM {{ ref('dim_member_current') }}

{% endsnapshot %}
