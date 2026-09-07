# Current Context

Concise handoff for a new conversation.

## Architectural rule added on this branch

The Transport data repository now has a **framework-independent portable core**. Synthetic data generation must work on any Snowflake platform without the enterprise framework, `PLATFORM_CONTROL`, Terraform, WIF, enterprise RBAC, or enterprise database/warehouse naming.

```text
portable domain core
  contracts/
  config/
  standalone/
  domain docs
        ↑
optional enterprise adapter
  dbt/
  enterprise GitHub workflows
        ↑
enterprise framework/platform
```

The framework is an optional operating/deployment adapter. It must not own Transport source contracts or be required to generate demo data.

See `docs/PORTABILITY.md` and `standalone/README.md`.

## Active stack

```text
PR #1  feature/domain-operational-contract
PR #2  feature/bootstrap-handoff-contract
PR #3  feature/medallion-one-click-deploy
PR #4  feature/dataset-reset-generation
feature/standalone-synthetic-data
  framework-free source simulation + portability contract
```

The standalone branch is intentionally stacked on the reset branch while the earlier stack is still open.

## Framework-free demo

Run these SQL files in any caller-selected Snowflake database:

```text
standalone/sql/00_setup.sql
standalone/sql/10_generate_vehicle_status.sql
standalone/sql/20_generate_vehicle_position.sql
standalone/sql/90_validate.sql
```

They create only:

```text
DEMO_TRANSPORT.VEHICLE_STATUS_CDC
DEMO_TRANSPORT.VEHICLE_STATUS_CURRENT
DEMO_TRANSPORT.VEHICLE_POSITION_EVENTS
```

The SQL does not create/switch database, warehouse or role. It contains no enterprise framework or `PLATFORM_CONTROL` reference. `vehicle_status` and `vehicle_position` columns align with this repo's RAW contracts.

`Standalone SQL CI` statically enforces the negative dependency boundary and expected source columns. Live Snowflake execution is still a separate proof gate.

## Optional enterprise framework pin

The enterprise adapter currently uses reset-aware framework SHA:

```text
8afe208bd911a59b9334add78a53878ffea93087
Framework CI #181: SUCCESS
```

This pin is **not required by `standalone/`**.

## Enterprise database/control contract

When used on the enterprise platform, stable databases use:

```text
<ENV>_TRANSPORT
  BRONZE
  SILVER_STAGING
  SILVER_INTERMEDIATE
  SILVER_CANONICAL
  GOLD_MARTS
  GOLD_SEMANTIC
  DQ
```

Enterprise runtime/config/reset surfaces remain under domain-scoped `PLATFORM_CONTROL` views/procedures. Those are adapter conventions, not portable-core requirements.

## Reference datasets

`vehicle_status` remains the reference full-change CDC/SCD2/bootstrap dataset. `vehicle_position` remains an append/event dataset.

The portable demo supplies synthetic source evidence for both without claiming a live SQL Server or GTFS source connection.

## Full reset

Enterprise incident recovery remains separate from portability:

```text
role: AR_TRANSPORT_RECOVERY
operation: transport_vehicle_status_full_reset
ACTIVE generation N
  -> RESETTING
  -> explicit Bronze/Silver/Gold cleanup
  -> generation N+1 / READY_FOR_INITIAL_LOAD
  -> normal pipeline success
  -> ACTIVE
```

Old generations remain auditable. Same reset ID is retryable only while `RESETTING`; an already ready/completed ID is rejected before cleanup. See `docs/RESET_RUNBOOK.md`.

## Verified lower-stack proof

```text
Framework reset implementation
8afe208bd911a59b9334add78a53878ffea93087
Framework CI #181: SUCCESS

Platform reset implementation
c20c09c0c5f51dff17ebc5fb3eec75c89c5ce5a2
Terraform CI #167: SUCCESS
Platform Control SQL CI #37: SUCCESS

Transport reset contract
649021fa5f84e580361e86d9bf8c66664e581a04
dbt Static CI #53: SUCCESS
PR Workspace #34: FAILURE before Snowflake execution at approved-environment configuration
```

The current portability branch has newer commits and must establish its own `Standalone SQL CI` proof after its PR is opened.

## Live boundary

Do not claim live enterprise deployment yet. Real DEV Snowflake/WIF remains required for enterprise grants, cross-domain denial, reset generation rollover and real pipelines.

Separately, the standalone synthetic path should eventually be executed once against a plain Snowflake database with no enterprise framework objects present; that will be the live portability acceptance proof.
