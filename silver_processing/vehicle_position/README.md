# vehicle_position — append Silver processing

The Bronze source is an event stream. Silver keeps one row per RAW-contract idempotency key `(vehicle_id, event_timestamp)` and preserves the event payload without turning it into current-state semantics.

`APPLY_VEHICLE_POSITION` is an explicit insert-only procedure. Replaying the same Bronze evidence does not duplicate Silver rows. Conflicting duplicate identities are surfaced by `020_validate.sql`.
