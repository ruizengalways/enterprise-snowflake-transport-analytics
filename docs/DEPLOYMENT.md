# Deployment

Stable deployment promotes one reviewed Git SHA.

The reusable toolkit workflow performs this order:

```text
validate project/RAW/Silver contracts
-> authenticate with account-scoped WIF
-> execute silver_processing/deploy_manifest.txt in committed order
-> dbt debug
-> dbt build Gold/Semantic
```

The workflow does not generate Silver SQL and does not pass dataset metadata into dbt.

`silver_processing/deploy_manifest.txt` is deliberately boring: each non-comment line is a repository-relative `.sql` file under `silver_processing/`. The reusable workflow rejects absolute/path-traversal entries and executes exactly the listed files.

Snowflake Tasks in this repository are created suspended. Deployment does not silently start ingestion-dependent schedules; resume them only after DEV acceptance confirms source cadence, role grants and correctness behavior.

DEV/UAT/PROD use the same immutable project SHA. Environment differences are account/database/identity configuration, not copied SQL branches.

Live WIF acceptance is still outstanding until a real Snowflake environment is configured and successfully exercised.
