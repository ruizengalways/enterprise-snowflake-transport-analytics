{#
  Explicit Transport full-reset plan.

  Repair/replay does not use this macro. Full reset abandons the current
  generation and clears reconstructable vehicle_status data before the main
  pipeline is run again.
#}

{% macro transport_vehicle_status_reset_relations() -%}
    {%- set database = target.database | upper -%}
    {{ return([
        database ~ '.BRONZE.VEHICLE_STATUS',
        database ~ '.SILVER_STAGING.VEHICLE_STATUS',
        database ~ '.SILVER_INTERMEDIATE.VEHICLE_STATUS',
        database ~ '.SILVER_CANONICAL.VEHICLE_STATUS',
        database ~ '.GOLD_MARTS.VEHICLE_STATUS'
    ]) }}
{%- endmacro %}

{% macro transport_vehicle_status_full_reset_contract_sql(
    reset_id='static-reset-contract',
    reason='static reset contract',
    git_sha=none
) -%}
    {%- set sql = enterprise_snowflake_framework.esf_dataset_full_reset_sql(
        'TRANSPORT',
        reset_id,
        'vehicle_status',
        reason,
        transport_vehicle_status_reset_relations(),
        git_sha,
        "OBJECT_CONSTRUCT('reset_type', 'FULL_RESET', 'dataset', 'vehicle_status')"
    ) -%}
    {%- do log(sql, info=true) -%}
    {{ return(sql) }}
{%- endmacro %}

{% macro transport_vehicle_status_full_reset(reset_id, reason, git_sha=none) -%}
    {{ return(enterprise_snowflake_framework.esf_execute_dataset_full_reset(
        'TRANSPORT',
        reset_id,
        'vehicle_status',
        reason,
        transport_vehicle_status_reset_relations(),
        git_sha,
        "OBJECT_CONSTRUCT('reset_type', 'FULL_RESET', 'dataset', 'vehicle_status')"
    )) }}
{%- endmacro %}
