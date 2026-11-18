-- ============================================================================
-- MIGRATION 20261117000600 — payment registration, confirmation and failure
-- Attirely / Razorpay integration — Phase 2 (DATABASE DESIGN — DO NOT EXECUTE
-- until reviewed and approved).
--
-- Purpose — the CENTRAL payment-state transition service at database level.
-- Both the FastAPI verification endpoint AND the webhook processor must call
-- THESE functions (never two different implementations):
--
--   register_razorpay_checkout - insert payments + payment_items after the
--                                Razorpay order is created. Amounts are
--                                RE-DERIVED from the reservation rows (source
--                                of truth) and cross-checked against the order
--                                amount; client/service amounts are never
--                                trusted.
--   confirm_razorpay_payment   - transactional, idempotent confirmation:
--                                marks the payment captured and flips every
--                                related booking to paid, creating
--                                seller_payables. Rejects expired/conflicting
--                                payments (late captures are recorded but NOT
--                                confirmed — they must be refunded).
--   fail_razorpay_payment      - records a failed attempt. Reservations stay
--                                alive until expires_at so the customer can
--                                retry without creating duplicate bookings.
--
-- CORRECTIONS (Phase 2 review):
--   1. Capture-after-rejection: a seller may reject/cancel a pending
--      reservation BEFORE the gateway capture completes. The previous design
--      raised an exception on the booking-count mismatch, which ROLLED BACK
--      the transaction containing a VERIFIED capture — a real payment record
--      was lost. Now the verified capture is always recorded
--      transactionally; if any booking is unconfirmable, NOTHING is
--      confirmed, the outcome is persisted
--      (metadata.confirmation_outcome='unconfirmable_refund_required') and
--      pending full-refund records are created for every item.
--   2. Outcome persistence + idempotent replay: every captured outcome is
--      persisted in metadata->>'confirmation_outcome' ('confirmed',
--      'late_capture', 'unconfirmable_refund_required') so verification and
--      webhook replays return IDENTICAL results forever. A late-capture or
--      unconfirmable outcome can never be replayed as an ordinary success.
--   3. Authorized-state replay: a repeated 'authorized' call with the same
--      gateway payment id is answered idempotently.
--   4. seller_payables insert uses greatest(...) clamping with the new
--      platform_subsidy column (migration 00300), so a platform fee larger
--      than the seller gross can never violate the payable CHECK and roll
--      back a verified capture.
--   5. create_full_item_refund_records: NEW helper that creates pending
--      full-refund records for every item of a payment (idempotent,
--      respects already-committed refunds).
--   6. All functions are backend-only: EXECUTE revoked from
--      public/anon/authenticated, granted to service_role (security section
--      at the end of this file). Signature verification stays in the FastAPI
--      layer.
--
-- CORRECTIONS (Phase 2 round 2):
--   A. register_razorpay_checkout: seller_payable_amount is clamped with
--      greatest(..., 0) and paired with the new payment_items.platform_subsidy
--      column — a negative payable can no longer violate the 00200 CHECK and
--      abort checkout registration.
--   B. confirm_razorpay_payment: ALL bookings of the checkout are locked
--      FOR UPDATE (stable order by id) BEFORE the confirmable count, so a
--      concurrent seller rejection can never interleave between the count
--      and the updates and roll back a verified capture.
--   C. create_full_item_refund_records: reconciles instead of blindly
--      inserting — tops up an uninitiated pending refund, or records the
--      uncovered remainder in payment_items.refund_due_amount when the
--      pending refund has already been handed to Razorpay (immutable).
--      Lock ordering (refunds before items) matches mark_refund_result.
--
-- Signature verification is NOT done here: HMAC verification of
-- razorpay_payment_id|razorpay_order_id|razorpay_signature happens in the
-- FastAPI layer (the Key Secret must never enter the database). This function
-- validates ownership, order/payment linkage, amount and gateway state.
--
-- Rollback:
--   drop function if exists public.fail_razorpay_payment(uuid, text, text, text);
--   drop function if exists public.confirm_razorpay_payment(uuid, text, bigint, text, text, jsonb);
--   drop function if exists public.create_full_item_refund_records(uuid, text);
--   drop function if exists public.register_razorpay_checkout(uuid, text, text, bigint, timestamptz, uuid, jsonb);
--   (Dropping a function also drops its grants.)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- register_razorpay_checkout
-- ---------------------------------------------------------------------------
create or replace function public.register_razorpay_checkout(
    p_booking_reference  uuid,
    p_checkout_type      text,          -- 'trial' | 'rental'
    p_razorpay_order_id  text,
    p_order_amount_paise bigint,
    p_expires_at         timestamptz,
    p_user_id            uuid,
    p_items              jsonb          -- [{booking_id, outfit_id}]
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_item           jsonb;
    v_booking_id     uuid;
    v_payment_id     uuid;
    v_total          numeric(12,2) := 0;
    v_items_out      jsonb := '[]'::jsonb;
    v_existing       public.payments%rowtype;
    v_rental         public.rentals%rowtype;
    v_trial          record;
begin
    if p_checkout_type not in ('trial', 'rental') then
        raise exception 'Invalid checkout type';
    end if;

    if p_razorpay_order_id is null or length(trim(p_razorpay_order_id)) = 0 then
        raise exception 'Razorpay order id is required';
    end if;

    if p_expires_at is null or p_expires_at <= now() then
        raise exception 'A future expiry time is required';
    end if;

    if p_items is null
       or jsonb_typeof(p_items) <> 'array'
       or jsonb_array_length(p_items) = 0
       or jsonb_array_length(p_items) > 20
    then
        raise exception 'Invalid checkout items';
    end if;

    -- Idempotency: one payment per booking reference. Retries reuse it.
    select * into v_existing
      from public.payments
     where booking_reference = p_booking_reference;

    if found then
        if v_existing.razorpay_order_id = p_razorpay_order_id
           and v_existing.payment_status in ('created', 'pending', 'failed')
        then
            return jsonb_build_object(
                'success',             true,
                'already_registered',  true,
                'payment_id',          v_existing.id,
                'amount',              v_existing.amount,
                'gateway_amount_paise', v_existing.gateway_amount_paise,
                'expires_at',          v_existing.expires_at
            );
        end if;

        raise exception 'A payment checkout already exists for this booking reference';
    end if;

    -- ------------------------------------------------------------------
    -- Re-derive every item amount from the reservation rows (source of
    -- truth). Reservations must be pending and belong to the customer.
    -- ------------------------------------------------------------------
    for v_item in
        select value
          from jsonb_array_elements(p_items)
    loop
        v_booking_id := (v_item->>'booking_id')::uuid;

        if v_booking_id is null then
            raise exception 'Every checkout item requires a booking_id';
        end if;

        if p_checkout_type = 'rental' then
            select * into v_rental
              from public.rentals
             where id = v_booking_id
               and booking_reference = p_booking_reference
               and user_id = p_user_id
               and payment_status = 'pending'
               and status = 'pending'
             for update;

            if not found then
                raise exception
                    'Rental reservation % not found, not pending, or not owned by the customer',
                    v_booking_id;
            end if;

            v_total := v_total + v_rental.total_amount;
        else
            select t.id, t.booking_reference, t.user_id, t.vendor_id,
                   t.outfit_id, t.trial_fee, t.platform_fee, t.trial_amount,
                   o.uploaded_by as seller_user_id
              into v_trial
              from public.trial_requests t
              join public.outfits o on o.id = t.outfit_id
             where t.id = v_booking_id
               and t.booking_reference = p_booking_reference
               and t.user_id = p_user_id
               and t.payment_status = 'pending'
               and t.status = 'pending'
             for update of t;

            if not found then
                raise exception
                    'Trial reservation % not found, not pending, or not owned by the customer',
                    v_booking_id;
            end if;

            v_total := v_total + v_trial.trial_amount;
        end if;
    end loop;

    -- ------------------------------------------------------------------
    -- The Razorpay order amount must EXACTLY equal the database-derived
    -- checkout total (integer paise).
    -- ------------------------------------------------------------------
    if p_order_amount_paise <> (round(v_total * 100))::bigint then
        raise exception
            'Razorpay order amount % does not match the checkout total %',
            p_order_amount_paise, (round(v_total * 100))::bigint;
    end if;

    insert into public.payments (
        user_id,
        booking_reference,
        checkout_type,
        razorpay_order_id,
        amount,
        gateway_amount_paise,
        payment_status,
        expires_at,
        metadata
    ) values (
        p_user_id,
        p_booking_reference,
        p_checkout_type,
        p_razorpay_order_id,
        v_total,
        (round(v_total * 100))::bigint,
        'created',
        p_expires_at,
        jsonb_build_object('order_created_at', now())
    )
    returning id into v_payment_id;

    -- ------------------------------------------------------------------
    -- Insert one payment_item per booking with seller accounting fields.
    --   refundable_amount:
    --     rental -> rental_amount + security_deposit (existing customer-cancel
    --               policy: platform fee retained)
    --     trial  -> trial_fee (platform fee retained)
    --   seller_payable_amount:
    --     gross (rental_amount / trial_fee) MINUS platform fee. Security
    --     deposits are customer liabilities, never seller income.
    --     CORRECTION (Phase 2 round 2): clamped with greatest(..., 0) and
    --     paired with platform_subsidy — a platform fee larger than the
    --     seller gross previously produced a NEGATIVE seller_payable_amount,
    --     violating the CHECK constraint on this table and aborting the
    --     whole checkout registration.
    -- ------------------------------------------------------------------
    for v_item in
        select value
          from jsonb_array_elements(p_items)
    loop
        v_booking_id := (v_item->>'booking_id')::uuid;

        if p_checkout_type = 'rental' then
            select * into v_rental
              from public.rentals
             where id = v_booking_id
               and booking_reference = p_booking_reference;

            insert into public.payment_items (
                payment_id, booking_reference, booking_type, booking_id,
                outfit_id, seller_type, vendor_id, seller_user_id,
                item_amount, rental_amount, trial_fee, security_deposit,
                platform_fee, platform_subsidy, refundable_amount,
                seller_payable_amount
            ) values (
                v_payment_id, p_booking_reference, 'rental', v_booking_id,
                v_rental.outfit_id,
                case when v_rental.vendor_id is not null
                     then 'vendor' else 'individual' end,
                v_rental.vendor_id, v_rental.outfit_owner_user_id,
                v_rental.total_amount, v_rental.rental_amount, null,
                v_rental.security_deposit_amount,
                v_rental.platform_fee,
                greatest(v_rental.platform_fee - v_rental.rental_amount, 0),
                v_rental.rental_amount + v_rental.security_deposit_amount,
                greatest(v_rental.rental_amount - v_rental.platform_fee, 0)
            )
            returning id into v_booking_id;

            v_items_out := v_items_out || jsonb_build_object(
                'payment_item_id', v_booking_id, 'booking_id', (v_item->>'booking_id')
            );
        else
            select t.id, t.booking_reference, t.user_id, t.vendor_id,
                   t.outfit_id, t.trial_fee, t.platform_fee, t.trial_amount,
                   o.uploaded_by as seller_user_id
              into v_trial
              from public.trial_requests t
              join public.outfits o on o.id = t.outfit_id
             where t.id = v_booking_id
               and t.booking_reference = p_booking_reference;

            insert into public.payment_items (
                payment_id, booking_reference, booking_type, booking_id,
                outfit_id, seller_type, vendor_id, seller_user_id,
                item_amount, rental_amount, trial_fee, security_deposit,
                platform_fee, platform_subsidy, refundable_amount,
                seller_payable_amount
            ) values (
                v_payment_id, p_booking_reference, 'trial', v_booking_id,
                v_trial.outfit_id,
                case when v_trial.vendor_id is not null
                     then 'vendor' else 'individual' end,
                v_trial.vendor_id, v_trial.seller_user_id,
                v_trial.trial_amount, null, v_trial.trial_fee, 0,
                v_trial.platform_fee,
                greatest(v_trial.platform_fee - v_trial.trial_fee, 0),
                v_trial.trial_fee,
                greatest(v_trial.trial_fee - v_trial.platform_fee, 0)
            )
            returning id into v_booking_id;

            v_items_out := v_items_out || jsonb_build_object(
                'payment_item_id', v_booking_id, 'booking_id', (v_item->>'booking_id')
            );
        end if;
    end loop;

    return jsonb_build_object(
        'success',              true,
        'payment_id',           v_payment_id,
        'booking_reference',    p_booking_reference,
        'checkout_type',        p_checkout_type,
        'amount',               v_total,
        'gateway_amount_paise', (round(v_total * 100))::bigint,
        'expires_at',           p_expires_at,
        'items',                v_items_out
    );
end;
$function$;

-- ---------------------------------------------------------------------------
-- create_full_item_refund_records (Phase 2 correction, ROUND 2 reconciled).
-- Ensures the ENTIRE remaining amount of every item of a captured payment is
-- durably represented as owed to the customer — without duplicate gateway
-- refunds — when a verified capture cannot be converted into confirmed
-- bookings (late capture after expiry, or a seller rejected/cancelled a
-- reservation before capture).
--
-- Reconciliation per item (v_needed = item_amount - pending - processed):
--   1. No pending refund exists
--        -> insert ONE pending full refund for v_needed.
--   2. A pending refund exists and has NOT been handed to Razorpay
--      (gateway_initiated_at IS NULL)
--        -> TOP IT UP: its amount is enlarged to also cover v_needed
--           (single gateway refund for the full remainder; the unique
--           pending-refund-per-booking index stays satisfied).
--   3. A pending refund exists that HAS reached Razorpay
--      (gateway_initiated_at IS NOT NULL)
--        -> it is IMMUTABLE (the gateway will process exactly the initiated
--           amount; enlarging or duplicating it risks a double refund), so
--           the uncovered remainder is recorded durably in
--           payment_items.refund_due_amount. mark_refund_result converts
--           that amount into a new pending refund record as soon as the
--           blocking refund settles (processed or failed) and frees the
--           unique index slot.
--
-- Lock ordering: payment_refunds BEFORE payment_items — the same order as
-- mark_refund_result, so the two functions can never deadlock against each
-- other (a deadlock here would roll back a verified capture).
-- Idempotent: repeated calls produce no duplicate records and no double
-- top-ups (the remaining-amount cap is recomputed each time).
-- ---------------------------------------------------------------------------
create or replace function public.create_full_item_refund_records(
    p_payment_id uuid,
    p_refund_reason text
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_item       record;
    v_pending    public.payment_refunds%rowtype;
    v_committed  numeric(12,2);
    v_needed     numeric(12,2);
    v_new_amount numeric(12,2);
    v_created    integer := 0;
    v_topped_up  integer := 0;
    v_deferred   integer := 0;
begin
    -- NOTE: no FOR UPDATE on payment_items here — deliberate, to preserve the
    -- payment_refunds -> payment_items lock order shared with
    -- mark_refund_result. Serialization comes from the payment row lock held
    -- by every caller.
    for v_item in
        select *
          from public.payment_items
         where payment_id = p_payment_id
         order by created_at
    loop
        select coalesce(sum(amount), 0)
          into v_committed
          from public.payment_refunds
         where payment_item_id = v_item.id
           and refund_status in ('pending', 'processed');

        v_needed := v_item.item_amount - v_committed;

        if v_needed <= 0 then
            -- Fully covered (e.g. by earlier pending refunds): clear any
            -- residual deferred-due marker so accounting stays exact.
            if coalesce(v_item.refund_due_amount, 0) <> 0 then
                update public.payment_items
                   set refund_due_amount = 0
                 where id = v_item.id;
            end if;
            continue;
        end if;

        select *
          into v_pending
          from public.payment_refunds
         where payment_item_id = v_item.id
           and refund_status   = 'pending'
         order by created_at
         limit 1;

        if found then
            if v_pending.gateway_initiated_at is null then
                -- Case 2: top up the uninitiated pending refund. The WHERE
                -- re-checks status/initiation for race safety against a
                -- concurrent mark_refund_result.
                v_new_amount := v_pending.amount + v_needed;

                update public.payment_refunds
                   set amount               = v_new_amount,
                       gateway_amount_paise = (round(v_new_amount * 100))::bigint,
                       refund_type          = case
                           when v_new_amount >= v_item.item_amount then 'full'
                           else 'partial'
                       end,
                       refund_reason        = left(
                           coalesce(v_pending.refund_reason, '')
                               || ' | topped up for full refund: '
                               || p_refund_reason, 500)
                 where id = v_pending.id
                   and refund_status          = 'pending'
                   and gateway_initiated_at is null;

                if found then
                    v_topped_up := v_topped_up + 1;
                    continue;
                end if;
                -- The re-check failed (settled concurrently): fall through to
                -- the deferred representation below.
            end if;

            -- Case 3: the pending refund is immutable (already handed to the
            -- gateway, or settled concurrently). Record the remainder.
            update public.payment_items
               set refund_due_amount = coalesce(refund_due_amount, 0) + v_needed
             where id = v_item.id;

            v_deferred := v_deferred + 1;
            continue;
        end if;

        -- Case 1: no pending refund — insert one for the full remainder.
        insert into public.payment_refunds (
            payment_id, payment_item_id, booking_type, booking_id,
            amount, gateway_amount_paise, refund_type, refund_status,
            refund_reason, initiated_by
        ) values (
            p_payment_id, v_item.id, v_item.booking_type, v_item.booking_id,
            v_needed, (round(v_needed * 100))::bigint,
            'full', 'pending', p_refund_reason, 'system'
        )
        on conflict do nothing;  -- payment_refunds_one_pending_per_booking

        v_created := v_created + 1;
    end loop;

    return jsonb_build_object(
        'success',           true,
        'refunds_created',   v_created,
        'refunds_topped_up', v_topped_up,
        'refunds_deferred',  v_deferred
    );
end;
$function$;

-- ---------------------------------------------------------------------------
-- confirm_razorpay_payment — the ONLY place bookings become paid.
-- ---------------------------------------------------------------------------
create or replace function public.confirm_razorpay_payment(
    p_payment_id           uuid,
    p_razorpay_payment_id  text,
    p_gateway_amount_paise bigint,
    p_gateway_status       text,            -- 'captured' | 'authorized'
    p_payment_method       text default null,
    p_gateway_payload      jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_payment      public.payments%rowtype;
    v_now          timestamptz := now();
    v_confirmed    integer := 0;
    v_expected     integer;
    v_confirmable  integer;
    v_outcome      text;
begin
    if p_gateway_status not in ('captured', 'authorized') then
        raise exception 'Invalid gateway status (expected captured or authorized)';
    end if;

    if p_razorpay_payment_id is null
       or length(trim(p_razorpay_payment_id)) = 0
    then
        raise exception 'Razorpay payment id is required';
    end if;

    select * into v_payment
      from public.payments
     where id = p_payment_id
     for update;

    if not found then
        raise exception 'Payment not found';
    end if;

    -- ------------------------------------------------------------------
    -- Idempotent replay (CORRECTION: outcome-aware).
    -- The original outcome is persisted in metadata->>'confirmation_outcome'
    -- so verification and webhook replays return IDENTICAL results forever:
    --   'confirmed'                     -> success / already_processed
    --   'late_capture'                  -> same refund-required outcome
    --   'unconfirmable_refund_required' -> same refund-required outcome
    -- A late-capture or unconfirmable outcome is NEVER replayed as an
    -- ordinary successful booking confirmation.
    -- ------------------------------------------------------------------
    if v_payment.payment_status = 'captured' then
        if v_payment.razorpay_payment_id is distinct from p_razorpay_payment_id then
            raise exception
                'Payment already confirmed with a different gateway payment id';
        end if;

        v_outcome := coalesce(v_payment.metadata->>'confirmation_outcome', 'confirmed');

        if v_outcome = 'confirmed' then
            return jsonb_build_object(
                'success',           true,
                'already_processed', true,
                'payment_status',    'captured'
            );
        end if;

        return jsonb_build_object(
            'success',           false,
            'outcome',           v_outcome,
            'already_processed', true,
            'message',           coalesce(
                                     v_payment.metadata->>'confirmation_outcome_message',
                                     'Payment was recorded but bookings were not confirmed; a full refund is required')
        );
    end if;

    -- ------------------------------------------------------------------
    -- Authorized-state replay (CORRECTION): a repeated 'authorized' call
    -- with the same gateway payment id is idempotent; a different gateway
    -- payment id is an error. A 'captured' call on an authorized payment
    -- falls through to the normal capture flow below.
    -- ------------------------------------------------------------------
    if v_payment.payment_status = 'authorized'
       and p_gateway_status = 'authorized'
    then
        if v_payment.razorpay_payment_id is distinct from p_razorpay_payment_id then
            raise exception 'Gateway payment id does not match the recorded payment';
        end if;

        return jsonb_build_object(
            'success',           true,
            'already_processed', true,
            'payment_status',    'authorized',
            'confirmed_items',   0,
            'message',           'Authorized; awaiting capture'
        );
    end if;

    -- ------------------------------------------------------------------
    -- Expired/cancelled payments must never confirm bookings silently.
    -- CORRECTION: a verified capture arriving here is recorded
    -- TRANSACTIONALLY (payment_status='captured' — the money IS with the
    -- gateway), pending full-refund records are created for every item, and
    -- the outcome is persisted so replays return the identical
    -- refund-required result. The previous version returned without
    -- recording the capture and without any durable refund record.
    -- ------------------------------------------------------------------
    if v_payment.payment_status in ('cancelled', 'expired') then
        if v_payment.razorpay_payment_id is not null
           and v_payment.razorpay_payment_id <> p_razorpay_payment_id
        then
            raise exception 'Gateway payment id does not match the recorded payment';
        end if;

        update public.payments
           set payment_status      = 'captured',
               gateway_status      = 'captured',
               razorpay_payment_id = p_razorpay_payment_id,
               payment_method      = coalesce(p_payment_method, payment_method),
               verified_at         = v_now,
               paid_at             = v_now,
               metadata            = metadata
                   || jsonb_build_object(
                          'confirmation_outcome',
                              'unconfirmable_refund_required',
                          'confirmation_outcome_message',
                              'Payment was captured after the checkout expired or was cancelled; bookings were not confirmed and the full gateway amount must be refunded',
                          'late_confirmation_attempt_at', v_now,
                          'requires_full_refund',         true,
                          'gateway_payload',              p_gateway_payload
                      )
         where id = p_payment_id;

        perform public.create_full_item_refund_records(
            p_payment_id,
            'Payment captured after checkout expiry or cancellation; bookings were not confirmed'
        );

        return jsonb_build_object(
            'success', false,
            'outcome', 'unconfirmable_refund_required',
            'message', 'Payment window has expired or the checkout was cancelled; the verified capture was recorded and the full gateway amount must be refunded'
        );
    end if;

    if v_payment.razorpay_order_id is null then
        raise exception 'Payment has no gateway order';
    end if;

    if v_payment.razorpay_payment_id is not null
       and v_payment.razorpay_payment_id <> p_razorpay_payment_id
       and v_payment.payment_status in ('captured', 'authorized')
    then
        raise exception 'Gateway payment id does not match the recorded payment';
    end if;

    -- CORRECTION (recheck): a RETRY after a failed attempt produces a NEW
    -- gateway payment id on the SAME order. In created/pending/failed states
    -- the recorded id is only the last attempt, so a new verified attempt on
    -- the same order legitimately replaces it. In captured/authorized states
    -- the id is authoritative and mismatches were already rejected by the
    -- replay guards above.

    -- Amount reconciliation (integer paise, exact).
    if p_gateway_amount_paise is null
       or p_gateway_amount_paise <> v_payment.gateway_amount_paise
    then
        raise exception
            'Gateway amount % does not match the payment amount %',
            p_gateway_amount_paise, v_payment.gateway_amount_paise;
    end if;

    -- ------------------------------------------------------------------
    -- Authorized but not captured: record, await capture (webhook or a later
    -- verify call). Bookings stay pending.
    -- ------------------------------------------------------------------
    if p_gateway_status = 'authorized' then
        update public.payments
           set payment_status      = 'authorized',
               gateway_status      = 'authorized',
               razorpay_payment_id = p_razorpay_payment_id,
               payment_method      = coalesce(p_payment_method, payment_method),
               metadata            = metadata
                   || jsonb_build_object('gateway_payload', p_gateway_payload)
         where id = p_payment_id;

        return jsonb_build_object(
            'success',         true,
            'payment_status',  'authorized',
            'confirmed_items', 0,
            'message',         'Authorized; awaiting capture'
        );
    end if;

    -- ------------------------------------------------------------------
    -- Captured AFTER expiry: record the money but do NOT confirm bookings
    -- (reservations may already be released and given to other customers).
    -- The backend service must auto-refund this amount (Phase 3). CORRECTION:
    -- the outcome is persisted and pending full-refund records are created
    -- in the SAME transaction, so replays (verification or webhook) return
    -- the identical late-capture/refund-required outcome — never success.
    -- ------------------------------------------------------------------
    if v_payment.expires_at < v_now then
        update public.payments
           set payment_status      = 'captured',
               gateway_status      = 'captured',
               razorpay_payment_id = p_razorpay_payment_id,
               payment_method      = coalesce(p_payment_method, payment_method),
               verified_at         = v_now,
               paid_at             = v_now,
               metadata            = metadata
                   || jsonb_build_object(
                          'confirmation_outcome',  'late_capture',
                          'confirmation_outcome_message',
                              'Payment was captured after the reservation expired; bookings were not confirmed and the full gateway amount must be refunded',
                          'late_capture',          true,
                          'late_capture_at',       v_now,
                          'requires_full_refund',  true,
                          'gateway_payload',       p_gateway_payload
                      )
         where id = p_payment_id;

        perform public.create_full_item_refund_records(
            p_payment_id,
            'Payment captured after the reservation expired; bookings were not confirmed'
        );

        return jsonb_build_object(
            'success', false,
            'outcome', 'late_capture',
            'message', 'Payment captured after the reservation expired; bookings were not confirmed'
        );
    end if;

    select count(*) into v_expected
      from public.payment_items
     where payment_id = v_payment.id;

    if v_expected = 0 then
        raise exception 'Payment has no payment items';
    end if;

    -- ------------------------------------------------------------------
    -- CORRECTION (capture after seller rejection/cancellation): count the
    -- CONFIRMABLE bookings BEFORE updating anything. A seller may reject or
    -- cancel a pending reservation between checkout and capture. The
    -- previous design raised an exception on the mismatch, which aborted the
    -- whole transaction containing a VERIFIED gateway capture — a successful
    -- payment record was silently lost.
    --
    -- New behaviour: the verified capture is always recorded
    -- transactionally. If ANY booking is unconfirmable, NOTHING is confirmed
    -- (a rejected reservation must never be flipped to paid), the outcome is
    -- persisted as 'unconfirmable_refund_required' with
    -- requires_full_refund=true, and pending full-refund records are created
    -- for every item. Both the verification path and the webhook path call
    -- this same function, so they behave identically and idempotently.
    --
    -- CORRECTION (Phase 2 round 2 — capture/rejection race): ALL bookings of
    -- this checkout are locked FOR UPDATE in a stable order (by id) BEFORE
    -- counting. A concurrent seller rejection/cancellation therefore either
    -- COMMITS before we lock (its rows count as unconfirmable → the
    -- whole-payment refund path below) or WAITS until after our transaction
    -- commits (it can no longer change a confirmed booking mid-flight).
    -- The count and the booking updates below therefore observe the same
    -- row states, and a verified capture can never be lost to a concurrent
    -- status change. The whole-payment refund policy is preserved.
    -- Lock order (payments -> bookings) never conflicts with
    -- manage_rental_status, which locks only single booking rows.
    --
    -- PRODUCT DECISION (interim rule, see design doc §7): a partially
    -- rejected multi-item checkout refunds the WHOLE payment and asks the
    -- customer to rebook, instead of confirming the still-valid items only.
    -- Partial confirmation is the documented alternative.
    -- ------------------------------------------------------------------
    if v_payment.checkout_type = 'rental' then
        perform 1
          from public.rentals
         where booking_reference = v_payment.booking_reference
         order by id
         for update;

        select count(*) into v_confirmable
          from public.rentals
         where booking_reference = v_payment.booking_reference
           and payment_status    = 'pending'
           and status            = 'pending';
    else
        perform 1
          from public.trial_requests
         where booking_reference = v_payment.booking_reference
         order by id
         for update;

        select count(*) into v_confirmable
          from public.trial_requests
         where booking_reference = v_payment.booking_reference
           and payment_status    = 'pending'
           and status            = 'pending';
    end if;

    if v_confirmable <> v_expected then
        update public.payments
           set payment_status      = 'captured',
               gateway_status      = 'captured',
               razorpay_payment_id = p_razorpay_payment_id,
               payment_method      = coalesce(p_payment_method, payment_method),
               verified_at         = v_now,
               paid_at             = v_now,
               metadata            = metadata
                   || jsonb_build_object(
                          'confirmation_outcome',
                              'unconfirmable_refund_required',
                          'confirmation_outcome_message',
                              'One or more bookings were rejected or cancelled by the seller before the payment was captured; bookings were not confirmed and the full gateway amount must be refunded',
                          'requires_full_refund', true,
                          'confirmable_items',    v_confirmable,
                          'expected_items',       v_expected,
                          'gateway_payload',      p_gateway_payload
                      )
         where id = p_payment_id;

        perform public.create_full_item_refund_records(
            p_payment_id,
            'Booking(s) rejected or cancelled by the seller before payment capture'
        );

        return jsonb_build_object(
            'success',           false,
            'outcome',           'unconfirmable_refund_required',
            'confirmable_items', v_confirmable,
            'expected_items',    v_expected,
            'message',           'Verified capture recorded; bookings were not confirmed because a reservation was rejected or cancelled before capture. Full refund required.'
        );
    end if;

    -- ------------------------------------------------------------------
    -- All bookings confirmable: confirm every booking. With the booking rows
    -- locked above, this post-update re-check CANNOT fire from a concurrent
    -- status change — only from a logic bug. If it ever fires, the whole
    -- transaction rolls back (payment stays unconfirmed) and the next
    -- verification/webhook replay converges to the correct outcome; a
    -- verified capture is never lost silently.
    -- ------------------------------------------------------------------
    if v_payment.checkout_type = 'rental' then
        with updated as (
            update public.rentals r
               set payment_status       = 'success',
                   payment_method       = coalesce(p_payment_method, 'razorpay'),
                   transaction_reference = p_razorpay_payment_id,
                   paid_at              = v_now,
                   updated_at           = v_now
             where r.booking_reference = v_payment.booking_reference
               and r.payment_status    = 'pending'
               and r.status            = 'pending'
            returning 1
        )
        select count(*) into v_confirmed from updated;

        if v_confirmed <> v_expected then
            raise exception
                'Rental confirmation mismatch: % of % items confirmable (a booking may have changed state)',
                v_confirmed, v_expected;
        end if;
    else
        with updated as (
            update public.trial_requests t
               set payment_status    = 'successful',
                   payment_method    = coalesce(p_payment_method, 'razorpay'),
                   payment_reference = p_razorpay_payment_id
             where t.booking_reference = v_payment.booking_reference
               and t.payment_status    = 'pending'
               and t.status            = 'pending'
            returning 1
        )
        select count(*) into v_confirmed from updated;

        if v_confirmed <> v_expected then
            raise exception
                'Trial confirmation mismatch: % of % items confirmable (a booking may have changed state)',
                v_confirmed, v_expected;
        end if;
    end if;

    -- ------------------------------------------------------------------
    -- Mark the payment captured and persist the CONFIRMED outcome so future
    -- replays return the success/already_processed result (CORRECTION).
    -- ------------------------------------------------------------------
    update public.payments
       set payment_status      = 'captured',
           gateway_status      = 'captured',
           razorpay_payment_id = p_razorpay_payment_id,
           payment_method      = coalesce(p_payment_method, payment_method),
           verified_at         = v_now,
           paid_at             = v_now,
           metadata            = metadata
               || jsonb_build_object(
                      'confirmation_outcome', 'confirmed',
                      'gateway_payload',      p_gateway_payload
                  )
     where id = p_payment_id;

    -- ------------------------------------------------------------------
    -- Seller payables: record seller-wise obligations (no transfers happen
    -- here — future Razorpay Route settlement only). Idempotent.
    -- CORRECTION: greatest() clamping with the platform_subsidy column
    -- (migration 00300) guarantees the payable CHECK can never be violated
    -- when the platform fee exceeds the seller gross — which would
    -- previously ROLL BACK an already-verified capture.
    -- ------------------------------------------------------------------
    insert into public.seller_payables (
        payment_id, payment_item_id, seller_user_id, vendor_id,
        booking_type, gross_amount, platform_fee, platform_subsidy, net_payable
    )
    select pi.payment_id,
           pi.id,
           pi.seller_user_id,
           pi.vendor_id,
           pi.booking_type,
           coalesce(pi.rental_amount, pi.trial_fee, 0),
           pi.platform_fee,
           greatest(pi.platform_fee - coalesce(pi.rental_amount, pi.trial_fee, 0), 0),
           greatest(coalesce(pi.rental_amount, pi.trial_fee, 0) - pi.platform_fee, 0)
      from public.payment_items pi
     where pi.payment_id = v_payment.id
    on conflict (payment_item_id) do nothing;

    return jsonb_build_object(
        'success',           true,
        'payment_id',        v_payment.id,
        'payment_status',    'captured',
        'confirmed_items',   v_confirmed,
        'booking_reference', v_payment.booking_reference
    );
end;
$function$;

-- ---------------------------------------------------------------------------
-- fail_razorpay_payment — record a failed attempt WITHOUT terminating the
-- checkout. Reservations remain valid until expires_at (retry allowed); no
-- booking is ever marked failed-as-paid.
-- ---------------------------------------------------------------------------
create or replace function public.fail_razorpay_payment(
    p_payment_id          uuid,
    p_razorpay_payment_id text default null,
    p_failure_reason      text default null,
    p_gateway_status      text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_payment public.payments%rowtype;
begin
    select * into v_payment
      from public.payments
     where id = p_payment_id
     for update;

    if not found then
        raise exception 'Payment not found';
    end if;

    -- A captured payment can never be "failed" afterwards.
    if v_payment.payment_status = 'captured' then
        return jsonb_build_object(
            'success', false,
            'message', 'Payment already captured; failure event ignored'
        );
    end if;

    if p_razorpay_payment_id is not null
       and v_payment.razorpay_payment_id is not null
       and v_payment.razorpay_payment_id <> p_razorpay_payment_id
       and v_payment.payment_status in ('captured', 'authorized')
    then
        raise exception 'Gateway payment id does not match the recorded payment';
    end if;

    -- CORRECTION (recheck): retries produce NEW gateway payment ids on the
    -- same order; in created/pending/failed states the recorded id is only
    -- the last attempt and is legitimately replaced by a newer attempt.

    update public.payments
       set payment_status      = 'failed',
           gateway_status      = coalesce(p_gateway_status, gateway_status),
           failure_reason      = left(coalesce(p_failure_reason, 'Payment failed'), 500),
           razorpay_payment_id = coalesce(p_razorpay_payment_id, razorpay_payment_id),
           metadata            = metadata
               || jsonb_build_object(
                      'failed_attempts',
                      coalesce((metadata->>'failed_attempts')::int, 0) + 1,
                      'last_failure_at', now()
                  )
     where id = p_payment_id;

    return jsonb_build_object(
        'success',        true,
        'payment_id',     p_payment_id,
        'payment_status', 'failed'
    );
end;
$function$;

-- ---------------------------------------------------------------------------
-- Function-level security (Phase 2 correction).
-- All four functions are SECURITY DEFINER with
-- `set search_path to 'public', 'pg_temp'` (verified above) so the backend
-- service role can drive the payment state machine regardless of table RLS
-- and cannot be hijacked through search_path manipulation.
--
-- They accept caller-supplied payment/booking ids and mutate money-relevant
-- state, so they are BACKEND-ONLY: direct EXECUTE is revoked from public,
-- anon and authenticated and granted exclusively to the service role used by
-- the FastAPI backend. This also prevents untrusted callers from invoking
-- functions with arbitrary user/payment ids.
-- NOTE: dropping a function (rollback above) also drops its grants.
-- ---------------------------------------------------------------------------
revoke execute on function
    public.register_razorpay_checkout(uuid, text, text, bigint, timestamptz, uuid, jsonb)
    from public, anon, authenticated;
revoke execute on function
    public.confirm_razorpay_payment(uuid, text, bigint, text, text, jsonb)
    from public, anon, authenticated;
revoke execute on function
    public.fail_razorpay_payment(uuid, text, text, text)
    from public, anon, authenticated;
revoke execute on function
    public.create_full_item_refund_records(uuid, text)
    from public, anon, authenticated;

grant execute on function
    public.register_razorpay_checkout(uuid, text, text, bigint, timestamptz, uuid, jsonb)
    to service_role;
grant execute on function
    public.confirm_razorpay_payment(uuid, text, bigint, text, text, jsonb)
    to service_role;
grant execute on function
    public.fail_razorpay_payment(uuid, text, text, text)
    to service_role;
grant execute on function
    public.create_full_item_refund_records(uuid, text)
    to service_role;
