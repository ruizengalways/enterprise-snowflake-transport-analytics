# Transport repository portability contract

## Goal

A Transport data repository must remain useful outside the enterprise Snowflake platform.

A team must be able to clone this repository, connect to an unrelated Snowflake account, and generate representative source data without installing or knowing about the enterprise data framework.

## Portable core

The portable core is:

```text
contracts/
config/
standalone/
domain documentation
```

Rules for the portable core:

- no dependency on `enterprise-snowflake-data-project-framework`;
- no dependency on `PLATFORM_CONTROL`;
- no Terraform requirement;
- no required `AR_*` role names;
- no required enterprise warehouse names;
- no `DEV_TRANSPORT` / `UAT_TRANSPORT` / `PROD_TRANSPORT` database assumption;
- no GitHub WIF requirement;
- synthetic data must run as ordinary Snowflake SQL in the caller-selected database;
- domain source shapes are owned by this repository's contracts, not by a framework package.

`standalone/tests/test_standalone_sql.py` enforces the most important negative dependencies in CI.

## Optional enterprise adapter

The existing `dbt/` and enterprise GitHub workflows are an adapter for the `enterprise-snowflake` platform. They may depend on shared framework capabilities such as:

```text
PLATFORM_CONTROL integration
Medallion deployment conventions
SCD2/bootstrap helpers
reset/generation control
WIF deployment workflows
```

Those dependencies must not leak into `standalone/` or become prerequisites for consuming the source contracts.

Dependency direction is therefore:

```text
portable Transport domain core
          ↑
optional enterprise adapter
          ↑
enterprise framework/platform
```

The framework may help operate the domain project; it must not own the domain's source contract or be required to create demo data.

## Synthetic source contract

The framework-free demo currently creates:

```text
DEMO_TRANSPORT.VEHICLE_STATUS_CDC
DEMO_TRANSPORT.VEHICLE_STATUS_CURRENT
DEMO_TRANSPORT.VEHICLE_POSITION_EVENTS
```

The CDC/event columns are aligned to:

```text
contracts/raw/vehicle_status.yml
contracts/raw/vehicle_position.yml
```

This allows a different Snowflake platform to build its own Bronze/Silver/Gold, Dynamic Tables, Streams/Tasks, dbt project, Snowpark pipeline, or other implementation on top of the same source shapes.

## What portability does not mean

Portability does not require every platform to use the same schemas, roles, control tables, orchestration, SCD implementation or deployment workflow.

The stable contract is the domain data shape and meaning. Enterprise implementation conventions remain optional.
