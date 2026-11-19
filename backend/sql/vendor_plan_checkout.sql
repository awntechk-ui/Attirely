begin;

create table public.vendor_plan_checkouts (
    id uuid primary key,
    vendor_id uuid not null references public.vendors(id) on delete cascade,
    plan_id text not null,
    plan_snapshot jsonb not null,
    amount_paise bigint not null check (amount_paise > 0),
    razorpay_order_id text not null unique,
    payment_id text unique,
    result jsonb,
    check ((payment_id is null) = (result is null))
);

create unique index vendor_plan_checkouts_pending_idx
    on public.vendor_plan_checkouts (vendor_id, plan_id, amount_paise)
    where payment_id is null;

alter table public.vendor_plan_checkouts enable row level security;
revoke all on public.vendor_plan_checkouts from public, anon, authenticated;
grant select on public.vendor_plan_checkouts to service_role;

create function public.register_vendor_plan_checkout(
    checkout_id uuid, owner_id uuid, selected_plan_id text,
    snapshot jsonb, amount bigint, order_id text
) returns jsonb
language plpgsql security definer
set search_path = pg_catalog, public
as $$
declare
    checkout public.vendor_plan_checkouts%rowtype;
begin
    perform 1 from public.vendors where id = owner_id for update;

    if exists (
        select 1 from public.vendor_subscriptions
        where vendor_id = owner_id and plan_id::text = selected_plan_id
          and status = 'active' and (ends_at is null or ends_at > now())
    ) then
        return null;
    end if;

    select * into checkout from public.vendor_plan_checkouts
    where vendor_id = owner_id and plan_id = selected_plan_id
      and amount_paise = amount and payment_id is null;
    if not found then
        insert into public.vendor_plan_checkouts (
            id, vendor_id, plan_id, plan_snapshot, amount_paise, razorpay_order_id
        ) values (
            checkout_id, owner_id, selected_plan_id, snapshot, amount, order_id
        ) returning * into checkout;
    end if;
    return to_jsonb(checkout);
end;
$$;

create function public.finalize_vendor_plan_checkout(
    checkout_id uuid, owner_id uuid, verified_payment_id text
) returns jsonb
language plpgsql security definer
set search_path = pg_catalog, public
as $$
declare
    checkout public.vendor_plan_checkouts%rowtype;
    selected_plan_id public.vendor_plan.id%type;
    subscription_id public.vendor_subscriptions.id%type;
    activation_time timestamptz;
    period_start timestamptz;
    paid_amount numeric;
    activation_result jsonb;
begin
    perform 1 from public.vendors where id = owner_id for update;
    select * into strict checkout from public.vendor_plan_checkouts
    where id = checkout_id and vendor_id = owner_id for update;

    if checkout.result is not null then
        if checkout.payment_id <> verified_payment_id then
            raise exception 'Checkout already paid';
        end if;
        return checkout.result;
    end if;

    select id into strict selected_plan_id from public.vendor_plan
    where id::text = checkout.plan_id;
    if checkout.plan_snapshot->>'billing_interval' is distinct from 'monthly' then
        raise exception 'Unsupported plan billing interval';
    end if;

    activation_time := clock_timestamp();

    -- If two valid payments for the same plan arrive after a price change,
    -- preserve the time already purchased when adding the new period.
    select max(ends_at) into period_start from public.vendor_subscriptions
    where vendor_id = owner_id and plan_id = selected_plan_id and status = 'active';
    period_start := greatest(activation_time, period_start);

    update public.vendor_subscriptions set status = 'expired'
    where vendor_id = owner_id and status = 'active' and ends_at <= activation_time;

    update public.vendor_subscriptions
    set status = 'cancelled', ends_at = activation_time, auto_renew = false
    where vendor_id = owner_id and status = 'active';

    paid_amount := checkout.amount_paise / 100.0;
    insert into public.vendor_subscriptions (
        vendor_id, plan_id, status, starts_at, activated_at, ends_at,
        auto_renew, amount_due, amount_paid, currency, plan_snapshot, terms_accepted
    ) values (
        owner_id, selected_plan_id, 'active', activation_time, activation_time,
        ((period_start at time zone 'Asia/Kolkata') + interval '1 month') at time zone 'Asia/Kolkata',
        false, paid_amount, paid_amount, 'INR', checkout.plan_snapshot, false
    ) returning id into subscription_id;

    activation_result := jsonb_build_object('success', true, 'subscription_id', subscription_id);
    update public.vendor_plan_checkouts
    set payment_id = verified_payment_id, result = activation_result
    where id = checkout_id;
    return activation_result;
end;
$$;

revoke all on function public.register_vendor_plan_checkout(uuid, uuid, text, jsonb, bigint, text)
    from public, anon, authenticated;
revoke all on function public.finalize_vendor_plan_checkout(uuid, uuid, text)
    from public, anon, authenticated;
grant execute on function public.register_vendor_plan_checkout(uuid, uuid, text, jsonb, bigint, text)
    to service_role;
grant execute on function public.finalize_vendor_plan_checkout(uuid, uuid, text)
    to service_role;

commit;
