
{% macro create_index(prefix, columns, unique=False) %}

	{%- if adapter.config.credentials.type == 'sqlite' -%}
		CREATE {% if unique %}UNIQUE {% endif %} INDEX {{ this.schema }}.idx_{{ prefix|string }}_{{ this.table }} ON {{ this.table }}
		({{ '"' + columns|join('", "') + '"' }})
	{% elif adapter.config.credentials.type == 'sqlserver' %}
		{#
		dbt-sqlserver auto-creates column store indexes, so make all create_index() calls no-ops.

		--CREATE {% if unique %}UNIQUE {% endif %} INDEX idx_{{ prefix|string }}_{{ this.table }} ON {{ this }}
		--({{ '"' + columns|join('", "') + '"' }})
		#}

		SELECT 1
	{% elif adapter.config.credentials.type == 'snowflake' %}
		SELECT 1
	{% else %}
		{{ exceptions.raise_not_implemented("create_index not implemented for this database type") }}
	{% endif %}

{% endmacro %}

{% macro drop_index(prefix) %}

	{%- if adapter.config.credentials.type == 'sqlite' -%}
		DROP INDEX IF EXISTS {{ this.schema }}.idx_{{ prefix|string }}_{{ this.table }}
	{% elif adapter.config.credentials.type == 'sqlserver' %}
		DROP INDEX IF EXISTS idx_{{ prefix|string }}_{{ this.table }} ON {{this}}
	{% elif adapter.config.credentials.type == 'snowflake' %}
		SELECT 1
	{% else %}
		{{ exceptions.raise_not_implemented("drop_index not implemented for this database type") }}
	{% endif %}

{% endmacro %}
