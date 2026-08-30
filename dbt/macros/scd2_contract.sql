{% macro transport_vehicle_status_scd2_contract_sql() -%}
    {%- set history_sql = enterprise_snowflake_framework.esf_scd2_history_select_for_dataset(
        'TRANSPORT_EVENT_RELATION',
        'vehicle_status'
    ) -%}
    {%- set rebuild_sql = enterprise_snowflake_framework.esf_scd2_rebuild_affected_keys_for_dataset_sql(
        'TRANSPORT_HISTORY_RELATION',
        'TRANSPORT_EVENT_RELATION',
        'TRANSPORT_AFFECTED_KEYS_RELATION',
        'vehicle_status'
    ) -%}

    {%- set rendered = history_sql ~ '\n\n-- affected-key rebuild contract\n' ~ rebuild_sql -%}
    {%- do log(rendered, info=true) -%}
    {{ return(rendered) }}
{%- endmacro %}
