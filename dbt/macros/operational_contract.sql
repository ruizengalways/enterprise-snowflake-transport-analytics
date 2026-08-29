{% macro transport_operational_contract_sql() -%}
    {%- set checkpoint_read_sql -%}
{{ enterprise_snowflake_framework.esf_domain_checkpoint_read_sql(
    'TRANSPORT',
    'vehicle_position',
    'source_position'
) }}
    {%- endset -%}

    {%- set checkpoint_advance_sql -%}
{{ enterprise_snowflake_framework.esf_domain_checkpoint_advance_call_sql(
    'TRANSPORT',
    'vehicle_position',
    'source_position',
    "object_construct('source_position', 'smoke-123')",
    'batch-smoke-123',
    '0000000000000000000000000000000000000000'
) }}
    {%- endset -%}

    {%- set run_start_sql -%}
{{ enterprise_snowflake_framework.esf_domain_pipeline_run_start_call_sql(
    'TRANSPORT',
    'run-smoke-123',
    1,
    'vehicle_position_capture',
    'vehicle_position',
    '0000000000000000000000000000000000000000',
    "object_construct('project', 'transport', 'workload', 'static_ci')",
    "object_construct('source_position', 'smoke-122')"
) }}
    {%- endset -%}

    {%- set run_finish_sql -%}
{{ enterprise_snowflake_framework.esf_domain_pipeline_run_finish_call_sql(
    'TRANSPORT',
    'run-smoke-123',
    1,
    'SUCCEEDED',
    "object_construct('source_position', 'smoke-123')",
    '100',
    '100',
    '100',
    '0',
    '0',
    none,
    none,
    "object_construct('mode', 'static_ci')"
) }}
    {%- endset -%}

    {%- set check_query -%}
select
    'freshness' as check_type,
    'vehicle_position_freshness' as check_name,
    'PASS' as status,
    'age_minutes' as measure_name,
    to_variant(1) as observed_value,
    object_construct('warn_after_minutes', 5, 'error_after_minutes', 15) as expected_value,
    object_construct('mode', 'static_ci') as details
    {%- endset -%}

    {%- set check_record_sql -%}
{{ enterprise_snowflake_framework.esf_domain_record_check_result_sql(
    'TRANSPORT',
    check_query,
    'run-smoke-123',
    1,
    'vehicle_position'
) }}
    {%- endset -%}

    {{ log(
        '---TRANSPORT_CHECKPOINT_READ---\n' ~ checkpoint_read_sql
        ~ '\n---TRANSPORT_CHECKPOINT_ADVANCE---\n' ~ checkpoint_advance_sql
        ~ '\n---TRANSPORT_RUN_START---\n' ~ run_start_sql
        ~ '\n---TRANSPORT_RUN_FINISH---\n' ~ run_finish_sql
        ~ '\n---TRANSPORT_CHECK_RESULT---\n' ~ check_record_sql,
        info=true
    ) }}
    {{ return('transport operational contract SQL rendered') }}
{%- endmacro %}
