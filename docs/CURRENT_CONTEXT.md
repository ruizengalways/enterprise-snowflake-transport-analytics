# Current Context

Concise handoff for a new conversation.

## Architectural rule

Transport now has a **framework-independent portable core**. Source contracts and synthetic data generation must work on any Snowflake platform without the enterprise framework, `PLATFORM_CONTROL`, Terraform, WIF, enterprise RBAC, or enterprise database/warehouse naming.

```text
portable Transport core
  contracts/
  config/
  standalone/
  domain docs
        ↑
optional enterprise adapter
  dbt/
  enterprise workflows
        ↑
enterprise framework/platform
```

See `docs/PORTABILITY.md` and `standalone/README.md`.

## Active stack

```text
PR #1 domain operational contract
PR #2 bootstrap handoff
PR #3 Medallion/config/one-click enterprise deploy
PR #4 generation-aware full reset
PR #5 framework-free portable synthetic data
```

PR #5 is stacked on PR #4 while the lower stack remains open.

## Portable demo — PR #5

Run on any caller-selected Snowflake database/warehouse:

```text
standalone/sql/00_setup.sql
standalone/sql/10_generate_vehicle_status.sql
standalone/sql/20_generate_vehicle_position.sql
standalone/sql/90_validate.sql
```

Creates only:

```text
DEMO_TRANSPORT.VEHICLE_STATUS_CDC
DEMO_TRANSPORT.VEHICLE_STATUS_CURRENT
DEMO_TRANSPORT.VEHICLE_POSITION_EVENTS
```

The SQL creates no database/warehouse/role, contains no framework or `PLATFORM_CONTROL` reference, and aligns with the repository RAW contracts.

Verified portability head:

```text
c898d8dec1397a2d51036b3ea4f5c9fb4a944f83
Standalone SQL CI #1: SUCCESS
PR Workspace #37: still blocked by enterprise ci environment configuration
```

The PR Workspace failure belongs to the optional enterprise adapter and does not affect standalone data generation.

## Optional enterprise adapter

Current reset-aware framework pin used only by the enterprise dbt/workflow path:

```text
8afe208bd911a59b9334add78a53878ffea93087
Framework CI #181: SUCCESS
```

Enterprise stable databases use `<ENV>_TRANSPORT` plus Medallion schemas. Those names are not portable-core requirements.

## Reference datasets

`vehicle_status` remains the full-change CDC/SCD2/bootstrap reference dataset. `vehicle_position` remains append/event.

The standalone demo supplies synthetic evidence for both without claiming a live SQL Server or GTFS source.

## Full reset enterprise adapter

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

Same reset ID retries only while `RESETTING`; ready/completed IDs fail before cleanup. See `docs/RESET_RUNBOOK.md`.

Verified lower stack:

```text
Framework reset
8afe208bd911a59b9334add78a53878ffea93087
Framework CI #181: SUCCESS

Platform reset
c20c09c0c5f51dff17ebc5fb3eec75c89c5ce5a2
Terraform CI #167: SUCCESS
Platform Control SQL CI #37: SUCCESS

Transport reset
a649021fa5f84e580361e86d9bf8c66664e581a04
```

Note: the Transport reset SHA above should be read as `649021fa5f84e580361e86d9bf8c66664e581a04`; the leading `a` in this prose is not part of the commit SHA.

dbt Static CI #53: SUCCESS.

## Live boundaries

Portable live acceptance:

```text
plain Snowflake database
no framework package
no PLATFORM_CONTROL
no enterprise roles/naming
 -> execute standalone SQL
 -> verify row counts, keys and CDC operations
```

Enterprise live acceptance separately requires real DEV Snowflake/WIF for grants, control plane, reset generation rollover and pipelines.
