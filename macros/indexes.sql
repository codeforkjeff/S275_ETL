
{% macro create_index(prefix, columns, unique=False) %}

	{%- if adapter.config.credentials.type == 'sqlite' -%}
		CREATE {% if unique %}UNIQUE {% endif %} INDEX {{ this.schema }}.idx_{{ prefix|string }}_{{ this.table }} ON {{ this.table }}
		({{ '"' + columns|join('", "') + '"' }})
	{% else %}
		{{ exceptions.raise_not_implemented("create_index not implemented for this database type") }}
	{% endif %}

{% endmacro %}

{% macro drop_index(prefix) %}

	{%- if adapter.config.credentials.type == 'sqlite' -%}
		DROP INDEX IF EXISTS {{ this.schema }}.idx_{{ prefix|string }}_{{ this.table }}
	{% else %}
		{{ exceptions.raise_not_implemented("drop_index not implemented for this database type") }}
	{% endif %}

{% endmacro %}
