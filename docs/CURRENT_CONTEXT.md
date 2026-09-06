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
```

PR #3 is intentionally stacked on PR #2. Retarget stacked PRs after lower dependencies merge.

## Framework pin

Verified immutable framework implementation used by this branch:

```text
02e3fca78b453e8a39a1722ce96b15dfc98d7cf8
Framework CI #175: SUCCESS
Bootstrap Contract CI #7: SUCCESS
```

It includes Medallion workspace/target naming, explicit `scd1_merge`, metadata-driven SCD2, bootstrap handoff, deterministic dataset config snapshots, `PLATFORM_CONTROL.CONFIG` domain API helpers, and post-build config registration.

Later framework branch commits may be documentation-only; do not repin merely because handoff prose changed.

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

Git is configuration truth. Snowflake CONFIG is immutable deployment audit/readback state.

## Reference datasets

`vehicle_status`:

```text
reference source: fleet_mssql
capture: full_change CDC
checkpoint: source_position
bootstrap: snapshot_then_incremental / exclusive
history: metadata-driven SCD2
late arrival: rebuild_affected_keys
```

`vehicle_position` is an append/event/position dataset and is deliberately not modeled as SCD2.

No live SQL Server source connection is claimed yet.

## Deployment UX

After PR #3 is merged to `main`:

```text
GitHub Actions -> Deploy -> Run workflow -> choose dev/uat/prod
```

No SHA is manually typed. The selected workflow revision SHA is passed to the reusable framework workflow and must still be reachable from current `main`. After successful `dbt build`, validated dataset config snapshots are registered through Transport-scoped owner-rights procedures.

See `docs/DEPLOYMENT.md`.

## Static proof

PR #3 implementation head:

```text
c96260554487630f15972affc7282073138de8e2
Metadata CI: SUCCESS
dbt Static CI: SUCCESS
PR Workspace: FAILURE because live ci Snowflake/WIF configuration is not yet available
```

Static CI proves operational and CONFIG domain isolation, Medallion target/profile compatibility, SCD2 rendering and bootstrap rendering.

Live DEV remains required for real authentication, platform grants, cross-domain denial, source snapshot/CDC consistency, transaction/concurrency behavior, retries/recovery and SCD2 execution.

## Cross-repository dependencies

```text
framework PR #4 / verified implementation SHA above
platform-infra PR #1 / domain operational/bootstrap surfaces
platform-infra PR #2 / Medallion schemas + PLATFORM_CONTROL.CONFIG
```

Do not describe this repository as live-deployed until platform DEV bootstrap and WIF are complete.
