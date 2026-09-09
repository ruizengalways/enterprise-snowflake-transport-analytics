-- Created suspended by Snowflake. Resume only after DEV acceptance and ingestion cadence review.
create or replace task SILVER_CANONICAL.TASK_APPLY_VEHICLE_STATUS
    warehouse = WH_TRANSPORT_TRANSFORM
    schedule = '5 MINUTE'
as
    call SILVER_CANONICAL.APPLY_VEHICLE_STATUS();
