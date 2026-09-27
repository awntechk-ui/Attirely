from fastapi import APIRouter, Depends, HTTPException

from app.core.auth_dependency import get_current_user
from app.core.supabase import supabase

router = APIRouter(
    prefix="/vendor",
    tags=["Vendor"]
)


@router.get("/me")
def get_my_vendor(
    current_user=Depends(get_current_user),
):
    try:
        user_id = str(current_user.id)

        # print("CURRENT USER ID:", user_id)

        response = (
            supabase
            .table("vendors")
            .select("id")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )

        # print("SUPABASE DATA:", response.data)

        if not response.data:
            return {
                "exists": False
            }

        return {
            "exists": True,
            "vendor_id": response.data[0]["id"]
        }

    except Exception as e:
        print("VENDOR ERROR:", repr(e))

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )
from pydantic import BaseModel


class CreateVendorRequest(BaseModel):
    full_name: str
    aadhaar: str | None = None
    pan: str | None = None
    role: str
    store_name: str
    business_description: str
    address: str
    city: str
    state: str
    pincode: str
    instagram: str | None = None


@router.post("/create")
def create_vendor(
    data: CreateVendorRequest,
    current_user=Depends(get_current_user),
):
    try:
        user_id = str(current_user.id)

        existing = (
            supabase
            .table("vendors")
            .select("id")
            .eq("user_id", user_id)
            .limit(1)
            .execute()
        )

        if existing.data:
            raise HTTPException(
                status_code=400,
                detail="Vendor profile already exists",
            )

        response = (
            supabase
            .table("vendors")
            .insert({
                "user_id": user_id,
                "full_name": data.full_name,
                "aadhaar": data.aadhaar,
                "pan": data.pan,
                "role": data.role,
                "store_name": data.store_name,
                "business_description": data.business_description,
                "address": data.address,
                "city": data.city,
                "state": data.state,
                "pincode": data.pincode,
                "instagram": data.instagram,
            })
            .execute()
        )

        return {
            "success": True,
            "message": "Vendor profile created successfully",
            "vendor": response.data[0],
        }

    except HTTPException:
        raise

    except Exception as e:
        print("CREATE VENDOR ERROR:", repr(e))

        raise HTTPException(
            status_code=500,
            detail=str(e),
        )