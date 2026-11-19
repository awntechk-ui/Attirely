import hashlib
import hmac
import logging
import os
from uuid import uuid4

import httpx
from fastapi import HTTPException
from fastapi.responses import JSONResponse

from app.core.supabase import supabase_admin


logger = logging.getLogger(__name__)


def razorpay_credentials():
    key_id = os.getenv("RAZORPAY_KEY_ID", "")
    secret = os.getenv("RAZORPAY_KEY_SECRET", "")
    if not key_id.startswith("rzp_test_") or not secret:
        raise HTTPException(503, "Razorpay test keys are not configured")
    return key_id, secret


def razorpay_request(method, path, **kwargs):
    key_id, secret = razorpay_credentials()
    try:
        response = httpx.request(
            method,
            f"https://api.razorpay.com/v1/{path}",
            auth=(key_id, secret),
            timeout=12,
            **kwargs,
        )
        response.raise_for_status()
        return response.json(), key_id
    except (httpx.HTTPError, ValueError) as error:
        logger.warning("Razorpay request failed: %s", type(error).__name__)
        raise HTTPException(502, "Razorpay is currently unavailable") from error


def create_razorpay_order(checkout_id, amount):
    return razorpay_request(
        "POST",
        "orders",
        json={
            "amount": amount,
            "currency": "INR",
            "receipt": checkout_id,
        },
    )


def create_checkout(user_id, kind, amount, booking):
    checkout_id = str(uuid4())
    order, key_id = create_razorpay_order(checkout_id, amount)
    supabase_admin.table("booking_checkouts").insert({
        "id": checkout_id,
        "user_id": user_id,
        "kind": kind,
        "amount_paise": amount,
        "razorpay_order_id": order["id"],
        "booking": {**booking, "payment_status": "pending"},
    }).execute()
    return {
        "checkout_id": checkout_id,
        "key_id": key_id,
        "razorpay_order_id": order["id"],
        "amount": amount,
        "currency": "INR",
    }


def get_checkout(user_id, checkout_id):
    response = (
        supabase_admin.table("booking_checkouts")
        .select("razorpay_order_id,amount_paise,payment_id,result")
        .eq("id", checkout_id)
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    if not response.data:
        raise HTTPException(404, "Checkout not found")
    return response.data[0]


def confirmation_pending(checkout_id, status):
    return JSONResponse(status_code=202, content={
        "success": False,
        "status": status,
        "checkout_id": checkout_id,
    })


def verify_razorpay_signature(order_id, payment_id, signature):
    _, secret = razorpay_credentials()
    expected = hmac.new(
        secret.encode(), f"{order_id}|{payment_id}".encode(), hashlib.sha256
    ).hexdigest()
    if not hmac.compare_digest(expected, signature):
        raise HTTPException(400, "Razorpay payment signature is invalid")


def razorpay_payment_status(checkout, payment):
    if (
        payment.get("order_id") != checkout["razorpay_order_id"]
        or payment.get("amount") != checkout["amount_paise"]
        or payment.get("currency") != "INR"
    ):
        raise HTTPException(400, "Payment details do not match this checkout")
    return payment.get("status")


def verify_checkout(user_id, checkout_id, payment_id, signature):
    checkout = get_checkout(user_id, checkout_id)
    verify_razorpay_signature(checkout["razorpay_order_id"], payment_id, signature)
    if checkout["result"] is not None:
        if checkout["payment_id"] != payment_id:
            raise HTTPException(409, "Checkout has already been paid")
        return checkout["result"]

    payment, _ = razorpay_request("GET", f"payments/{payment_id}")
    payment_status = razorpay_payment_status(checkout, payment)
    if payment_status in {"created", "authorized"}:
        return confirmation_pending(checkout_id, "capture_pending")
    if payment_status != "captured":
        raise HTTPException(400, "Razorpay did not capture this payment.")

    try:
        response = supabase_admin.rpc("finalize_booking_checkout", {
            "checkout_id": checkout_id,
            "customer_id": user_id,
            "verified_payment_id": payment_id,
        }).execute()
    except Exception:
        logger.exception("Could not confirm checkout %s", checkout_id)
        # Supabase may have committed the booking even if its response was lost.
        try:
            saved = get_checkout(user_id, checkout_id)
            if saved["payment_id"] == payment_id and saved["result"] is not None:
                return saved["result"]
        except Exception:
            logger.exception("Could not read back checkout %s", checkout_id)
        return confirmation_pending(checkout_id, "booking_pending")
    return response.data
