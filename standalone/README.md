# Standalone synthetic data

This directory is the portable entry point for this repository.

It uses **Snowflake SQL only**. It does not require dbt, the enterprise data framework, `PLATFORM_CONTROL`, Terraform, a particular role hierarchy, warehouse name, or database naming convention.

## Prerequisites

Connect to any Snowflake account, select any database and warehouse, and use a role that can create a schema plus tables/views in that database.

The scripts never create or switch databases, roles, or warehouses.

## Run order

Execute these files in order using Snowsight, SnowSQL, Snowflake CLI, JDBC/ODBC, or any SQL client:

```text
00_setup.sql
10_generate_vehicle_status.sql
20_generate_vehicle_position.sql
90_validate.sql
```

The scripts create only the schema:

```text
DEMO_TRANSPORT
```

Re-running the generation scripts is deterministic and replaces the demo tables/views.

## Generated source-like objects

```text
DEMO_TRANSPORT.VEHICLE_STATUS_CDC
DEMO_TRANSPORT.VEHICLE_STATUS_CURRENT
DEMO_TRANSPORT.VEHICLE_POSITION_EVENTS
```

`VEHICLE_STATUS_CDC` matches the repository RAW contract for `vehicle_status` and contains inserts, updates and tombstone deletes. `VEHICLE_POSITION_EVENTS` matches the append/event RAW contract for `vehicle_position`.

The generated data is synthetic and contains no external source data.

## Cleanup

Run:

```text
99_cleanup.sql
```

This drops only `DEMO_TRANSPORT` in the currently selected database.

## Enterprise integration

The repository may also contain optional dbt/platform integration for the enterprise Snowflake platform. That integration is not required to generate or inspect this demo data. A consumer on another Snowflake platform can ignore it completely.
