-- ============================================================================
-- MIGRATION 20261117000400 — rental checkout reservation + stale-checkout expiry
-- Attirely / Razorpay integration — Phase 2 (DATABASE DESIGN — DO NOT EXECUTE
-- until reviewed and approved).
--
-- Purpose:
--   init_rental_checkout   - NEW function. Reserves ALL rental items of one
--                            checkout in ONE transaction with
--                            payment_status='pending'. The existing
--                            create_rental_booking overloads are NOT modified
--                            (see design doc §Existing Functions) and remain
--                            untouched as the rollback path.
--   expire_stale_checkouts - releases inventory reserved by abandoned
--                            checkouts. Called lazily by every checkout-init
--                            function and optionally scheduled by pg_cron
--                            (migration 20261117000900).
--
-- Why a new function instead of modifying create_rental_booking:
--   - The legacy function inserts payment_status='success', paid_at=NOW() and a
--     dummy transaction reference; payments must stay pending until Razorpay
--     verification.
--   - The backend calls it ONCE PER ITEM (separate transactions), which allows
--     partially-booked checkouts. A real payment must reserve all items
--     atomically: any item failure rolls back the whole reservation.
--   - Platform fee now comes from payment_fee_settings, not a parameter.
--
-- Expiry design (see design doc §Expiry):
--   - Rentals with status 'pending' + payment_status 'pending' block the same
--     outfit+size for other customers via the existing exclusion constraint.
--   - Exclusion constraints cannot reference NOW(), so expiry is enforced by
--     expiring payments.expires_at in this function and cancelling the
--     corresponding reservations with EXISTING rental status values
--     ('cancelled'), which releases the exclusion constraint.
--   - No new rental status vocabulary is introduced.
--
-- Rollback:
--   drop function if exists public.init_rental_checkout(uuid, uuid, jsonb, jsonb);
--   drop function if exists public.expire_stale_checkouts();
--   drop function if exists public.expire_orphan_reservations();
--   drop index if exists public.rentals_pending_created_idx;
--   drop index if exists public.trial_requests_pending_created_idx;
--   (Dropping a function also drops its grants.)
--
-- CORRECTIONS (Phase 2 review):
--   1. init_rental_checkout now validates outfit publication ('published')
--      and availability (is_available is true), mirroring /trials/book.
--   2. All three functions are SECURITY DEFINER; EXECUTE is revoked from
--      public/anon/authenticated and granted to service_role only (see the
--      security section at the end of this file). None of these functions
--      may be exposed to clients: they accept caller-supplied user ids and
--      must only be invoked by the backend service after authentication.
--
-- CORRECTION (Phase 2 round 2):
--   3. init_rental_checkout now ALSO calls expire_orphan_reservations()
--      lazily. Orphan reservations (created before a Razorpay order could be
--      registered) previously relied on the OPTIONAL pg_cron schedule; when
--      pg_cron is unavailable they stayed pending indefinitely, holding
--      inventory via the exclusion constraint. The 1-day grace period inside
--      expire_orphan_reservations keeps the lazy call harmless.
--   4. Partial indexes on rentals/trial_requests (pending + created_at) keep
--      both lazy cleanup scans cheap even as bookings accumulate. Plain
--      CREATE INDEX (not CONCURRENTLY): brief write lock while building,
--      acceptable for a one-off migration.
-- ============================================================================

create or replace function public.expire_stale_checkouts()
returns integer
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_expired_payments integer := 0;
    v_rentals_released integer := 0;
    v_trials_marked    integer := 0;
