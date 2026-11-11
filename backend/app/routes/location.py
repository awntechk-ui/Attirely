
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.auth_dependency import get_current_user
from app.core.supabase import supabase_admin


router = APIRouter(
    prefix="/location",
    tags=["Location"],
)


# ============================================================
# REQUEST MODEL
# ============================================================

class LocationSetupRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)


# ============================================================
# FIND THE AUTHENTICATED ACCOUNT
# ============================================================

def _get_account_location_record(user_id: str):
    """
    Identify whether the authenticated account is a vendor or user.
    Vendor is checked first, matching your existing /auth/session logic.
    """

    vendor_response = (
        supabase_admin
        .table("vendors")
        .select(
            "id, latitude, longitude, location_setup_completed"
        )
        .eq("auth_user_id", user_id)
        .limit(1)
        .execute()
    )

    if vendor_response.data:
        return "vendor", vendor_response.data[0]

    user_response = (
        supabase_admin
        .table("users")
        .select(
            "id, latitude, longitude, location_setup_completed"
        )
        .eq("id", user_id)
        .limit(1)
        .execute()
    )

    if user_response.data:
        return "user", user_response.data[0]

    raise HTTPException(
        status_code=404,
        detail="User or vendor profile not found.",
    )


# ============================================================
# GET LOCATION SETUP STATUS
# ============================================================

@router.get("/me")
def get_my_location(
    current_user=Depends(get_current_user),
):
    user_id = str(current_user.id)

    try:
        role, record = _get_account_location_record(user_id)

        return {
            "success": True,
            "role": role,
            "location_setup_completed": (
                record.get("location_setup_completed") is True
            ),
            "latitude": record.get("latitude"),
            "longitude": record.get("longitude"),
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("GET LOCATION ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to retrieve location.",
        )


# ============================================================
# SAVE INITIAL OR UPDATED LOCATION
# ============================================================

@router.put("/setup")
def save_my_location(
    data: LocationSetupRequest,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user.id)

    try:
        role, record = _get_account_location_record(user_id)

        if role == "vendor":
            response = (
                supabase_admin
                .table("vendors")
                .update({
                    "latitude": data.latitude,
                    "longitude": data.longitude,
                    "location_setup_completed": True,
                })
                .eq("auth_user_id", user_id)
                .execute()
            )

        else:
            response = (
                supabase_admin
                .table("users")
                .update({
                    "latitude": data.latitude,
                    "longitude": data.longitude,
                    "location_setup_completed": True,
                })
                .eq("id", user_id)
                .execute()
            )

        if not response.data:
            raise HTTPException(
                status_code=500,
                detail="Location could not be saved.",
            )

        saved = response.data[0]

        return {
            "success": True,
            "message": "Location saved successfully.",
            "role": role,
            "location_setup_completed": True,
            "latitude": saved.get("latitude"),
            "longitude": saved.get("longitude"),
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("SAVE LOCATION ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to save location.",
        )
