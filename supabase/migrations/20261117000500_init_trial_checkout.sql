-- ============================================================================
-- MIGRATION 20261117000500 — trial checkout reservation
-- Attirely / Razorpay integration — Phase 2 (DATABASE DESIGN — DO NOT EXECUTE
-- until reviewed and approved).
--
-- Purpose:
--   init_trial_checkout - NEW function replacing the direct table inserts made
--   by the FastAPI route /trials/book (backend/app/routes/trails.py).
--
--   Current /trials/book behaviour (verified in the backend source, not SQL):
--     * validates user, duplicates within request, dates, outfit state, sizes
--     * resolves vendor vs individual ownership
--     * inserts trial_requests with payment_status='successful',
--       payment_method='dummy', payment_reference='DUMMY-<uuid>',
--       hardcoded trial_fee=150 / platform_fee=50 / trial_amount=200
--   The new function keeps all validation identical but reserves rows with
--   payment_status='pending' and fees from payment_fee_settings.
--
--   Trial booking_reference is shared across the items of one trial checkout
--   (same as today), and payment_items links each trial row to one payment.
--
-- trial_method semantics (Phase 2 review):
--   The current /trials/book workflow leaves trial_method UNSET for every
--   inserted row (the column is simply omitted from its insert). This
--   function therefore also inserts NULL and does NOT invent a default.
--   When Phase 3 lets customers choose a trial method, the value is passed
--   through the items JSON and validated here — until then the existing
--   semantics (NULL) are preserved exactly.
--
-- Rollback:
--   drop function if exists public.init_trial_checkout(uuid, uuid, jsonb);
--   (Dropping the function also drops its grants.)
--
-- Security (Phase 2 correction): SECURITY DEFINER, backend-only. EXECUTE is
-- revoked from public/anon/authenticated and granted to service_role only
-- (see the security section at the end of this file).
--
-- CORRECTION (Phase 2 round 2): expire_orphan_reservations() is called
-- lazily alongside expire_stale_checkouts() so abandoned reservations are
-- cleaned up even when the OPTIONAL pg_cron schedule is unavailable.
-- ============================================================================

