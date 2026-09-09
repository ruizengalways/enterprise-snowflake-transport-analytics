-- PROCESSING reset for vehicle_status.
-- Bronze is deliberately preserved.
--
-- Usage from a stable DEV/UAT/PROD Transport database with AR_TRANSPORT_RECOVERY:
--   set RESET_ID = 'incident-2026-09-09-001';
--   set RESET_REASON = 'rebuild trusted vehicle status after incorrect Silver deployment';
--   set GIT_SHA = '<40-char-deployed-sha>';
--   snow sql ... -f operations/reset_vehicle_status.sql

execute immediate $$
declare
    wrong_database exception (-20001, 'vehicle_status reset is allowed only in DEV/UAT/PROD_TRANSPORT');
begin
    if (current_database() not in ('DEV_TRANSPORT', 'UAT_TRANSPORT', 'PROD_TRANSPORT')) then
        raise wrong_database;
    end if;
end;
$$;

call PLATFORM_CONTROL.OPERATIONS.TRANSPORT_DATASET_RESET_START(
    $RESET_ID,
    'vehicle_status',
    $RESET_REASON,
    $GIT_SHA,
    object_construct(
        'reset_type', 'PROCESSING_FULL_RESET',
        'dataset', 'vehicle_status',
        'bronze_preserved', true
    )
);

-- If either TRUNCATE fails, stop here. Do not call RESET_COMPLETE; the lifecycle
-- intentionally remains RESETTING until an operator retries the cleanup.
truncate table if exists SILVER_CANONICAL.VEHICLE_STATUS_HISTORY;
truncate table if exists SILVER_CANONICAL.VEHICLE_STATUS_HISTORY__EVENTS;

call PLATFORM_CONTROL.OPERATIONS.TRANSPORT_DATASET_RESET_COMPLETE(
    $RESET_ID,
    'vehicle_status',
    object_construct(
        'reset_type', 'PROCESSING_FULL_RESET',
        'dataset', 'vehicle_status',
        'bronze_preserved', true
    )
);
