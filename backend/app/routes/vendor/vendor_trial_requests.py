from datetime import datetime, timezone
from typing import Literal, Union
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.auth_dependency import get_current_vendor
from app.core.supabase import supabase_admin as supabase

router = APIRouter(
    prefix="/vendor/trial-requests",
    tags=["Vendor Trial Requests"],
)


# ============================================================
# REQUEST MODELS
# ============================================================


class TrialAcceptRequest(BaseModel):
    status: Literal["accepted"]
    trial_method: Literal[
        "doorstep_delivery",
        "store_visit"
    ]


class TrialRejectRequest(BaseModel):
    status: Literal["rejected"]
    rejection_reason: str = Field(
        min_length=1,
        max_length=500,
    )


TrialStatusUpdate = Union[
    TrialAcceptRequest,
    TrialRejectRequest,
]



# ============================================================
# GET VENDOR TRIAL REQUESTS
# ============================================================

@router.get("")
def get_vendor_trial_requests(
    vendor=Depends(get_current_vendor),
):
    try:
        vendor_id = str(vendor["id"])

        result = (
            supabase.table("trial_requests")
            .select("*")
            .eq("vendor_id", vendor_id)
            .order("created_at", desc=True)
            .execute()
        )

        requests = result.data or []

        # Collect outfit IDs to fetch images in one query.
        outfit_ids = list({
            request["outfit_id"]
            for request in requests
            if request.get("outfit_id")
        })

        image_map = {}

        if outfit_ids:
            image_result = (
                supabase.table("outfit_images")
                .select(
                    "outfit_id,image_url,is_cover,display_order"
                )
                .in_("outfit_id", outfit_ids)
                .order("display_order")
                .execute()
            )

            images = image_result.data or []

            for image in images:
                outfit_id = image["outfit_id"]

                if outfit_id not in image_map:
                    image_map[outfit_id] = []

                image_map[outfit_id].append(image)

        # Attach cover image to every request.
        enriched_requests = []

        for request in requests:
            request = dict(request)

            outfit_images = image_map.get(
                request.get("outfit_id"),
                [],
            )

            cover_image = next(
                (
                    image
                    for image in outfit_images
                    if image.get("is_cover") is True
                ),
                outfit_images[0] if outfit_images else None,
            )

            request["outfit_image_url"] = (
                cover_image.get("image_url")
                if cover_image
                else None
            )

            enriched_requests.append(request)

        return {
            "success": True,
            "total": len(enriched_requests),
            "requests": enriched_requests,
        }

    except Exception as e:
        print("GET VENDOR TRIAL REQUESTS ERROR:", repr(e))

        raise HTTPException(
            status_code=500,
            detail="Failed to fetch trial requests.",
        )


# ============================================================
# ACCEPT / REJECT TRIAL REQUEST
# ============================================================


@router.patch("/{request_id}/status")
def update_trial_request_status(
    request_id: UUID,
    payload: TrialStatusUpdate,
    vendor=Depends(get_current_vendor),
):
    try:
        vendor_id = str(vendor["id"])

        update_data = {}

        # ACCEPT REQUEST
        if payload.status == "accepted":

            update_data = {
                "status": "accepted",
                "trial_method": payload.trial_method,
                "accepted_at": datetime.now(
                    timezone.utc
                ).isoformat(),
                "rejection_reason": None,
            }

        # REJECT REQUEST
        elif payload.status == "rejected":

            reason = payload.rejection_reason.strip()

            if not reason:
                raise HTTPException(
                    status_code=400,
                    detail="Please provide a rejection reason."
                )

            update_data = {
                "status": "rejected",
                "rejection_reason": reason,
            }

        # UPDATE ONLY PENDING REQUESTS
        updated = (
            supabase.table("trial_requests")
            .update(update_data)
            .eq("id", str(request_id))
            .eq("vendor_id", vendor_id)
            .eq("status", "pending")
            .execute()
        )

        if not updated.data:
            raise HTTPException(
                status_code=409,
                detail=(
                    "Pending trial request not found. "
                    "It may already have been processed."
                )
            )

        return {
            "success": True,
            "message": (
                "Trial request accepted successfully."
                if payload.status == "accepted"
                else "Trial request rejected successfully."
            ),
            "request": updated.data[0],
        }

    except HTTPException:
        raise

    except Exception as e:
        print("UPDATE TRIAL REQUEST ERROR:", repr(e))

        raise HTTPException(
            status_code=500,
            detail="Failed to update trial request."
        )
