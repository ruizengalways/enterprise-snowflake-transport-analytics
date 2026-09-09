# Standalone synthetic data

This directory is the portable entry point for this repository.

It uses **Snowflake SQL only**. It does not require dbt, the enterprise data framework, `PLATFORM_CONTROL`, Terraform, a particular role hierarchy, warehouse name, or database naming convention.

## Prerequisites

Connect to any Snowflake account, select any database and warehouse, and use a role that can create a schema plus tables/views/procedures in that database.

The scripts never create or switch databases, roles, or warehouses.

## Bulk demo data

Execute these files in order using Snowsight, SnowSQL, Snowflake CLI, JDBC/ODBC, or any SQL client:

```text
00_setup.sql
10_generate_vehicle_status.sql
20_generate_vehicle_position.sql
90_validate.sql
```

This deterministic path creates source-like history in one run:

```text
DEMO_TRANSPORT.VEHICLE_STATUS_CDC
DEMO_TRANSPORT.VEHICLE_STATUS_CURRENT
DEMO_TRANSPORT.VEHICLE_POSITION_EVENTS
```

`VEHICLE_STATUS_CDC` matches the repository RAW contract for `vehicle_status` and contains inserts, updates and tombstone deletes. `VEHICLE_POSITION_EVENTS` matches the append/event RAW contract for `vehicle_position`.

## Stateful incremental simulator

Run once to install the simulator:

```text
30_incremental_vehicle_status_simulator.sql
```

It creates independent simulator objects:

```text
DEMO_TRANSPORT.VEHICLE_STATUS_SIM_CDC
DEMO_TRANSPORT.VEHICLE_STATUS_SIM_CURRENT
DEMO_TRANSPORT.VEHICLE_STATUS_SIM_STATE
DEMO_TRANSPORT.RESET_VEHICLE_STATUS_SIMULATOR()
DEMO_TRANSPORT.ADVANCE_VEHICLE_STATUS_SIMULATOR()
```

The procedures use Snowflake SQL Scripting (`LANGUAGE SQL`), not Python.

Typical SCD2/incremental test cycle:

```sql
CALL DEMO_TRANSPORT.RESET_VEHICLE_STATUS_SIMULATOR();

CALL DEMO_TRANSPORT.ADVANCE_VEHICLE_STATUS_SIMULATOR();
-- initial I records: run your pipeline

CALL DEMO_TRANSPORT.ADVANCE_VEHICLE_STATUS_SIMULATOR();
-- deterministic U records: run your pipeline again

CALL DEMO_TRANSPORT.ADVANCE_VEHICLE_STATUS_SIMULATOR();
-- more U records

CALL DEMO_TRANSPORT.ADVANCE_VEHICLE_STATUS_SIMULATOR();
CALL DEMO_TRANSPORT.ADVANCE_VEHICLE_STATUS_SIMULATOR();
-- later batches also contain a small number of D tombstones
```

Each call advances `current_batch`. Event timestamps and source sequences are deterministic, so the same reset-and-advance sequence is reproducible. The simulator emits source CDC; it does **not** implement SCD2 itself. Your pipeline decides whether those changes become SCD2, SCD1, append-only, or another target model.

The bulk and incremental paths use different tables, so they can coexist.

## Schema and cleanup

All standalone objects live only in:

```text
DEMO_TRANSPORT
```

The generated data is synthetic and contains no external source data.

Run:

```text
99_cleanup.sql
```

This drops only `DEMO_TRANSPORT` in the currently selected database.

## Enterprise integration

The repository may also contain optional dbt/platform integration for the enterprise Snowflake platform. That integration is not required to generate or inspect this demo data. A consumer on another Snowflake platform can ignore it completely.
