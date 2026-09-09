{{ config(
    materialized='dynamic_table',
    target_lag='5 minutes',
    refresh_mode='ADAPTIVE',
    snowflake_warehouse=target.warehouse
) }}

select
    depot_id,
    status,
    count(*) as vehicle_count
from {{ source('silver_transport', 'vehicle_status_current') }}
group by
    depot_id,
    status
