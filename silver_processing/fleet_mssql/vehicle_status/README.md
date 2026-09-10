# vehicle_status — SCD2 Silver pattern

Keep the implementation visible in the domain repository.

Reference algorithm:

1. capture new Bronze evidence into the version-local retained event ledger;
2. identify affected business keys;
3. deduplicate source evidence with the RAW contract idempotency key;
4. delete only affected history rows;
5. rebuild those keys deterministically from retained evidence;
6. treat tombstones as history boundaries but not published versions;
7. keep full history in one physical table and expose current state with `IS_ACTIVE = TRUE`.

Each implementation version owns an independent Stream, Task and SQL procedure. Candidate versions remain unpublished until explicit release SQL is reviewed and executed.

## Implementation version

`v1` is a initial implementation using `stream_task`. Semantic pattern remains `scd2`. SQL in this directory is domain-owned after creation.
