-- Triggered by unconsumed stream data.
-- Operational settings below belong to this implementation version, not to the logical dataset SLA.
-- This version owns a new task name. CREATE is intentionally fail-closed: an unexpected
-- pre-existing task is an ownership conflict and must not be silently replaced or suspended.
-- Snowflake creates new tasks suspended. Validation and activation are explicit.
-- One task run applies the transformation and then records dataset-local structural DQ evidence.
CREATE TASK SILVER.GTFS_REALTIME_VEHICLE_POSITION_V1_TASK
    WAREHOUSE = WH_TRANSPORT_TRANSFORM
    WHEN SYSTEM$STREAM_HAS_DATA('BRONZE.GTFS_REALTIME_VEHICLE_POSITION_V1_STREAM')
AS
BEGIN
    CALL SILVER.APPLY_GTFS_REALTIME_VEHICLE_POSITION_V1();
    CALL SILVER.VALIDATE_GTFS_REALTIME_VEHICLE_POSITION_V1();
END;

-- Triggered task activation after validation:
-- ALTER TASK SILVER.GTFS_REALTIME_VEHICLE_POSITION_V1_TASK RESUME;
-- A task without SCHEDULE/AFTER/WHEN can still be tested explicitly with:
-- EXECUTE TASK SILVER.GTFS_REALTIME_VEHICLE_POSITION_V1_TASK;
