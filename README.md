# Enterprise Snowflake Transport Analytics

Reference domain project for event-oriented and near-real-time data engineering.

## Current status

This repository is a thin domain project that consumes the shared framework through immutable revisions.

Implemented in source/static CI includes:

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
.github/workflows/deploy.yml
```

No live Snowflake dbt deployment or project-CI workspace execution has happened yet. Kafka Connector and direct Snowpipe Streaming remain intentionally deferred.

## Workload intent

Transport will demonstrate high-frequency events, out-of-order/late data, burst handling, near-real-time freshness, streaming-ingestion choices and workload-specific SLOs without forcing downstream redesign when ingestion technology changes.

## Current first dataset contract

`vehicle_position` is the first technical contract:

```text
source_system:       gtfs_realtime
load_strategy:       append_only
business identity:   vehicle_id
watermark:           event_timestamp
capture archetype:   full_change
capture fidelity:    full_event
checkpoint:          source_position
ordering:            event_timestamp
idempotency:         vehicle_id + event_timestamp
change semantics:    append
freshness warning:   5 minutes
freshness error:     15 minutes
contract policy:     versioned_contract
```

The RAW grain is one row per vehicle-position event. Metadata describes stable technical behaviour only; transport business calculations and semantic rules stay explicit project SQL/tests.

## Framework consumption

The framework owns reusable technical mechanics:

- metadata schemas and semantic validation;
- workspace/query-tag utilities;
- dbt physical target/context resolution;
- standard load/capture/checkpoint/quality primitives;
- reusable SCD consumers where needed by future Transport datasets;
- reusable static CI, PR workspace and stable deployment workflows.

Transport owns its RAW contracts, dataset configuration, business SQL and later ingestion-specific configuration.

The exact currently approved framework SHA is pinned in `dbt/packages.yml` and all workflow callers. Cross-repository release status is tracked centrally in `enterprise-snowflake-platform-infra/docs/CURRENT_CONTEXT.md` rather than duplicated here.

## dbt target model

Model SQL must not hard-code `DEV_TRANSPORT`, `CI_TRANSPORT`, `UAT_TRANSPORT` or `PROD_TRANSPORT`.

The shared resolver supplies:

```text
DEV personal -> DEV_TRANSPORT / WH_TRANSPORT_TRANSFORM / <DEVELOPER>_<LAYER>
PR CI        -> CI_TRANSPORT  / WH_TRANSPORT_CI        / PR_<NUMBER>_<LAYER>
DEV deploy   -> DEV_TRANSPORT / WH_TRANSPORT_TRANSFORM / stable schemas
UAT deploy   -> UAT_TRANSPORT / WH_TRANSPORT_TRANSFORM / stable schemas
PROD deploy  -> PROD_TRANSPORT / WH_TRANSPORT_TRANSFORM / stable schemas
```

The checked-in profile contains no password/private key. Human DEV uses interactive authentication; machine CI/deployment targets use Snowflake workload identity with short-lived GitHub OIDC tokens.

## CI and delivery

`Metadata CI` validates project/dataset/RAW contract metadata using a pinned framework action.

`dbt Static CI` installs pinned dbt/framework dependencies, resolves an offline CI target and runs project parsing/contract checks without connecting to Snowflake.

`PR Workspace` is a thin caller for guarded `PR_<n>_*` workspace creation/drop through `SU_GITHUB_TRANSPORT_CI -> AR_TRANSPORT_CI`. It becomes live only after the DEV project identity and GitHub Environment `ci` are configured.

`Deploy` is a thin manual caller for the framework stable deployment workflow. It accepts `dev`, `uat` or `prod` plus a full project Git SHA. The framework verifies the SHA belongs to `main` history, checks out the exact revision, verifies the dbt framework pin, enters the protected target GitHub Environment and authenticates as `SU_GITHUB_TRANSPORT_DEPLOY -> AR_TRANSPORT_DEPLOY`.

Promotion uses the same reviewed project SHA across DEV -> UAT -> PROD; there are no environment branches.

## Future ingestion comparison

Both future ingestion paths must converge on this same logical RAW contract:

```text
Transport producer -> direct Snowpipe Streaming -> RAW contract
```

or:

```text
Transport producer -> Kafka -> Snowflake Kafka Connector -> RAW contract
```

Normally one path is active for a comparison. Switching ingestion mechanism must not require downstream dbt redesign.

Producer/runtime code belongs in `enterprise-snowflake-demo-source-systems`; Snowflake/project ingestion configuration belongs here when implementation begins.

For current cross-repository status and live blockers, read `enterprise-snowflake-platform-infra/docs/CURRENT_CONTEXT.md` first, then `docs/PROJECT_BLUEPRINT.md` in that repository.
