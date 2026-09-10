# Framework 0.25 adoption

## Why this is staged

This repository predates the current Silver-first Framework architecture. Its existing production/reference path uses dbt for `SILVER_STAGING` and `SILVER_CANONICAL`, and its older dataset metadata lives under `config/datasets/`.

Framework 0.25 instead separates:

```text
reviewed RAW/source semantics
  -> config/sources/<source>.yml
  -> contracts/raw/<source>/<dataset>.yml

Silver implementation
  -> silver_processing/<source>/<dataset>/

dbt
  -> trusted Silver -> Gold / Marts / Semantic
```

Adoption must not silently reinterpret data semantics or replace working transformation SQL merely to match a newer repository shape.

## Phase 1 — current metadata boundary

This change adopts only the current machine-readable source and RAW contract boundary.

Existing reviewed evidence maps directly to:

```text
fleet_mssql.vehicle_status
  pattern: scd2
  RAW: contracts/raw/fleet_mssql/vehicle_status.yml

gtfs_realtime.vehicle_position
  pattern: append
  RAW: contracts/raw/gtfs_realtime/vehicle_position.yml
```

The previous flat RAW paths are removed so `esf validate` has one authoritative source-scoped contract location.

The old `config/datasets/*.yml` files remain temporarily as human migration references only. Their Bronze-to-Silver entries point at the new RAW paths, but they are no longer the authoritative Framework contract.

`config/datasets/depot_fleet_status.yml` is deliberately not converted to a source manifest because it describes a downstream Gold aggregation Dynamic Table, not a Bronze-to-Silver dataset.

## CI boundary

Current Framework contract validation is pinned to immutable Framework 0.25 merge SHA:

```text
b81d0150c96e8bf5bbacee11438971be5df676b6
```

and runs:

```bash
esf validate --project-root .
```

The existing dbt runtime has a separate credential-free CI job that only installs dbt, resolves packages, parses the still-active dbt project offline, and checks migration/readability invariants. It intentionally does **not** run the obsolete Framework v2 metadata validator.

Live PR workspaces are a separate opt-in gate. `.github/workflows/pr-workspace.yml` is pinned to the same Framework 0.25 SHA and runs only when the repository variable below is explicitly enabled:

```text
ESF_PR_WORKSPACE_ENABLED=true
```

The `ci` GitHub Environment must then also define `SNOWFLAKE_ACCOUNT` and an account-scoped `SNOWFLAKE_OIDC_AUDIENCE`. Until those live credentials/configuration exist, PR workspace execution should be skipped rather than reported as a static code failure.

Phase 1 itself does not connect to Snowflake, deploy Control migrations, or execute/scaffold Silver.

## What remains unchanged in phase 1

The following runtime code is intentionally unchanged:

```text
dbt/models/silver_staging/**
dbt/models/silver_canonical/**
dbt/models/gold_marts/**
dbt reset macros
standalone simulator
current deployment workflow/runtime
```

That means phase 1 is a metadata/validation adoption, **not** a production runtime cutover.

## Phase 2 — candidate Silver implementations

After phase 1 is merged and stable, create current Framework Silver candidates for:

```text
fleet_mssql.vehicle_status      -> scd2
gtfs_realtime.vehicle_position  -> append
```

The generated ownership units must be normal Framework source code under `silver_processing/`; existing dbt Silver models must not be deleted in the same step.

Compare candidate outputs against the current dbt Silver outputs using explicit DQ/reconciliation evidence before deciding any cutover.

For `vehicle_status`, preserve the reviewed semantics already present in the RAW contract:

```text
business key: vehicle_id
source timestamp: source_updated_at
ordering: source_updated_at, source_sequence
tombstone delete: source_operation = D
tracked business attributes: status, depot_id, route_id
late evidence: rebuild affected key history
```

Do not infer any additional business rule from the existing SQL unless it is explicitly reviewed.

## Phase 3 — Control Plane and deployment adoption

Only after current Silver ownership units exist should the repository adopt the current Framework deployment workflow, because that workflow requires:

```text
control_plane/deploy_manifest.txt
silver_processing/deploy_manifest.txt
current contract validation
current Control preflight
apply-once migration history
```

At that point initialize/materialize the current Control Plane through migration 140, review `esf control-plan`, and explicitly adopt the manifest. Never replay historical migrations blindly into a populated environment; use the Framework's reviewed baseline path when deployment history is empty but objects already exist.

The deployment workflow should then pin the same reviewed immutable Framework SHA used for the adopted contract version.

## Phase 4 — retire legacy Silver metadata/code

After candidate comparison and an explicit release/cutover, remove or archive the old `config/datasets` Bronze-to-Silver metadata and obsolete dbt Silver models in a separate reviewed change.

Gold `depot_fleet_status` remains downstream business transformation and should continue to be owned by dbt/Gold semantics rather than being misclassified as a source/Silver pipeline.

## Certification

Static CI is not Snowflake certification. Framework 0.25 merge SHA `b81d0150c96e8bf5bbacee11438971be5df676b6` passed Framework static CI, but its automatic Snowflake Framework Certification run was skipped and produced no certification artifact.

This domain adoption therefore must not claim live Snowflake acceptance until a configured environment actually executes the relevant deployment/candidate path successfully.
