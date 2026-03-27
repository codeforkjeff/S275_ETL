-- This macro is necessary for resolving the case sensitivity issue between sqlite and dbt

{% macro generate_alias_name(custom_alias_name=none, node=none) -%}
    {%- if custom_alias_name is not none -%}
        {{ custom_alias_name | lower | trim }}
    {%- elif node is not none -%}
        {{ node.name | lower | trim }}
    {%- else -%}
        {{ return(none) }}
    {%- endif -%}
{%- endmacro %}