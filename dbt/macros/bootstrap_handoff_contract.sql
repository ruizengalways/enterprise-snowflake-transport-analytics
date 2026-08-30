{% macro transport_vehicle_status_bootstrap_contract_sql() -%}
    {%- set read_sql = enterprise_snowflake_framework.esf_domain_bootstrap_read_sql(
        'TRANSPORT',
        'vehicle_status',
        'bootstrap-reference'
    ) -%}
    {%- set start_sql = enterprise_snowflake_framework.esf_domain_bootstrap_start_call_sql(
        'TRANSPORT',
        'vehicle_status',
        'bootstrap-reference',
        "parse_json('{\"source_position\":100}')",
        'reference-git-sha'
    ) -%}
    {%- set landed_sql = enterprise_snowflake_framework.esf_domain_bootstrap_snapshot_landed_call_sql(
        'TRANSPORT',
        'vehicle_status',
        'bootstrap-reference',
        'snapshot-reference',
        'snapshot-batch-reference'
    ) -%}
    {%- set validated_sql = enterprise_snowflake_framework.esf_domain_bootstrap_validated_call_sql(
        'TRANSPORT',
        'vehicle_status',
        'bootstrap-reference',
        "parse_json('{\"status\":\"PASS\"}')"
    ) -%}
    {%- set commit_sql = enterprise_snowflake_framework.esf_domain_bootstrap_commit_handoff_call_sql(
        'TRANSPORT',
        'vehicle_status',
        'bootstrap-reference',
        'snapshot-batch-reference',
        'reference-git-sha'
    ) -%}
    {%- set rendered =
        '---BOOTSTRAP_READ---\n' ~ read_sql ~
        '\n---BOOTSTRAP_START---\n' ~ start_sql ~
        '\n---BOOTSTRAP_LANDED---\n' ~ landed_sql ~
        '\n---BOOTSTRAP_VALIDATED---\n' ~ validated_sql ~
        '\n---BOOTSTRAP_COMMIT---\n' ~ commit_sql
    -%}
    {%- do log(rendered, info=true) -%}
    {{ return(rendered) }}
{%- endmacro %}
