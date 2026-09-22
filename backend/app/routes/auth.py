from datetime import date

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr, Field

from app.core.supabase import supabase


router = APIRouter(
    prefix="/auth",
    tags=["Auth"]
)


# =========================
# REGISTER MODEL
# =========================

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    full_name: str
    phone_number: str
    date_of_birth: date
    gender: str
    has_store: bool


# =========================
# LOGIN MODEL
# =========================

class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# =========================
# REGISTER
# =========================

@router.post("/register")
def register(data: RegisterRequest):

    try:

        response = supabase.auth.sign_up({

            "email": data.email,

            "password": data.password,

            "options": {
                "data": {
                    "full_name": data.full_name,

                    "phone_number":
                        data.phone_number,

                    "date_of_birth":
                        data.date_of_birth.isoformat(),

                    "gender":
                        data.gender,

                    "has_store":
                        data.has_store
                }
            }
        })

        if response.user is None:

            raise HTTPException(
                status_code=400,
                detail="Registration failed"
            )

        return {

            "success": True,

            "message":
                "Registration successful.",

            "user_id":
                str(response.user.id)
        }

    except HTTPException:

        raise

    except Exception as e:

        raise HTTPException(
            status_code=400,
            detail=str(e)
        )


# =========================
# LOGIN
# =========================

@router.post("/login")
def login(data: LoginRequest):

    try:

        response = supabase.auth.sign_in_with_password({

            "email": data.email,

            "password": data.password
        })

        if response.user is None:

            raise HTTPException(

                status_code=401,

                detail="Invalid email or password"
            )

        return {

            "success": True,

            "message":
                "Login successful",

            "access_token":
                response.session.access_token,

            "refresh_token":
                response.session.refresh_token,

            "user_id":
                str(response.user.id)
        }

    except HTTPException:

        raise

    except Exception as e:

        raise HTTPException(

            status_code=401,

            detail=str(e)
        )