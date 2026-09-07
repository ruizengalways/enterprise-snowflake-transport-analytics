-- Synthetic append-only events matching contracts/raw/vehicle_position.yml.

CREATE OR REPLACE TABLE DEMO_TRANSPORT.VEHICLE_POSITION_EVENTS AS
WITH vehicles AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS vehicle_n
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
),
events AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS event_n
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
)
SELECT
    'VH-' || LPAD(TO_VARCHAR(v.vehicle_n + 1), 6, '0') AS vehicle_id,
    DATEADD(
        'minute',
        e.event_n * 2 + MOD(v.vehicle_n, 2),
        '2026-01-01 06:00:00'::TIMESTAMP_NTZ
    ) AS event_timestamp,
    -33.90 + MOD(v.vehicle_n, 80) * 0.001 + e.event_n * 0.0001 AS latitude,
    151.10 + MOD(v.vehicle_n, 90) * 0.001 + e.event_n * 0.0001 AS longitude,
    'ROUTE-' || LPAD(TO_VARCHAR(MOD(v.vehicle_n, 40) + 1), 3, '0') AS route_id,
    DATEADD(
        'second',
        3,
        DATEADD('minute', e.event_n * 2 + MOD(v.vehicle_n, 2), '2026-01-01 06:00:00'::TIMESTAMP_NTZ)
    ) AS ingested_at
FROM vehicles v
CROSS JOIN events e;
