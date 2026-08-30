# Vehicle status history

## Why this exists

`vehicle_status` is the first Transport reference dataset used to prove the standard metadata-driven SCD2 and initial-bootstrap paths before a DEV Snowflake account is available.

It is deliberately separate from `vehicle_position`. Vehicle positions are naturally append-oriented events; forcing that feed into SCD2 would make the example less representative and harder to read.

This reference contract is not a claim that a production `fleet_mssql` source is already connected. The source name and columns define the shape we want the reusable pipeline to support. A real source mapping can replace or version the RAW contract later without changing the framework design.

## Where to look

Human explanation lives here under `docs/`.

Machine-readable source truth lives in `contracts/raw/vehicle_status.yml`.

Machine-readable analytical behavior lives in `config/datasets/vehicle_status.yml`.

Reusable SCD2 and bootstrap call generation live in the framework; this repository should not copy those implementations.

Offline machine contract renderers are deliberately thin and separate:

```text
dbt/macros/scd2_contract.sql
dbt/macros/bootstrap_handoff_contract.sql
```

CI renders them without connecting to Snowflake so we can verify that project metadata reaches the intended framework APIs.

## Intended history behavior

The logical entity is a vehicle identified by `vehicle_id`.

Changes to status, depot, or route should create a new history version. Source timestamps and source sequence provide deterministic event ordering but are not themselves treated as business attributes.

A source tombstone closes the active interval. If an older event arrives late, the standard policy is to rebuild the history for only the affected vehicle keys from an append-preserved full-change/full-event relation, rather than patching only the latest row.

The relation used for that rebuild must retain the complete event history needed for an affected vehicle. The RAW contract's landing-retention setting is not automatically proof of that property; production wiring may use a separate durable event ledger. DEV integration must prove the actual retained relation can reconstruct an affected key before checkpoint advancement is allowed.

## Intended initial bootstrap

A transaction-log or comparable full-change feed commonly needs an initial current-state snapshot before steady-state changes can be applied safely.

The RAW machine contract therefore declares:

```text
mode:                    snapshot_then_incremental
snapshot consistency:    at_handoff_position
incremental start:       exclusive
reconciliation required: true
```

For the eventual real `fleet_mssql` implementation, source-specific code must first obtain a resumable source position and a snapshot that is demonstrably consistent with that position. How SQL Server supplies that guarantee is not encoded in generic YAML and is not implemented by this reference contract.

The intended runtime sequence is:

```text
capture source boundary
  -> record BOUNDARY_CAPTURED
  -> land initial snapshot
  -> record SNAPSHOT_LANDED
  -> reconcile snapshot
  -> record SNAPSHOT_VALIDATED
  -> atomically commit steady-state checkpoint + HANDOFF_COMMITTED
  -> start normal CDC strictly after the handoff position
```

The platform control plane rejects starting this initial-bootstrap path if a steady-state checkpoint already exists, and the final handoff must not overwrite a different checkpoint value. Re-seeding an already-running dataset is a different operational problem and should not be hidden inside the initial-bootstrap contract.

## What static CI proves

Before Snowflake exists, CI can prove that the RAW contract and dataset metadata agree, every referenced column exists, the capture has full-change/full-event fidelity, required source and idempotency ordering is preserved, tracked attributes are explicit, tombstone handling is consistent, and the framework renders both the SCD2 and Transport-domain bootstrap APIs.

Static CI also proves that the Transport bootstrap renderer targets only `TRANSPORT_PIPELINE_BOOTSTRAP*` surfaces and does not render direct shared-control DML.

It cannot prove a real SQL Server snapshot/LSN consistency mechanism, Snowflake transaction behavior, retained rebuild history, Streams/Tasks behavior, role grants, concurrency, warehouse performance, or retry behavior. Those remain DEV integration tests once the account is available.
