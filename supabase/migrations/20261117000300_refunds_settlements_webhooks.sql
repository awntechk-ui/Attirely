-- ============================================================================
-- MIGRATION 20261117000300 — payment_refunds, seller_payables, payment_webhook_events
-- Attirely / Razorpay integration — Phase 2 (DATABASE DESIGN — DO NOT EXECUTE
-- until reviewed and approved).
--
-- Purpose:
--   payment_refunds         - every gateway refund (full or partial), pending →
--                             processed/failed lifecycle. A refund RECORD is
--                             never proof that money moved; the Razorpay
--                             refund id + 'processed' status are.
--   seller_payables         - seller-wise financial obligations for future
--                             Razorpay Route settlements. Security deposits are
--                             NOT part of seller gross (they are customer
--                             liabilities, returned on item completion).
--   payment_webhook_events  - raw webhook storage + idempotency + retries.
--
-- CORRECTION (Phase 2 review) — seller_payables financial safety:
--   The original CHECK `net_payable = gross_amount - platform_fee` combined
--   with `net_payable >= 0` FAILS whenever platform_fee > gross_amount (e.g. a
--   very low rental amount with the current ₹50 platform fee). Inside
--   confirm_razorpay_payment that failure would roll back an ALREADY-VERIFIED
--   gateway capture — the worst possible failure mode.
--   Fix (interim financial rule, documented in RAZORPAY_DATABASE_DESIGN.md §7):
--     net_payable      = greatest(gross_amount - platform_fee, 0)
--     platform_subsidy = greatest(platform_fee - gross_amount, 0)
--   platform_subsidy records how much of the platform fee the platform absorbs
--   when it exceeds the seller gross. The "seller owes platform" alternative
--   (allowing negative net_payable) is a PRODUCT DECISION and is NOT
--   implemented silently — see design doc §7 and the audit correction section.
--
-- CORRECTION (Phase 2 round 2): payment_refunds gains gateway_initiated_at /
-- gateway_initiated_amount — a pending refund handed to Razorpay is immutable;
-- see the column comments.
--
-- Rollback:
--   drop trigger if exists trg_payment_refunds_updated_at on public.payment_refunds;
--   drop trigger if exists trg_seller_payables_updated_at on public.seller_payables;
--   drop table if exists public.payment_webhook_events;
--   drop table if exists public.seller_payables;
--   drop table if exists public.payment_refunds;
--   (Dropping a table drops its constraints, indexes and RLS policies.)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- payment_refunds
-- ---------------------------------------------------------------------------
create table if not exists public.payment_refunds (
    id                    uuid primary key default gen_random_uuid(),
    payment_id            uuid not null references public.payments(id) on delete restrict,
    payment_item_id       uuid references public.payment_items(id) on delete restrict,
    booking_type          text check (booking_type in ('trial', 'rental')),
    booking_id            uuid,
    razorpay_refund_id    text unique,
    amount                numeric(12,2) not null check (amount > 0),
    gateway_amount_paise  bigint not null check (gateway_amount_paise > 0),
    refund_type           text not null check (refund_type in ('full', 'partial')),
    refund_status         text not null default 'pending'
        check (refund_status in ('pending', 'processed', 'failed')),
    refund_reason         text,
    initiated_by          text not null default 'system'
        check (initiated_by in ('customer', 'seller', 'system', 'admin')),
    -- CORRECTION (Phase 2 round 2): gateway-immutability tracking.
    -- Phase 3 contract: the backend sets gateway_initiated_at (and the exact
    -- initiated amount) IMMEDIATELY after calling the Razorpay Refund API,
    -- before any result is recorded. A pending refund that has reached the
    -- gateway is IMMUTABLE: its amount must never be enlarged and no second
    -- concurrent gateway refund may be created for the same money
    -- (create_full_item_refund_records relies on this).
    gateway_initiated_at    timestamptz,
    gateway_initiated_amount numeric(12,2),
    failure_reason        text,
    initiated_at          timestamptz not null default now(),
    processed_at          timestamptz,
    created_at            timestamptz not null default now(),
    updated_at            timestamptz not null default now(),

    -- Gateway amount equals the record amount expressed in paise.
    constraint payment_refunds_amount_paise_matches
        check (gateway_amount_paise = (round(amount * 100))::bigint),

    -- booking_type/booking_id are either both set or both unset.
    constraint payment_refunds_booking_ref_consistency
        check ((booking_type is null) = (booking_id is null))
);

create index if not exists payment_refunds_payment_idx
    on public.payment_refunds (payment_id);

