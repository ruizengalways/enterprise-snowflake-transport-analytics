{{ enterprise_snowflake_framework.esf_apply_dataset_config('depot_fleet_status') }}

select
    depot_id,
    status,
    count(*) as vehicle_count
from {{ ref('vehicle_status_current') }}
group by
    depot_id,
    status
