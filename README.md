# Enterprise Snowflake Transport Analytics

This repository is intentionally readable without opening the shared toolkit.

## Data path

```text
external transport sources
  -> ingestion
  -> BRONZE                     raw / replayable evidence
  -> silver_processing/         explicit Snowflake SQL
  -> SILVER_CANONICAL           trusted current/history/events
  -> dbt
  -> GOLD_MARTS                 warehouse models
  -> GOLD_SEMANTIC              semantic models when added
```

## Where to change things

- Source semantics/evidence: `contracts/raw/`
- Bronze-to-Silver correctness: `silver_processing/<dataset>/`
- Business warehouse models: `dbt/models/gold_marts/`
- Operational recovery: `operations/`
- Portable synthetic demo: `standalone/`

There is no Framework dbt package and no custom shared SCD materialization.

## Current datasets

`vehicle_status` is explicit SCD2. Its complete replay/delete/reinsert/late-arrival algorithm is in `silver_processing/vehicle_status/010_apply.sql`; the authoritative history/current objects are in `SILVER_CANONICAL`.

`vehicle_position` is a trusted append event relation maintained by explicit insert-only Silver SQL.

`depot_fleet_status` and `fct_vehicle_position` are ordinary dbt Gold models reading trusted Silver sources. This is where dbt begins in the enterprise data path.

## Reuse

The shared project toolkit validates contracts, provides one-time scaffold patterns, reusable CI/deployment and workspace utilities. It does not generate production Silver SQL at runtime.

## Proof boundary

Static CI can validate contracts, dbt parsing and readable SQL invariants without Snowflake. Live WIF/Snowflake execution remains a separate acceptance gate and must not be inferred from static success.
