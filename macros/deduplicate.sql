{% macro deduplicate_by_key(model_name, unique_key, order_by='ingestion_timestamp DESC') %}
    WITH ranked AS (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY {{ unique_key }}
                ORDER BY {{ order_by }}
            ) AS rn
        FROM {{ model_name }}
    )
    SELECT *
    FROM ranked
    WHERE rn = 1
{% endmacro %}