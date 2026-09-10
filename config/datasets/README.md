# Legacy dataset metadata

The YAML files in this directory predate the current Enterprise Snowflake Framework contract and are retained temporarily as migration/reference material.

They are **not** the current Framework machine contract.

Current Framework metadata lives at:

```text
config/project.yml
config/sources/<source>.yml
contracts/raw/<source>/<dataset>.yml
```

For the two Bronze-to-Silver datasets currently being adopted:

```text
fleet_mssql.vehicle_status
  -> config/sources/fleet_mssql.yml
  -> contracts/raw/fleet_mssql/vehicle_status.yml

gtfs_realtime.vehicle_position
  -> config/sources/gtfs_realtime.yml
  -> contracts/raw/gtfs_realtime/vehicle_position.yml
```

`depot_fleet_status.yml` describes a Gold aggregation Dynamic Table and is not being converted into a Silver source-manifest dataset. Gold remains downstream dbt/business transformation.

Do not add new runtime policy, business logic, SLA rules, or source declarations here. During the migration period these files remain only to explain the previous v2 design and to support review against the current contracts.

The existing dbt Silver models are also retained during the transition. A later, separate change can scaffold candidate Silver implementations from the current source/RAW contracts and compare them with the existing dbt outputs before any runtime cutover.
