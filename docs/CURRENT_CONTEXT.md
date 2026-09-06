# Current Context

Concise handoff for a new conversation.

## Active stack

```text
PR #1  feature/domain-operational-contract
  domain-scoped runtime + metadata-driven vehicle_status SCD2

PR #2  feature/bootstrap-handoff-contract
  safe vehicle_status initial snapshot -> incremental handoff

current stacked branch
  feature/medallion-one-click-deploy
  adds Medallion naming, config snapshot control and simplified deployment
```

The current branch is intentionally based on PR #2. Retarget after lower PRs merge.

## Framework pin

Current immutable framework revision for this branch:

```text
02e3fca78b453e8a39a1722ce96b15dfc98d7cf8
```

That framework revision has green Framework CI and Bootstrap Contract CI and includes:

```text
Medallion workspace/target naming
explicit scd1_merge
metadata-driven SCD2
bootstrap handoff
deterministic dataset config snapshots
PLATFORM_CONTROL.CONFIG domain API helpers
stable deployment context + post-build config registration
```

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

## Control-plane contract

Runtime state:

```text
PLATFORM_CONTROL.OPERATIONS.TRANSPORT_*
```

Deployment config audit:

```text
PLATFORM_CONTROL.CONFIG.TRANSPORT_DATASET_CONFIG_SNAPSHOT
PLATFORM_CONTROL.CONFIG.TRANSPORT_REGISTER_DATASET_CONFIG_SNAPSHOT
```

Git is configuration truth. Snowflake CONFIG is immutable audit/readback state.

## Current reference datasets

`vehicle_status`:

```text
reference source: fleet_mssql
capture: full_change CDC
checkpoint: source_position
bootstrap: snapshot_then_incremental / exclusive
history: metadata-driven SCD2
late arrival: rebuild_affected_keys
```

`vehicle_position` is an event/position dataset and is deliberately not modeled as SCD2.

No live SQL Server source connection is claimed yet.

## Deployment UX

After this branch is merged to `main`:

```text
GitHub Actions -> Deploy -> Run workflow -> choose dev/uat/prod
```

No SHA is manually typed. The selected workflow revision SHA is passed to the reusable framework deploy workflow and must still pass the immutable-main-history guard.

The successful deploy path ends by registering all validated dataset config snapshots. See `docs/DEPLOYMENT.md`.

## Proof boundary

Expected static proof on this branch:

```text
Metadata CI
DBT Static CI
  operational domain isolation
  CONFIG domain isolation
  SCD2 rendering
  bootstrap rendering
```

PR Workspace still requires a real Snowflake `ci` GitHub Environment/WIF configuration and may fail for that external reason.

Live DEV remains required for real account auth, platform grants, cross-domain denial, source snapshot/CDC consistency, transaction/concurrency behavior, retries/recovery and SCD2 execution.

## Cross-repository dependencies

```text
framework PR #4 / green SHA above
platform-infra PR #2 / Medallion + PLATFORM_CONTROL.CONFIG
platform-infra PR #1 / domain operational/bootstrap surfaces
```

Do not describe this as live-deployed until platform DEV bootstrap and WIF are complete.
