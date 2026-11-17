begin;

create table if not exists public.booking_checkouts (
    id uuid primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    kind text not null check (kind in ('trial', 'rental')),
    amount_paise bigint not null check (amount_paise > 0),
    razorpay_order_id text not null unique,
    booking jsonb not null,
    payment_id text unique,
    result jsonb,
    created_at timestamptz not null default now(),
    check ((payment_id is null) = (result is null))
);

alter table public.booking_checkouts enable row level security;
revoke all on public.booking_checkouts from public, anon, authenticated;
grant select, insert on public.booking_checkouts to service_role;

create or replace function public.finalize_booking_checkout(
    checkout_id uuid,
    customer_id uuid,
    verified_payment_id text
) returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
    checkout public.booking_checkouts%rowtype;
    item jsonb;
    rental_result jsonb;
    rental_id uuid;
    rental_ids jsonb := '[]'::jsonb;
    booked_items jsonb := '[]'::jsonb;
    trial_requests jsonb;
    booking_result jsonb;
begin
    select * into strict checkout
    from public.booking_checkouts c
    where c.id = checkout_id and c.user_id = customer_id
    for update;

    if checkout.result is not null then
        if checkout.payment_id <> verified_payment_id then
            raise exception 'Checkout already paid';
        end if;
        return checkout.result;
    end if;

    if checkout.kind = 'trial' then
        with inserted as (
            insert into public.trial_requests (
                booking_reference, user_id, outfit_id, vendor_id, user_name,
                outfit_name, selected_size, preferred_trial_date,
                preferred_time_slot, trial_address, status, payment_status,
                payment_method, payment_reference, trial_fee, platform_fee, trial_amount
            )
            select checkout.id, trial_row.user_id, trial_row.outfit_id, trial_row.vendor_id, trial_row.user_name,
                trial_row.outfit_name, trial_row.selected_size, trial_row.preferred_trial_date,
                trial_row.preferred_time_slot, trial_row.trial_address, 'pending', 'successful',
                'razorpay', verified_payment_id, trial_row.trial_fee, trial_row.platform_fee, trial_row.trial_amount
            from jsonb_populate_recordset(null::public.trial_requests, checkout.booking->'rows') as trial_row
            returning *
        )
        select jsonb_agg(to_jsonb(inserted)) into trial_requests from inserted;

        if trial_requests is null then
            raise exception 'No trial requests were created';
        end if;

        booking_result := jsonb_build_object(
            'success', true,
            'message', 'Trial booking created successfully',
            'booking_reference', checkout.id,
            'payment_status', 'successful',
            'total_outfits', jsonb_array_length(trial_requests),
            'total_amount', checkout.amount_paise / 100.0,
            'requests', trial_requests
        );
    else
        -- Serialize checkouts for the same outfits in a consistent lock order.
        perform 1
        from public.outfits o
        where o.id in (
            select (entry->>'outfit_id')::uuid
            from jsonb_array_elements(checkout.booking->'items') as entry
        )
        order by o.id
        for update;

        for item in select value from jsonb_array_elements(checkout.booking->'items')
        loop
            if not exists (
                select 1 from public.outfits o
                where o.id = (item->>'outfit_id')::uuid
                and o.status = 'published'
                and o.is_available
                and o.rental_price = (item->>'quoted_rate')::numeric
                and coalesce(o.security_deposit, 0) = (item->>'quoted_deposit')::numeric
            ) then
                raise exception 'Rental price or availability changed';
            end if;

            -- The existing RPC accepts a single outfit per call.
            -- The enclosing transaction commits all rentals and the payment together.
            rental_result := public.create_rental_booking(
                p_user_id => checkout.user_id,
                p_booking_reference => checkout.id::text,
                p_items => jsonb_build_array(item - 'quoted_rate' - 'quoted_deposit'),
                p_payment_method => 'razorpay',
                p_transaction_reference => verified_payment_id,
                p_platform_fee_per_outfit => (checkout.booking->>'platform_fee_per_outfit')::numeric,
                p_delivery_address => checkout.booking->'delivery_address'
            );
            rental_id := (rental_result->'rental_ids'->>0)::uuid;
            if not coalesce((rental_result->>'success')::boolean, false) or rental_id is null then
                raise exception 'An outfit could not be booked';
            end if;
            rental_ids := rental_ids || jsonb_build_array(rental_id);
            booked_items := booked_items || jsonb_build_array(
                (item - 'quoted_rate' - 'quoted_deposit') || jsonb_build_object(
                    'rental_id', rental_id,
                    'status', 'pending',
                    'message', 'Rental request successfully placed.'
                )
            );
        end loop;

        if jsonb_array_length(rental_ids) = 0 then
            raise exception 'No rental requests were created';
        end if;

        booking_result := jsonb_build_object(
            'success', true,
            'partial_success', false,
            'booking_reference', checkout.id,
            'transaction_reference', verified_payment_id,
            'total_outfits', jsonb_array_length(rental_ids),
            'successful_count', jsonb_array_length(rental_ids),
            'failed_count', 0,
            'rental_ids', rental_ids,
            'successful_items', booked_items,
            'failed_items', '[]'::jsonb,
            'message', 'Rental booking confirmed'
        );
    end if;

    update public.booking_checkouts
    set payment_id = verified_payment_id,
        result = booking_result,
        booking = jsonb_set(booking, '{payment_status}', '"paid"'::jsonb)
    where id = checkout.id;
    return booking_result;
end;
$$;

revoke all on function public.finalize_booking_checkout(uuid, uuid, text)
    from public, anon, authenticated;
grant execute on function public.finalize_booking_checkout(uuid, uuid, text)
    to service_role;

-- Add the status to existing checkouts based on their saved confirmation.
update public.booking_checkouts
set booking = jsonb_set(
    booking,
    '{payment_status}',
    to_jsonb(case when payment_id is not null then 'paid' else 'pending' end)
)
where booking->>'payment_status' is distinct from
    (case when payment_id is not null then 'paid' else 'pending' end);

commit;

