
from datetime import datetime, timezone

from fastapi import HTTPException

from app.core.supabase import supabase_admin


# =========================================================
# PLAN HELPERS
# =========================================================

def _get_plan_restrictions(plan: dict) -> dict:
    """
    Read media limits from the plan's restrictions JSON.
    Safe defaults are used if a key is missing.
    """
    restrictions = plan.get("restrictions") or {}

    return {
        "max_images_per_listing": int(
            restrictions.get("max_images_per_listing", 5)
        ),
        "max_videos_per_listing": int(
            restrictions.get("max_videos_per_listing", 0)
        ),
    }


def _build_plan_snapshot(plan: dict) -> dict:
    restrictions = _get_plan_restrictions(plan)

    return {
        "plan_code": plan["plan_code"],
        "plan_name": plan["plan_name"],
        "plan_label": plan.get("plan_label"),
        "description": plan.get("description"),
        "price": float(plan["price"]),
        "currency": plan["currency"],
        "billing_interval": plan["billing_interval"],

        "outfits_limit": plan.get("outfits_limit"),
        "accessories_limit": plan.get("accessories_limit"),

        "outfits_unlimited": plan["outfits_unlimited"],
        "accessories_unlimited": plan["accessories_unlimited"],

        "features": plan.get("features") or [],
        "restrictions": restrictions,

        "max_images_per_listing": restrictions[
            "max_images_per_listing"
        ],
        "max_videos_per_listing": restrictions[
            "max_videos_per_listing"
        ],
    }


# =========================================================
# SELECT / ACTIVATE VENDOR PLAN
# =========================================================

def select_vendor_plan(vendor: dict, plan_code: str):

    vendor_id = vendor["id"]

    plan_response = (
        supabase_admin.table("vendor_plan")
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

    # Paid plans remain unavailable until payment integration is ready.
    if (
        float(plan["price"]) != 0
        or plan["billing_interval"] != "lifetime"
    ):
        raise HTTPException(
            status_code=501,
            detail="Paid subscription activation is coming soon",
        )

    active_response = (
        supabase_admin.table("vendor_subscriptions")
        .select("*")
        .eq("vendor_id", vendor_id)
        .eq("status", "active")
        .limit(1)
        .execute()
    )

    if active_response.data:
        existing = active_response.data[0]

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

    pending_response = (
        supabase_admin.table("vendor_subscriptions")
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

    now = datetime.now(timezone.utc).isoformat()

    plan_snapshot = _build_plan_snapshot(plan)

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
            supabase_admin.table("vendor_subscriptions")
            .insert(subscription_data)
            .execute()
        )

        if not insert_response.data:
            raise HTTPException(
                status_code=500,
                detail="Subscription could not be created",
            )

        return {
            "success": True,
            "message": "Starter plan activated successfully",
            "subscription": insert_response.data[0],
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


# =========================================================
# GET CURRENT ACTIVE SUBSCRIPTION
# =========================================================

def get_current_vendor_subscription(vendor: dict):

    vendor_id = vendor["id"]

    response = (
        supabase_admin.table("vendor_subscriptions")
        .select("*")
        .eq("vendor_id", vendor_id)
        .eq("status", "active")
        .limit(1)
        .execute()
    )

    if not response.data:
        return {
            "success": True,
            "has_active_subscription": False,
            "subscription": None,
        }

    subscription = response.data[0]

    plan = subscription.get("plan_snapshot") or {}

    # Existing subscriptions may have been created before
    # media limits were added to the plan restrictions.
    restrictions = plan.get("restrictions") or {}

    if (
        "max_images_per_listing" not in restrictions
        or "max_videos_per_listing" not in restrictions
    ):
        current_plan_response = (
            supabase_admin.table("vendor_plan")
            .select("*")
            .eq("id", subscription["plan_id"])
            .limit(1)
            .execute()
        )

        if current_plan_response.data:
            current_plan = current_plan_response.data[0]
            current_restrictions = _get_plan_restrictions(
                current_plan
            )

            restrictions.update(current_restrictions)

    max_images = int(
        restrictions.get("max_images_per_listing", 5)
    )

    max_videos = int(
        restrictions.get("max_videos_per_listing", 0)
    )

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

            "outfits_unlimited": plan.get(
                "outfits_unlimited", False
            ),
            "accessories_unlimited": plan.get(
                "accessories_unlimited", False
            ),

            "max_images_per_listing": max_images,
            "max_videos_per_listing": max_videos,

            "starts_at": subscription.get("starts_at"),
            "ends_at": subscription.get("ends_at"),
        },
    }


