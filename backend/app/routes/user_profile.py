
import uuid
from datetime import date
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from pydantic import BaseModel, EmailStr

from app.core.auth_dependency import get_current_user
from app.core.supabase import supabase_admin


router = APIRouter(
    prefix="/users",
    tags=["User Profile"],
)


# ============================================================
# UPDATE PROFILE MODEL
# ============================================================

class UpdateProfileRequest(BaseModel):
    full_name: str | None = None
    phone_number: str | None = None
    date_of_birth: date | None = None
    gender: str | None = None


# ============================================================
# GET LOGGED-IN USER PROFILE
# GET /users/me
# ============================================================

@router.get("/me")
def get_my_profile(current_user=Depends(get_current_user)):

    try:
        user_id = str(current_user.id)

        response = (
            supabase_admin
            .table("users")
            .select(
                "id, email, full_name, phone_number, "
                "date_of_birth, gender, created_at, "
                "profile_image_url"
            )
            .eq("id", user_id)
            .limit(1)
            .execute()
        )

        if not response.data:
            raise HTTPException(
                status_code=404,
                detail="User profile not found",
            )

        return {
            "success": True,
            "profile": response.data[0],
        }

    except HTTPException:
        raise

    except Exception as e:
        print("GET USER PROFILE ERROR:", repr(e))
        raise HTTPException(
            status_code=500,
            detail="Failed to fetch user profile",
        )


# ============================================================
# UPDATE USER PROFILE
# PUT /users/me
# ============================================================

@router.put("/me")
def update_my_profile(
    data: UpdateProfileRequest,
    current_user=Depends(get_current_user),
):

    try:
        user_id = str(current_user.id)

        update_data = data.model_dump(
            exclude_unset=True,
            exclude_none=True,
        )

        if not update_data:
            raise HTTPException(
                status_code=400,
                detail="No profile details provided",
            )

        response = (
            supabase_admin
            .table("users")
            .update(update_data)
            .eq("id", user_id)
            .execute()
        )

        if not response.data:
            raise HTTPException(
                status_code=404,
                detail="User profile not found",
            )

        return {
            "success": True,
            "message": "Profile updated successfully",
            "profile": response.data[0],
        }

    except HTTPException:
        raise

    except Exception as e:
        print("UPDATE USER PROFILE ERROR:", repr(e))
        raise HTTPException(
            status_code=500,
            detail="Failed to update user profile",
        )


# ============================================================
# UPLOAD / CHANGE PROFILE IMAGE
# POST /users/me/profile-image
# ============================================================

# ============================================================
# UPLOAD / CHANGE PROFILE IMAGE
# POST /users/me/profile-image
# ============================================================

@router.post("/me/profile-image")
async def upload_profile_image(
    file: UploadFile = File(...),
    current_user=Depends(get_current_user),
):
    try:
        user_id = str(current_user.id)

        allowed_types = {
            "image/jpeg": ".jpg",
            "image/png": ".png",
            "image/webp": ".webp",
            "image/heic": ".heic",
            "image/heif": ".heif",
        }

        content_type = (file.content_type or "").lower()

        if content_type not in allowed_types:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Unsupported image format. "
                    "Please select a JPG, PNG, WEBP, HEIC or HEIF image."
                ),
            )

        image_bytes = await file.read()

        if not image_bytes:
            raise HTTPException(
                status_code=400,
                detail="Please select an image",
            )

        extension = allowed_types[content_type]

        file_path = f"{user_id}/{uuid.uuid4().hex}{extension}"

        supabase_admin.storage.from_("profile-images").upload(
            path=file_path,
            file=image_bytes,
            file_options={
                "content-type": content_type,
                "upsert": "true",
            },
        )

        image_url = (
            supabase_admin.storage
            .from_("profile-images")
            .get_public_url(file_path)
        )

        response = (
            supabase_admin
            .table("users")
            .update({
                "profile_image_url": image_url,
            })
            .eq("id", user_id)
            .execute()
        )

        if not response.data:
            raise HTTPException(
                status_code=404,
                detail="User profile not found",
            )

        return {
            "success": True,
            "message": "Profile image uploaded successfully",
            "profile_image_url": image_url,
        }

    except HTTPException:
        raise

    except Exception as e:
        print("PROFILE IMAGE UPLOAD ERROR:", repr(e))
        raise HTTPException(
            status_code=500,
            detail=f"Failed to upload profile image: {str(e)}",
        )

    finally:
        await file.close()
