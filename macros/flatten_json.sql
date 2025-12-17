{% macro flatten_json_array(column_name) %}
    JSON_EXTRACT_ARRAY({{ column_name }}) AS {{ column_name }}_array
{% endmacro %}

{% macro extract_json_field(column_name, field_name, default_value='') %}
    JSON_EXTRACT_SCALAR({{ column_name }}, '$.{{ field_name }}') AS {{ field_name }}
{% endmacro %}