from datetime import date

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, EmailStr, Field

from app.core.auth_dependency import get_current_user
from app.core.supabase import (
    supabase_auth,
    supabase_admin,
)


router = APIRouter(
    prefix="/auth",
    tags=["Auth"],
)


# ============================================================
# REGISTER MODEL
# ============================================================

class RegisterRequest(BaseModel):
    # ========================================================
    # COMMON ACCOUNT DETAILS
    # ========================================================

    email: EmailStr
    password: str = Field(min_length=8)

    full_name: str
    phone_number: str
    date_of_birth: date
    gender: str

    # ========================================================
    # ACCOUNT TYPE
    # ========================================================

    has_store: bool

    # ========================================================
    # VENDOR DETAILS
    # Required only when has_store = True
    # ========================================================

    store_name: str | None = None
    business_description: str | None = None
    owner_type: str | None = None

    address: str | None = None
    city: str | None = None
    state: str | None = None
    pincode: str | None = None

    instagram: str | None = None

    aadhaar: str | None = None
    pan: str | None = None

# ============================================================
# LOGIN MODEL
# ============================================================

class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    role : str


# ============================================================
# REGISTER
# ============================================================

# ============================================================
# REGISTER
# ============================================================

@router.post("/register")
def register(data: RegisterRequest):

    try:

        # ====================================================
        # VALIDATE VENDOR DETAILS
        # ====================================================

        if data.has_store:

            required_vendor_fields = {
                "store_name": data.store_name,
                "business_description": data.business_description,
                "owner_type": data.owner_type,
                "address": data.address,
                "city": data.city,
                "state": data.state,
                "pincode": data.pincode,
            }

            missing_fields = [
                field
                for field, value in required_vendor_fields.items()
                if value is None or not str(value).strip()
            ]

            if missing_fields:
                raise HTTPException(
                    status_code=400,
                    detail=(
                        "Missing vendor details: "
                        + ", ".join(missing_fields)
                    ),
                )

            if data.owner_type not in [
                "individual",
                "store_owner",
            ]:
                raise HTTPException(
                    status_code=400,
                    detail=(
                        "owner_type must be "
                        "'individual' or 'store_owner'"
                    ),
                )

        # ====================================================
        # CREATE SUPABASE AUTH ACCOUNT
        # ====================================================

        response = supabase_auth.auth.sign_up(
            {
                "email": data.email,
                "password": data.password,
                "options": {
                    "data": {
                        "full_name": data.full_name,
                        "phone_number": data.phone_number,
                        "date_of_birth": (
                            data.date_of_birth.isoformat()
                        ),
                        "gender": data.gender,
                        "has_store": data.has_store,
                    }
                },
            }
        )

        if response.user is None:
            raise HTTPException(
                status_code=400,
                detail="Registration failed",
            )

        auth_user_id = str(response.user.id)

        # ====================================================
        # CREATE USER PROFILE
        # ====================================================

        if not data.has_store:

            user_response = (
                supabase_admin
                .table("users")
                .insert(
                    {
                        "id": auth_user_id,
                        "email": data.email,
                        "full_name": data.full_name,
                        "phone_number": data.phone_number,
                        "date_of_birth": (
                            data.date_of_birth.isoformat()
                        ),
                        "gender": data.gender,
                    }
                )
                .execute()
            )

            if not user_response.data:
                raise HTTPException(
                    status_code=500,
                    detail="User profile creation failed",
                )

            return {
                "success": True,
                "message": "User registration successful.",
                "user_id": auth_user_id,
                "role": "user",
            }

        # ====================================================
        # CREATE VENDOR PROFILE
        # ====================================================

        vendor_response = (
            supabase_admin
            .table("vendors")
            .insert(
                {
                    "auth_user_id": auth_user_id,
                    "full_name": data.full_name,
                    "store_name": data.store_name,
                    "business_description": (
                        data.business_description
                    ),
                    "owner_type": data.owner_type,
                    "phone_number": data.phone_number,
                    "address": data.address,
                    "city": data.city,
                    "state": data.state,
                    "pincode": data.pincode,
                    "instagram": data.instagram,
                    "aadhaar": data.aadhaar,
                    "pan": data.pan,
                }
            )
            .execute()
        )

        if not vendor_response.data:
            raise HTTPException(
                status_code=500,
                detail="Vendor profile creation failed",
            )

        return {
            "success": True,
            "message": "Vendor registration successful.",
            "user_id": auth_user_id,
            "role": "vendor",
            "vendor_id": vendor_response.data[0]["id"],
        }

    except HTTPException:
        raise

    except Exception as e:

        print(
            "REGISTRATION ERROR:",
            repr(e),
        )

        # If the Auth account was already created but
        # profile creation failed, remove the Auth account.
        try:
            if "auth_user_id" in locals() and auth_user_id:
                supabase_admin.auth.admin.delete_user(
                    auth_user_id
                )
                print(
                    "AUTH USER CLEANED UP:",
                    auth_user_id,
                )
        except Exception as cleanup_error:
            print(
                "AUTH CLEANUP ERROR:",
                repr(cleanup_error),
            )

        raise HTTPException(
            status_code=400,
            detail="Registration failed. Please try again.",
        )

