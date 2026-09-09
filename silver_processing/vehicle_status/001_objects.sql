-- vehicle_status: durable Silver objects.
-- Bronze remains ingestion-owned evidence and is never mutated here.

create table if not exists SILVER_CANONICAL.VEHICLE_STATUS_HISTORY__EVENTS (
    vehicle_id          varchar       not null,
    status              varchar,
    depot_id            varchar,
    route_id            varchar,
    source_updated_at   timestamp_ntz not null,
    source_operation    varchar       not null,
    source_sequence     number        not null,
    ingested_at         timestamp_ntz not null
);

create table if not exists SILVER_CANONICAL.VEHICLE_STATUS_HISTORY (
    vehicle_id          varchar       not null,
    status              varchar,
    depot_id            varchar,
    route_id            varchar,
    source_updated_at   timestamp_ntz not null,
    source_operation    varchar       not null,
    source_sequence     number        not null,
    ingested_at         timestamp_ntz not null,
    version_order       number        not null,
    valid_from          timestamp_ntz not null,
    valid_to            timestamp_ntz,
    is_current          boolean       not null
);

create or replace view SILVER_CANONICAL.VEHICLE_STATUS_CURRENT as
select
    vehicle_id,
    status,
    depot_id,
    route_id,
    source_updated_at,
    source_sequence,
    ingested_at,
    valid_from
from SILVER_CANONICAL.VEHICLE_STATUS_HISTORY
where is_current = true;
