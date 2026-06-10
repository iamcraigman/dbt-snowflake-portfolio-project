{% macro validate_email(column_name) %}
    case 
        when regexp_contains({{ column_name }}, r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$") then true
        else false
    end
{% endmacro %}