
{# Macros that translate from SQL Server to SQLite dialect #}

{% macro substring_fname() %}
	{%- if adapter.config.credentials.type == 'sqlite' -%}
	SUBSTR
	{%- else -%}
	SUBSTRING
	{%- endif -%}
{% endmacro %}

{% macro len_fname() %}
	{%- if adapter.config.credentials.type == 'sqlite' -%}
	LENGTH
	{%- else -%}
	LEN
	{%- endif -%}
{% endmacro %}

{% macro concat_fname() %}
	{%- if adapter.config.credentials.type == 'sqlite' -%}
	LENGTH
	{%- else -%}
	LEN
	{%- endif -%}
{% endmacro %}

{# this one does string replacment on caller 'body' #}
{% macro concat() %}
	{%- if adapter.config.credentials.type in ('sqlite', 'snowflake') -%}
		{{ caller()|replace('+','||') }}
	{%- else -%}
		{{ caller() }}
	{%- endif -%}
{% endmacro %}

{% macro getdate_fn() %}
	{%- if adapter.config.credentials.type == 'sqlite' -%}
		DATETIME('NOW')
	{%- else -%}
		GETDATE()
	{%- endif -%}
{% endmacro %}

{% macro hash() %}
	{%- if adapter.config.credentials.type == 'sqlite' -%}
		{# sqlite doesn't have any builtin hashing fns, so do nothing #}
		{{ caller() }}
	{%- elif adapter.config.credentials.type == 'snowflake' -%}
		MD5({{ caller() }})
	{%- else -%}
		CONVERT(VARCHAR(30), HASHBYTES('MD5', {{ caller() }}), 2)
	{%- endif -%}
{% endmacro %}
