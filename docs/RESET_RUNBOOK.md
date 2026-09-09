# vehicle_status processing reset

Use `operations/reset_vehicle_status.sql` for an explicit full **processing** reset.

The reset boundary is intentional:

```text
KEEP
  BRONZE.VEHICLE_STATUS
  platform audit / old generation state

CLEAR
  SILVER_CANONICAL.VEHICLE_STATUS_HISTORY
  SILVER_CANONICAL.VEHICLE_STATUS_HISTORY__EVENTS
```

The script first calls the guarded `TRANSPORT_DATASET_RESET_START`, then truncates the two reconstructable Silver tables one statement at a time, then calls `TRANSPORT_DATASET_RESET_COMPLETE`.

If cleanup fails, do not force completion. The platform lifecycle should remain `RESETTING` so the operator can retry safely. After successful reset completion the dataset is ready for a fresh Silver apply from preserved Bronze evidence.

The script refuses databases outside `DEV_TRANSPORT`, `UAT_TRANSPORT`, `PROD_TRANSPORT`. Run it with the domain recovery role, not a dbt macro.

This runbook is repository/static contract only until live DEV verifies reset generation, grants and retry behavior.
