# Transport Analytics

Transport is a domain project, not an ingestion framework.

```text
external transport sources -> ingestion -> BRONZE
                                      -> SILVER_STAGING
                                      -> SILVER_CANONICAL
                                      -> GOLD_MARTS
```

## What a new engineer should see first

- `config/datasets/vehicle_status.yml`: SCD2 maintenance semantics.
- `config/datasets/vehicle_position.yml`: append-only event semantics.
- `dbt/models/silver_staging/`: readable source-faithful SQL after Bronze.
- `dbt/models/silver_canonical/vehicle_status_history.sql`: authoritative SCD2 input/model.
- `dbt/models/silver_canonical/vehicle_status_current.sql`: one current-state view for all downstream consumers.
- `dbt/models/gold_marts/depot_fleet_status.sql`: readable business aggregation, materialized as a Snowflake Dynamic Table.
- `standalone/`: portable synthetic simulator with zero Framework, PLATFORM_CONTROL, Terraform, or enterprise WIF dependency.

The project follows `Metadata = HOW TO RUN; SQL = WHAT THE DATA MEANS`. Metadata never describes joins, filters, CASE expressions, window functions, or GROUP BY business logic.

## Dataset policies

| Dataset | Silver/Gold role | Load | Materialization | Runtime |
| --- | --- | --- | --- | --- |
| `vehicle_status` | authoritative history | SCD2 | table | dbt |
| `vehicle_position` | event history | append-only | table | dbt |
| `depot_fleet_status` | Gold aggregation | derived | Dynamic Table / ADAPTIVE | Snowflake managed |

Physical warehouse names do not appear in dataset metadata. `compute.workload: transform` is resolved by the platform for each domain/environment.

## Live acceptance

Static CI validates v2 metadata and parses dbt offline. Live Snowflake deployment/reset/SCD2/Dynamic Table acceptance remains gated by configured WIF environments; do not infer live success from static CI.

See `standalone/README.md` for the independent simulator.
