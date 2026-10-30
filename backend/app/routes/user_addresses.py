
from uuid import UUID
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.auth_dependency import get_current_user
from app.core.supabase import supabase_admin as supabase


router = APIRouter(
    prefix="/addresses",
    tags=["User Addresses"],
)


# ============================================================
# REQUEST MODELS
# ============================================================

class AddressRequest(BaseModel):
    full_name: str = Field(..., min_length=2)
    mobile: str = Field(..., min_length=10, max_length=15)

    house: str = Field(..., min_length=1)
    street: str = Field(..., min_length=1)
    landmark: Optional[str] = None

    city: str = Field(..., min_length=1)
    state: str = Field(..., min_length=1)
    pincode: str = Field(..., min_length=6, max_length=10)

    address_type: str = "Home"

    latitude: Optional[float] = None
    longitude: Optional[float] = None


class UpdateAddressRequest(BaseModel):
    full_name: Optional[str] = None
    mobile: Optional[str] = None

    house: Optional[str] = None
    street: Optional[str] = None
    landmark: Optional[str] = None

    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None

    address_type: Optional[str] = None

    latitude: Optional[float] = None
    longitude: Optional[float] = None


# ============================================================
# VERIFY NORMAL USER ACCOUNT
# ============================================================

def _get_user_id(current_user):
    user_id = str(current_user.id)

    try:
        result = (
            supabase.table("users")
            .select("id")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=403,
                detail="Only registered users can manage addresses.",
            )

        return user_id

    except HTTPException:
        raise

    except Exception as exc:
        print("ADDRESS USER VALIDATION ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to verify user account.",
        )


# ============================================================
# VALIDATE ADDRESS TYPE
# ============================================================

def _validate_address_type(address_type):
    if address_type not in ["Home", "Work", "Other"]:
        raise HTTPException(
            status_code=400,
            detail="Address type must be Home, Work or Other.",
        )


# ============================================================
# GET ALL USER ADDRESSES
# ============================================================

@router.get("")
def get_addresses(
    current_user=Depends(get_current_user),
):
    user_id = _get_user_id(current_user)

    try:
        result = (
            supabase.table("user_addresses")
            .select("*")
            .eq("user_id", user_id)
            .order("is_default", desc=True)
            .order("created_at", desc=True)
            .execute()
        )

        addresses = result.data or []

        return {
            "success": True,
            "count": len(addresses),
            "addresses": addresses,
        }

    except Exception as exc:
        print("GET ADDRESSES ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to load addresses.",
        )


# ============================================================
# ADD NEW ADDRESS
# ============================================================

@router.post("", status_code=201)
def add_address(
    data: AddressRequest,
    current_user=Depends(get_current_user),
):
    user_id = _get_user_id(current_user)

    _validate_address_type(data.address_type)

    try:
        existing = (
            supabase.table("user_addresses")
            .select("id")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )

        # First saved address automatically becomes default.
        is_default = not bool(existing.data)

        address_data = data.model_dump()

        address_data.update({
            "user_id": user_id,
            "is_default": is_default,
        })

        result = (
            supabase.table("user_addresses")
            .insert(address_data)
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=500,
                detail="Could not save address.",
            )

        return {
            "success": True,
            "message": "Address added successfully.",
            "address": result.data[0],
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("ADD ADDRESS ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to add address.",
        )


# ============================================================
# UPDATE ADDRESS
# ============================================================

@router.put("/{address_id}")
def update_address(
    address_id: UUID,
    data: UpdateAddressRequest,
    current_user=Depends(get_current_user),
):
    user_id = _get_user_id(current_user)

    try:
        update_data = data.model_dump(exclude_unset=True)

        if not update_data:
            raise HTTPException(
                status_code=400,
                detail="No fields provided for update.",
            )

        if "address_type" in update_data:
            _validate_address_type(update_data["address_type"])

        update_data["updated_at"] = datetime.now(timezone.utc).isoformat()

        result = (
            supabase.table("user_addresses")
            .update(update_data)
            .eq("id", str(address_id))
            .eq("user_id", user_id)
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=404,
                detail="Address not found.",
            )

        return {
            "success": True,
            "message": "Address updated successfully.",
            "address": result.data[0],
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("UPDATE ADDRESS ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to update address.",
        )


# ============================================================
# SET DEFAULT ADDRESS
# ============================================================

@router.patch("/{address_id}/default")
def set_default_address(
    address_id: UUID,
    current_user=Depends(get_current_user),
):
    user_id = _get_user_id(current_user)

    try:
        target = (
            supabase.table("user_addresses")
            .select("id")
            .eq("id", str(address_id))
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )

        if not target.data:
            raise HTTPException(
                status_code=404,
                detail="Address not found.",
            )

        # Remove the previous default.
        supabase.table("user_addresses").update({
            "is_default": False,
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }).eq(
            "user_id", user_id
        ).eq(
            "is_default", True
        ).execute()

        # Set the selected address as default.
        result = (
            supabase.table("user_addresses")
            .update({
                "is_default": True,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            })
            .eq("id", str(address_id))
            .eq("user_id", user_id)
            .execute()
        )

        return {
            "success": True,
            "message": "Default address updated.",
            "address": result.data[0],
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("SET DEFAULT ADDRESS ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to set default address.",
        )


# ============================================================
# DELETE ADDRESS
# ============================================================

@router.delete("/{address_id}")
def delete_address(
    address_id: UUID,
    current_user=Depends(get_current_user),
):
    user_id = _get_user_id(current_user)

    try:
        target = (
            supabase.table("user_addresses")
            .select("*")
            .eq("id", str(address_id))
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )

        if not target.data:
            raise HTTPException(
                status_code=404,
                detail="Address not found.",
            )

        was_default = target.data[0].get("is_default") is True

        supabase.table("user_addresses").delete().eq(
            "id", str(address_id)
        ).eq(
            "user_id", user_id
        ).execute()

        # If the deleted address was default,
        # promote the most recently created remaining address.
        if was_default:
            remaining = (
                supabase.table("user_addresses")
                .select("id")
                .eq("user_id", user_id)
                .order("created_at", desc=True)
                .limit(1)
                .execute()
            )

            if remaining.data:
                new_default_id = remaining.data[0]["id"]

                supabase.table("user_addresses").update({
                    "is_default": True,
                    "updated_at": datetime.now(timezone.utc).isoformat(),
                }).eq(
                    "id", new_default_id
                ).eq(
                    "user_id", user_id
                ).execute()

        return {
            "success": True,
            "message": "Address deleted successfully.",
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("DELETE ADDRESS ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to delete address.",
        )
