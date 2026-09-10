# Transport Analytics

Transport is a business-domain data project, not an ingestion framework.

This repository is currently adopting the Enterprise Snowflake Data Project Framework 0.25 in stages. The first stage changes the **metadata/validation boundary only**; it does not cut production Silver runtime over from the existing dbt implementation.

## Current Framework metadata boundary

Reviewed source/RAW semantics now live in the current source-scoped contract:

```text
config/project.yml
config/sources/fleet_mssql.yml
config/sources/gtfs_realtime.yml
contracts/raw/fleet_mssql/vehicle_status.yml
contracts/raw/gtfs_realtime/vehicle_position.yml
```

The two Bronze-to-Silver logical datasets are:

| Source | Dataset | Pattern | Reviewed evidence |
| --- | --- | --- | --- |
| `fleet_mssql` | `vehicle_status` | SCD2 | business key, ordering, tombstone delete, full-change fidelity |
| `gtfs_realtime` | `vehicle_position` | append | event timestamp, ordering/idempotency, full-event fidelity |

`config/datasets/*.yml` predates the current Framework contract and is retained temporarily as migration reference only. Do not add new Framework behavior there. See `config/datasets/README.md`.

## Runtime transition

The existing dbt Silver code is deliberately still present during phase 1:

```text
dbt/models/silver_staging/
dbt/models/silver_canonical/
```

Those models remain the current comparison/reference implementation until separate Framework Silver candidates are scaffolded and reconciled. This PR does not silently rewrite or delete them.

The intended target boundary is:

```text
source-specific ingestion
  -> BRONZE
  -> Framework-owned, explicit Silver implementation under silver_processing/
  -> trusted SILVER
  -> dbt Gold / Marts / Semantic
```

The next adoption phase will scaffold candidate Silver implementations for `fleet_mssql.vehicle_status` and `gtfs_realtime.vehicle_position`, then compare them with the existing dbt Silver results before any cutover.

## Gold remains Gold

`dbt/models/gold_marts/depot_fleet_status.sql` is downstream business aggregation. Its Dynamic Table execution is a Gold implementation detail and is **not** being reclassified as a source-manifest/Silver dataset merely to make repository shapes uniform.

## Validation

Framework contract CI is pinned to immutable Framework 0.25 merge SHA:

```text
b81d0150c96e8bf5bbacee11438971be5df676b6
```

and runs:

```bash
esf validate --project-root .
```

This stage is credential-free and does not deploy Snowflake objects.

## Deployment and live acceptance

The existing deployment workflow is intentionally unchanged in phase 1 because the current Framework deploy contract requires a fully adopted `control_plane/` and `silver_processing/` migration boundary. Switching deployment before those ownership units exist would create a half-migrated runtime.

Static CI is not Snowflake certification. Framework 0.25 passed its static CI, but the automatic Snowflake Framework Certification run for that SHA was skipped and produced no certification artifact.

See `docs/FRAMEWORK_025_ADOPTION.md` for the staged migration plan and `standalone/README.md` for the independent simulator.
