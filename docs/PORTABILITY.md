# Transport portability contract

The portable synthetic core remains `contracts/` + `standalone/` and does not require the enterprise toolkit, `PLATFORM_CONTROL`, Terraform, WIF, enterprise role names or enterprise warehouse names.

The enterprise implementation is deliberately visible in this repository rather than supplied by a runtime framework:

```text
silver_processing/  domain-owned Bronze -> Silver SQL
dbt/                ordinary Silver -> Gold/Semantic modeling
operations/         explicit enterprise recovery scripts
.github/             optional enterprise CI/deployment adapter
```

A non-enterprise consumer can ignore those directories, use the same source contracts/synthetic data, and implement its own Bronze/Silver/Gold conventions.

The stable portable contract is the source data shape and meaning. SCD implementation, schemas, roles, orchestration, control tables and deployment workflows are platform choices.

`standalone/tests/test_standalone_sql.py` continues to enforce the important negative dependencies for the synthetic demo core.
