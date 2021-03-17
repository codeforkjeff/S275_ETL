
{# Macros that translate from SQL Server to SQLite dialect #}

{% macro substring_fname() %}
	{%- if adapter.config.credentials.type == 'sqlite' -%}
	SUBSTR
	{%- else -%}
	SUBSTRING
	{%- endif -%}
{% endmacro %}

{% macro len_fname() %}
	{%- if adapter.config.credentials.type in ('sqlite', 'bigquery') -%}
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
	{%- if adapter.config.credentials.type in ('sqlite', 'snowflake', 'bigquery') -%}
		{{ caller()|replace('+','||') }}
	{%- else -%}
		{{ caller() }}
	{%- endif -%}
{% endmacro %}

{% macro getdate_fn() %}
	{%- if adapter.config.credentials.type == 'sqlite' -%}
		DATETIME('NOW')
	{%- elif adapter.config.credentials.type == 'bigquery' -%}
		CURRENT_DATETIME()
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
	{%- elif adapter.config.credentials.type == 'bigquery' -%}
		TO_HEX(MD5({{ caller() }}))
	{%- else -%}
		CONVERT(VARCHAR(30), HASHBYTES('MD5', {{ caller() }}), 2)
	{%- endif -%}
{% endmacro %}

{% macro except() %}
	EXCEPT
	{%- if adapter.config.credentials.type == 'bigquery' %} DISTINCT {% endif -%}
{% endmacro %}

{% macro t_varchar(size=None) %}
	{%- if adapter.config.credentials.type == 'bigquery' -%}
		STRING
	{%- else -%}
		VARCHAR{%- if size is not none -%}({{ size }}){%- endif -%}
	{%- endif -%}
{% endmacro %}

{% macro t_int() %}
	{%- if adapter.config.credentials.type == 'bigquery' -%}
		INT64
	{%- else -%}
		INT
	{%- endif -%}
{% endmacro %}

{% macro t_tinyint() %}
	{%- if adapter.config.credentials.type == 'bigquery' -%}
		INT64
	{%- else -%}
		TINYINT
	{%- endif -%}
{% endmacro %}

{% macro t_smallint() %}
	{%- if adapter.config.credentials.type == 'bigquery' -%}
		INT64
	{%- else -%}
		SMALLINT
	{%- endif -%}
{% endmacro %}

{% macro t_real() %}
	{%- if adapter.config.credentials.type == 'bigquery' -%}
		FLOAT64
	{%- else -%}
		REAL
	{%- endif -%}
{% endmacro %}

{% macro t_float() %}
	{%- if adapter.config.credentials.type == 'bigquery' -%}
		FLOAT64
	{%- else -%}
		FLOAT
	{%- endif -%}
{% endmacro %}

{% macro t_numeric(precision=None, scale=None) %}
	{%- if adapter.config.credentials.type == 'bigquery' -%}
		NUMERIC
	{%- else -%}
		NUMERIC{%- if precision is not none -%}({{ precision }} {%- if scale is not none %}, {{ scale }}{%- endif -%}){%- endif -%}
	{%- endif -%}
{% endmacro %}

