from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import datetime, timezone
from app.core.auth_dependency import get_current_user
from app.core.supabase import supabase_admin as supabase


router = APIRouter(
    prefix="/trial-requests",
    tags=["Trial Requests"]
)


class TrialStatusUpdate(BaseModel):
    status: str
    rejection_reason: Optional[str] = Field(default=None, max_length=500)


def get_authenticated_user_id(current_user):
    """Support the existing authenticated user object or dictionary."""
    if isinstance(current_user, dict):
        user_id = current_user.get("id")
    else:
        user_id = getattr(current_user, "id", None)

    if not user_id:
        raise HTTPException(
            status_code=401,
            detail="Unable to identify authenticated user."
        )

    return str(user_id)


def get_current_vendor_id(user_id: str):
    """Resolve the vendor profile belonging to the authenticated user."""
    result = (
        supabase.table("vendors")
        .select("id")
        .eq("auth_user_id", user_id)
        .limit(1)
        .execute()
    )

    if not result.data:
        raise HTTPException(
            status_code=403,
            detail="Vendor profile not found."
        )

    return str(result.data[0]["id"])


def attach_outfit_image(request):
    """Attach the cover image for the requested outfit."""
    outfit_result = (
        supabase.table("outfits")
        .select("id,name")
        .eq("id", request["outfit_id"])
        .limit(1)
        .execute()
    )

    request["outfit_image_url"] = None

    if not outfit_result.data:
        return request

    image_result = (
        supabase.table("outfit_images")
        .select("image_url,is_cover,display_order")
        .eq("outfit_id", request["outfit_id"])
        .order("display_order")
        .execute()
    )

    images = image_result.data or []

    cover = next(
        (image for image in images if image.get("is_cover")),
        images[0] if images else None
    )

    if cover:
        request["outfit_image_url"] = cover.get("image_url")

    return request


# =====================================================
# GET ALL TRIAL REQUESTS FOR LOGGED-IN VENDOR
# =====================================================

@router.get("/vendor")
def get_vendor_trial_requests(
    current_user=Depends(get_current_user)
):
    try:
        user_id = get_authenticated_user_id(current_user)
        vendor_id = get_current_vendor_id(user_id)

        result = (
            supabase.table("trial_requests")
            .select("*")
            .eq("vendor_id", vendor_id)
            .order("created_at", desc=True)
            .execute()
        )

        requests = result.data or []

        enriched_requests = [
            attach_outfit_image(dict(request))
            for request in requests
        ]

        return {
            "success": True,
            "vendor_id": vendor_id,
            "total": len(enriched_requests),
            "requests": enriched_requests
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("GET VENDOR TRIAL REQUESTS ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to fetch trial requests."
        )


# =====================================================
# ACCEPT OR REJECT TRIAL REQUEST
# =====================================================

@router.patch("/{request_id}/status")
def update_trial_request_status(
    request_id: UUID,
    payload: TrialStatusUpdate,
    current_user=Depends(get_current_user)
):
    try:
        user_id = get_authenticated_user_id(current_user)
        vendor_id = get_current_vendor_id(user_id)

        new_status = payload.status.strip().lower()

        if new_status not in ["accepted", "rejected"]:
            raise HTTPException(
                status_code=400,
                detail="Only accepted or rejected status is allowed."
            )

        update_data = {
            "status": new_status
        }

        if new_status == "accepted":
            update_data["accepted_at"] = datetime.now(
                timezone.utc
            ).isoformat()

        if new_status == "rejected":
            reason = (payload.rejection_reason or "").strip()

            if not reason:
                raise HTTPException(
                    status_code=400,
                    detail="Rejection reason is required."
                )

            update_data["rejection_reason"] = reason

        # Update only a pending request belonging to this vendor.
        existing = (
            supabase.table("trial_requests")
            .select("id,status")
            .eq("id", str(request_id))
            .eq("vendor_id", vendor_id)
            .limit(1)
            .execute()
        )

        if not existing.data:
            raise HTTPException(
                status_code=404,
                detail="Trial request not found."
            )

        if existing.data[0]["status"] != "pending":
            raise HTTPException(
                status_code=409,
                detail="This request has already been processed."
            )

        update_result = (
            supabase.table("trial_requests")
            .update(update_data)
            .eq("id", str(request_id))
            .eq("vendor_id", vendor_id)
            .eq("status", "pending")
            .execute()
        )

        if not update_result.data:
            raise HTTPException(
                status_code=409,
                detail="Request could not be updated. Please refresh."
            )

        return {
            "success": True,
            "message": (
                "Trial request accepted successfully."
                if new_status == "accepted"
                else "Trial request rejected successfully."
            ),
            "request": update_result.data[0]
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("UPDATE TRIAL REQUEST STATUS ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to update trial request."
        )