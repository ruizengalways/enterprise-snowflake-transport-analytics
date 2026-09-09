create or replace procedure SILVER_CANONICAL.APPLY_VEHICLE_POSITION()
returns varchar
language sql
execute as owner
as
$$
declare
    inserted_rows number default 0;
begin
    insert into SILVER_CANONICAL.VEHICLE_POSITION (
        vehicle_id,
        event_timestamp,
        latitude,
        longitude,
        route_id,
        ingested_at
    )
    with ranked as (
        select
            b.*,
            row_number() over (
                partition by b.vehicle_id, b.event_timestamp
                order by
                    hash(b.latitude, b.longitude, b.route_id) desc,
                    b.ingested_at desc
            ) as identity_rank
        from BRONZE.VEHICLE_POSITION b
        where not exists (
            select 1
            from SILVER_CANONICAL.VEHICLE_POSITION s
            where s.vehicle_id = b.vehicle_id
              and s.event_timestamp = b.event_timestamp
        )
    )
    select
        vehicle_id,
        event_timestamp,
        latitude,
        longitude,
        route_id,
        ingested_at
    from ranked
    where identity_rank = 1;

    inserted_rows := SQLROWCOUNT;
    return 'vehicle_position: inserted ' || inserted_rows || ' events';
end;
$$;
