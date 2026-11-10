
# app/routes/trials.py

from datetime import date
from typing import Any
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.auth_dependency import get_current_user
from app.core.supabase import supabase_admin as supabase


router = APIRouter(
    prefix="/trials",
    tags=["Trials"]
)


# ============================================================
# REQUEST MODELS
# ============================================================

class TrialOutfitItem(BaseModel):
    outfit_id: UUID
    selected_size: str = Field(min_length=1)

    preferred_trial_date: date
    preferred_time_slot: str = Field(min_length=1)

    # Snapshot of the address selected for this outfit.
    trial_address: dict[str, Any]


class TrialBookingRequest(BaseModel):
    outfits: list[TrialOutfitItem] = Field(min_length=1)


# ============================================================
# CREATE TRIAL BOOKING
# ============================================================

@router.post("/book")
def book_trials(
    payload: TrialBookingRequest,
    current_user=Depends(get_current_user)
):
    try:
        user_id = str(current_user.id)

        # ----------------------------------------------------
        # 1. GET USER PROFILE
        # ----------------------------------------------------

        user_response = (
            supabase.table("users")
            .select("id, full_name")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )

        if not user_response.data:
            raise HTTPException(
                status_code=404,
                detail="User profile not found"
            )

        user_name = user_response.data[0]["full_name"]

        # ----------------------------------------------------
        # 2. CHECK DUPLICATE OUTFITS IN SAME REQUEST
        # ----------------------------------------------------

        outfit_ids = [str(item.outfit_id) for item in payload.outfits]

        if len(outfit_ids) != len(set(outfit_ids)):
            raise HTTPException(
                status_code=400,
                detail="The same outfit cannot be added twice"
            )

        # ----------------------------------------------------
        # 3. GENERATE COMMON BOOKING REFERENCE
        # ----------------------------------------------------

        booking_reference = str(uuid4())

        trial_rows = []

        # ----------------------------------------------------
        # 4. VALIDATE EACH OUTFIT
        # ----------------------------------------------------

        for item in payload.outfits:

            outfit_id = str(item.outfit_id)
            selected_size = item.selected_size.strip()

            if not item.trial_address:
                raise HTTPException(
                    status_code=400,
                    detail=f"Trial address is missing for outfit {outfit_id}"
                )

            # Validate preferred date
            if item.preferred_trial_date < date.today():
                raise HTTPException(
                    status_code=400,
                    detail="Trial date cannot be in the past"
                )

            # Fetch outfit
            outfit_response = (
                supabase.table("outfits")
                .select(
                    "id, uploaded_by, role, name, sizes, "
                    "status, is_available"
                )
                .eq("id", outfit_id)
                .limit(1)
                .execute()
            )

            if not outfit_response.data:
                raise HTTPException(
                    status_code=404,
                    detail=f"Outfit not found: {outfit_id}"
                )

            outfit = outfit_response.data[0]

            # Only vendor-uploaded outfits for this first version
            if outfit["role"] != "vendor":
                raise HTTPException(
                    status_code=400,
                    detail=f"{outfit['name']} is not a vendor-uploaded outfit"
                )

            if outfit["status"] != "published":
                raise HTTPException(
                    status_code=400,
                    detail=f"{outfit['name']} is not published"
                )

            if not outfit["is_available"]:
                raise HTTPException(
                    status_code=400,
                    detail=f"{outfit['name']} is currently unavailable"
                )

            # Validate size against JSONB array, e.g. ["L"]
            available_sizes = outfit.get("sizes") or []

            if selected_size not in available_sizes:
                raise HTTPException(
                    status_code=400,
                    detail=(
                        f"Size {selected_size} is not available "
                        f"for {outfit['name']}"
                    )
                )

            # ------------------------------------------------
            # 5. RESOLVE VENDOR FROM OUTFIT OWNER
            # ------------------------------------------------

            vendor_response = (
                supabase.table("vendors")
                .select("id")
                .eq("auth_user_id", outfit["uploaded_by"])
                .limit(1)
                .execute()
            )

            if not vendor_response.data:
                raise HTTPException(
                    status_code=400,
                    detail=f"Vendor profile not found for {outfit['name']}"
                )

            vendor_id = vendor_response.data[0]["id"]

            # ------------------------------------------------
            # 6. PREPARE ONE ROW PER OUTFIT
            # ------------------------------------------------

            trial_rows.append({
                "booking_reference": booking_reference,

                "user_id": user_id,
                "vendor_id": vendor_id,

                "outfit_id": outfit_id,

                "user_name": user_name,
                "outfit_name": outfit["name"],

                "selected_size": selected_size,

                "preferred_trial_date": (
                    item.preferred_trial_date.isoformat()
                ),
                "preferred_time_slot": item.preferred_time_slot,

                "trial_address": item.trial_address,

                "trial_method": None,
                "status": "pending",
                "rejection_reason": None,

                # Dummy payment for now
                "payment_status": "successful",
                "payment_method": "dummy",
                "payment_reference": f"DUMMY-{booking_reference}",

                "trial_fee": 150,
                "platform_fee": 50,
                "trial_amount": 200,
            })

        # ----------------------------------------------------
        # 7. INSERT ALL OUTFIT REQUESTS
        # ----------------------------------------------------

        insert_response = (
            supabase.table("trial_requests")
            .insert(trial_rows)
            .execute()
        )

        if not insert_response.data:
            raise HTTPException(
                status_code=500,
                detail="Could not create trial booking"
            )

        return {
            "success": True,
            "message": "Trial booking created successfully",
            "booking_reference": booking_reference,
            "payment_status": "successful",
            "total_outfits": len(insert_response.data),
            "total_amount": len(insert_response.data) * 200,
            "requests": insert_response.data
        }

    except HTTPException:
        raise

    except Exception as e:
        print("TRIAL BOOKING ERROR:", repr(e))

        raise HTTPException(
            status_code=500,
            detail="Failed to create trial booking"
        )
