-- Human-readable validation queries. Expected results are documented below.

SELECT COUNT(*) AS vehicle_status_change_rows
FROM DEMO_TRANSPORT.VEHICLE_STATUS_CDC;
-- expected: 3000

SELECT source_operation, COUNT(*) AS rows_by_operation
FROM DEMO_TRANSPORT.VEHICLE_STATUS_CDC
GROUP BY source_operation
ORDER BY source_operation;
-- expected: I, U and D are all present

SELECT COUNT(*) AS current_vehicle_rows
FROM DEMO_TRANSPORT.VEHICLE_STATUS_CURRENT;
-- expected: 475 (25 deterministic tombstone deletes)

SELECT COUNT(*) AS vehicle_position_rows
FROM DEMO_TRANSPORT.VEHICLE_POSITION_EVENTS;
-- expected: 12000

SELECT COUNT(*) AS duplicate_status_events
FROM (
    SELECT vehicle_id, source_sequence
    FROM DEMO_TRANSPORT.VEHICLE_STATUS_CDC
    GROUP BY vehicle_id, source_sequence
    HAVING COUNT(*) > 1
);
-- expected: 0

SELECT COUNT(*) AS duplicate_position_events
FROM (
    SELECT vehicle_id, event_timestamp
    FROM DEMO_TRANSPORT.VEHICLE_POSITION_EVENTS
    GROUP BY vehicle_id, event_timestamp
    HAVING COUNT(*) > 1
);
-- expected: 0
