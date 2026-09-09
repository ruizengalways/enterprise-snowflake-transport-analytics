-- Created suspended by Snowflake. Resume only after DEV acceptance and ingestion cadence review.
create or replace task SILVER_CANONICAL.TASK_APPLY_VEHICLE_POSITION
    warehouse = WH_TRANSPORT_TRANSFORM
    schedule = '1 MINUTE'
as
    call SILVER_CANONICAL.APPLY_VEHICLE_POSITION();