begin
    -- ------------------------------------------------------------------
    -- 1. Expire payments that are still awaiting payment past expires_at.
    --    'authorized' payments are deliberately EXCLUDED: the gateway may
    --    still capture them; expiring an authorized payment would lose money.
    -- ------------------------------------------------------------------
    with expired as (
        update public.payments
           set payment_status = 'expired',
               metadata = metadata || jsonb_build_object('expired_at', now())
         where payment_status in ('created', 'pending', 'failed')
           and expires_at < now()
        returning id, booking_reference, checkout_type
    )
    select count(*) into v_expired_payments from expired;

    if v_expired_payments = 0 then
        return 0;
    end if;

    -- ------------------------------------------------------------------
    -- 2. Release rental reservations of expired payments.
    --    Uses the existing 'cancelled' status + existing payment_status
    --    value 'failed'. cancelled_by_role = 'system' (free-text column;
    --    no CHECK constraint observed — see design doc §Assumptions).
    --    The trg_customer_rental_refund trigger does not fire: it only
    --    reacts to cancelled_by_role = 'customer'.
    -- ------------------------------------------------------------------
    update public.rentals r
       set status               = 'cancelled',
           cancellation_reason  = 'Payment was not completed within the reservation window',
           cancelled_by_role    = 'system',
           cancelled_at         = now(),
           payment_status       = 'failed',
           updated_at           = now()
      from public.payments p
     where p.booking_reference = r.booking_reference
       and p.payment_status    = 'expired'
       and r.status            = 'pending'
       and r.payment_status    = 'pending';
    get diagnostics v_rentals_released = row_count;

    -- ------------------------------------------------------------------
    -- 3. Trial reservations of expired payments.
    --    trial_requests has no 'cancelled' status vocabulary in use, so no
    --    new status value is introduced: the request stays 'pending' but is
    --    marked payment_status='failed'. It is not confirmable afterwards
    --    (confirm_razorpay_payment only confirms payment_status='pending'
    --    rows — a retried checkout always creates fresh rows).
    -- ------------------------------------------------------------------
    update public.trial_requests t
       set payment_status = 'failed'
      from public.payments p
     where p.booking_reference = t.booking_reference
       and p.payment_status    = 'expired'
       and t.payment_status    = 'pending';
    get diagnostics v_trials_marked = row_count;

    return v_rentals_released + v_trials_marked;
end;
$function$;

-- ---------------------------------------------------------------------------
-- Orphan cleanup: reservations created by an init function whose payment row
-- was never registered (process crash between reservation and Razorpay order
-- creation). Runs on the same schedule; the 1-day grace period keeps it out
-- of the way of normal flows.
-- ---------------------------------------------------------------------------
create or replace function public.expire_orphan_reservations()
returns integer
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_rentals_released integer := 0;
    v_trials_marked    integer := 0;
begin
    update public.rentals r
       set status              = 'cancelled',
           cancellation_reason = 'Checkout abandoned before payment order creation',
           cancelled_by_role   = 'system',
           cancelled_at        = now(),
           payment_status      = 'failed',
           updated_at          = now()
     where r.status           = 'pending'
       and r.payment_status   = 'pending'
       and r.created_at       < now() - interval '1 day'
       and not exists (
             select 1
               from public.payments p
              where p.booking_reference = r.booking_reference
           );
    get diagnostics v_rentals_released = row_count;

    update public.trial_requests t
       set payment_status = 'failed'
     where t.payment_status = 'pending'
       and t.created_at     < now() - interval '1 day'
       and not exists (
             select 1
               from public.payments p
              where p.booking_reference = t.booking_reference
           );
    get diagnostics v_trials_marked = row_count;

    return v_rentals_released + v_trials_marked;
end;
$function$;

