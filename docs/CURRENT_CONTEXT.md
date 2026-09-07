# Current Context

Concise handoff for a new conversation.

## Active stack

```text
PR #1  feature/domain-operational-contract
  domain-scoped runtime + metadata-driven vehicle_status SCD2

PR #2  feature/bootstrap-handoff-contract
  safe vehicle_status initial snapshot -> incremental handoff

PR #3  feature/medallion-one-click-deploy
  Medallion naming, config snapshot control and simplified deployment

PR #4  feature/dataset-reset-generation
  Senior+ full reset + generation-aware recovery for vehicle_status
```

PR #4 is intentionally stacked on PR #3. Retarget stacked PRs after lower dependencies merge.

## Framework pin

Current reset-aware immutable framework pin used by this branch:

```text
8afe208bd911a59b9334add78a53878ffea93087
Framework CI #181: SUCCESS
```

It includes Medallion workspace/target naming, explicit `scd1_merge`, metadata-driven SCD2, bootstrap handoff, deterministic dataset config snapshots, stable deployment helpers and bounded full-reset execution helpers.

## Domain database contract

```text
<ENV>_TRANSPORT
  BRONZE
  SILVER_STAGING
  SILVER_INTERMEDIATE
  SILVER_CANONICAL
  GOLD_MARTS
  GOLD_SEMANTIC
  DQ
```

Ordinary new sources share `BRONZE`; a new source should not require a Terraform-created database/schema by default.

## Control plane

Runtime state:

```text
PLATFORM_CONTROL.OPERATIONS.TRANSPORT_*
```

Deployment config audit:

```text
PLATFORM_CONTROL.CONFIG.TRANSPORT_DATASET_CONFIG_SNAPSHOT
PLATFORM_CONTROL.CONFIG.TRANSPORT_REGISTER_DATASET_CONFIG_SNAPSHOT
```

Reset/generation surface:

```text
PLATFORM_CONTROL.OPERATIONS.TRANSPORT_DATASET_LIFECYCLE
PLATFORM_CONTROL.OPERATIONS.TRANSPORT_DATASET_RESET
PLATFORM_CONTROL.OPERATIONS.TRANSPORT_DATASET_RESET_START
PLATFORM_CONTROL.OPERATIONS.TRANSPORT_DATASET_RESET_COMPLETE
```

Git is configuration truth. Snowflake CONFIG is immutable deployment audit/readback state; OPERATIONS contains mutable runtime/recovery state.

## Reference datasets

`vehicle_status`:

```text
reference source: fleet_mssql
capture: full_change CDC
checkpoint: source_position
bootstrap: snapshot_then_incremental / exclusive
history: metadata-driven SCD2
late arrival: rebuild_affected_keys
full reset: explicit reconstructable Bronze/Silver/Gold Mart cleanup
```

`vehicle_position` is an append/event/position dataset and is deliberately not modeled as SCD2 or included in the `vehicle_status` reset plan.

No live SQL Server source connection is claimed yet.

## Full reset

Operator role:

```text
AR_TRANSPORT_RECOVERY
```

Intended for Senior Data Engineer+ incident recovery. No mandatory multi-person approval chain is implemented. Transport Admin inherits the recovery capability.

Executable operation:

```text
transport_vehicle_status_full_reset
```

Current explicit reset plan:

```text
<ENV>_TRANSPORT.BRONZE.VEHICLE_STATUS
<ENV>_TRANSPORT.SILVER_STAGING.VEHICLE_STATUS
<ENV>_TRANSPORT.SILVER_INTERMEDIATE.VEHICLE_STATUS
<ENV>_TRANSPORT.SILVER_CANONICAL.VEHICLE_STATUS
<ENV>_TRANSPORT.GOLD_MARTS.VEHICLE_STATUS
```

Lifecycle:

```text
ACTIVE generation N
  -> RESETTING
  -> explicit cleanup
  -> generation N+1 / READY_FOR_INITIAL_LOAD
  -> normal vehicle_status pipeline succeeds
  -> ACTIVE
```

Old runtime generation records remain auditable. A failed cleanup remains `RESETTING` and can retry with the same reset ID. A reset ID that already reached `READY_FOR_RELOAD` or `COMPLETED` is rejected before cleanup; a later incident must use a new reset ID.

Operational instructions: `docs/RESET_RUNBOOK.md`.

## Deployment UX

After the lower stack is merged to `main`:

```text
GitHub Actions -> Deploy -> Run workflow -> choose dev/uat/prod
```

No SHA is manually typed. The selected workflow revision SHA is passed to the reusable framework workflow and must still be reachable from current `main`. After successful `dbt build`, validated dataset config snapshots are registered through Transport-scoped owner-rights procedures.

## Static proof

Latest reset-contract source/static proof:

```text
649021fa5f84e580361e86d9bf8c66664e581a04
dbt Static CI #53: SUCCESS
PR Workspace #34: FAILURE at Load approved Snowflake environment configuration
```

The current branch also contains documentation-only commits after that source/static head. The Workspace failure occurs before Snowflake execution; approved `ci` Snowflake environment/WIF configuration is still unavailable.

Static CI proves reset SQL rendering, explicit relation scope, domain control isolation, Medallion target/profile compatibility, config snapshot boundaries, SCD2 rendering and bootstrap rendering.

Live DEV remains required for real authentication, recovery role/table privileges, generation rollover, completed reset-ID rejection, cross-domain denial, source snapshot/CDC consistency, transaction/concurrency behavior, retries/recovery and actual reload execution.

## Cross-repository dependencies

```text
framework PR #5
  reset-aware pin 8afe208bd911a59b9334add78a53878ffea93087

platform-infra PR #3
  generation-aware reset control
  verified head c20c09c0c5f51dff17ebc5fb3eec75c89c5ce5a2
  Terraform CI #167: SUCCESS
  Platform Control SQL CI #37: SUCCESS
```

Lower platform/framework PRs remain dependencies for runtime/bootstrap, Medallion and CONFIG control.

Do not describe this repository as live-deployed until platform DEV bootstrap and WIF are complete.
