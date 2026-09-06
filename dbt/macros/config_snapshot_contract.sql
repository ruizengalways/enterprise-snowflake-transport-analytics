{% macro transport_vehicle_status_config_snapshot_contract_sql() -%}
    {%- set read_sql -%}
{{ enterprise_snowflake_framework.esf_domain_dataset_config_read_sql(
    'TRANSPORT',
    'vehicle_status'
) }}
    {%- endset -%}

    {%- set register_sql -%}
{{ enterprise_snowflake_framework.esf_domain_register_dataset_config_call_sql(
    'TRANSPORT',
    'vehicle_status',
    '1111111111111111111111111111111111111111'
) }}
    {%- endset -%}

    {{ log(
        '---CONFIG_SNAPSHOT_READ---\n' ~ read_sql
        ~ '\n---CONFIG_SNAPSHOT_REGISTER---\n' ~ register_sql,
        info=true
    ) }}
    {{ return('Transport dataset config snapshot contract rendered') }}
{%- endmacro %}
