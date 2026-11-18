-- ============================================================================
-- MIGRATION 20261117000900 — OPTIONAL: scheduled stale-checkout expiry
-- Attirely / Razorpay integration — Phase 2 (DATABASE DESIGN — DO NOT EXECUTE
-- until reviewed and approved.)
--
-- Purpose:
--   Runs expire_stale_checkouts() and expire_orphan_reservations() every
--   minute so abandoned reservations release inventory even when no new
--   checkout is initiated. This is a convenience layer ONLY: every checkout
--   init function already calls expire_stale_checkouts() lazily (see
--   migration 20261117000400), so the system is correct without pg_cron.
--
-- Rollback:
--   select cron.unschedule('attirely-expire-stale-checkouts');
--   select cron.unschedule('attirely-expire-orphan-reservations');
--   drop extension if exists pg_cron;   -- only if no other jobs exist
-- ============================================================================

-- pg_cron may already be installed on the Supabase project; if the extension
-- is unavailable, the notices explain that lazy expiry still covers correctness.
do $$
begin
    create extension if not exists pg_cron;
exception
    when others then
        raise notice 'pg_cron is unavailable on this project; scheduled expiry skipped. Lazy expiry in checkout functions remains active.';
end
$$;

-- Re-schedule idempotently.
do $$
begin
    perform cron.unschedule(jobid)
      from cron.job
     where jobname in ('attirely-expire-stale-checkouts',
                       'attirely-expire-orphan-reservations');

    perform cron.schedule(
        'attirely-expire-stale-checkouts',
        '* * * * *',
        $job$ select public.expire_stale_checkouts(); $job$
    );

    perform cron.schedule(
        'attirely-expire-orphan-reservations',
        '*/10 * * * *',
        $job$ select public.expire_orphan_reservations(); $job$
    );
exception
    when undefined_object then
        raise notice 'cron schema unavailable; skipping schedule. Lazy expiry remains active.';
end
$$;