-- ---------------------------------------------------------------------------
-- init_rental_checkout
-- Reserves every rental item of ONE checkout atomically (payment_status
-- 'pending', no paid_at, no transaction reference) and returns the
-- server-calculated amounts. Validation logic mirrors the ACTIVE overload of
-- create_rental_booking (the 7-argument one with p_delivery_address).
-- ---------------------------------------------------------------------------
create or replace function public.init_rental_checkout(
    p_user_id           uuid,
    p_booking_reference uuid,
    p_items             jsonb,
    p_delivery_address  jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_item              jsonb;
    v_outfit            public.outfits%rowtype;
    v_outfit_id         uuid;
    v_rental_id         uuid;
    v_vendor_id         uuid;
    v_size              text;
    v_outfit_image_url  text;
    v_start_date        date;
    v_return_date       date;
    v_days              integer;
    v_rental_amount     numeric(12,2);
    v_deposit           numeric(12,2);
    v_platform_fee      numeric(10,2);
    v_item_total        numeric(12,2);
    v_total             numeric(12,2) := 0;
    v_items_out         jsonb := '[]'::jsonb;
    v_count             integer := 0;
begin
    -- Release inventory held by abandoned checkouts before reserving new items.
    -- CORRECTION (Phase 2 round 2): orphan reservations (checkout crashed
    -- before the Razorpay order was registered) are cleaned up lazily too,
    -- so correctness does not depend on the OPTIONAL pg_cron schedule.
    perform public.expire_stale_checkouts();
    perform public.expire_orphan_reservations();

    -- Validate customer
    if not exists (select 1 from public.users where id = p_user_id) then
        raise exception 'Customer account not found';
    end if;

    -- Validate delivery address
    if p_delivery_address is null
       or jsonb_typeof(p_delivery_address) <> 'object'
       or p_delivery_address = '{}'::jsonb
    then
        raise exception 'Valid delivery address is required';
    end if;

    -- Validate booking input
    if p_items is null
       or jsonb_typeof(p_items) <> 'array'
       or jsonb_array_length(p_items) = 0
       or jsonb_array_length(p_items) > 20
    then
        raise exception 'Invalid rental items';
    end if;

    -- Duplicate checkout guard: one checkout per booking reference.
    if exists (
        select 1
          from public.payments
         where booking_reference = p_booking_reference
    ) then
        raise exception 'A payment checkout already exists for this booking reference';
    end if;

    -- Platform fee from database configuration (never trusted from the client).
    v_platform_fee := public.get_platform_fee('rental_platform_fee');

    for v_item in
        select value
          from jsonb_array_elements(p_items)
    loop
        v_outfit_id   := (v_item->>'outfit_id')::uuid;
        v_size        := nullif(trim(v_item->>'selected_size'), '');
        v_start_date  := (v_item->>'rental_start_date')::date;
        v_days        := (v_item->>'rental_days')::integer;

        if v_outfit_id is null
           or v_size is null
           or v_start_date is null
           or v_days is null
           or v_days <= 0
           or v_days > 365
        then
            raise exception 'Invalid rental details';
        end if;

        -- Lock outfit while processing the reservation
        select *
          into v_outfit
          from public.outfits
         where id = v_outfit_id
         for update;

        if not found then
            raise exception 'Outfit % not found', v_outfit_id;
        end if;

        -- Cover image (fallback to first image) — same rule as the legacy function.
        select oi.image_url
          into v_outfit_image_url
          from public.outfit_images oi
         where oi.outfit_id = v_outfit.id
         order by
             oi.is_cover desc,
             oi.display_order asc,
             oi.created_at asc
         limit 1;

        -- Prevent users from renting their own outfits
        if v_outfit.uploaded_by = p_user_id then
            raise exception 'You cannot rent your own outfit';
        end if;

        -- CORRECTION (Phase 2 review): validate publication and availability,
        -- mirroring the /trials/book validation. A reservation of an
        -- unpublished or unavailable outfit must be impossible.
        if v_outfit.status <> 'published' then
            raise exception '% is not published', v_outfit.name;
        end if;

        if v_outfit.is_available is not true then
            raise exception '% is currently unavailable', v_outfit.name;
        end if;

        -- Validate size
        if v_outfit.sizes is null
           or not (v_outfit.sizes ? v_size)
        then
            raise exception
                'Selected size % is unavailable for outfit %',
                v_size, v_outfit.name;
        end if;

        -- Identify outfit owner
        if v_outfit.role = 'vendor' then
            select id
              into v_vendor_id
              from public.vendors
             where auth_user_id = v_outfit.uploaded_by;

            if not found then
                raise exception
                    'Vendor profile not found for outfit %',
                    v_outfit.name;
            end if;
        elsif v_outfit.role = 'user' then
            v_vendor_id := null;
        else
            raise exception 'Invalid outfit ownership role';
        end if;

        -- Calculate dates (inclusive)
        v_return_date := v_start_date + (v_days - 1);

        -- Calculate amounts from database values only
        v_rental_amount := v_outfit.rental_price * v_days;
        v_deposit       := coalesce(v_outfit.security_deposit, 0);
        v_item_total    := v_rental_amount + v_deposit + v_platform_fee;

        -- Reserve: pending payment, no paid_at, no transaction reference.
        insert into public.rentals (
            booking_reference,
            user_id,
            outfit_id,
            outfit_owner_user_id,
            vendor_id,
            outfit_name,
            outfit_image_url,
            selected_size,
            rental_start_date,
            rental_return_date,
            rental_days,
            rental_price_per_day,
            rental_amount,
            security_deposit_amount,
            platform_fee,
            total_amount,
            delivery_address,
            payment_status,
            payment_method,
            transaction_reference,
            paid_at,
            status
        ) values (
            p_booking_reference,
            p_user_id,
            v_outfit.id,
            v_outfit.uploaded_by,
            v_vendor_id,
            v_outfit.name,
            v_outfit_image_url,
            v_size,
            v_start_date,
            v_return_date,
            v_days,
            v_outfit.rental_price,
            v_rental_amount,
            v_deposit,
            v_platform_fee,
            v_item_total,
            p_delivery_address,
            'pending',
            null,
            null,
            null,
            'pending'
        )
        returning id into v_rental_id;

        v_items_out := v_items_out || jsonb_build_object(
            'rental_id',        v_rental_id,
            'outfit_id',        v_outfit.id,
            'outfit_name',      v_outfit.name,
            'selected_size',    v_size,
            'rental_start_date', v_start_date,
            'rental_return_date', v_return_date,
            'rental_days',      v_days,
            'seller_user_id',   v_outfit.uploaded_by,
            'vendor_id',        v_vendor_id,
            'seller_type',      case when v_vendor_id is not null
                                     then 'vendor' else 'individual' end,
            'rental_amount',    v_rental_amount,
            'security_deposit', v_deposit,
            'platform_fee',     v_platform_fee,
            'item_total',       v_item_total
        );

        v_total := v_total + v_item_total;
        v_count := v_count + 1;
    end loop;

    return jsonb_build_object(
        'success',           true,
        'booking_reference', p_booking_reference,
        'checkout_type',     'rental',
        'total_items',       v_count,
        'total_amount',      v_total,
        'items',             v_items_out
    );
end;
$function$;

-- ---------------------------------------------------------------------------
-- Function-level security (Phase 2 correction).
-- All three functions are SECURITY DEFINER with
-- `set search_path to 'public', 'pg_temp'` (verified above) so they can write
-- reservations regardless of the caller role and cannot be hijacked through
-- search_path manipulation.
--
-- They accept caller-supplied user ids and create reservations, so they are
-- BACKEND-ONLY: direct EXECUTE is revoked from public, anon and authenticated
-- and granted exclusively to the service role used by the FastAPI backend.
-- The pg_cron schedules (migration 00900) run expire_stale_checkouts() /
-- expire_orphan_reservations() as the schedule owner, which is unaffected by
-- these grants.
-- NOTE: dropping a function (rollback above) also drops its grants.
-- ---------------------------------------------------------------------------
revoke execute on function public.expire_stale_checkouts()
    from public, anon, authenticated;
revoke execute on function public.expire_orphan_reservations()
    from public, anon, authenticated;
revoke execute on function
    public.init_rental_checkout(uuid, uuid, jsonb, jsonb)
    from public, anon, authenticated;

grant execute on function public.expire_stale_checkouts() to service_role;
grant execute on function public.expire_orphan_reservations() to service_role;
grant execute on function
    public.init_rental_checkout(uuid, uuid, jsonb, jsonb)
    to service_role;

-- ---------------------------------------------------------------------------
-- CORRECTION (Phase 2 round 2): supporting indexes for the LAZY cleanup
-- scans. expire_stale_checkouts()/expire_orphan_reservations() now run
-- inside every checkout-init call; without these indexes each call would
-- scan pending bookings as the tables grow.
-- Plain CREATE INDEX (not CONCURRENTLY): a brief write lock while building,
-- acceptable for a one-off migration on the existing tables. Existing table
-- data is not modified. Rollback: drop these two indexes.
-- ---------------------------------------------------------------------------
create index if not exists rentals_pending_created_idx
    on public.rentals (created_at)
    where status = 'pending' and payment_status = 'pending';

create index if not exists trial_requests_pending_created_idx
    on public.trial_requests (created_at)
    where status = 'pending' and payment_status = 'pending';
