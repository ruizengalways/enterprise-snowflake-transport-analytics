# Current Context — Transport v2

Updated: 2026-09-09

## Canonical state

Transport Hybrid Framework v2 is merged to `main`. The v2 baseline merge is:

```text
563d8883a63faa606e06e4ac12e97b840e327e87
```

The enterprise adapter pins the merged Framework v2 baseline:

```text
7d3498f8b5ef48d868ea44aade62cf13e50e58f6
Framework v2 CI #193: SUCCESS
```

Transport PR #6 is the canonical v2 migration. Earlier stacked PRs #2–#5 are closed as superseded; their old framework pins and combined strategy vocabulary are historical only.

## Architectural rule

Transport keeps a **framework-independent portable core**:

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

Source contracts and synthetic data generation must work without Framework, `PLATFORM_CONTROL`, Terraform, enterprise WIF/RBAC or enterprise database/warehouse naming.

## Current datasets

```text
vehicle_status
  source: full-change CDC evidence
  load.strategy: scd2
  authoritative object: SILVER_CANONICAL vehicle_status_history
  current consumer surface: vehicle_status_current view

vehicle_position
  source: event/append evidence
  load.strategy: append_only

depot_fleet_status
  Gold readable aggregation SQL
  materialization.type: dynamic_table
  runtime.mode: snowflake_managed
  refresh_mode: adaptive
```

Business aggregation remains ordinary SQL; metadata describes execution mechanics only.

## Portable synthetic source

The framework-free path remains under `standalone/`.

Bulk deterministic source data:

```text
standalone/sql/00_setup.sql
standalone/sql/10_generate_vehicle_status.sql
standalone/sql/20_generate_vehicle_position.sql
standalone/sql/90_validate.sql
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

The simulator models source CDC only. It does not implement SCD2; a consuming pipeline determines target semantics. Reset-and-replay is deterministic and later batches include bounded updates and delete tombstones.

## Processing reset enterprise adapter

Generation-aware processing reset is exposed through `dbt/macros/reset_contract.sql` and the domain recovery boundary. It preserves ingestion-owned Bronze evidence and clears only the persisted SCD2 processing state:

```text
AR_TRANSPORT_RECOVERY
ACTIVE generation N
 -> RESETTING
 -> truncate SILVER_CANONICAL.VEHICLE_STATUS_HISTORY
 -> truncate SILVER_CANONICAL.VEHICLE_STATUS_HISTORY__ESF_EVENTS
 -> generation N+1 / READY_FOR_INITIAL_LOAD
 -> rebuild from retained Bronze evidence
 -> ACTIVE
```

The current/staging views are not truncated and the derived Gold Dynamic Table is not treated as an ordinary table. The reset macro rejects prefixed PR/personal workspaces and mismatched environment databases. Repair/replay remains separate from reset. See `docs/RESET_RUNBOOK.md`.

## Verified static state

The v2 migration was verified before merge with:

```text
Metadata v2 CI #43: SUCCESS
Transport dbt v2 CI #60: SUCCESS
Standalone SQL CI #14: SUCCESS
```

The PR Workspace job failed closed before Snowflake connection because GitHub Environment `ci` did not define `SNOWFLAKE_ACCOUNT` and `SNOWFLAKE_OIDC_AUDIENCE`. OIDC token request, Snowflake connection and workspace SQL were not executed.

## Remaining acceptance gates

Portable live acceptance:

```text
plain Snowflake database
no Framework / PLATFORM_CONTROL
-> execute standalone setup + simulator SQL
-> RESET + ADVANCE batches
-> verify deterministic I/U/D source evolution
```

Enterprise live acceptance:

```text
configure DEV Snowflake + GitHub Environment WIF
-> prove PR workspace lifecycle
-> deploy platform/control-plane prerequisites
-> run live vehicle_status SCD2 replay/update/delete/reinsert/late-arrival cases
-> prove processing reset/generation rollover and recovery-role isolation
-> run Gold Dynamic Table and stable deployment
```

A complete same-SHA DEV -> UAT -> PROD promotion orchestrator is intentionally deferred until the live DEV deployment path is proven. Static CI must not be described as live Snowflake proof.
