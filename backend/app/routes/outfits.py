import json
import uuid
from typing import Optional
from pathlib import Path

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
)

from app.core.supabase import supabase_admin as supabase
from app.core.auth_dependency import get_current_vendor

router = APIRouter(
    prefix="/vendor/outfits",
    tags=["Vendor Outfits"],
)


ALLOWED_IMAGE_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
}

ALLOWED_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
    ".webp",
}

MAX_IMAGES = 5
MAX_FILE_SIZE = 5 * 1024 * 1024


@router.post("")
async def create_outfit(
    name: str = Form(...),
    description: Optional[str] = Form(None),

    gender: str = Form(...),
    brand: Optional[str] = Form(None),

    occasion: str = Form(...),
    category: str = Form(...),

    rental_price: float = Form(...),
    mrp: Optional[float] = Form(None),
    security_deposit: float = Form(...),

    color_name: Optional[str] = Form(None),
    color_hex: Optional[str] = Form(None),

    size_type: str = Form("standard"),
    sizes: Optional[str] = Form(None),
    measurements: Optional[str] = Form(None),

    material: Optional[str] = Form(None),
    sleeve: Optional[str] = Form(None),

    photos: list[UploadFile] = File(...),

    current_vendor=Depends(get_current_vendor),
):

    # ============================================================
    # 1. BASIC VALIDATION
    # ============================================================

    name = name.strip()

    if len(name) < 2:
        raise HTTPException(
            status_code=400,
            detail="Outfit name must contain at least 2 characters.",
        )

    if rental_price <= 0:
        raise HTTPException(
            status_code=400,
            detail="Rental price must be greater than 0.",
        )

    if mrp is not None and mrp < rental_price:
        raise HTTPException(
            status_code=400,
            detail="MRP cannot be lower than rental price.",
        )

    if security_deposit < 0:
        raise HTTPException(
            status_code=400,
            detail="Security deposit cannot be negative.",
        )

    # ============================================================
    # 2. PHOTO VALIDATION
    # ============================================================

    if not photos:
        raise HTTPException(
            status_code=400,
            detail="At least one outfit photo is required.",
        )

    if len(photos) > MAX_IMAGES:
        raise HTTPException(
            status_code=400,
            detail=f"Maximum {MAX_IMAGES} photos allowed.",
        )

    for photo in photos:

        extension = Path(photo.filename or "").suffix.lower()

        if (
            photo.content_type not in ALLOWED_IMAGE_TYPES
            and extension not in ALLOWED_EXTENSIONS
        ):
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported image type: {photo.filename}",
            )

    # ============================================================
    # 3. PARSE SIZES
    # ============================================================

    parsed_sizes = None

    if sizes:

        try:
            parsed_sizes = json.loads(sizes)

        except json.JSONDecodeError:

            raise HTTPException(
                status_code=400,
                detail="Invalid sizes format.",
            )

    # ============================================================
    # 4. PARSE MEASUREMENTS
    # ============================================================

    parsed_measurements = None

    if measurements:

        try:
            parsed_measurements = json.loads(
                measurements
            )

        except json.JSONDecodeError:

            raise HTTPException(
                status_code=400,
                detail="Invalid measurements format.",
            )

    # ============================================================
    # 5. AUTHENTICATED VENDOR
    # ============================================================

    vendor_id = current_vendor["id"]

    if not vendor_id:
        raise HTTPException(
            status_code=401,
            detail="Vendor authentication required.",
        )

    # ============================================================
    # 6. CREATE OUTFIT
    # ============================================================

    outfit_id = str(uuid.uuid4())

    outfit_data = {

        "id": outfit_id,
        "vendor_id": vendor_id,

        "name": name,
        "description": description,

        "gender": gender,
        "brand": brand,

        "occasion": occasion,
        "category": category,

        "rental_price": rental_price,
        "mrp": mrp,
        "security_deposit": security_deposit,

        "color_name": color_name,
        "color_hex": color_hex,

        "size_type": size_type,
        "sizes": parsed_sizes,
        "measurements": parsed_measurements,

        "material": material,
        "sleeve": sleeve,

        "status": "published",
        "is_available": True,
    }

    outfit_response = (
        supabase
        .table("outfits")
        .insert(outfit_data)
        .execute()
    )

    if not outfit_response.data:

        raise HTTPException(
            status_code=500,
            detail="Failed to create outfit.",
        )

    # ============================================================
    # 7. UPLOAD IMAGES
    # ============================================================

    uploaded_images = []

    try:

        for index, photo in enumerate(photos):

            file_bytes = await photo.read()

            if len(file_bytes) > MAX_FILE_SIZE:

                raise HTTPException(
                    status_code=400,
                    detail=(
                        f"{photo.filename} exceeds "
                        f"the 5 MB limit."
                    ),
                )

            extension = (
                photo.filename
                .split(".")[-1]
                .lower()
            )

            storage_path = (
                f"{vendor_id}/"
                f"{outfit_id}/"
                f"{index + 1}.{extension}"
            )

            # Upload to Supabase Storage
            (
                supabase
                .storage
                .from_("Outfit-images")
                .upload(
                    storage_path,
                    file_bytes,
                    {
                        "content-type": photo.content_type,
                        "upsert": "false",
                    },
                )
            )

            image_url = (
                supabase
                .storage
                .from_("Outfit-images")
                .get_public_url(
                    storage_path
                )
            )

            uploaded_images.append({
                "outfit_id": outfit_id,
                "image_url": image_url,
                "storage_path": storage_path,
                "display_order": index,
                "is_cover": index == 0,
            })

        # ========================================================
        # 8. SAVE IMAGE RECORDS
        # ========================================================

        (
            supabase
            .table("Outfit-images")
            .insert(uploaded_images)
            .execute()
        )

    except HTTPException:
        raise

    except Exception as e:

        # ========================================================
        # CLEANUP OUTFIT IF IMAGE UPLOAD FAILS
        # ========================================================

        try:

            (
                supabase
                .table("outfits")
                .delete()
                .eq("id", outfit_id)
                .execute()
            )

        except Exception:
            pass

        raise HTTPException(
            status_code=500,
            detail=f"Failed to upload outfit images: {str(e)}",
        )

    # ============================================================
    # 9. SUCCESS
    # ============================================================

    return {
        "success": True,
        "message": "Outfit published successfully.",
        "outfit_id": outfit_id,
    }