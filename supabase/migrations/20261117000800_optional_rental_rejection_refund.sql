-- ============================================================================
-- MIGRATION 20261117000800 — OPTIONAL: extend the rental refund trigger policy
-- Attirely / Razorpay integration — Phase 2 (DATABASE DESIGN — DO NOT EXECUTE
-- until reviewed and approved. This migration is OPTIONAL and requires an
-- explicit product decision — see "Approval required" below.)
--
-- Approval required:
--   The existing policy (calculate_customer_rental_refund) only computes a
--   refund when the CUSTOMER cancels a PENDING rental. With real money the
--   following gaps become customer-facing problems:
--
--     Gap 1: a seller REJECTS a paid pending rental (manage_rental_status
--            action='reject') -> today the customer stays paid with no refund.
--     Gap 2: a seller/owner CANCELS an accepted paid rental (allowed by
--            manage_rental_status more than 24h before start) -> today the
--            customer stays paid with no refund.
--
-- Proposed extension (amounts consistent with the existing policy: platform
-- fee retained, refund = rental_amount + security_deposit):
--     Gap 1 -> refund on pending -> rejected (paid)
--     Gap 2 -> refund on accepted -> cancelled by vendor/owner (paid)
--
-- Refunds stay gateway-neutral (refund_status='pending'); Razorpay refunds
-- are initiated by the backend service and confirmed by mark_refund_result.
--
-- Rollback:
--   Restore the original function body from
--   backend/app/core/existing_payment_functions.sql
--   (CREATE OR REPLACE FUNCTION public.calculate_customer_rental_refund ...),
--   then drop the payment_refunds rows created by the extension if any
--   (refund_reason = 'Rental rejected by seller' / 'Rental cancelled by seller').
-- ============================================================================

create or replace function public.calculate_customer_rental_refund()
returns trigger
language plpgsql
as $function$
begin

    -- ---------------------------------------------------------------
    -- EXISTING POLICY (unchanged): customer cancels a pending rental.
    -- Refund rental amount + security deposit; platform fee retained.
    -- ---------------------------------------------------------------
    IF OLD.status = 'pending'
       AND NEW.status = 'cancelled'
       AND NEW.cancelled_by_role = 'customer'
    THEN

        IF LOWER(COALESCE(NEW.payment_status, '')) = 'success' THEN

            NEW.refund_amount :=
                COALESCE(NEW.rental_amount, 0)
                + COALESCE(NEW.security_deposit_amount, 0);

            NEW.refund_status := 'pending';

        ELSE

            NEW.refund_amount := 0;
            NEW.refund_status := 'not_applicable';

        END IF;

        NEW.refunded_at := NULL;

    -- ---------------------------------------------------------------
    -- EXTENSION (Gap 1): seller rejects a paid pending rental.
    -- ---------------------------------------------------------------
    ELSIF OLD.status = 'pending'
       AND NEW.status = 'rejected'
       AND LOWER(COALESCE(NEW.payment_status, '')) = 'success'
    THEN

        NEW.refund_amount :=
            COALESCE(NEW.rental_amount, 0)
            + COALESCE(NEW.security_deposit_amount, 0);

        NEW.refund_status := 'pending';
        NEW.refunded_at   := NULL;

    -- ---------------------------------------------------------------
    -- EXTENSION (Gap 2): seller/owner cancels an accepted paid rental.
    -- (manage_rental_status already blocks owner cancellation within
    --  24 hours of the start date.)
    -- ---------------------------------------------------------------
    ELSIF OLD.status = 'accepted'
       AND NEW.status = 'cancelled'
       AND NEW.cancelled_by_role IN ('vendor', 'owner')
       AND LOWER(COALESCE(NEW.payment_status, '')) = 'success'
    THEN

        NEW.refund_amount :=
            COALESCE(NEW.rental_amount, 0)
            + COALESCE(NEW.security_deposit_amount, 0);

        NEW.refund_status := 'pending';
        NEW.refunded_at   := NULL;

    END IF;

    RETURN NEW;
END;
$function$;
