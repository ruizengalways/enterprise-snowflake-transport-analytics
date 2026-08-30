# Vehicle status history

## Why this exists

`vehicle_status` is the first Transport reference dataset used to prove the standard metadata-driven SCD2 path before a DEV Snowflake account is available.

It is deliberately separate from `vehicle_position`. Vehicle positions are naturally append-oriented events; forcing that feed into SCD2 would make the example less representative and harder to read.

This reference contract is not a claim that a production `fleet_mssql` source is already connected. The source name and columns define the shape we want the reusable pipeline to support. A real source mapping can replace or version the RAW contract later without changing the framework design.

## Where to look

Human explanation lives here under `docs/`.

Machine-readable source truth lives in `contracts/raw/vehicle_status.yml`.

Machine-readable analytical behavior lives in `config/datasets/vehicle_status.yml`.

Reusable SCD2 SQL generation lives in the framework; this repository should not copy that implementation.

The offline contract renderer is `dbt/macros/scd2_contract.sql`. CI renders it without connecting to Snowflake so we can verify the metadata actually reaches the framework macros.

## Intended history behavior

The logical entity is a vehicle identified by `vehicle_id`.

Changes to status, depot, or route should create a new history version. Source timestamps and source sequence provide deterministic event ordering but are not themselves treated as business attributes.

A source tombstone closes the active interval. If an older event arrives late, the standard policy is to rebuild the history for only the affected vehicle keys from an append-preserved full-change/full-event relation, rather than patching only the latest row.

The relation used for that rebuild must retain the complete event history needed for an affected vehicle. The RAW contract's landing-retention setting is not automatically proof of that property; production wiring may use a separate durable event ledger. DEV integration must prove the actual retained relation can reconstruct an affected key before checkpoint advancement is allowed.

## What static CI proves

Before Snowflake exists, CI can prove that the RAW contract and dataset metadata agree, every referenced column exists, the capture has full-change/full-event fidelity, required source and idempotency ordering is preserved, tracked attributes are explicit, tombstone handling is consistent, and the framework renders both the full history select and affected-key rebuild SQL.

It cannot prove Snowflake transaction semantics, retained rebuild history, Streams/Tasks behavior, role grants, concurrency, warehouse performance, or retry behavior. Those remain DEV integration tests once the account is available.
