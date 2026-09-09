{{ config(materialized='view') }}

select
    vehicle_id,
    status,
    depot_id,
    route_id,
    source_updated_at,
    source_sequence,
    source_operation,
    ingested_at
from {{ source('bronze_transport', 'vehicle_status') }}
