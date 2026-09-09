{{ enterprise_snowflake_framework.esf_apply_dataset_config('vehicle_status') }}

select
    vehicle_id,
    status,
    depot_id,
    route_id,
    source_updated_at,
    source_sequence,
    source_operation
from {{ ref('stg_vehicle_status') }}
