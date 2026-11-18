-- ============================================================================
-- MIGRATION 20261117000200 — payments + payment_items
-- Attirely / Razorpay integration — Phase 2 (DATABASE DESIGN — DO NOT EXECUTE
-- until reviewed and approved).
--
-- Purpose:
--   Core payment architecture.
--     payments       - ONE row per Razorpay checkout transaction (one order).
--     payment_items  - ONE row per booking item included in that payment.
--
-- Amount policy:
--   - Business amounts are stored as NUMERIC(12,2) rupees (consistent with the
--     existing rentals / trial_requests financial columns).
--   - gateway_amount_paise (BIGINT) is the authoritative amount sent to and
--     reconciled against Razorpay (integer paise, no float precision issues).
--   - A CHECK constraint ties the two together.
--
-- Idempotency:
--   - UNIQUE(booking_reference): one payment record per checkout; retries reuse
--     the same payment row and the same Razorpay order.
--   - UNIQUE(razorpay_order_id), UNIQUE(razorpay_payment_id).
--
-- CORRECTION (Phase 2 review):
--   payment_items previously had no updated_at column while
--   trg_payment_items_updated_at (payment_touch_updated_at) references
--   NEW.updated_at — any UPDATE (e.g. mark_refund_result setting
--   refunded_amount) would fail with "column updated_at does not exist".
--   The column is now part of the table definition.
--
-- CORRECTION (Phase 2 round 2):
--   platform_subsidy (subsidy accounting consistent with seller_payables)
--   and refund_due_amount (durable representation of a refund remainder that
--   cannot be recorded while an already-gateway-initiated pending refund
--   blocks the one-pending-refund-per-booking index) are new columns.
--
-- Rollback:
--   drop function if exists public.payment_touch_updated_at();
--   drop table if exists public.payment_items;
--   drop table if exists public.payments;
--   (Dropping the tables also drops their triggers; dropping the function
--   drops its usage.)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Generic updated_at maintenance for payment tables.
-- ---------------------------------------------------------------------------
create or replace function public.payment_touch_updated_at()
returns trigger
language plpgsql
as $function$
begin
    new.updated_at = now();
    return new;
end;
$function$;

-- ---------------------------------------------------------------------------
-- payments
-- ---------------------------------------------------------------------------
create table if not exists public.payments (
    id                   uuid primary key default gen_random_uuid(),
    user_id              uuid not null references public.users(id) on delete restrict,
    booking_reference    uuid not null,
    checkout_type        text not null check (checkout_type in ('trial', 'rental')),
    gateway              text not null default 'razorpay' check (gateway = 'razorpay'),
    razorpay_order_id    text unique,
    razorpay_payment_id  text unique,
    amount               numeric(12,2) not null check (amount > 0),
    gateway_amount_paise bigint not null check (gateway_amount_paise > 0),
    currency             text not null default 'INR' check (currency = 'INR'),
    payment_status       text not null default 'created'
        check (payment_status in (
            'created',            -- order created, checkout not yet completed
            'pending',            -- checkout opened, attempt in progress
            'authorized',         -- gateway authorized, awaiting capture
            'captured',           -- verified successful payment
            'failed',             -- last attempt failed (retry still allowed until expiry)
            'cancelled',          -- explicitly cancelled by operator/system
            'expired',            -- abandoned: reservation window elapsed
            'partially_refunded', -- one or more items refunded
            'refunded'            -- fully refunded
        )),
    gateway_status       text,
    failure_reason       text,
    payment_method       text,
    verified_at          timestamptz,
    paid_at              timestamptz,
    expires_at           timestamptz not null,
    metadata             jsonb not null default '{}'::jsonb,
    created_at           timestamptz not null default now(),
    updated_at           timestamptz not null default now(),

    -- Gateway amount must equal the business amount expressed in paise.
    constraint payments_amount_paise_matches
        check (gateway_amount_paise = (round(amount * 100))::bigint)
);

create unique index if not exists payments_booking_reference_key
    on public.payments (booking_reference);

-- Active-checkout scan index (used by expire_stale_checkouts and retry lookups).
create index if not exists payments_active_expiry_idx
    on public.payments (expires_at)
    where payment_status in ('created', 'pending', 'failed');

create index if not exists payments_user_created_idx
    on public.payments (user_id, created_at desc);

create index if not exists payments_status_idx
    on public.payments (payment_status);

