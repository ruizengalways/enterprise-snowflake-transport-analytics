# Current Context — Transport Analytics

Updated: 2026-09-11

## Current state

Transport is migrating from the earlier Hybrid Framework v2 shape to the current Enterprise Snowflake Data Project Framework 0.25 architecture.

The current Framework release being adopted is pinned by immutable SHA:

```text
Framework 0.25
b81d0150c96e8bf5bbacee11438971be5df676b6
```

That Framework SHA passed its static main CI, but its automatic Snowflake Framework Certification workflow was **SKIPPED** and produced no certification artifact. Do not describe it as live Snowflake-certified.

## Adoption phase

The current migration is deliberately staged. Phase 1 adopts only the reviewed **metadata/validation boundary**:

```text
config/project.yml
config/sources/<source>.yml
contracts/raw/<source>/<dataset>.yml
```

It does not replace production/reference Silver SQL, initialize the current Control Plane, or switch the deployment workflow.

Current source boundaries are:

```text
fleet_mssql
  -> vehicle_status
  -> pattern: scd2
  -> contracts/raw/fleet_mssql/vehicle_status.yml

gtfs_realtime
  -> vehicle_position
  -> pattern: append
  -> contracts/raw/gtfs_realtime/vehicle_position.yml
```

The existing reviewed RAW contract semantics are preserved; no key/order/delete/business rule is inferred during the path migration.

## Legacy metadata during transition

`config/datasets/*.yml` predates the current Framework source-manifest contract. Those files remain temporarily as human migration references only and must not become a second active machine contract.

`depot_fleet_status.yml` is intentionally not converted to `config/sources`: it describes downstream Gold aggregation rather than a Bronze-to-Silver logical dataset.

See `config/datasets/README.md` and `docs/FRAMEWORK_025_ADOPTION.md`.

## Current runtime remains unchanged in phase 1

The existing dbt Silver implementation remains the comparison/reference runtime:

```text
dbt/models/silver_staging/
dbt/models/silver_canonical/
```

Current dataset semantics remain:

```text
vehicle_status
  source: fleet_mssql full-change CDC evidence
  business key: vehicle_id
  ordering: source_updated_at, source_sequence
  tombstone delete: source_operation = D
  existing reference output: SILVER_CANONICAL vehicle_status history/current

vehicle_position
  source: gtfs_realtime full-event append evidence
  ordering/idempotency: vehicle_id + event_timestamp
  existing reference output: SILVER_CANONICAL vehicle_position

depot_fleet_status
  Gold business aggregation
  current implementation: dbt / Snowflake Dynamic Table
```

Phase 1 does not edit these dbt models, the reset macro, the Gold model, or the standalone simulator.

## CI boundary

Current Framework contract validation is credential-free and pinned to exact Framework 0.25 SHA:

```bash
esf validate --project-root .
```

The legacy dbt runtime has a separate offline parse/readability job. It no longer invokes the obsolete Framework v2 metadata validator; current machine contracts are owned by Framework Contract CI.

Live PR workspace execution is opt-in and pinned to the same Framework 0.25 SHA. It runs only when:

```text
ESF_PR_WORKSPACE_ENABLED=true
```

and the `ci` GitHub Environment provides `SNOWFLAKE_ACCOUNT` plus an account-scoped `SNOWFLAKE_OIDC_AUDIENCE`. Without that configuration the live workspace gate is expected to be skipped, not treated as static acceptance evidence.

## Portable synthetic source

The Framework-independent simulator remains under `standalone/` and is deliberately outside the enterprise Control Plane/runtime contract.

The simulator models source evidence, not SCD2 target behavior. It remains useful for later candidate comparison because it can generate deterministic CDC and append events without requiring the Framework.

## Existing reset adapter

The earlier dbt processing-reset/generation contract remains present while the dbt Silver reference implementation remains active. Phase 1 does not reinterpret or delete it.

When current Framework Silver candidates are introduced, reset/replay behavior must be reviewed separately against the candidate implementation rather than assuming the old dbt macro is automatically portable.

## Next adoption phase

After phase 1 static CI is green and merged:

```text
1. scaffold current Framework Silver candidate for fleet_mssql.vehicle_status (scd2)
2. scaffold current Framework Silver candidate for gtfs_realtime.vehicle_position (append)
3. preserve existing dbt Silver as comparison baseline
4. compare/reconcile candidate outputs against the existing reference outputs
5. only then adopt current Control Plane / apply-once deployment and perform explicit cutover
```

Do not move `depot_fleet_status` into Silver merely because it is a Dynamic Table. It remains Gold.

## Live acceptance gates

No static CI result is live Snowflake proof.

The live path still requires configured Snowflake/GitHub Environment identity. Once available, prove candidate Silver behavior, Control migrations, deployment history, DQ/reconciliation and release/cutover on the exact reviewed project/framework SHAs.

Until then, preserve the current runtime and advance only reviewable, fail-closed migration steps.
