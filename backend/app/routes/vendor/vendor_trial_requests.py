# from datetime import datetime, timezone
# from typing import Literal, Union
# from uuid import UUID

# from fastapi import APIRouter, Depends, HTTPException
# from pydantic import BaseModel, Field

# from app.core.auth_dependency import get_current_vendor
# from app.core.supabase import supabase_admin as supabase

# router = APIRouter(
#     prefix="/vendor/trial-requests",
#     tags=["Vendor Trial Requests"],
# )


# # ============================================================
# # REQUEST MODELS
# # ============================================================


# class TrialAcceptRequest(BaseModel):
#     status: Literal["accepted"]
#     trial_method: Literal[
#         "doorstep_delivery",
#         "store_visit"
#     ]


# class TrialRejectRequest(BaseModel):
#     status: Literal["rejected"]
#     rejection_reason: str = Field(
#         min_length=1,
#         max_length=500,
#     )


# TrialStatusUpdate = Union[
#     TrialAcceptRequest,
#     TrialRejectRequest,
# ]



# # ============================================================
# # GET VENDOR TRIAL REQUESTS
# # ============================================================

# @router.get("")
# def get_vendor_trial_requests(
#     vendor=Depends(get_current_vendor),
# ):
#     try:
#         vendor_id = str(vendor["id"])

#         result = (
#             supabase.table("trial_requests")
#             .select("*")
#             .eq("vendor_id", vendor_id)
#             .order("created_at", desc=True)
#             .execute()
#         )

#         requests = result.data or []

#         # Collect outfit IDs to fetch images in one query.
#         outfit_ids = list({
#             request["outfit_id"]
#             for request in requests
#             if request.get("outfit_id")
#         })

#         image_map = {}

#         if outfit_ids:
#             image_result = (
#                 supabase.table("outfit_images")
#                 .select(
#                     "outfit_id,image_url,is_cover,display_order"
#                 )
#                 .in_("outfit_id", outfit_ids)
#                 .order("display_order")
#                 .execute()
#             )

#             images = image_result.data or []

#             for image in images:
#                 outfit_id = image["outfit_id"]

#                 if outfit_id not in image_map:
#                     image_map[outfit_id] = []

#                 image_map[outfit_id].append(image)

#         # Attach cover image to every request.
#         enriched_requests = []

#         for request in requests:
#             request = dict(request)

#             outfit_images = image_map.get(
#                 request.get("outfit_id"),
#                 [],
#             )

#             cover_image = next(
#                 (
#                     image
#                     for image in outfit_images
#                     if image.get("is_cover") is True
#                 ),
#                 outfit_images[0] if outfit_images else None,
#             )

#             request["outfit_image_url"] = (
#                 cover_image.get("image_url")
#                 if cover_image
#                 else None
#             )

#             enriched_requests.append(request)

#         return {
#             "success": True,
#             "total": len(enriched_requests),
#             "requests": enriched_requests,
#         }

#     except Exception as e:
#         print("GET VENDOR TRIAL REQUESTS ERROR:", repr(e))

#         raise HTTPException(
#             status_code=500,
#             detail="Failed to fetch trial requests.",
#         )


# # ============================================================
# # ACCEPT / REJECT TRIAL REQUEST
# # ============================================================


# @router.patch("/{request_id}/status")
# def update_trial_request_status(
#     request_id: UUID,
#     payload: TrialStatusUpdate,
#     vendor=Depends(get_current_vendor),
# ):
#     try:
#         vendor_id = str(vendor["id"])

#         update_data = {}

#         # ACCEPT REQUEST
#         if payload.status == "accepted":

#             update_data = {
#                 "status": "accepted",
#                 "trial_method": payload.trial_method,
#                 "accepted_at": datetime.now(
#                     timezone.utc
#                 ).isoformat(),
#                 "rejection_reason": None,
#             }

#         # REJECT REQUEST
#         elif payload.status == "rejected":

#             reason = payload.rejection_reason.strip()

#             if not reason:
#                 raise HTTPException(
#                     status_code=400,
#                     detail="Please provide a rejection reason."
#                 )

#             update_data = {
#                 "status": "rejected",
#                 "rejection_reason": reason,
#             }

#         # UPDATE ONLY PENDING REQUESTS
#         updated = (
#             supabase.table("trial_requests")
#             .update(update_data)
#             .eq("id", str(request_id))
#             .eq("vendor_id", vendor_id)
#             .eq("status", "pending")
#             .execute()
#         )

#         if not updated.data:
#             raise HTTPException(
#                 status_code=409,
#                 detail=(
#                     "Pending trial request not found. "
#                     "It may already have been processed."
#                 )
#             )

#         return {
#             "success": True,
#             "message": (
#                 "Trial request accepted successfully."
#                 if payload.status == "accepted"
#                 else "Trial request rejected successfully."
#             ),
#             "request": updated.data[0],
#         }

#     except HTTPException:
#         raise

#     except Exception as e:
#         print("UPDATE TRIAL REQUEST ERROR:", repr(e))

#         raise HTTPException(
#             status_code=500,
#             detail="Failed to update trial request."
#         )

from datetime import datetime, timezone
from typing import Literal, Union
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.auth_dependency import get_current_user
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


class TrialHandedOverRequest(BaseModel):
    status: Literal["handed_over"]


class TrialCompleteRequest(BaseModel):
    status: Literal["completed"]


TrialStatusUpdate = Union[
    TrialAcceptRequest,
    TrialRejectRequest,
    TrialHandedOverRequest,
    TrialCompleteRequest,
]


# ============================================================
# GET OWNER TRIAL REQUESTS
# Supports vendor and individual user outfit owners
# ============================================================

