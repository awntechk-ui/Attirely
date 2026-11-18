-- ============================================================================
-- MIGRATION 20261117000100 — payment_fee_settings
-- Attirely / Razorpay integration — Phase 2 (DATABASE DESIGN — DO NOT EXECUTE
-- until reviewed and approved).
--
-- Purpose:
--   Replaces hardcoded platform fees (previously: 50 in
--   app/services/rentals_service.py PLATFORM_FEE_PER_OUTFIT, 150/50 in
--   app/routes/trails.py and hardcoded in Flutter BookTrialLogic /
--   PaymentSecurityPage) with database-configured values.
--
-- Fee keys:
--   trial_fee           - per-trial-item fee charged for a trial (seller
--                         service fee; currently hardcoded 150).
--   trial_platform_fee  - per-trial-item Attirely platform fee (currently 50).
--   rental_platform_fee - per-rental-item Attirely platform fee (currently 50).
--
-- Rollback:
--   drop function if exists public.get_platform_fee(text);
--   drop table if exists public.payment_fee_settings;
--
-- Security:
--   get_platform_fee is SECURITY DEFINER (booking functions must read fees
--   regardless of caller). Execution is restricted to the service role; the
--   anon/authenticated/public paths are revoked. Dropping the function also
--   drops its grants.
-- ============================================================================

create table if not exists public.payment_fee_settings (
    id           uuid primary key default gen_random_uuid(),
    fee_key      text not null unique,
    description  text,
    fee_amount   numeric(10,2) not null check (fee_amount >= 0),
    currency     text not null default 'INR' check (currency in ('INR')),
    is_active    boolean not null default true,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now(),
    constraint payment_fee_settings_known_keys
        check (fee_key in ('trial_fee', 'trial_platform_fee', 'rental_platform_fee'))
);

-- ---------------------------------------------------------------------------
-- Seed values matching the CURRENT hardcoded behaviour exactly, so enabling
-- this table changes no financial outcome until fees are consciously changed.
-- (idempotent: only inserts when the key does not exist)
-- ---------------------------------------------------------------------------
insert into public.payment_fee_settings (fee_key, description, fee_amount)
values
    ('trial_fee',
     'Fixed per-item fee charged for a clothing trial (previously hardcoded at 150).',
     150),
    ('trial_platform_fee',
     'Attirely platform fee retained per trial item (previously hardcoded at 50).',
     50),
    ('rental_platform_fee',
     'Attirely platform fee retained per rental item (previously hardcoded at 50).',
     50)
on conflict (fee_key) do nothing;

-- ---------------------------------------------------------------------------
-- Fee lookup helper (read-only, SECURITY DEFINER so booking functions can read
-- the settings regardless of the caller role).
-- Raises when the requested fee is missing/inactive so callers cannot
-- silently compute a zero-fee checkout.
-- ---------------------------------------------------------------------------
create or replace function public.get_platform_fee(p_fee_key text)
returns numeric
language plpgsql
stable
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
    v_fee numeric(10,2);
begin
    select fee_amount
      into v_fee
      from public.payment_fee_settings
     where fee_key = p_fee_key
       and is_active = true
     limit 1;

    if v_fee is null then
        raise exception 'Platform fee % is not configured', p_fee_key;
    end if;

    return v_fee;
end;
$function$;

-- ---------------------------------------------------------------------------
-- RLS: read-only for authenticated clients (fee amounts are not secret).
-- Writes are restricted to the service role (RLS bypassed for service role).
-- ---------------------------------------------------------------------------
alter table public.payment_fee_settings enable row level security;

drop policy if exists "payment_fee_settings_read" on public.payment_fee_settings;
create policy "payment_fee_settings_read"
    on public.payment_fee_settings
    for select
    to authenticated
    using (true);
-- No insert/update/delete policies: customers/vendors can never modify fees.

-- ---------------------------------------------------------------------------
-- Function-level security (Phase 2 correction):
-- get_platform_fee is a backend/booking-internal helper. The checkout
-- functions call it as the function OWNER (SECURITY DEFINER), so no client
-- role needs direct EXECUTE. Direct client calls are revoked; the service
-- role (FastAPI backend) is granted execution explicitly.
-- NOTE: dropping the function (rollback above) also drops these grants.
-- ---------------------------------------------------------------------------
revoke execute on function public.get_platform_fee(text)
    from public, anon, authenticated;
grant execute on function public.get_platform_fee(text) to service_role;
