
from datetime import datetime, timezone

from fastapi import HTTPException

from app.core.supabase import supabase_admin


def select_vendor_plan(vendor: dict, plan_code: str):

    vendor_id = vendor["id"]

    # 1. Fetch the selected plan
    plan_response = (
        supabase_admin
        .table("vendor_plan")
        .select("*")
        .eq("plan_code", plan_code)
        .eq("target_role", "vendor")
        .eq("is_active", True)
        .limit(1)
        .execute()
    )

    if not plan_response.data:
        raise HTTPException(
            status_code=404,
            detail="Selected subscription plan is unavailable",
        )

    plan = plan_response.data[0]

    # 2. Only free lifetime plans are enabled for now
    if float(plan["price"]) != 0 or plan["billing_interval"] != "lifetime":
        raise HTTPException(
            status_code=501,
            detail="Paid subscription activation is coming soon",
        )

    # 3. Check whether this vendor already has an active subscription
    active_response = (
        supabase_admin
        .table("vendor_subscriptions")
        .select("*")
        .eq("vendor_id", vendor_id)
        .eq("status", "active")
        .limit(1)
        .execute()
    )

    if active_response.data:
        existing = active_response.data[0]

        # Repeated request for the same plan:
        # return the existing subscription instead of creating another.
        if str(existing["plan_id"]) == str(plan["id"]):
            return {
                "success": True,
                "message": "Your plan is already active",
                "subscription": existing,
                "already_active": True,
            }

        raise HTTPException(
            status_code=409,
            detail="You already have an active vendor subscription",
        )

    # 4. Check pending subscriptions
    pending_response = (
        supabase_admin
        .table("vendor_subscriptions")
        .select("id")
        .eq("vendor_id", vendor_id)
        .eq("status", "pending_payment")
        .limit(1)
        .execute()
    )

    if pending_response.data:
        raise HTTPException(
            status_code=409,
            detail="You already have a pending subscription",
        )

    # 5. Create a snapshot of the selected plan
    now = datetime.now(timezone.utc).isoformat()

    plan_snapshot = {
        "plan_code": plan["plan_code"],
        "plan_name": plan["plan_name"],
        "plan_label": plan["plan_label"],
        "description": plan["description"],
        "price": float(plan["price"]),
        "currency": plan["currency"],
        "billing_interval": plan["billing_interval"],
        "outfits_limit": plan["outfits_limit"],
        "accessories_limit": plan["accessories_limit"],
        "outfits_unlimited": plan["outfits_unlimited"],
        "accessories_unlimited": plan["accessories_unlimited"],
        "features": plan["features"],
        "restrictions": plan["restrictions"],
    }

    # 6. Activate the free subscription
    subscription_data = {
        "vendor_id": vendor_id,
        "plan_id": plan["id"],
        "status": "active",
        "starts_at": now,
        "activated_at": now,
        "ends_at": None,
        "auto_renew": False,
        "amount_due": 0,
        "amount_paid": 0,
        "currency": plan["currency"],
        "plan_snapshot": plan_snapshot,
        "terms_accepted": False,
    }

    try:
        insert_response = (
            supabase_admin
            .table("vendor_subscriptions")
            .insert(subscription_data)
            .execute()
        )

        if not insert_response.data:
            raise HTTPException(
                status_code=500,
                detail="Subscription could not be created",
            )

        subscription = insert_response.data[0]

        return {
            "success": True,
            "message": "Starter plan activated successfully",
            "subscription": subscription,
            "already_active": False,
        }

    except HTTPException:
        raise

    except Exception as e:
        print("VENDOR SUBSCRIPTION ERROR:", repr(e))

        raise HTTPException(
            status_code=500,
            detail="Failed to activate vendor subscription",
        )
def get_current_vendor_subscription(vendor: dict):

    vendor_id = vendor["id"]

    # 1. Fetch the vendor's active subscription
    response = (
        supabase_admin
        .table("vendor_subscriptions")
        .select("*")
        .eq("vendor_id", vendor_id)
        .eq("status", "active")
        .limit(1)
        .execute()
    )

    # 2. No active subscription found
    if not response.data:
        return {
            "success": True,
            "has_active_subscription": False,
            "subscription": None,
        }

    subscription = response.data[0]

    # 3. Get plan details from the saved plan snapshot
    plan = subscription.get("plan_snapshot") or {}

    return {
        "success": True,
        "has_active_subscription": True,
        "subscription": {
            "id": subscription["id"],
            "status": subscription["status"],
            "plan_code": plan.get("plan_code"),
            "plan_name": plan.get("plan_name"),
            "plan_label": plan.get("plan_label"),
            "price": plan.get("price"),
            "billing_interval": plan.get("billing_interval"),
            "outfits_limit": plan.get("outfits_limit"),
            "accessories_limit": plan.get("accessories_limit"),
            "outfits_unlimited": plan.get("outfits_unlimited"),
            "accessories_unlimited": plan.get("accessories_unlimited"),
            "starts_at": subscription.get("starts_at"),
            "ends_at": subscription.get("ends_at"),
        },
    }