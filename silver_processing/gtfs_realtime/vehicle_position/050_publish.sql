-- Initial publication is create-only. If the stable name unexpectedly exists,
-- fail rather than replace an object whose ownership or grants are unknown.
CREATE VIEW SILVER.GTFS_REALTIME_VEHICLE_POSITION AS
SELECT *
FROM SILVER.GTFS_REALTIME_VEHICLE_POSITION_V1;
