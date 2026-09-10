-- Dataset-local structural validation. Business DQ rules may be added here by the domain.
-- Results are normalized into CONTROL.DQ_RESULT; CONTROL does not define these checks at runtime.
-- The version owns a unique procedure name, so CREATE is fail-closed on an unexpected collision.
CREATE PROCEDURE SILVER.VALIDATE_GTFS_REALTIME_VEHICLE_POSITION_V1()
RETURNS OBJECT
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
    V_RUN_ID VARCHAR DEFAULT UUID_STRING();
    V_VIOLATIONS NUMBER DEFAULT 0;
    V_CHECKS NUMBER DEFAULT 0;
    V_FAILED_CHECKS NUMBER DEFAULT 0;
BEGIN
    V_VIOLATIONS := (SELECT COUNT(*) FROM (
            SELECT VEHICLE_ID, EVENT_TIMESTAMP
            FROM SILVER.GTFS_REALTIME_VEHICLE_POSITION_V1
            GROUP BY VEHICLE_ID, EVENT_TIMESTAMP
            HAVING COUNT(*) > 1
        ));

    INSERT INTO CONTROL.DQ_RESULT (
        RESULT_ID, RUN_ID, DATASET_ID, VERSION, CHECK_ID, CHECK_SEVERITY,
        STATUS, VIOLATION_COUNT, DETAILS, QUERY_ID, CHECKED_AT
    ) VALUES (
        UUID_STRING(), :V_RUN_ID, 'gtfs_realtime.vehicle_position', 'v1', 'duplicate_idempotency_key', 'ERROR',
        IFF(:V_VIOLATIONS = 0, 'PASS', 'FAIL'), :V_VIOLATIONS,
        OBJECT_CONSTRUCT('description', 'Append output must preserve one Silver row per RAW-contract idempotency key.'), LAST_QUERY_ID(), CURRENT_TIMESTAMP()
    );

    V_FAILED_CHECKS := V_FAILED_CHECKS + IFF(V_VIOLATIONS > 0, 1, 0);
    V_CHECKS := V_CHECKS + 1;

    V_VIOLATIONS := (SELECT COUNT(*) FROM SILVER.GTFS_REALTIME_VEHICLE_POSITION_V1 WHERE VEHICLE_ID IS NULL);

    INSERT INTO CONTROL.DQ_RESULT (
        RESULT_ID, RUN_ID, DATASET_ID, VERSION, CHECK_ID, CHECK_SEVERITY,
        STATUS, VIOLATION_COUNT, DETAILS, QUERY_ID, CHECKED_AT
    ) VALUES (
        UUID_STRING(), :V_RUN_ID, 'gtfs_realtime.vehicle_position', 'v1', 'null_business_key', 'ERROR',
        IFF(:V_VIOLATIONS = 0, 'PASS', 'FAIL'), :V_VIOLATIONS,
        OBJECT_CONSTRUCT('description', 'Business-key columns must not be NULL in Silver output.'), LAST_QUERY_ID(), CURRENT_TIMESTAMP()
    );

    V_FAILED_CHECKS := V_FAILED_CHECKS + IFF(V_VIOLATIONS > 0, 1, 0);
    V_CHECKS := V_CHECKS + 1;

    RETURN OBJECT_CONSTRUCT(
        'run_id', V_RUN_ID,
        'dataset_id', 'gtfs_realtime.vehicle_position',
        'version', 'v1',
        'checks', V_CHECKS,
        'failed_checks', V_FAILED_CHECKS,
        'status', IFF(V_FAILED_CHECKS = 0, 'PASS', 'FAIL')
    );
END;
$$;
