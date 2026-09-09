{{ enterprise_snowflake_framework.esf_apply_dataset_config('vehicle_position') }}

select
    vehicle_id,
    event_timestamp,
    latitude,
    longitude,
    route_id,
    ingested_at
from {{ ref('stg_vehicle_position') }}
{% if is_incremental() %}
where event_timestamp > (
    select coalesce(max(event_timestamp), '1900-01-01'::timestamp_ntz)
    from {{ this }}
)
{% endif %}