create trigger trg_payments_updated_at
    before update on public.payments
    for each row execute function public.payment_touch_updated_at();

-- ---------------------------------------------------------------------------
-- payment_items
-- ---------------------------------------------------------------------------
create table if not exists public.payment_items (
    id                    uuid primary key default gen_random_uuid(),
    payment_id            uuid not null references public.payments(id) on delete cascade,
    booking_reference     uuid not null,
    booking_type          text not null check (booking_type in ('trial', 'rental')),
    booking_id            uuid not null,
    outfit_id             uuid not null references public.outfits(id) on delete restrict,
    seller_type           text not null check (seller_type in ('vendor', 'individual')),
    vendor_id             uuid references public.vendors(id) on delete set null,
    seller_user_id        uuid not null,
    item_amount           numeric(12,2) not null check (item_amount >= 0),
    rental_amount         numeric(12,2),
    trial_fee             numeric(10,2),
    security_deposit      numeric(12,2) not null default 0 check (security_deposit >= 0),
    platform_fee          numeric(10,2) not null default 0 check (platform_fee >= 0),
    -- CORRECTION (Phase 2 round 2): consistent subsidy accounting. When the
    -- platform fee exceeds the seller gross (rental_amount / trial_fee), the
    -- platform absorbs the difference. Mirrors seller_payables.platform_subsidy.
    platform_subsidy      numeric(10,2) not null default 0 check (platform_subsidy >= 0),
    -- CORRECTION (Phase 2 round 2): deferred refund obligation. Set ONLY by
    -- create_full_item_refund_records when an item already has a pending
    -- refund that has been handed to Razorpay (immutable) and the full-refund
    -- requirement exceeds it. The Phase 3 refund pickup converts this amount
    -- into a real pending refund record once the blocking refund settles
    -- (mark_refund_result does this automatically). Never part of
    -- item_amount accounting; it is an amount still OWED to the customer.
    refund_due_amount     numeric(12,2) not null default 0 check (refund_due_amount >= 0),
    refundable_amount     numeric(12,2) not null default 0 check (refundable_amount >= 0),
    seller_payable_amount numeric(12,2) not null default 0 check (seller_payable_amount >= 0),
    refunded_amount       numeric(12,2) not null default 0 check (refunded_amount >= 0),
    created_at            timestamptz not null default now(),
    updated_at            timestamptz not null default now(),

    -- Type-specific financial components.
    constraint payment_items_type_consistency check (
        (booking_type = 'rental' and rental_amount is not null and trial_fee is null)
        or
        (booking_type = 'trial'  and trial_fee    is not null and rental_amount is null)
    ),

    -- Item amount must equal the sum of its recorded components.
    constraint payment_items_amount_match check (
        (booking_type = 'rental'
            and item_amount = rental_amount + security_deposit + platform_fee)
        or
        (booking_type = 'trial'
            and item_amount = trial_fee + platform_fee)
    )
);

-- One payment item per booking; one booking cannot appear in two payments.
create unique index if not exists payment_items_booking_key
    on public.payment_items (booking_type, booking_id);

create unique index if not exists payment_items_payment_booking_key
    on public.payment_items (payment_id, booking_id);

create index if not exists payment_items_payment_idx
    on public.payment_items (payment_id);

create index if not exists payment_items_seller_idx
    on public.payment_items (seller_user_id);

create index if not exists payment_items_vendor_idx
    on public.payment_items (vendor_id)
    where vendor_id is not null;

create trigger trg_payment_items_updated_at
    before update on public.payment_items
    for each row execute function public.payment_touch_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- The FastAPI backend uses the service role (RLS bypassed). These policies
-- protect against any future direct client access.
-- ---------------------------------------------------------------------------
alter table public.payments enable row level security;

drop policy if exists "payments_select_own" on public.payments;
create policy "payments_select_own"
    on public.payments
    for select
    to authenticated
    using (user_id = auth.uid());
-- No write policies: only the service role can create/modify payments.

alter table public.payment_items enable row level security;

drop policy if exists "payment_items_select_own" on public.payment_items;
create policy "payment_items_select_own"
    on public.payment_items
    for select
    to authenticated
    using (
        exists (
            select 1
              from public.payments p
             where p.id = payment_id
               and p.user_id = auth.uid()
        )
    );
-- No write policies: only the service role.
