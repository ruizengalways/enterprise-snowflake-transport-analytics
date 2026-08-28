# Enterprise Snowflake Transport Analytics

Reference data project for an event-oriented, near-real-time workload.

## Workload intent

Transport will demonstrate streaming/event ingestion, high-frequency changes, out-of-order events, burst handling, near-real-time freshness, different SCD2 choices and workload-specific SLOs.

## This repository owns

- Transport project configuration
- Transport dataset metadata
- Transport RAW contracts
- Transport source mappings
- Transport-specific dbt SQL and business rules
- Transport-specific tests and semantic definitions
- Transport-specific Snowpipe Streaming / Kafka Connector configuration when those phases begin

## This repository consumes

Reusable technical behaviour from `enterprise-snowflake-data-project-framework` through versioned dependencies.

## Architecture boundary

Both planned ingestion paths converge on the same logical RAW contract:

```text
Transport generator -> Snowpipe Streaming -> TRANSPORT_RAW
```

and

```text
Transport generator -> Kafka -> Snowflake Kafka Connector -> Snowpipe Streaming -> TRANSPORT_RAW
```

Only one ingestion path should normally be active at once. Switching ingestion mechanism must not require downstream dbt redesign.

Kafka and Snowpipe Streaming are **not implemented during Phase 0**.

The canonical platform architecture is maintained in `enterprise-snowflake-platform-infra/docs/PROJECT_BLUEPRINT.md`.