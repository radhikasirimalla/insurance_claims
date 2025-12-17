{% macro flatten_json_array(source_table, column_name='DATA') %}

-- Macro to flatten top-level JSON arrays (or handle single objects)
-- source_table : the raw source table (e.g., raw_insurance.claims_raw)
-- column_name  : name of the JSON column (default 'DATA')

SELECT
    VALUE AS flattened_record,
    INGEST_TS,
    FILE_NAME,
    FILE_ROW_NUMBER
FROM {{ source_table }},
LATERAL FLATTEN(input => {{ column_name }})

{% endmacro %}

