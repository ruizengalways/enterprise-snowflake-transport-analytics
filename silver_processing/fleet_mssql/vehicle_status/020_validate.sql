-- Dataset-local structural validation. Business DQ rules may be added here by the domain.
-- Results are normalized into CONTROL.DQ_RESULT; CONTROL does not define these checks at runtime.
-- The version owns a unique procedure name, so CREATE is fail-closed on an unexpected collision.
CREATE PROCEDURE SILVER.VALIDATE_FLEET_MSSQL_VEHICLE_STATUS_V1()
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
            SELECT VEHICLE_ID
            FROM SILVER.FLEET_MSSQL_VEHICLE_STATUS_V1_HISTORY
            WHERE IS_ACTIVE = TRUE
            GROUP BY VEHICLE_ID
            HAVING COUNT(*) > 1
        ));

    INSERT INTO CONTROL.DQ_RESULT (
        RESULT_ID, RUN_ID, DATASET_ID, VERSION, CHECK_ID, CHECK_SEVERITY,
        STATUS, VIOLATION_COUNT, DETAILS, QUERY_ID, CHECKED_AT
    ) VALUES (
        UUID_STRING(), :V_RUN_ID, 'fleet_mssql.vehicle_status', 'v1', 'multiple_active_rows', 'ERROR',
        IFF(:V_VIOLATIONS = 0, 'PASS', 'FAIL'), :V_VIOLATIONS,
        OBJECT_CONSTRUCT('description', 'At most one active history row may exist per business key.'), LAST_QUERY_ID(), CURRENT_TIMESTAMP()
    );

    V_FAILED_CHECKS := V_FAILED_CHECKS + IFF(V_VIOLATIONS > 0, 1, 0);
    V_CHECKS := V_CHECKS + 1;

    V_VIOLATIONS := (SELECT COUNT(*) FROM SILVER.FLEET_MSSQL_VEHICLE_STATUS_V1_HISTORY WHERE VEHICLE_ID IS NULL);

    INSERT INTO CONTROL.DQ_RESULT (
        RESULT_ID, RUN_ID, DATASET_ID, VERSION, CHECK_ID, CHECK_SEVERITY,
        STATUS, VIOLATION_COUNT, DETAILS, QUERY_ID, CHECKED_AT
    ) VALUES (
        UUID_STRING(), :V_RUN_ID, 'fleet_mssql.vehicle_status', 'v1', 'null_business_key', 'ERROR',
        IFF(:V_VIOLATIONS = 0, 'PASS', 'FAIL'), :V_VIOLATIONS,
        OBJECT_CONSTRUCT('description', 'Business-key columns must not be NULL in Silver history.'), LAST_QUERY_ID(), CURRENT_TIMESTAMP()
    );

    V_FAILED_CHECKS := V_FAILED_CHECKS + IFF(V_VIOLATIONS > 0, 1, 0);
    V_CHECKS := V_CHECKS + 1;

    V_VIOLATIONS := (SELECT COUNT(*) FROM (
            WITH ORDERED AS (
                SELECT
                    VEHICLE_ID,
                    VALID_FROM,
                    VALID_TO,
                    LAG(VALID_TO) OVER (
                        PARTITION BY VEHICLE_ID
                        ORDER BY VALID_FROM
                    ) AS PREVIOUS_VALID_TO
                FROM SILVER.FLEET_MSSQL_VEHICLE_STATUS_V1_HISTORY
            )
            SELECT 1
            FROM ORDERED
            WHERE PREVIOUS_VALID_TO IS NOT NULL
              AND VALID_FROM < PREVIOUS_VALID_TO
        ));

    INSERT INTO CONTROL.DQ_RESULT (
        RESULT_ID, RUN_ID, DATASET_ID, VERSION, CHECK_ID, CHECK_SEVERITY,
        STATUS, VIOLATION_COUNT, DETAILS, QUERY_ID, CHECKED_AT
    ) VALUES (
        UUID_STRING(), :V_RUN_ID, 'fleet_mssql.vehicle_status', 'v1', 'overlapping_effective_periods', 'ERROR',
        IFF(:V_VIOLATIONS = 0, 'PASS', 'FAIL'), :V_VIOLATIONS,
        OBJECT_CONSTRUCT('description', 'SCD2 effective periods must not overlap for a business key.'), LAST_QUERY_ID(), CURRENT_TIMESTAMP()
    );

    V_FAILED_CHECKS := V_FAILED_CHECKS + IFF(V_VIOLATIONS > 0, 1, 0);
    V_CHECKS := V_CHECKS + 1;

    RETURN OBJECT_CONSTRUCT(
        'run_id', V_RUN_ID,
        'dataset_id', 'fleet_mssql.vehicle_status',
        'version', 'v1',
        'checks', V_CHECKS,
        'failed_checks', V_FAILED_CHECKS,
        'status', IFF(V_FAILED_CHECKS = 0, 'PASS', 'FAIL')
    );
END;
$$;
