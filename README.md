# Enterprise Snowflake Transport Analytics

Transport data-product repository. The **portable core is framework-independent**: the repository can generate and expose synthetic Transport source data on any Snowflake platform without the enterprise data framework, `PLATFORM_CONTROL`, Terraform, or enterprise-specific RBAC/database naming.

## Start here

1. `standalone/README.md` — run synthetic Transport data on any Snowflake account.
2. `docs/PORTABILITY.md` — portable-core versus optional enterprise-integration boundary.
3. `docs/CURRENT_CONTEXT.md` — current PR stack, CI status and live blockers.
4. `docs/DEPLOYMENT.md` — optional enterprise-platform deployment path.
5. `docs/datasets/vehicle-status.md` — CDC/SCD2/bootstrap reference contract.

## Portable core

The portable core is owned by this repository and must not depend on a shared implementation framework:

```text
contracts/
config/                 domain metadata
standalone/             pure Snowflake SQL synthetic sources
docs/                   domain knowledge and operating guidance
```

To generate demo data, select any Snowflake database/warehouse and run:

```text
standalone/sql/00_setup.sql
standalone/sql/10_generate_vehicle_status.sql
standalone/sql/20_generate_vehicle_position.sql
standalone/sql/90_validate.sql
```

This creates only:

```text
DEMO_TRANSPORT.VEHICLE_STATUS_CDC
DEMO_TRANSPORT.VEHICLE_STATUS_CURRENT
DEMO_TRANSPORT.VEHICLE_POSITION_EVENTS
```

No enterprise framework installation is needed. `Standalone SQL CI` enforces that these scripts contain no `PLATFORM_CONTROL`, enterprise role/warehouse/database names, or framework references.

## Domain contracts

`vehicle_status` is the reference full-change CDC dataset with metadata-driven SCD2 semantics in the enterprise integration. `vehicle_position` is an append/event dataset and is deliberately not modeled as SCD2.

The standalone synthetic tables align with the repository RAW contracts, so another Snowflake platform can use the same source shapes even if it implements ingestion/transforms differently.

## Optional enterprise integration

The existing `dbt/` project and GitHub deployment workflows integrate this portable domain repo with the `enterprise-snowflake` platform. That path may use the enterprise framework for control-plane, deployment, reset, SCD2/bootstrap and WIF conveniences.

It is an **adapter**, not a prerequisite for using the repository or generating demo data. A consumer on another Snowflake platform may ignore the enterprise integration and use the portable contracts/SQL directly.

Enterprise stable databases currently use:

```text
DEV_TRANSPORT / UAT_TRANSPORT / PROD_TRANSPORT
BRONZE / SILVER_STAGING / SILVER_INTERMEDIATE / SILVER_CANONICAL
GOLD_MARTS / GOLD_SEMANTIC / DQ
```

Those names are enterprise-platform conventions, not requirements of the portable core.

## Proof boundary

Standalone CI proves the synthetic SQL has no enterprise-framework/platform dependency and that expected contract columns are present. Enterprise static CI separately proves the optional platform adapter.

Neither static suite is a live Snowflake execution proof. Real Snowflake WIF, grants, cross-domain denial, reset runtime behavior and source CDC semantics remain live integration gates.