create index if not exists payment_refunds_item_idx
    on public.payment_refunds (payment_item_id)
    where payment_item_id is not null;

-- Duplicate-refund protection: at most ONE pending refund per booking at a
-- time. Processed/failed refunds do not block a legitimate retry.
create unique index if not exists payment_refunds_one_pending_per_booking
    on public.payment_refunds (booking_type, booking_id)
    where booking_id is not null and refund_status = 'pending';

create trigger trg_payment_refunds_updated_at
    before update on public.payment_refunds
    for each row execute function public.payment_touch_updated_at();

-- ---------------------------------------------------------------------------
-- seller_payables (future Razorpay Route settlement accounting; NO transfers
-- are implemented in this phase)
-- ---------------------------------------------------------------------------
create table if not exists public.seller_payables (
    id                   uuid primary key default gen_random_uuid(),
    payment_id           uuid not null references public.payments(id) on delete restrict,
    payment_item_id      uuid not null unique references public.payment_items(id) on delete restrict,
    seller_user_id       uuid not null,
    vendor_id            uuid references public.vendors(id) on delete set null,
    booking_type         text not null check (booking_type in ('trial', 'rental')),
    -- Gross excludes the security deposit: deposits are refundable customer
    -- liabilities, never seller income.
    gross_amount         numeric(12,2) not null check (gross_amount >= 0),
    platform_fee         numeric(10,2) not null default 0 check (platform_fee >= 0),
    -- Interim rule (product decision pending): when the platform fee exceeds
    -- the seller gross, the platform absorbs the difference (subsidy) and the
    -- seller simply owes nothing. platform_subsidy makes that visible instead
    -- of losing the information in a clamped net_payable.
    platform_subsidy     numeric(10,2) not null default 0 check (platform_subsidy >= 0),
    net_payable          numeric(12,2) not null check (net_payable >= 0),
    refund_amount        numeric(12,2) not null default 0 check (refund_amount >= 0),
    settlement_status    text not null default 'pending'
        check (settlement_status in ('pending', 'eligible', 'on_hold', 'settled', 'cancelled')),
    settlement_reference text,
    created_at           timestamptz not null default now(),
    updated_at           timestamptz not null default now(),

    constraint seller_payables_net_matches
        check (net_payable      = greatest(gross_amount - platform_fee, 0)
           and platform_subsidy = greatest(platform_fee - gross_amount, 0))
);

create index if not exists seller_payables_seller_idx
    on public.seller_payables (seller_user_id);

create index if not exists seller_payables_settlement_status_idx
    on public.seller_payables (settlement_status);

create trigger trg_seller_payables_updated_at
    before update on public.seller_payables
    for each row execute function public.payment_touch_updated_at();

-- ---------------------------------------------------------------------------
-- payment_webhook_events
-- razorpay_event_id comes from the X-Razorpay-Event-Id header (falls back to a
-- deterministic hash of the raw payload computed by the backend). UNIQUE
-- guarantees an event can never be processed twice.
-- ---------------------------------------------------------------------------
create table if not exists public.payment_webhook_events (
    id                    uuid primary key default gen_random_uuid(),
    razorpay_event_id     text not null unique,
    event_type            text not null,
    razorpay_event_created_at bigint,
    razorpay_payment_id   text,
    razorpay_order_id     text,
    razorpay_refund_id    text,
    signature_valid       boolean not null default true,
    payload               jsonb not null,
    processing_status     text not null default 'received'
        check (processing_status in ('received', 'processed', 'failed', 'skipped')),
    processing_error      text,
    retry_count           integer not null default 0,
    received_at           timestamptz not null default now(),
    processed_at          timestamptz
);

create index if not exists payment_webhook_events_status_idx
    on public.payment_webhook_events (processing_status, received_at);

create index if not exists payment_webhook_events_payment_idx
    on public.payment_webhook_events (razorpay_payment_id)
    where razorpay_payment_id is not null;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.payment_refunds enable row level security;

drop policy if exists "payment_refunds_select_own" on public.payment_refunds;
create policy "payment_refunds_select_own"
    on public.payment_refunds
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

alter table public.seller_payables enable row level security;

drop policy if exists "seller_payables_select_own" on public.seller_payables;
create policy "seller_payables_select_own"
    on public.seller_payables
    for select
    to authenticated
    using (seller_user_id = auth.uid());
-- Sellers can see their own payables; nobody else's. Writes: service role only.

alter table public.payment_webhook_events enable row level security;
-- No policies at all: webhook events are internal; only the service role can
-- read/write them.