@router.get("")
def get_vendor_trial_requests(
    current_user=Depends(get_current_user),
):
    try:
        user_id = str(current_user.id)

        # Find all outfits uploaded by this logged-in user.
        # Supports both vendor and individual outfit roles.
        outfit_result = (
            supabase.table("outfits")
            .select("id")
            .eq("uploaded_by", user_id)
            .in_("role", ["vendor", "user"])
            .execute()
        )

        outfit_ids = [
            str(outfit["id"])
            for outfit in (outfit_result.data or [])
        ]

        if not outfit_ids:
            return {
                "success": True,
                "total": 0,
                "requests": [],
            }

        # Fetch trial requests belonging to these outfits.
        result = (
            supabase.table("trial_requests")
            .select("*")
            .in_("outfit_id", outfit_ids)
            .order("created_at", desc=True)
            .execute()
        )

        requests = result.data or []

        # Collect outfit IDs to fetch images in one query.
        request_outfit_ids = list({
            str(request["outfit_id"])
            for request in requests
            if request.get("outfit_id")
        })

        image_map = {}

        if request_outfit_ids:
            image_result = (
                supabase.table("outfit_images")
                .select(
                    "outfit_id,image_url,is_cover,display_order"
                )
                .in_("outfit_id", request_outfit_ids)
                .order("display_order")
                .execute()
            )

            for image in (image_result.data or []):
                outfit_id = str(image["outfit_id"])

                image_map.setdefault(outfit_id, []).append(image)

        # Attach cover image to every request.
        enriched_requests = []

        for request in requests:
            request = dict(request)

            outfit_id = str(request.get("outfit_id", ""))

            outfit_images = image_map.get(outfit_id, [])

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
        print("GET OWNER TRIAL REQUESTS ERROR:", repr(e))

        raise HTTPException(
            status_code=500,
            detail="Failed to fetch trial requests.",
        )


# ============================================================
# ACCEPT / REJECT / HAND OVER / COMPLETE
# ============================================================

@router.patch("/{request_id}/status")
def update_trial_request_status(
    request_id: UUID,
    payload: TrialStatusUpdate,
    current_user=Depends(get_current_user),
):
    try:
        user_id = str(current_user.id)

        # ----------------------------------------------------
        # 1. FETCH REQUEST
        # ----------------------------------------------------

        request_result = (
            supabase.table("trial_requests")
            .select("id,outfit_id,status")
            .eq("id", str(request_id))
            .limit(1)
            .execute()
        )

        if not request_result.data:
            raise HTTPException(
                status_code=404,
                detail="Trial request not found.",
            )

        trial_request = request_result.data[0]

        outfit_id = str(trial_request["outfit_id"])
        current_status = trial_request["status"]

        # ----------------------------------------------------
        # 2. VERIFY OUTFIT OWNERSHIP
        # ----------------------------------------------------

        outfit_result = (
            supabase.table("outfits")
            .select("id,uploaded_by,role")
            .eq("id", outfit_id)
            .eq("uploaded_by", user_id)
            .in_("role", ["vendor", "user"])
            .limit(1)
            .execute()
        )

        if not outfit_result.data:
            raise HTTPException(
                status_code=403,
                detail="You are not authorized to manage this trial request.",
            )

        # ----------------------------------------------------
        # 3. PREPARE STATUS UPDATE
        # ----------------------------------------------------

        update_data = {}

        # ACCEPT
        if payload.status == "accepted":

            if current_status != "pending":
                raise HTTPException(
                    status_code=409,
                    detail="Only pending requests can be accepted.",
                )

            update_data = {
                "status": "accepted",
                "trial_method": payload.trial_method,
                "accepted_at": datetime.now(
                    timezone.utc
                ).isoformat(),
                "rejection_reason": None,
            }

        # REJECT
        elif payload.status == "rejected":

            if current_status != "pending":
                raise HTTPException(
                    status_code=409,
                    detail="Only pending requests can be rejected.",
                )

            reason = payload.rejection_reason.strip()

            if not reason:
                raise HTTPException(
                    status_code=400,
                    detail="Please provide a rejection reason.",
                )

            update_data = {
                "status": "rejected",
                "rejection_reason": reason,
            }

        # HAND OVER TO CUSTOMER
        elif payload.status == "handed_over":

            if current_status != "accepted":
                raise HTTPException(
                    status_code=409,
                    detail="Only accepted requests can be handed over.",
                )

            update_data = {
                "status": "handed_over",
            }

        # COMPLETE
        elif payload.status == "completed":

            if current_status != "handed_over":
                raise HTTPException(
                    status_code=409,
                    detail="Only handed-over requests can be completed.",
                )

            update_data = {
                "status": "completed",
                "completed_at": datetime.now(
                    timezone.utc
                ).isoformat(),
            }

        # ----------------------------------------------------
        # 4. UPDATE REQUEST
        # ----------------------------------------------------

        updated = (
            supabase.table("trial_requests")
            .update(update_data)
            .eq("id", str(request_id))
            .eq("status", current_status)
            .execute()
        )

        if not updated.data:
            raise HTTPException(
                status_code=409,
                detail="Trial request status changed. Please refresh and try again.",
            )

        messages = {
            "accepted": "Trial request accepted successfully.",
            "rejected": "Trial request rejected successfully.",
            "handed_over": "Outfit handed over to customer successfully.",
            "completed": "Trial request completed successfully.",
        }

        return {
            "success": True,
            "message": messages[payload.status],
            "request": updated.data[0],
        }

    except HTTPException:
        raise

    except Exception as e:
        print("UPDATE TRIAL REQUEST ERROR:", repr(e))

        raise HTTPException(
            status_code=500,
            detail="Failed to update trial request.",
        )
