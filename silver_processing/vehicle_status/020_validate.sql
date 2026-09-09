-- vehicle_status: operator/CI invariants. Every query should return zero rows.

-- A source event identity must not describe two different events.
select
    vehicle_id,
    source_sequence,
    count(*) as rows_for_identity,
    count(distinct hash(status, depot_id, route_id, source_updated_at, source_operation)) as distinct_payloads
from BRONZE.VEHICLE_STATUS
group by vehicle_id, source_sequence
having count(distinct hash(status, depot_id, route_id, source_updated_at, source_operation)) > 1;

-- At most one current version per vehicle.
select vehicle_id, count(*) as current_rows
from SILVER_CANONICAL.VEHICLE_STATUS_HISTORY
where is_current
group by vehicle_id
having count(*) > 1;

-- Current/open-ended contract must agree.
select *
from SILVER_CANONICAL.VEHICLE_STATUS_HISTORY
where (is_current and valid_to is not null)
   or (not is_current and valid_to is null);

-- No negative validity intervals.
select *
from SILVER_CANONICAL.VEHICLE_STATUS_HISTORY
where valid_to < valid_from;

-- Published versions are numbered without gaps.
select vehicle_id
from SILVER_CANONICAL.VEHICLE_STATUS_HISTORY
qualify version_order <> row_number() over (
    partition by vehicle_id
    order by valid_from, source_sequence
);

-- No overlapping published intervals.
with intervals as (
    select
        vehicle_id,
        valid_from,
        valid_to,
        lead(valid_from) over (
            partition by vehicle_id
            order by version_order
        ) as next_valid_from
    from SILVER_CANONICAL.VEHICLE_STATUS_HISTORY
)
select *
from intervals
where valid_to > next_valid_from;
