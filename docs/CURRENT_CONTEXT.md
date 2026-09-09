# Current Context — Transport Silver-first architecture

Updated: 2026-09-09

## Canonical boundary

```text
BRONZE -> explicit Snowflake Silver processing -> SILVER_CANONICAL -> dbt -> GOLD/SEMANTIC
```

The old dbt Silver staging/canonical models, Framework package pin, `esf_apply_dataset_config`, custom SCD materialization and dbt reset wrapper are no longer the target architecture.

## Silver

- `vehicle_status`: domain-owned SCD2 procedure + retained event ledger + authoritative history/current view.
- `vehicle_position`: domain-owned append procedure.
- Snowflake Tasks are created suspended and are not live-proven.

## dbt

dbt reads `SILVER_CANONICAL` as sources and builds Gold models only. No Framework package is installed by dbt.

## Toolkit pin

Reusable validation/deployment/workspace workflows pin toolkit merge commit:

`3f264d2446493c6ddfb4c62815e3094f372b92a2`

## Reset

`operations/reset_vehicle_status.sql` is the explicit processing-reset runbook SQL. It preserves Bronze, clears history + retained event ledger, and uses domain-scoped PLATFORM_CONTROL reset procedures.

## Proof boundary

Repository/static proof does not claim live Snowflake execution. DEV WIF, live tasks, SCD scenarios, reset generation and cross-domain authorization remain part of the platform live-acceptance gate.
