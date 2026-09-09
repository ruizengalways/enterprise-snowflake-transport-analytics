{{ config(materialized='view') }}

select
    vehicle_id,
    event_timestamp,
    latitude,
    longitude,
    route_id,
    ingested_at
from {{ source('silver_transport', 'vehicle_position') }}
