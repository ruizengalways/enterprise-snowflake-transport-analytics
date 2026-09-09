{{ config(materialized='view') }}

select
    vehicle_id,
    status,
    depot_id,
    route_id,
    source_updated_at,
    valid_from,
    valid_to,
    version_order
from {{ ref('vehicle_status_history') }}
where is_current = true
