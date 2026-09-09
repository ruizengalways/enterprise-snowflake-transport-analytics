# vehicle_status — SCD2 Silver processing

## Contract

```text
input        BRONZE.VEHICLE_STATUS
business key vehicle_id
order        source_updated_at, source_sequence
identity     vehicle_id, source_sequence
delete       source_operation = 'D'
outputs      SILVER_CANONICAL.VEHICLE_STATUS_HISTORY
             SILVER_CANONICAL.VEHICLE_STATUS_CURRENT
```

## Algorithm

`APPLY_VEHICLE_STATUS` is intentionally ordinary Snowflake SQL in this repository.

1. Find Bronze events that are not already in the retained event ledger.
2. Detect conflicting source-event identities deterministically; `020_validate.sql` surfaces them as a contract violation.
3. Build the set of affected `vehicle_id` values.
4. In one transaction, append new events to the ledger, delete only affected history rows, and rebuild those keys from the complete retained event stream.
5. Treat a tombstone as a state boundary but do not publish it as a history version.
6. Build `valid_to` from the next state boundary, then number only published non-delete versions.
7. Publish current state through a normal view filtering `is_current`.

This makes replay a no-op, closes history on delete, supports reinsert after delete, and corrects late-arriving events by rebuilding only affected vehicles.

## Operational assumption

There is one logical writer for this dataset. The scheduled Snowflake Task is created suspended; resume it only after DEV acceptance. If higher write concurrency is required later, introduce an explicit single-writer/locking design rather than hiding concurrency inside a shared framework.

## Performance

The correctness-first implementation scans Bronze to discover unseen event identities. For a high-volume production source, replace only the discovery step with a Snowflake Stream or landed-data checkpoint after proving equivalent replay/reset semantics. The history algorithm should remain locally readable.
