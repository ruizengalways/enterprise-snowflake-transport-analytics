# Current Context

Concise handoff for a new conversation.

## Architectural rule

Transport has a **framework-independent portable core**. Source contracts and synthetic data generation must work on any Snowflake platform without the enterprise framework, `PLATFORM_CONTROL`, Terraform, WIF, enterprise RBAC, or enterprise database/warehouse naming.

```text
portable Transport core
  contracts/
  config/
  standalone/
  domain docs
        ↑
optional enterprise adapter
  dbt/
  enterprise workflows
        ↑
enterprise framework/platform
```

See `docs/PORTABILITY.md` and `standalone/README.md`.

## Active stack

```text
PR #1 domain operational contract
PR #2 bootstrap handoff
PR #3 Medallion/config/one-click enterprise deploy
PR #4 generation-aware full reset
PR #5 framework-free portable synthetic data + stateful source simulator
```

PR #5 is stacked on PR #4 while the lower stack remains open.

## Portable demo — PR #5

Bulk deterministic source data:

```text
standalone/sql/00_setup.sql
standalone/sql/10_generate_vehicle_status.sql
standalone/sql/20_generate_vehicle_position.sql
standalone/sql/90_validate.sql
```

Bulk objects:

```text
DEMO_TRANSPORT.VEHICLE_STATUS_CDC
DEMO_TRANSPORT.VEHICLE_STATUS_CURRENT
DEMO_TRANSPORT.VEHICLE_POSITION_EVENTS
```

Stateful incremental source simulator:

```text
standalone/sql/30_incremental_vehicle_status_simulator.sql

DEMO_TRANSPORT.VEHICLE_STATUS_SIM_CDC
DEMO_TRANSPORT.VEHICLE_STATUS_SIM_CURRENT
DEMO_TRANSPORT.VEHICLE_STATUS_SIM_STATE
DEMO_TRANSPORT.RESET_VEHICLE_STATUS_SIMULATOR()
DEMO_TRANSPORT.ADVANCE_VEHICLE_STATUS_SIMULATOR()
```

The simulator uses native Snowflake Scripting (`LANGUAGE SQL`), not Python. `RESET` returns `current_batch` to `-1`. The first `ADVANCE` emits deterministic insert records for 500 vehicles. Later calls emit deterministic update records for a bounded subset; later batches also emit a small number of delete tombstones. Event timestamps and source sequences are deterministic so reset-and-replay is reproducible.

The simulator models **source CDC only**. It does not implement SCD2 itself. A consuming pipeline can use the same changes to test SCD2, SCD1 or another target strategy.

The standalone SQL creates no database/warehouse/role and contains no enterprise framework or control-plane dependency. Bulk and incremental simulator objects are separate and can coexist.

Verified simulator source/static head:

```text
5f957b9d8ca3cd7c5734d9d1c0b34b0eca8fcf78
Standalone SQL CI #8: SUCCESS
PR Workspace #44: FAILURE at Load approved Snowflake environment configuration
```

This `CURRENT_CONTEXT.md` update is documentation-only after that verified source head. The PR Workspace failure belongs to the optional enterprise adapter and occurs before checkout/Snowflake execution.

## Optional enterprise adapter

Current reset-aware framework pin used only by the enterprise dbt/workflow path:

```text
8afe208bd911a59b9334add78a53878ffea93087
Framework CI #181: SUCCESS
```

Enterprise stable databases use `<ENV>_TRANSPORT` plus Medallion schemas. Those names are not portable-core requirements.

## Reference datasets

`vehicle_status` remains the full-change CDC/SCD2/bootstrap reference dataset. `vehicle_position` remains append/event.

The standalone bulk generator and stateful simulator provide synthetic source evidence without claiming a live SQL Server or GTFS source.

## Full reset enterprise adapter

```text
role: AR_TRANSPORT_RECOVERY
operation: transport_vehicle_status_full_reset
ACTIVE generation N
 -> RESETTING
 -> explicit Bronze/Silver/Gold cleanup
 -> generation N+1 / READY_FOR_INITIAL_LOAD
 -> normal pipeline success
 -> ACTIVE
```

Same reset ID retries only while `RESETTING`; ready/completed IDs fail before cleanup. See `docs/RESET_RUNBOOK.md`.

Verified lower stack:

```text
Framework reset
8afe208bd911a59b9334add78a53878ffea93087
Framework CI #181: SUCCESS

Platform reset
c20c09c0c5f51dff17ebc5fb3eec75c89c5ce5a2
Terraform CI #167: SUCCESS
Platform Control SQL CI #37: SUCCESS

Transport reset
649021fa5f84e580361e86d9bf8c66664e581a04
dbt Static CI #53: SUCCESS
```

## Live boundaries

Portable live acceptance:

```text
plain Snowflake database
no framework package
no PLATFORM_CONTROL
no enterprise roles/naming
 -> execute standalone setup + simulator SQL
 -> RESET simulator
 -> ADVANCE initial batch
 -> inspect CDC/current state
 -> ADVANCE multiple change batches
 -> verify deterministic I/U/D evolution
 -> optionally run any consuming pipeline between ADVANCE calls
```

Current Snowflake Scripting variable-binding and `SQLROWCOUNT` placement have been checked against Snowflake documentation, but static CI is not a live Snowflake compiler/runtime proof.

Enterprise live acceptance separately requires real DEV Snowflake/WIF for grants, control plane, reset generation rollover and pipelines.
