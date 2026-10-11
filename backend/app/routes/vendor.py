from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.auth_dependency import (
    get_current_user,
    get_current_vendor,
)
from app.core.supabase import supabase_admin


router = APIRouter(
    prefix="/vendor",
    tags=["Vendor"],
)


# ============================================================
# VENDOR PROFILE RESPONSE
# ============================================================

@router.get("/me")
def get_vendor_profile(
    vendor=Depends(get_current_vendor),
):
    return {
        "success": True,
        "vendor": vendor,
    }


# ============================================================
# UPDATE VENDOR PROFILE
# ============================================================

class VendorUpdateRequest(BaseModel):
    store_name: str | None = None
    business_description: str | None = None
    owner_type: str | None = None

    phone_number: str | None = None

    address: str | None = None
    city: str | None = None
    state: str | None = None
    pincode: str | None = None

    instagram: str | None = None

    aadhaar: str | None = None
    pan: str | None = None


@router.put("/me")
def update_vendor_profile(
    data: VendorUpdateRequest,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user.id)

    # ========================================================
    # CHECK VENDOR EXISTS
    # ========================================================

    existing = (
        supabase_admin
        .table("vendors")
        .select("id")
        .eq("auth_user_id", user_id)
        .limit(1)
        .execute()
    )

    if not existing.data:
        raise HTTPException(
            status_code=403,
            detail="Vendor profile not found",
        )

    # ========================================================
    # VALIDATE OWNER TYPE
    # ========================================================

    if (
        data.owner_type is not None
        and data.owner_type
        not in ["individual", "store_owner"]
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "owner_type must be "
                "'individual' or 'store_owner'"
            ),
        )

    # ========================================================
    # BUILD UPDATE DATA
    # ========================================================

    update_data = {
        key: value
        for key, value in data.model_dump().items()
        if value is not None
    }

    if not update_data:
        raise HTTPException(
            status_code=400,
            detail="No fields to update",
        )

    # ========================================================
    # UPDATE
    # ========================================================

    response = (
        supabase_admin
        .table("vendors")
        .update(update_data)
        .eq("auth_user_id", user_id)
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=500,
            detail="Failed to update vendor profile",
        )

    return {
        "success": True,
        "message": "Vendor profile updated successfully",
        "vendor": response.data[0],
    }


# ============================================================
# CHECK CURRENT USER'S VENDOR STATUS
# ============================================================

@router.get("/status")
def vendor_status(
    current_user=Depends(get_current_user),
):
    user_id = str(current_user.id)

    response = (
        supabase_admin
        .table("vendors")
        .select("id, store_name, owner_type")
        .eq("auth_user_id", user_id)
        .limit(1)
        .execute()
    )

    if not response.data:
        return {
            "is_vendor": False,
            "vendor": None,
        }

    return {
        "is_vendor": True,
        "vendor": response.data[0],
    }   