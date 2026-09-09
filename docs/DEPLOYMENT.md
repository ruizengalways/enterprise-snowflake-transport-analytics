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

Static CI protects this wrapper boundary: it rejects a manual `git_sha` workflow input, requires the approved framework pin and `github.sha` handoff, and rejects copied WIF/token logic in the domain wrapper.

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

## Promotion semantics

The architectural target remains immutable promotion:

```text
same project SHA
DEV -> UAT -> PROD
```

The current environment-only wrapper proves and deploys the SHA of the ref selected when the manual workflow is started. For the normal browser flow that means the current selected branch head. Therefore it is already suitable for one-click deployment of the current `main` revision, but it is **not yet a complete same-SHA promotion orchestrator**.

If `main` advances after a DEV deployment, starting a later UAT or PROD run from the newer `main` would deploy a different SHA. Do not describe that as promotion of the DEV release.

A later release/promotion workflow should carry forward the exact previously approved/deployed SHA (for example through an immutable release ref or automated deployment record) without introducing DEV/UAT/PROD source branches. That orchestration should be implemented after the live DEV deployment path is proven rather than guessed in static infrastructure now.

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

The next deployment milestone is live DEV. Exact cross-environment promotion orchestration follows that proof.
