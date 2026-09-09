-- Synthetic full-change CDC data matching contracts/raw/vehicle_status.yml.

CREATE OR REPLACE TABLE DEMO_TRANSPORT.VEHICLE_STATUS_CDC AS
WITH vehicles AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS vehicle_n
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
),
events AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS event_n
    FROM TABLE(GENERATOR(ROWCOUNT => 6))
),
changes AS (
    SELECT
        v.vehicle_n,
        e.event_n,
        DATEADD(
            'minute',
            e.event_n * 20 + MOD(v.vehicle_n, 20),
            '2026-01-01 00:00:00'::TIMESTAMP_NTZ
        ) AS source_updated_at,
        IFF(e.event_n = 0, 'I', IFF(e.event_n = 5 AND MOD(v.vehicle_n, 20) = 0, 'D', 'U')) AS source_operation
    FROM vehicles v
    CROSS JOIN events e
)
SELECT
    'VH-' || LPAD(TO_VARCHAR(vehicle_n + 1), 6, '0') AS vehicle_id,
    IFF(
        source_operation = 'D',
        NULL,
        CASE MOD(vehicle_n + event_n, 4)
            WHEN 0 THEN 'IN_SERVICE'
            WHEN 1 THEN 'LAYOVER'
            WHEN 2 THEN 'MAINTENANCE'
            ELSE 'OUT_OF_SERVICE'
        END
    ) AS status,
    IFF(source_operation = 'D', NULL, 'DEPOT-' || LPAD(TO_VARCHAR(MOD(vehicle_n, 12) + 1), 2, '0')) AS depot_id,
    IFF(source_operation = 'D', NULL, 'ROUTE-' || LPAD(TO_VARCHAR(MOD(vehicle_n + event_n, 40) + 1), 3, '0')) AS route_id,
    source_updated_at,
    source_operation,
    vehicle_n * 100 + event_n + 1 AS source_sequence,
    DATEADD('second', 5, source_updated_at) AS ingested_at
FROM changes;

CREATE OR REPLACE VIEW DEMO_TRANSPORT.VEHICLE_STATUS_CURRENT AS
SELECT
    vehicle_id,
    status,
    depot_id,
    route_id,
    source_updated_at,
    source_operation,
    source_sequence,
    ingested_at
FROM DEMO_TRANSPORT.VEHICLE_STATUS_CDC
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY vehicle_id
    ORDER BY source_sequence DESC
) = 1
AND source_operation <> 'D';
