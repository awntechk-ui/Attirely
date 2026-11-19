import logging
from decimal import Decimal
from uuid import uuid4

import httpx
from fastapi import HTTPException
from postgrest.exceptions import APIError

from app.core.supabase import supabase_admin
from app.services.booking_payments import (
    confirmation_pending,
    create_razorpay_order,
    razorpay_payment_status,
    razorpay_request,
    verify_razorpay_signature,
)
from app.services.vendor_subscription_service import (
    _active_subscriptions,
    _build_plan_snapshot,
    get_available_vendor_plan,
)


logger = logging.getLogger(__name__)


def _execute_checkout_query(query, operation):
    try:
        return query.execute().data
    except APIError as error:
        logger.error("Vendor checkout database error during %s: %s", operation, error.code)
        if error.code in {"PGRST205", "PGRST202", "42P01", "42883", "42501"}:
            raise HTTPException(
                503,
                "Vendor plan payments are unavailable because the database setup is incomplete.",
            ) from error
        raise HTTPException(502, "Unable to access vendor checkout. Try again.") from error
    except httpx.RequestError as error:
        logger.warning("Vendor checkout database unavailable during %s", operation)
        raise HTTPException(503, "Vendor plan payments are temporarily unavailable.") from error


def _finalize_checkout(checkout, payment_id):
    try:
        return supabase_admin.rpc(
            "finalize_vendor_plan_checkout",
            {
                "checkout_id": checkout["id"],
                "owner_id": checkout["vendor_id"],
                "verified_payment_id": payment_id,
            },
        ).execute().data
    except Exception:
        logger.exception("Could not activate vendor checkout %s", checkout["id"])
        return confirmation_pending(checkout["id"], "activation_pending")


def start_vendor_plan_checkout(vendor, plan_code):
    plan = get_available_vendor_plan(plan_code)
    if (
        plan["billing_interval"] != "monthly"
        or plan["currency"] != "INR"
        or "coming soon" in (plan.get("price_note") or "").lower()
    ):
        raise HTTPException(400, "This plan is unavailable for payment")

    amount = Decimal(str(plan["price"])) * 100
    if amount <= 0 or amount != amount.to_integral_value():
        raise HTTPException(400, "The selected plan has an invalid price")
    amount = int(amount)

    vendor_id = vendor["id"]
    plan_id = str(plan["id"])
    pending = _execute_checkout_query(
        supabase_admin.table("vendor_plan_checkouts")
        .select("*")
        .eq("vendor_id", vendor_id)
        .eq("plan_id", plan_id)
        .is_("payment_id", "null"),
        "read pending orders",
    )

    # Recover a payment if the app closed before sending the Checkout callback.
    reusable = None
    key_id = None
    awaiting_capture = None
    for checkout in pending:
        order_id = checkout["razorpay_order_id"]
        payments, key_id = razorpay_request("GET", f"orders/{order_id}/payments")
        for payment in payments["items"]:
            status = razorpay_payment_status(checkout, payment)
            if status == "captured":
                return _finalize_checkout(checkout, payment["id"])
            if status in {"created", "authorized"}:
                awaiting_capture = checkout["id"]
        if checkout["amount_paise"] == amount:
            reusable = checkout
    if awaiting_capture:
        return confirmation_pending(awaiting_capture, "capture_pending")

    active = _active_subscriptions(vendor_id).eq("plan_id", plan_id).limit(1).execute()
    if active.data:
        return {"success": True, "subscription_id": active.data[0]["id"]}

    if reusable is None:
        checkout_id = str(uuid4())
        order, key_id = create_razorpay_order(checkout_id, amount)
        reusable = _execute_checkout_query(
            supabase_admin.rpc(
                "register_vendor_plan_checkout",
                {
                    "checkout_id": checkout_id,
                    "owner_id": vendor_id,
                    "selected_plan_id": plan_id,
                    "snapshot": _build_plan_snapshot(plan),
                    "amount": amount,
                    "order_id": order["id"],
                },
            ),
            "register order",
        )
        if reusable is None:
            return {"success": True}

    return {
        "checkout_id": reusable["id"],
        "key_id": key_id,
        "razorpay_order_id": reusable["razorpay_order_id"],
        "amount": reusable["amount_paise"],
        "currency": "INR",
    }


def verify_vendor_plan_checkout(vendor, checkout_id, payment_id, signature):
    checkouts = _execute_checkout_query(
        supabase_admin.table("vendor_plan_checkouts")
        .select("*")
        .eq("id", checkout_id)
        .eq("vendor_id", vendor["id"])
        .limit(1),
        "read order for verification",
    )
    if not checkouts:
        raise HTTPException(404, "Checkout not found")

    checkout = checkouts[0]
    verify_razorpay_signature(checkout["razorpay_order_id"], payment_id, signature)
    if checkout["result"] is not None:
        if checkout["payment_id"] != payment_id:
            raise HTTPException(409, "Checkout has already been paid")
        return checkout["result"]

    payment, _ = razorpay_request("GET", f"payments/{payment_id}")
    status = razorpay_payment_status(checkout, payment)
    if status in {"created", "authorized"}:
        return confirmation_pending(checkout_id, "capture_pending")
    if status != "captured":
        raise HTTPException(400, "Razorpay did not capture this payment.")
    return _finalize_checkout(checkout, payment_id)
