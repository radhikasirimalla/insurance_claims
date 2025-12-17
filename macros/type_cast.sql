{% macro try_cast_date(column_name, default_value='1900-01-01') %}
    TRY_CAST({{ column_name }} AS DATE) 
    {% if default_value %}
        COALESCE(TRY_CAST({{ column_name }} AS DATE), DATE '{{ default_value }}')
    {% endif %}
{% endmacro %}

{% macro try_cast_float(column_name, default_value=0.0) %}
    COALESCE(TRY_CAST({{ column_name }} AS FLOAT), {{ default_value }})
{% endmacro %}

{% macro try_cast_int(column_name, default_value=0) %}
    COALESCE(TRY_CAST({{ column_name }} AS INTEGER), {{ default_value }})
{% endmacro %}