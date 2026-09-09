create table if not exists SILVER_CANONICAL.VEHICLE_POSITION (
    vehicle_id       varchar       not null,
    event_timestamp  timestamp_ntz not null,
    latitude         float         not null,
    longitude        float         not null,
    route_id         varchar,
    ingested_at      timestamp_ntz not null
);