# =========================================================
# GET ACTIVE VENDOR PLAN FOR ENFORCEMENT
# =========================================================

def get_vendor_plan_limits(vendor: dict) -> dict:
    """
    Returns the authenticated vendor's active plan limits.
    Raises an error if the vendor has no active subscription.
    """

    vendor_id = vendor["id"]

    response = (
        supabase_admin.table("vendor_subscriptions")
        .select("*")
        .eq("vendor_id", vendor_id)
        .eq("status", "active")
        .limit(1)
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=403,
            detail="No active vendor subscription found. Please select a plan.",
        )

    subscription = response.data[0]
    snapshot = subscription.get("plan_snapshot") or {}

    restrictions = snapshot.get("restrictions") or {}

    # Backward compatibility for subscriptions created
    # before media limits were stored in plan_snapshot.
    if (
        "max_images_per_listing" not in restrictions
        or "max_videos_per_listing" not in restrictions
    ):
        plan_response = (
            supabase_admin.table("vendor_plan")
            .select("*")
            .eq("id", subscription["plan_id"])
            .limit(1)
            .execute()
        )

        if not plan_response.data:
            raise HTTPException(
                status_code=500,
                detail="Subscription plan details could not be found.",
            )

        plan = plan_response.data[0]

        restrictions = _get_plan_restrictions(plan)

        snapshot["restrictions"] = restrictions

    return {
        "vendor_id": vendor_id,
        "auth_user_id": str(vendor["auth_user_id"]),
        "subscription_id": subscription["id"],

        "plan_code": snapshot.get("plan_code"),

        "outfits_limit": snapshot.get("outfits_limit"),
        "accessories_limit": snapshot.get("accessories_limit"),

        "outfits_unlimited": snapshot.get(
            "outfits_unlimited", False
        ),
        "accessories_unlimited": snapshot.get(
            "accessories_unlimited", False
        ),

        "max_images_per_listing": int(
            restrictions.get("max_images_per_listing", 5)
        ),
        "max_videos_per_listing": int(
            restrictions.get("max_videos_per_listing", 0)
        ),
    }


# =========================================================
# COUNT VENDOR LISTINGS
# =========================================================

def get_vendor_listing_counts(vendor: dict) -> dict:
    """
    Count all vendor listings.
    Unavailable listings are included.
    Permanently deleted listings are naturally excluded.
    """

    user_id = str(vendor["auth_user_id"])

    outfits_response = (
        supabase_admin.table("outfits")
        .select("id", count="exact")
        .eq("uploaded_by", user_id)
        .eq("role", "vendor")
        .execute()
    )

    accessories_response = (
        supabase_admin.table("accessories")
        .select("id", count="exact")
        .eq("uploaded_by", user_id)
        .eq("role", "vendor")
        .execute()
    )

    return {
        "outfits_count": outfits_response.count or 0,
        "accessories_count": accessories_response.count or 0,
    }


# =========================================================
# CHECK LISTING QUOTA BEFORE CREATE
# =========================================================

def check_vendor_listing_quota(
    vendor: dict,
    listing_type: str,
) -> dict:

    limits = get_vendor_plan_limits(vendor)
    counts = get_vendor_listing_counts(vendor)

    if listing_type == "outfit":

        current_count = counts["outfits_count"]
        maximum = limits["outfits_limit"]
        unlimited = limits["outfits_unlimited"]

        if not unlimited and current_count >= maximum:
            raise HTTPException(
                status_code=403,
                detail=(
                    f"You have reached your outfit limit "
                    f"({current_count}/{maximum}). "
                    "Upgrade your plan to add more outfits."
                ),
            )

    elif listing_type == "accessory":

        current_count = counts["accessories_count"]
        maximum = limits["accessories_limit"]
        unlimited = limits["accessories_unlimited"]

        if not unlimited and current_count >= maximum:
            raise HTTPException(
                status_code=403,
                detail=(
                    f"You have reached your accessory limit "
                    f"({current_count}/{maximum}). "
                    "Upgrade your plan to add more accessories."
                ),
            )

    else:
        raise ValueError("Invalid listing type")

    return {
        **limits,
        **counts,
    }


# =========================================================
# CHECK IMAGE LIMIT
# =========================================================

def check_vendor_image_limit(
    vendor: dict,
    image_count: int,
) -> int:

    limits = get_vendor_plan_limits(vendor)

    maximum = limits["max_images_per_listing"]

    if image_count > maximum:
        raise HTTPException(
            status_code=403,
            detail=(
                f"Your {limits['plan_code']} plan allows "
                f"up to {maximum} images per listing. "
                f"You selected {image_count} images."
            ),
        )

    return maximum