# ============================================================
# LOGIN
# ============================================================
@router.post("/login")
def login(data: LoginRequest):
    try:
        # ====================================================
        # VALIDATE SELECTED ROLE
        # ====================================================

        if data.role not in ["user", "vendor"]:
            raise HTTPException(
                status_code=400,
                detail="Invalid account type",
            )

        # ====================================================
        # SUPABASE AUTHENTICATION
        # ====================================================

        response = supabase_auth.auth.sign_in_with_password(
            {
                "email": data.email,
                "password": data.password,
            }
        )

        if response.user is None:
            raise HTTPException(
                status_code=401,
                detail="Invalid email or password",
            )

        user_id = str(response.user.id)

        # ====================================================
        # CHECK SELECTED ROLE
        # ====================================================

        if data.role == "user":

            user_response = (
                supabase_admin
                .table("users")
                .select("id, full_name, email")
                .eq("id", user_id)
                .limit(1)
                .execute()
            )

            if not user_response.data:
                raise HTTPException(
                    status_code=403,
                    detail="This account is not registered as a user",
                )

            return {
                "success": True,
                "message": "User login successful",
                "access_token": response.session.access_token,
                "refresh_token": response.session.refresh_token,
                "user_id": user_id,
                "role": "user",
                "profile": user_response.data[0],
            }

        # ====================================================
        # VENDOR LOGIN
        # ====================================================

        vendor_response = (
            supabase_admin
            .table("vendors")
            .select(
                "id, store_name, owner_type"
            )
            .eq("auth_user_id", user_id)
            .limit(1)
            .execute()
        )

        if not vendor_response.data:
            raise HTTPException(
                status_code=403,
                detail="This account is not registered as a vendor",
            )

        return {
            "success": True,
            "message": "Vendor login successful",
            "access_token": response.session.access_token,
            "refresh_token": response.session.refresh_token,
            "user_id": user_id,
            "role": "vendor",
            "vendor_id": vendor_response.data[0]["id"],
            "profile": vendor_response.data[0],
        }

    except HTTPException:
        raise

    except Exception as e:
        print(
            "LOGIN ERROR:",
            repr(e),
        )

        raise HTTPException(
            status_code=401,
            detail="Login failed",
        )

# ============================================================
# VALIDATE SESSION + DETERMINE ACCOUNT TYPE
# ============================================================

@router.get("/session")
def validate_session(
    current_user=Depends(get_current_user),
):
    print("SESSION ENDPOINT CALLED")

    user_id = str(current_user.id)

    try:

        # ----------------------------------------------------
        # CHECK VENDOR
        # ----------------------------------------------------

        vendor_response = (
            supabase_admin
            .table("vendors")
            .select("id, store_name")
            .eq("auth_user_id", user_id)
            .limit(1)
            .execute()
        )

        if vendor_response.data:

            return {
                "valid": True,
                "user_id": user_id,
                "role": "vendor",
                "vendor_id": vendor_response.data[0]["id"],
                "store_name": vendor_response.data[0]["store_name"],
            }

        # ----------------------------------------------------
        # CHECK NORMAL USER
        # ----------------------------------------------------

        user_response = (
            supabase_admin
            .table("users")
            .select("id, full_name")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )

        if user_response.data:

            return {
                "valid": True,
                "user_id": user_id,
                "role": "user",
                "full_name": user_response.data[0]["full_name"],
            }

        # ----------------------------------------------------
        # AUTH ACCOUNT EXISTS BUT PROFILE DOES NOT
        # ----------------------------------------------------

        raise HTTPException(
            status_code=403,
            detail="Account profile not found",
        )

    except HTTPException:
        raise

    except Exception as e:

        print("SESSION ROLE ERROR:", repr(e))

        raise HTTPException(
            status_code=500,
            detail="Failed to determine account type",
        )
    