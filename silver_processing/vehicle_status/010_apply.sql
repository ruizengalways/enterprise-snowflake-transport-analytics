-- vehicle_status: explicit SCD2 state maintenance.
-- No dbt macro or shared runtime generates this procedure.

create or replace procedure SILVER_CANONICAL.APPLY_VEHICLE_STATUS()
returns varchar
language sql
execute as owner
as
$$
declare
    new_event_count number default 0;
    affected_key_count number default 0;
begin
    -- One representative per source event identity. Conflicting identities are
    -- reported by 020_validate.sql; this deterministic ranking prevents a retry
    -- from multiplying the same source event in Silver.
    create or replace temporary table VEHICLE_STATUS_NEW_EVENTS as
    with ranked as (
        select
            b.vehicle_id,
            b.status,
            b.depot_id,
            b.route_id,
            b.source_updated_at,
            b.source_operation,
            b.source_sequence,
            b.ingested_at,
            row_number() over (
                partition by b.vehicle_id, b.source_sequence
                order by
                    b.source_updated_at desc,
                    hash(b.status, b.depot_id, b.route_id, b.source_operation) desc,
                    b.ingested_at desc
            ) as identity_rank
        from BRONZE.VEHICLE_STATUS b
        where not exists (
            select 1
            from SILVER_CANONICAL.VEHICLE_STATUS_HISTORY__EVENTS e
            where e.vehicle_id = b.vehicle_id
              and e.source_sequence = b.source_sequence
        )
    )
    select * exclude identity_rank
    from ranked
    where identity_rank = 1;

    select count(*) into :new_event_count
    from VEHICLE_STATUS_NEW_EVENTS;

    -- Include ledger keys missing from history as a recovery guard. This lets an
    -- accidentally emptied history table rebuild from retained Silver evidence.
    create or replace temporary table VEHICLE_STATUS_AFFECTED_KEYS as
    select distinct vehicle_id
    from VEHICLE_STATUS_NEW_EVENTS

    union

    select distinct e.vehicle_id
    from SILVER_CANONICAL.VEHICLE_STATUS_HISTORY__EVENTS e
    where not exists (
        select 1
        from SILVER_CANONICAL.VEHICLE_STATUS_HISTORY h
        where h.vehicle_id = e.vehicle_id
    );

    select count(*) into :affected_key_count
    from VEHICLE_STATUS_AFFECTED_KEYS;

    if (affected_key_count = 0) then
        return 'vehicle_status: no new or missing Silver state';
    end if;

    begin transaction;

    insert into SILVER_CANONICAL.VEHICLE_STATUS_HISTORY__EVENTS (
        vehicle_id,
        status,
        depot_id,
        route_id,
        source_updated_at,
        source_operation,
        source_sequence,
        ingested_at
    )
    select
        n.vehicle_id,
        n.status,
        n.depot_id,
        n.route_id,
        n.source_updated_at,
        n.source_operation,
        n.source_sequence,
        n.ingested_at
    from VEHICLE_STATUS_NEW_EVENTS n
    where not exists (
        select 1
        from SILVER_CANONICAL.VEHICLE_STATUS_HISTORY__EVENTS e
        where e.vehicle_id = n.vehicle_id
          and e.source_sequence = n.source_sequence
    );

    delete from SILVER_CANONICAL.VEHICLE_STATUS_HISTORY h
    using VEHICLE_STATUS_AFFECTED_KEYS a
    where h.vehicle_id = a.vehicle_id;

    insert into SILVER_CANONICAL.VEHICLE_STATUS_HISTORY (
        vehicle_id,
        status,
        depot_id,
        route_id,
        source_updated_at,
        source_operation,
        source_sequence,
        ingested_at,
        version_order,
        valid_from,
        valid_to,
        is_current
    )
    with ordered_events as (
        select
            e.*,
            hash(e.status, e.depot_id, e.route_id) as record_hash,
            e.source_operation = 'D' as is_delete,
            row_number() over (
                partition by e.vehicle_id
                order by e.source_updated_at, e.source_sequence
            ) as event_ordinal,
            lag(hash(e.status, e.depot_id, e.route_id)) over (
                partition by e.vehicle_id
                order by e.source_updated_at, e.source_sequence
            ) as previous_record_hash,
            lag(e.source_operation = 'D') over (
                partition by e.vehicle_id
                order by e.source_updated_at, e.source_sequence
            ) as previous_is_delete
        from SILVER_CANONICAL.VEHICLE_STATUS_HISTORY__EVENTS e
        inner join VEHICLE_STATUS_AFFECTED_KEYS a
            on a.vehicle_id = e.vehicle_id
    ),
    state_boundaries as (
        select *
        from ordered_events
        where event_ordinal = 1
           or is_delete
           or coalesce(previous_is_delete, false)
           or not equal_null(record_hash, previous_record_hash)
    ),
    intervalized as (
        select
            state_boundaries.*,
            lead(source_updated_at) over (
                partition by vehicle_id
                order by source_updated_at, source_sequence
            ) as next_boundary_at
        from state_boundaries
    ),
    published_versions as (
        select *
        from intervalized
        where not is_delete
    ),
    numbered_versions as (
        select
            published_versions.*,
            row_number() over (
                partition by vehicle_id
                order by source_updated_at, source_sequence
            ) as published_version_order
        from published_versions
    )
    select
        vehicle_id,
        status,
        depot_id,
        route_id,
        source_updated_at,
        source_operation,
        source_sequence,
        ingested_at,
        published_version_order as version_order,
        source_updated_at as valid_from,
        next_boundary_at as valid_to,
        next_boundary_at is null as is_current
    from numbered_versions;

    commit;

    return 'vehicle_status: applied ' || new_event_count || ' new events across ' || affected_key_count || ' affected vehicles';
exception
    when other then
        rollback;
        raise;
end;
$$;
