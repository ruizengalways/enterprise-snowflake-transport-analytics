# Enterprise Snowflake Transport Analytics

Reference domain project for event-oriented and near-real-time data engineering.

## Current status

The repository is now a thin executable domain shell rather than a README-only placeholder.

Implemented in source/static CI:

```text
config/project.yml
config/datasets/vehicle_position.yml
contracts/raw/vehicle_position.yml

dbt/dbt_project.yml
dbt/packages.yml
dbt/profiles.yml
dbt/macros/target_wrappers.sql

.github/workflows/metadata-ci.yml
.github/workflows/dbt-static-ci.yml
.github/workflows/pr-workspace.yml
```

No live Snowflake dbt run or project-CI workspace execution has happened yet. Kafka Connector and direct Snowpipe Streaming remain intentionally deferred.

## Workload intent

Transport will demonstrate high-frequency events, out-of-order/late data, burst handling, near-real-time freshness, streaming ingestion choices and workload-specific SLOs without forcing downstream redesign when ingestion technology changes.

## Current first dataset contract

`vehicle_position` is the first technical contract:

```text
source_system:       gtfs_realtime
load_strategy:       append_only
business key:        vehicle_id (RAW contract identity field)
watermark:           event_timestamp
change semantics:    append
freshness warning:   5 minutes
freshness error:     15 minutes
contract policy:     versioned_contract
```

The RAW grain is one row per vehicle-position event. Metadata describes stable technical behaviour only; transport business calculations and semantic rules stay explicit project SQL/tests.

## Framework consumption

This repo consumes `enterprise-snowflake-data-project-framework` through immutable revisions.

The framework owns shared metadata validation, workspace/query-tag utilities, dbt physical target resolution, reusable static CI and future generic loading/DQ/reconciliation mechanics.

The Transport repo owns its RAW contracts, dataset configuration, business SQL and later ingestion-specific configuration.

## dbt target model

Model SQL must not hard-code `DEV_TRANSPORT`, `CI_TRANSPORT`, `UAT_TRANSPORT` or `PROD_TRANSPORT`.

The shared resolver supplies:

```text
DEV personal -> DEV_TRANSPORT / WH_TRANSPORT_TRANSFORM / <DEVELOPER>_<LAYER>
PR CI        -> CI_TRANSPORT  / WH_TRANSPORT_CI        / PR_<NUMBER>_<LAYER>
UAT          -> UAT_TRANSPORT / stable layer schemas
PROD         -> PROD_TRANSPORT / stable layer schemas
```

The checked-in profile contains no password/private key. Human DEV defaults to external-browser auth; machine targets use Snowflake workload identity with short-lived OIDC tokens when live execution is enabled.

## CI

`Metadata CI` validates project/dataset/RAW contract metadata using a pinned framework action.

`dbt Static CI` installs pinned dbt versions, resolves an offline CI target, installs the pinned framework package and runs `dbt parse` without connecting to Snowflake.

`PR Workspace` is a thin caller for the framework workspace lifecycle and becomes live only after the DEV project-CI identity/GitHub Environment is applied/configured.

## Future ingestion comparison

Both future paths must converge on the same logical RAW contract:

```text
Transport producer -> direct Snowpipe Streaming -> RAW contract
```

or:

```text
Transport producer -> Kafka -> Snowflake Kafka Connector -> RAW contract
```

Normally one path is active for the comparison. Switching ingestion mechanism must not require downstream dbt redesign.

For current cross-repository status, read `enterprise-snowflake-platform-infra/docs/CURRENT_CONTEXT.md` first, then `docs/PROJECT_BLUEPRINT.md` in that repository.
