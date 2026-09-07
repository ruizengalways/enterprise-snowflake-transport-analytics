-- Stateful synthetic vehicle_status source simulator.
-- Pure Snowflake SQL Scripting: no Python, dbt, framework or PLATFORM_CONTROL.
--
-- Usage:
--   CALL DEMO_TRANSPORT.RESET_VEHICLE_STATUS_SIMULATOR();
--   CALL DEMO_TRANSPORT.ADVANCE_VEHICLE_STATUS_SIMULATOR(); -- initial I batch
--   CALL DEMO_TRANSPORT.ADVANCE_VEHICLE_STATUS_SIMULATOR(); -- deterministic U batch
--   CALL DEMO_TRANSPORT.ADVANCE_VEHICLE_STATUS_SIMULATOR(); -- more changes
--
-- The simulator writes to its own objects so the bulk generator remains available.

CREATE TABLE IF NOT EXISTS DEMO_TRANSPORT.VEHICLE_STATUS_SIM_CDC (
    vehicle_id         VARCHAR         NOT NULL,
    status             VARCHAR,
    depot_id           VARCHAR,
    route_id           VARCHAR,
    source_updated_at  TIMESTAMP_NTZ   NOT NULL,
    source_operation   VARCHAR         NOT NULL,
    source_sequence    NUMBER          NOT NULL,
    ingested_at        TIMESTAMP_NTZ   NOT NULL
);

CREATE TABLE IF NOT EXISTS DEMO_TRANSPORT.VEHICLE_STATUS_SIM_STATE (
    simulator_name VARCHAR PRIMARY KEY,
    current_batch  NUMBER NOT NULL,
    updated_at     TIMESTAMP_NTZ NOT NULL
);

MERGE INTO DEMO_TRANSPORT.VEHICLE_STATUS_SIM_STATE target
USING (SELECT 'vehicle_status' simulator_name, -1 current_batch) source
   ON target.simulator_name = source.simulator_name
WHEN NOT MATCHED THEN INSERT (simulator_name, current_batch, updated_at)
VALUES (source.simulator_name, source.current_batch, CURRENT_TIMESTAMP());

CREATE OR REPLACE VIEW DEMO_TRANSPORT.VEHICLE_STATUS_SIM_CURRENT AS
SELECT
    vehicle_id,
    status,
    depot_id,
    route_id,
    source_updated_at,
    source_operation,
    source_sequence,
    ingested_at
FROM DEMO_TRANSPORT.VEHICLE_STATUS_SIM_CDC
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY vehicle_id
    ORDER BY source_sequence DESC
) = 1
AND source_operation <> 'D';

CREATE OR REPLACE PROCEDURE DEMO_TRANSPORT.RESET_VEHICLE_STATUS_SIMULATOR()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    TRUNCATE TABLE DEMO_TRANSPORT.VEHICLE_STATUS_SIM_CDC;

    UPDATE DEMO_TRANSPORT.VEHICLE_STATUS_SIM_STATE
       SET current_batch = -1,
           updated_at = CURRENT_TIMESTAMP()
     WHERE simulator_name = 'vehicle_status';

    RETURN 'vehicle_status simulator reset; next ADVANCE emits initial inserts';
END;
$$;

CREATE OR REPLACE PROCEDURE DEMO_TRANSPORT.ADVANCE_VEHICLE_STATUS_SIMULATOR()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_batch NUMBER;
    v_event_time TIMESTAMP_NTZ;
    v_rows NUMBER;
BEGIN
    SELECT current_batch + 1
      INTO :v_batch
      FROM DEMO_TRANSPORT.VEHICLE_STATUS_SIM_STATE
     WHERE simulator_name = 'vehicle_status';

    v_event_time := DATEADD('minute', v_batch * 15, '2026-01-01 00:00:00'::TIMESTAMP_NTZ);

    IF (v_batch = 0) THEN
        INSERT INTO DEMO_TRANSPORT.VEHICLE_STATUS_SIM_CDC (
            vehicle_id, status, depot_id, route_id,
            source_updated_at, source_operation, source_sequence, ingested_at
        )
        SELECT
            'VH-' || LPAD(TO_VARCHAR(vehicle_n + 1), 6, '0'),
            CASE MOD(vehicle_n, 4)
                WHEN 0 THEN 'IN_SERVICE'
                WHEN 1 THEN 'LAYOVER'
                WHEN 2 THEN 'MAINTENANCE'
                ELSE 'OUT_OF_SERVICE'
            END,
            'DEPOT-' || LPAD(TO_VARCHAR(MOD(vehicle_n, 12) + 1), 2, '0'),
            'ROUTE-' || LPAD(TO_VARCHAR(MOD(vehicle_n, 40) + 1), 3, '0'),
            :v_event_time,
            'I',
            vehicle_n * 1000 + :v_batch + 1,
            DATEADD('second', 5, :v_event_time)
        FROM (
            SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS vehicle_n
            FROM TABLE(GENERATOR(ROWCOUNT => 500))
        );
    ELSE
        INSERT INTO DEMO_TRANSPORT.VEHICLE_STATUS_SIM_CDC (
            vehicle_id, status, depot_id, route_id,
            source_updated_at, source_operation, source_sequence, ingested_at
        )
        SELECT
            vehicle_id,
            IFF(is_delete, NULL,
                CASE MOD(vehicle_n + :v_batch, 4)
                    WHEN 0 THEN 'IN_SERVICE'
                    WHEN 1 THEN 'LAYOVER'
                    WHEN 2 THEN 'MAINTENANCE'
                    ELSE 'OUT_OF_SERVICE'
                END
            ),
            IFF(is_delete, NULL,
                'DEPOT-' || LPAD(TO_VARCHAR(MOD(vehicle_n + :v_batch, 12) + 1), 2, '0')
            ),
            IFF(is_delete, NULL,
                'ROUTE-' || LPAD(TO_VARCHAR(MOD(vehicle_n + :v_batch * 3, 40) + 1), 3, '0')
            ),
            :v_event_time,
            IFF(is_delete, 'D', 'U'),
            vehicle_n * 1000 + :v_batch + 1,
            DATEADD('second', 5, :v_event_time)
        FROM (
            SELECT
                vehicle_n,
                'VH-' || LPAD(TO_VARCHAR(vehicle_n + 1), 6, '0') AS vehicle_id,
                (:v_batch >= 4 AND MOD(vehicle_n + :v_batch, 97) = 0) AS is_delete
            FROM (
                SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS vehicle_n
                FROM TABLE(GENERATOR(ROWCOUNT => 500))
            )
            WHERE MOD(vehicle_n + :v_batch, 5) = 0
        );
    END IF;

    v_rows := SQLROWCOUNT;

    UPDATE DEMO_TRANSPORT.VEHICLE_STATUS_SIM_STATE
       SET current_batch = :v_batch,
           updated_at = CURRENT_TIMESTAMP()
     WHERE simulator_name = 'vehicle_status';

    RETURN 'vehicle_status simulator advanced to batch ' || v_batch || '; emitted rows=' || v_rows;
END;
$$;