create or replace function public.init_trial_checkout(
    p_user_id           uuid,
    p_booking_reference uuid,
    p_items             jsonb
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_item           jsonb;
    v_outfit         record;
    v_vendor_id      uuid;
    v_user_name      text;
    v_trial_id       uuid;
    v_outfit_id      uuid;
    v_size           text;
    v_trial_date     date;
    v_time_slot      text;
    v_trial_address  jsonb;
    v_trial_fee      numeric(10,2);
    v_platform_fee   numeric(10,2);
    v_item_total     numeric(12,2);
    v_total          numeric(12,2) := 0;
    v_items_out      jsonb := '[]'::jsonb;
    v_count          integer := 0;
    v_distinct_outfits integer;
    v_total_outfits    integer;
begin
    -- Release inventory held by abandoned checkouts (trial rows are not
    -- inventory-blocking, but this keeps payment records consistent).
    -- CORRECTION (Phase 2 round 2): orphan reservations are cleaned up
    -- lazily too, so correctness does not depend on the OPTIONAL pg_cron
    -- schedule.
    perform public.expire_stale_checkouts();
    perform public.expire_orphan_reservations();

    -- Validate customer and fetch display name (mirrors /trials/book).
    select full_name
      into v_user_name
      from public.users
     where id = p_user_id;

    if not found then
        raise exception 'Customer account not found';
    end if;

    -- Validate booking input
    if p_items is null
       or jsonb_typeof(p_items) <> 'array'
       or jsonb_array_length(p_items) = 0
       or jsonb_array_length(p_items) > 20
    then
        raise exception 'Invalid trial items';
    end if;

    -- Duplicate checkout guard: one checkout per booking reference.
    if exists (
        select 1
          from public.payments
         where booking_reference = p_booking_reference
    ) then
        raise exception 'A payment checkout already exists for this booking reference';
    end if;

    -- Fees from database configuration (never trusted from the client).
    v_trial_fee    := public.get_platform_fee('trial_fee');
    v_platform_fee := public.get_platform_fee('trial_platform_fee');
    v_item_total   := v_trial_fee + v_platform_fee;

    -- Same-outfit-duplicate guard (mirrors /trials/book).
    select count(distinct value->>'outfit_id'),
           count(value->>'outfit_id')
      into v_distinct_outfits, v_total_outfits
      from jsonb_array_elements(p_items);

    if v_distinct_outfits <> v_total_outfits then
        raise exception 'The same outfit cannot be added twice';
    end if;

    for v_item in
        select value
          from jsonb_array_elements(p_items)
    loop
        v_outfit_id     := (v_item->>'outfit_id')::uuid;
        v_size          := nullif(trim(v_item->>'selected_size'), '');
        v_trial_date    := (v_item->>'preferred_trial_date')::date;
        v_time_slot     := nullif(trim(v_item->>'preferred_time_slot'), '');
        v_trial_address := v_item->'trial_address';

        if v_outfit_id is null
           or v_size is null
           or v_trial_date is null
           or v_time_slot is null
           or v_trial_address is null
           or jsonb_typeof(v_trial_address) <> 'object'
           or v_trial_address = '{}'::jsonb
        then
            raise exception 'Invalid trial details';
        end if;

        -- Trial date cannot be in the past (mirrors /trials/book).
        if v_trial_date < current_date then
            raise exception 'Trial date cannot be in the past';
        end if;

        -- Lock the outfit for consistent validation.
        select id, uploaded_by, role, name, sizes, status, is_available
          into v_outfit
          from public.outfits
         where id = v_outfit_id
         for update;

        if not found then
            raise exception 'Outfit % not found', v_outfit_id;
        end if;

        -- Prevent users from booking their own outfits.
        if v_outfit.uploaded_by = p_user_id then
            raise exception 'You cannot book a trial for your own outfit';
        end if;

        -- Validate ownership role (mirrors /trials/book).
        if v_outfit.role not in ('vendor', 'user') then
            raise exception 'Invalid ownership role for %', v_outfit.name;
        end if;

        -- Validate publish + availability state (mirrors /trials/book).
        if v_outfit.status <> 'published' then
            raise exception '% is not published', v_outfit.name;
        end if;

        if v_outfit.is_available is not true then
            raise exception '% is currently unavailable', v_outfit.name;
        end if;

        -- Resolve owner (mirrors /trials/book).
        v_vendor_id := null;

        if v_outfit.role = 'vendor' then
            select id
              into v_vendor_id
              from public.vendors
             where auth_user_id = v_outfit.uploaded_by;

            if not found then
                raise exception 'Vendor profile not found for %', v_outfit.name;
            end if;
        end if;

        -- Validate size against the jsonb size array.
        if v_outfit.sizes is null
           or not (v_outfit.sizes ? v_size)
        then
            raise exception
                'Size % is not available for %',
                v_size, v_outfit.name;
        end if;

        -- Reserve: pending payment, no payment reference.
        insert into public.trial_requests (
            booking_reference,
            user_id,
            vendor_id,
            outfit_id,
            user_name,
            outfit_name,
            selected_size,
            preferred_trial_date,
            preferred_time_slot,
            trial_address,
            trial_method,
            status,
            rejection_reason,
            payment_status,
            payment_method,
            payment_reference,
            trial_fee,
            platform_fee,
            trial_amount
        ) values (
            p_booking_reference,
            p_user_id,
            v_vendor_id,
            v_outfit.id,
            v_user_name,
            v_outfit.name,
            v_size,
            v_trial_date,
            v_time_slot,
            v_trial_address,
            null,                 -- trial_method: /trials/book leaves it unset; preserved
            'pending',
            null,
            'pending',
            null,
            null,
            v_trial_fee,
            v_platform_fee,
            v_item_total
        )
        returning id into v_trial_id;

        v_items_out := v_items_out || jsonb_build_object(
            'trial_id',           v_trial_id,
            'outfit_id',          v_outfit.id,
            'outfit_name',        v_outfit.name,
            'selected_size',      v_size,
            'preferred_trial_date', v_trial_date,
            'preferred_time_slot',  v_time_slot,
            'seller_user_id',     v_outfit.uploaded_by,
            'vendor_id',          v_vendor_id,
            'seller_type',        case when v_vendor_id is not null
                                       then 'vendor' else 'individual' end,
            'trial_fee',          v_trial_fee,
            'platform_fee',       v_platform_fee,
            'item_total',         v_item_total
        );

        v_total := v_total + v_item_total;
        v_count := v_count + 1;
    end loop;

    return jsonb_build_object(
        'success',           true,
        'booking_reference', p_booking_reference,
        'checkout_type',     'trial',
        'total_items',       v_count,
        'total_amount',      v_total,
        'items',             v_items_out
    );
end;
$function$;

-- ---------------------------------------------------------------------------
-- Function-level security (Phase 2 correction).
-- init_trial_checkout is SECURITY DEFINER with
-- `set search_path to 'public', 'pg_temp'` (verified above) and accepts a
-- caller-supplied user id, so it is BACKEND-ONLY: EXECUTE is revoked from
-- public, anon and authenticated and granted exclusively to the service role
-- used by the FastAPI backend. It must never be exposed to clients.
-- NOTE: dropping the function (rollback above) also drops its grants.
-- ---------------------------------------------------------------------------
revoke execute on function
    public.init_trial_checkout(uuid, uuid, jsonb)
    from public, anon, authenticated;

grant execute on function
    public.init_trial_checkout(uuid, uuid, jsonb)
    to service_role;
