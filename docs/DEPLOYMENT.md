# Deployment

## Preferred operator experience

Stable deployment is intentionally thin in this repository.

After the desired revision is merged to `main`:

1. Open **GitHub Actions**.
2. Select **Deploy**.
3. Ensure the workflow is being run from `main`.
4. Choose `dev`, `uat` or `prod`.
5. Select **Run workflow**.

There is no project SHA text box. The wrapper passes the selected workflow revision (`github.sha`) to the reusable framework workflow, which independently verifies that the SHA is reachable from current `main` history.

## What the reusable workflow does

```text
validate immutable project/framework revisions
  -> enter protected GitHub Environment
  -> load SNOWFLAKE_ACCOUNT + account-scoped SNOWFLAKE_OIDC_AUDIENCE
  -> checkout project main history and exact requested revision
  -> verify dbt package pin == framework revision
  -> validate Git project/dataset/RAW metadata
  -> resolve DEV/UAT/PROD database, warehouse and SILVER_STAGING default
  -> build bounded dbt vars + deterministic dataset config snapshots
  -> request short-lived Snowflake WIF token
  -> dbt debug
  -> dbt build
  -> register config snapshots through TRANSPORT-scoped owner-rights procedures
```

Config snapshots are registered only after `dbt build` succeeds.

## Required platform/GitHub setup

Each protected GitHub Environment (`dev`, `uat`, `prod`) must define:

```text
SNOWFLAKE_ACCOUNT
SNOWFLAKE_OIDC_AUDIENCE
```

The corresponding Snowflake account must already contain the platform-managed identities and runtime surfaces, including:

```text
SU_GITHUB_TRANSPORT_DEPLOY
AR_TRANSPORT_DEPLOY
WH_TRANSPORT_TRANSFORM
<ENV>_TRANSPORT with Medallion schemas
PLATFORM_CONTROL.OPERATIONS.TRANSPORT_*
PLATFORM_CONTROL.CONFIG.TRANSPORT_*
```

The platform-infra repository owns those objects. This domain repository does not bootstrap account-level infrastructure.

## Promotion

Promote the same project Git revision across environments:

```text
same SHA
DEV -> UAT -> PROD
```

Do not use environment branches or rebuild different source revisions for each environment.

## Fail-closed behavior

Deployment fails when any of these invariants is not met:

- requested revision is not reachable from `main`;
- project `dbt/packages.yml` does not pin the exact framework SHA used by the workflow;
- metadata validation fails;
- protected environment WIF variables are absent/invalid;
- Snowflake identity/grants are not ready;
- `dbt build` fails;
- dataset config snapshot registration fails.

A failed build does not create a successful deployment config snapshot.

## Current live boundary

The workflow is implemented, but live execution still depends on the real Snowflake DEV/UAT/PROD accounts and GitHub Environment WIF configuration. Static CI success is not a claim that a live deployment has already occurred.
