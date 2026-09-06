# Enterprise Snowflake Transport Analytics

Domain repository for Transport-owned Snowflake analytics.

## Start here

For a new conversation/session, read:

1. `docs/CURRENT_CONTEXT.md` — current branch/PR stack, framework pin, CI status, blockers and next gate.
2. `docs/DEPLOYMENT.md` — one-click deployment path and environment prerequisites.
3. `docs/datasets/vehicle-status.md` — reference CDC/SCD2/bootstrap contract and source-specific boundary.

Human documentation lives under `docs/`. Machine configuration lives under `config/` and `contracts/`. Reusable technical implementation belongs in `enterprise-snowflake-data-project-framework` rather than being copied here.

## Domain database shape

Stable environment databases are owned by the Transport data product:

```text
DEV_TRANSPORT
UAT_TRANSPORT
PROD_TRANSPORT
```

They use the shared Medallion schema vocabulary:

```text
BRONZE
SILVER_STAGING
SILVER_INTERMEDIATE
SILVER_CANONICAL
GOLD_MARTS
GOLD_SEMANTIC
DQ
```

Ordinary new physical sources do not require a new database or Terraform-created source schema. Source identity remains in Git metadata and Bronze object naming unless governance requires explicit isolation.

## Current datasets

```text
vehicle_position
  event/position dataset; not modeled as SCD2

vehicle_status
  reference full-change CDC contract
  metadata-driven SCD2 history
  safe initial snapshot -> incremental handoff contract
```

`fleet_mssql` is a reference source contract only. This repository does not yet claim a live SQL Server connection or live LSN/consistent-snapshot implementation.

## Control plane

The project uses domain-scoped platform surfaces only:

```text
PLATFORM_CONTROL.OPERATIONS.TRANSPORT_*
PLATFORM_CONTROL.CONFIG.TRANSPORT_*
```

Project roles must not directly DML the shared PLATFORM_CONTROL base tables.

Git remains the dataset configuration source of truth. Successful stable deployments register immutable validated config snapshots through the Transport-scoped CONFIG procedure.

## Delivery

PR CI uses framework-generated `PR_<number>_<MEDALLION_LAYER>` workspaces.

Stable DEV/UAT/PROD deployment is exposed through `.github/workflows/deploy.yml`. After the change is on `main`, use GitHub Actions -> Deploy -> Run workflow and choose only the target environment. The workflow passes the selected `main` revision SHA to the pinned reusable framework deployment contract.

The reusable deployment validates main history, builds dbt from validated Git metadata, authenticates via protected-environment WIF, runs `dbt build`, then registers dataset config snapshots only after a successful build.

See `docs/DEPLOYMENT.md` for the exact operational path and prerequisites.

## Proof boundary

Static CI proves metadata validation, dbt offline rendering, domain-scoped operational/config API usage, SCD2 contract rendering and bootstrap contract rendering.

Live Snowflake WIF, platform grants, cross-domain denial, source snapshot/CDC consistency, retries/recovery and performance remain DEV integration gates.
