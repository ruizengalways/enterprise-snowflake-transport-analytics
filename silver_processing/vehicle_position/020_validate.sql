-- Every query should return zero rows.

select vehicle_id, event_timestamp, count(*) as silver_rows
from SILVER_CANONICAL.VEHICLE_POSITION
group by vehicle_id, event_timestamp
having count(*) > 1;

select
    vehicle_id,
    event_timestamp,
    count(distinct hash(latitude, longitude, route_id)) as distinct_payloads
from BRONZE.VEHICLE_POSITION
group by vehicle_id, event_timestamp
having count(distinct hash(latitude, longitude, route_id)) > 1;
