-- ============================================================================
-- MIGRATION 20261117000700 — refund bookkeeping + trial rejection refund policy
-- Attirely / Razorpay integration — Phase 2 (DATABASE DESIGN — DO NOT EXECUTE
-- until reviewed and approved).
--
-- Purpose:
--   initiate_item_refund        - create a pending refund RECORD for one
--                                 booking item after eligibility validation
--                                 (never exceeds the remaining refundable
--                                 amount; duplicate protection via the unique
--                                 partial index on pending refunds).
--   initiate_full_payment_refund- create pending refund records for ALL
--                                 remaining items of a payment (used for
--                                 late captures after expiry and operator
--                                 interventions).
--   mark_refund_result          - apply a gateway result (processed/failed)
--                                 transactionally: updates the refund record,
--                                 the booking, the payment aggregate and the
--                                 seller payable.
--   handle_trial_rejection_refund (trigger)
--                               - CONFIRMED POLICY: when a seller rejects a
--                                 PAID trial request, the trial fee is
--                                 refunded and the platform fee retained. The
--                                 trigger only creates a PENDING refund
--                                 record — a calculated amount is never
--                                 treated as money actually refunded; the
--                                 Razorpay refund is initiated by the backend
--                                 service and confirmed by mark_refund_result.
--
-- CORRECTIONS (Phase 2 review):
--   1. mark_refund_result now flips a booking to payment_status='refunded'
--      ONLY when its entire refundable portion has been returned (the
--      retained platform fee is tracked in financial columns, not in the
--      booking status). Partial refunds keep the booking status unchanged.
--   2. seller_payables.refund_amount is clamped against the remaining
--      un-refunded seller gross (multiple refunds on one item can never
--      push it past gross_amount).
--   3. Razorpay refund API responses with status 'pending' must never be
--      recorded as processed (see mark_refund_result header) — Phase 3
--      backend rule.
--   4. Function-level security: all definer functions are backend-only;
--      EXECUTE revoked from public/anon/authenticated, granted to
--      service_role (security section at the end of this file).
--
-- CORRECTIONS (Phase 2 round 2):
--   5. initiate_item_refund / initiate_full_payment_refund now subtract
--      payment_items.refund_due_amount from the remaining refundable
--      amount — the deferred obligation (created when an immutable
--      gateway-initiated pending refund blocked the full-refund
--      requirement) can never be double-recorded.
--   6. NEW convert_refund_due_to_pending_refund(uuid): converts the
--      deferred obligation into a fresh PENDING refund record once the
--      blocking refund settles (processed or failed) and frees the unique
--      index slot. Called automatically from mark_refund_result on every
--      result; gateway-neutral (pending record only).
--
-- Rollback:
--   drop trigger if exists trg_trial_rejection_refund on public.trial_requests;
--   drop function if exists public.handle_trial_rejection_refund();
--   drop function if exists public.convert_refund_due_to_pending_refund(uuid);
--   drop function if exists public.mark_refund_result(uuid, text, text, text);
--   drop function if exists public.initiate_full_payment_refund(uuid, text, text);
--   drop function if exists public.initiate_item_refund(uuid, numeric, text, text);
--   (Dropping a function also drops its grants.)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- initiate_item_refund — one booking item (booking-level refunds)
-- ---------------------------------------------------------------------------
create or replace function public.initiate_item_refund(
    p_payment_item_id uuid,
    p_amount          numeric,
    p_refund_reason   text,
    p_initiated_by    text default 'system'
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_item         public.payment_items%rowtype;
    v_payment      public.payments%rowtype;
    v_committed    numeric(12,2);
    v_remaining    numeric(12,2);
    v_refund_id    uuid;
begin
    if p_initiated_by not in ('customer', 'seller', 'system', 'admin') then
        raise exception 'Invalid initiator';
    end if;

    select * into v_item
      from public.payment_items
     where id = p_payment_item_id
     for update;

    if not found then
        raise exception 'Payment item not found';
    end if;

    select * into v_payment
      from public.payments
     where id = v_item.payment_id;

    -- Refunds are only possible against verified captured money.
    if v_payment.payment_status not in ('captured', 'partially_refunded') then
        raise exception
            'Refunds can only be initiated for captured payments (current status: %)',
            v_payment.payment_status;
    end if;

    -- Amounts already pending or processed for this item.
    select coalesce(sum(amount), 0)
      into v_committed
      from public.payment_refunds
     where payment_item_id = v_item.id
       and refund_status in ('pending', 'processed');

    -- CORRECTION (Phase 2 round 2): the deferred refund obligation
    -- (refund_due_amount — recorded by create_full_item_refund_records when
    -- an immutable gateway-initiated pending refund blocked the full
    -- amount) is money already committed to the customer and reduces what
    -- can still be recorded here.
    v_remaining := v_item.refundable_amount
                   - v_committed
                   - coalesce(v_item.refund_due_amount, 0);

    if p_amount is null or p_amount <= 0 then
        raise exception 'Refund amount must be positive';
    end if;

    if v_remaining <= 0 then
        raise exception
            'No refundable amount remaining for this item (refundable %, committed %, deferred due %)',
            v_item.refundable_amount, v_committed,
            coalesce(v_item.refund_due_amount, 0);
    end if;

    if p_amount > v_remaining then
        raise exception
            'Refund amount % exceeds the remaining refundable amount %',
            p_amount, v_remaining;
    end if;

    insert into public.payment_refunds (
        payment_id, payment_item_id, booking_type, booking_id,
        amount, gateway_amount_paise, refund_type, refund_status,
        refund_reason, initiated_by
    ) values (
        v_item.payment_id, v_item.id, v_item.booking_type, v_item.booking_id,
        p_amount, (round(p_amount * 100))::bigint,
        case when p_amount = v_item.refundable_amount then 'full' else 'partial' end,
        'pending', p_refund_reason, p_initiated_by
    )
    returning id into v_refund_id;

    return jsonb_build_object(
        'success',       true,
        'refund_id',     v_refund_id,
        'refund_status', 'pending',
        'remaining_refundable', v_remaining - p_amount
    );
end;
$function$;

-- ---------------------------------------------------------------------------
-- initiate_full_payment_refund — every item of a payment (late captures,
-- operator-initiated full refunds)
-- ---------------------------------------------------------------------------
create or replace function public.initiate_full_payment_refund(
    p_payment_id    uuid,
    p_refund_reason text,
    p_initiated_by  text default 'system'
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_item         record;
    v_committed    numeric(12,2);
    v_remaining    numeric(12,2);
    v_created      integer := 0;
    v_refund_ids   jsonb := '[]'::jsonb;
    v_refund_id    uuid;
    v_payment      public.payments%rowtype;
begin
    if p_initiated_by not in ('customer', 'seller', 'system', 'admin') then
        raise exception 'Invalid initiator';
    end if;

    select * into v_payment
      from public.payments
     where id = p_payment_id;

    if not found then
        raise exception 'Payment not found';
    end if;

    if v_payment.payment_status not in ('captured', 'partially_refunded') then
        raise exception
            'Refunds can only be initiated for captured payments (current status: %)',
            v_payment.payment_status;
    end if;

    for v_item in
        select *
          from public.payment_items
         where payment_id = p_payment_id
         order by created_at
         for update
    loop
        -- Full-item ceiling: item_amount (everything the customer paid for
        -- this item), minus amounts already pending or processed.
        select coalesce(sum(amount), 0)
          into v_committed
          from public.payment_refunds
         where payment_item_id = v_item.id
           and refund_status in ('pending', 'processed');

        -- CORRECTION (Phase 2 round 2): the deferred refund obligation is
        -- already committed to the customer and cannot be recorded twice.
        v_remaining := v_item.item_amount
                       - v_committed
                       - coalesce(v_item.refund_due_amount, 0);

        if v_remaining <= 0 then
            continue;
        end if;

        insert into public.payment_refunds (
            payment_id, payment_item_id, booking_type, booking_id,
            amount, gateway_amount_paise, refund_type, refund_status,
            refund_reason, initiated_by
        ) values (
            p_payment_id, v_item.id, v_item.booking_type, v_item.booking_id,
            v_remaining, (round(v_remaining * 100))::bigint,
            'full', 'pending', p_refund_reason, p_initiated_by
        )
        returning id into v_refund_id;

        v_refund_ids := v_refund_ids || to_jsonb(v_refund_id);
        v_created := v_created + 1;
    end loop;

    return jsonb_build_object(
        'success',       true,
        'refunds_created', v_created,
        'refund_ids',    v_refund_ids
    );
end;
$function$;

-- ---------------------------------------------------------------------------
-- convert_refund_due_to_pending_refund (NEW — Phase 2 round 2).
-- Completes the reconciliation started by create_full_item_refund_records:
-- converts a recorded payment_items.refund_due_amount (the remainder that
-- could not be recorded while an immutable gateway-initiated pending refund
-- blocked the one-pending-per-booking index) into a fresh PENDING refund
-- record once that blocking refund has settled (processed OR failed) and
-- freed the unique index slot.
-- Gateway-neutral: it only creates a pending record; the Razorpay refund is
-- initiated by the backend and confirmed via mark_refund_result.
-- Called automatically by mark_refund_result on every refund result.
-- Lock order: payment_items first, then insert — no conflict with the
-- refund -> item order of the other functions (an INSERT takes no prior
-- row locks).
-- ---------------------------------------------------------------------------
create or replace function public.convert_refund_due_to_pending_refund(
    p_payment_item_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_item        public.payment_items%rowtype;
    v_due         numeric(12,2);
    v_committed   numeric(12,2);
    v_convertible numeric(12,2);
    v_refund_id   uuid;
begin
    select * into v_item
      from public.payment_items
     where id = p_payment_item_id
     for update;

    if not found then
        raise exception 'Payment item not found';
    end if;

    v_due := coalesce(v_item.refund_due_amount, 0);

    if v_due <= 0 then
        return jsonb_build_object('success', true, 'converted', 0);
    end if;

    -- Only convert what the item amount still leaves uncovered.
    select coalesce(sum(amount), 0)
      into v_committed
      from public.payment_refunds
     where payment_item_id = p_payment_item_id
       and refund_status in ('pending', 'processed');

    v_convertible := least(v_due, v_item.item_amount - v_committed);

    if v_convertible <= 0 then
        -- Over-covered by now: clear the residual marker.
        update public.payment_items
           set refund_due_amount = 0
         where id = p_payment_item_id;

        return jsonb_build_object('success', true, 'converted', 0);
    end if;

    insert into public.payment_refunds (
        payment_id, payment_item_id, booking_type, booking_id,
        amount, gateway_amount_paise, refund_type, refund_status,
        refund_reason, initiated_by
    ) values (
        v_item.payment_id, v_item.id, v_item.booking_type, v_item.booking_id,
        v_convertible, (round(v_convertible * 100))::bigint,
        case when v_committed + v_convertible >= v_item.item_amount
             then 'full' else 'partial' end,
        'pending',
        'Deferred full-refund remainder converted after the blocking refund settled',
        'system'
    )
    returning id into v_refund_id;

    update public.payment_items
       set refund_due_amount = refund_due_amount - v_convertible
     where id = p_payment_item_id;

    return jsonb_build_object(
        'success',   true,
        'converted', v_convertible,
        'refund_id', v_refund_id
    );
end;
$function$;

-- ---------------------------------------------------------------------------
-- mark_refund_result — apply a gateway refund outcome.
--   p_refund_status: 'processed' | 'failed'
--   Called by the backend after the Razorpay refund API call and/or the
--   refund.processed / refund.failed webhooks.
--
--   IMPORTANT (Phase 2 review — confirmed): Razorpay's Refund API can
--   respond with status 'pending'. A PENDING API response must NEVER be
--   passed here as 'processed' — money is not yet confirmed returned. Only
--   a verified 'refund.processed' webhook, or a re-fetched gateway state
--   that shows the refund has settled, may mark the refund processed. The
--   backend service enforces this rule in Phase 3 (pending refunds stay
--   'pending' and remain visible for reconciliation until then).
-- ---------------------------------------------------------------------------
create or replace function public.mark_refund_result(
    p_refund_id          uuid,
    p_razorpay_refund_id text,
    p_refund_status      text,
    p_failure_reason     text default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_refund        public.payment_refunds%rowtype;
    v_item          public.payment_items%rowtype;
    v_seller_refund numeric(12,2);
    v_refunded_total numeric(12,2);
    v_payment_amount numeric(12,2);
    v_item_refunded_after numeric(12,2);
    v_payable_gross       numeric(12,2);
    v_payable_refunded    numeric(12,2);
begin
    if p_refund_status not in ('processed', 'failed') then
        raise exception 'Refund result status must be processed or failed';
    end if;

    select * into v_refund
      from public.payment_refunds
     where id = p_refund_id
     for update;

    if not found then
        raise exception 'Refund record not found';
    end if;

    -- ------------------------------------------------------------------
    -- Idempotency: already processed with the same gateway refund id.
    -- ------------------------------------------------------------------
    if v_refund.refund_status = 'processed' then
        if p_razorpay_refund_id is not null
           and v_refund.razorpay_refund_id = p_razorpay_refund_id
        then
            return jsonb_build_object('success', true, 'already_processed', true);
        end if;

        raise exception
            'Refund already processed with a different gateway refund id';
    end if;

    if p_razorpay_refund_id is not null then
        if exists (
            select 1
              from public.payment_refunds
             where razorpay_refund_id = p_razorpay_refund_id
               and id <> p_refund_id
        ) then
            raise exception 'Gateway refund id already recorded on another refund';
        end if;
    end if;

    if p_refund_status = 'failed' then
        update public.payment_refunds
           set refund_status   = 'failed',
               razorpay_refund_id = coalesce(p_razorpay_refund_id, razorpay_refund_id),
               failure_reason  = left(coalesce(p_failure_reason, 'Refund failed'), 500)
         where id = p_refund_id;

        -- CORRECTION (Phase 2 round 2): the failed result frees the unique
        -- pending-per-booking slot — convert any deferred full-refund
        -- remainder into a fresh pending record so the obligation stays
        -- durably represented and retryable.
        perform public.convert_refund_due_to_pending_refund(v_refund.payment_item_id);

        return jsonb_build_object(
            'success', true,
            'refund_status', 'failed'
        );
    end if;

    -- ------------------ processed ------------------
    update public.payment_refunds
       set refund_status      = 'processed',
           razorpay_refund_id = p_razorpay_refund_id,
           processed_at       = now(),
           failure_reason     = null
     where id = p_refund_id;

    select * into v_item
      from public.payment_items
     where id = v_refund.payment_item_id
     for update;

    -- ------------------------------------------------------------------
    -- Item-level refunded total first, so the booking outcome can use it.
    -- ------------------------------------------------------------------
    update public.payment_items
       set refunded_amount = refunded_amount + v_refund.amount
     where id = v_item.id
    returning refunded_amount into v_item_refunded_after;

    -- ------------------------------------------------------------------
    -- Booking-level outcome.
    -- CORRECTION (Phase 2 review) — 'refunded' semantics: a booking's
    -- payment_status becomes 'refunded' ONLY when its ENTIRE refundable
    -- portion (rental_amount + security_deposit for rentals, trial_fee for
    -- trials) has been returned. The retained platform fee is tracked in
    -- the financial columns (payment_items.platform_fee /
    -- seller_payables), never expressed through the booking status. Until
    -- the full refundable portion is returned, the booking keeps
    -- 'success'/'successful' with refund_status='processed'.
    -- ------------------------------------------------------------------
    if v_item.booking_type = 'rental' then
        if v_item_refunded_after >= v_item.refundable_amount then
            update public.rentals
               set payment_status = 'refunded',
                   refund_status  = 'processed',
                   refunded_at    = coalesce(refunded_at, now()),
                   updated_at     = now()
             where id = v_item.booking_id
               and payment_status = 'success';
        else
            update public.rentals
               set refund_status  = 'processed',
                   refunded_at    = coalesce(refunded_at, now()),
                   updated_at     = now()
             where id = v_item.booking_id
               and payment_status = 'success';
        end if;
    else
        if v_item_refunded_after >= v_item.refundable_amount then
            update public.trial_requests
               set payment_status = 'refunded'
             where id = v_item.booking_id
               and payment_status = 'successful';
        end if;
    end if;

    -- Seller payable impact: only the seller gross portion (rental_amount /
    -- trial_fee) reduces seller liability; a security deposit component was
    -- never seller income.
    -- CORRECTION (Phase 2 review): clamp against the REMAINING un-refunded
    -- seller gross, so multiple refunds on one item can never push
    -- seller_payables.refund_amount past gross_amount.
    select gross_amount, refund_amount
      into v_payable_gross, v_payable_refunded
      from public.seller_payables
     where payment_item_id = v_item.id
     for update;

    if found then
        v_seller_refund := least(
            v_refund.amount,
            v_payable_gross - v_payable_refunded
        );

        if v_seller_refund > 0 then
            update public.seller_payables
               set refund_amount    = refund_amount + v_seller_refund,
                   settlement_status = case
                       when settlement_status = 'settled' then settlement_status
                       else 'on_hold'
                   end
             where payment_item_id = v_item.id;
        end if;
    end if;
    -- (No seller payable row: the item was recorded by
    --  create_full_item_refund_records without confirmation, e.g. a late
    --  capture that could not confirm bookings — nothing to adjust.)

    -- CORRECTION (Phase 2 round 2): the settled refund frees the unique
    -- pending-per-booking slot — convert any deferred full-refund remainder
    -- into a fresh pending record so the obligation stays durably
    -- represented (mark_refund_result never treats a calculated amount as
    -- money moved; the new record is pending like any other).
    perform public.convert_refund_due_to_pending_refund(v_refund.payment_item_id);

    -- Payment aggregate status.
    select coalesce(sum(amount), 0)
      into v_refunded_total
      from public.payment_refunds
     where payment_id = v_refund.payment_id
       and refund_status = 'processed';

    update public.payments
       set payment_status = case
               when v_refunded_total >= amount then 'refunded'
               else 'partially_refunded'
           end
     where id = v_refund.payment_id;

    select amount
      into v_payment_amount
      from public.payments
     where id = v_refund.payment_id;

    return jsonb_build_object(
        'success',        true,
        'refund_status',  'processed',
        'refund_id',      p_refund_id,
        'refunded_total', v_refunded_total,
        'payment_status', case
               when v_refunded_total >= v_payment_amount then 'refunded'
               else 'partially_refunded'
           end
    );
end;
$function$;

-- ---------------------------------------------------------------------------
-- Trial rejection refund policy (CONFIRMED in Phase 2):
--   seller rejects a PAID trial request -> refund the trial fee, retain the
--   platform fee. Creates only a PENDING refund record; the actual Razorpay
--   refund is initiated by the backend service and confirmed via
--   mark_refund_result.
-- Legacy dummy rows (payment_status='successful' without a payment_item)
-- are ignored: no payment_item exists for them.
-- ---------------------------------------------------------------------------
create or replace function public.handle_trial_rejection_refund()
returns trigger
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_item record;
begin
    if old.status = 'pending'
       and new.status = 'rejected'
       and lower(coalesce(new.payment_status, '')) = 'successful'
    then
        select pi.id as payment_item_id, pi.payment_id, pi.trial_fee
          into v_item
          from public.payment_items pi
         where pi.booking_type = 'trial'
           and pi.booking_id = new.id;

        if found and v_item.trial_fee > 0 then
            insert into public.payment_refunds (
                payment_id, payment_item_id, booking_type, booking_id,
                amount, gateway_amount_paise, refund_type, refund_status,
                refund_reason, initiated_by
            ) values (
                v_item.payment_id, v_item.payment_item_id, 'trial', new.id,
                v_item.trial_fee, (round(v_item.trial_fee * 100))::bigint,
                'partial', 'pending',
                'Trial request rejected by seller', 'system'
            )
            on conflict do nothing;  -- payment_refunds_one_pending_per_booking
        end if;
    end if;

    return new;
end;
$function$;

create trigger trg_trial_rejection_refund
    after update of status on public.trial_requests
    for each row
    execute function public.handle_trial_rejection_refund();

-- ---------------------------------------------------------------------------
-- Function-level security (Phase 2 correction).
-- All definer functions are SECURITY DEFINER with
-- `set search_path to 'public', 'pg_temp'` (verified above) and mutate
-- money-relevant refund state, so they are BACKEND-ONLY: direct EXECUTE is
-- revoked from public, anon and authenticated and granted exclusively to the
-- service role used by the FastAPI backend.
-- handle_trial_rejection_refund is a trigger function: it is executed as the
-- trigger owner and can never be called directly by a client, but the
-- revocation keeps it defense-in-depth consistent with the others.
-- NOTE: dropping a function (rollback above) also drops its grants.
-- ---------------------------------------------------------------------------
revoke execute on function
    public.initiate_item_refund(uuid, numeric, text, text)
    from public, anon, authenticated;
revoke execute on function
    public.initiate_full_payment_refund(uuid, text, text)
    from public, anon, authenticated;
revoke execute on function
    public.mark_refund_result(uuid, text, text, text)
    from public, anon, authenticated;
revoke execute on function
    public.handle_trial_rejection_refund()
    from public, anon, authenticated;
revoke execute on function
    public.convert_refund_due_to_pending_refund(uuid)
    from public, anon, authenticated;

grant execute on function
    public.initiate_item_refund(uuid, numeric, text, text)
    to service_role;
grant execute on function
    public.initiate_full_payment_refund(uuid, text, text)
    to service_role;
grant execute on function
    public.mark_refund_result(uuid, text, text, text)
    to service_role;
grant execute on function
    public.handle_trial_rejection_refund()
    to service_role;
grant execute on function
    public.convert_refund_due_to_pending_refund(uuid)
    to service_role;
