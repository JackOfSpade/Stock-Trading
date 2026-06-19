{#
  Override dbt's default schema-naming so models land in BARE dataset names.

  dbt's built-in generate_schema_name PREFIXES the target/profile dataset onto any
  custom schema (e.g. a model with +schema: state would land in `state_state` or
  `<profile_dataset>_state`). For this project the dataset IS the canonical home of
  the live object (state.* / perf.* / analytics.* in bigquery/*.sql), so we want the
  custom schema used verbatim — no prefix.

  Behavior:
    - When a model sets +schema (custom_schema_name not none): use it AS-IS
      -> state / perf / analytics, matching the live datasets exactly.
    - Otherwise: fall back to the profile's `dataset` (target.schema).

  This is the documented BigQuery+dbt pattern: schema == dataset, bare names.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
