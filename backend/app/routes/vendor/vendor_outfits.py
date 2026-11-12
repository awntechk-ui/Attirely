
import json
import uuid
from pathlib import Path

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
)

from app.core.auth_dependency import get_current_user, get_current_vendor
from app.core.supabase import supabase_admin as supabase

from app.services.vendor_subscription_service import (
    check_vendor_listing_quota,
    check_vendor_image_limit,
)


router = APIRouter(
    prefix="/vendor/outfits",
    tags=["Vendor Outfits"],
)

BUCKET_NAME = "outfit-images"
MAX_FILE_SIZE = 5 * 1024 * 1024

ALLOWED_GENDERS = {
    "women",
    "girl_kid",
    "boy_kid",
    "men",
    "unisex_adult",
    "unisex_kid",
}

KID_GENDERS = {
    "girl_kid",
    "boy_kid",
    "unisex_kid",
}

ALLOWED_TYPES = {
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


def get_vendor_user_id(vendor: dict) -> str:
    """
    Get the authenticated user's ID from the vendor profile.
    Never accept vendor ID or uploader ID from the client.
    """
    user_id = vendor.get("auth_user_id")

    if not user_id:
        raise HTTPException(
            status_code=403,
            detail="Vendor authentication profile is invalid.",
        )

    return str(user_id)


def validate_photo(photo: UploadFile):
    extension = Path(photo.filename or "").suffix.lower()

    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported image file: {photo.filename}",
        )

    if photo.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported image type: {photo.filename}",
        )


async def validate_photo_size(photo: UploadFile):
    contents = await photo.read()

    if not contents or len(contents) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail="Each image must be between 1 byte and 5 MB.",
        )

    photo.file.seek(0)


def parse_outfit_sizes(sizes: str, measurements: str):
    try:
        parsed_sizes = json.loads(sizes)
        parsed_measurements = json.loads(measurements)

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=400,
            detail="Invalid sizes or measurements JSON.",
        )

    if not isinstance(parsed_sizes, list):
        raise HTTPException(
            status_code=400,
            detail="Sizes must be a JSON array.",
        )

    if not isinstance(parsed_measurements, dict):
        raise HTTPException(
            status_code=400,
            detail="Measurements must be a JSON object.",
        )

    return parsed_sizes, parsed_measurements


def validate_size_selection(
    size_type: str,
    parsed_sizes: list,
    parsed_measurements: dict,
):
    if size_type not in {"standard", "measurements"}:
        raise HTTPException(
            status_code=400,
            detail="Invalid size type.",
        )

    if size_type == "standard" and not parsed_sizes:
        raise HTTPException(
            status_code=400,
            detail="Select at least one standard size.",
        )

    if size_type == "measurements" and not parsed_measurements:
        raise HTTPException(
            status_code=400,
            detail="Provide outfit measurements.",
        )


def validate_gender_and_age(gender: str, age_group: str | None):
    gender = gender.strip().lower()

    if gender not in ALLOWED_GENDERS:
        raise HTTPException(
            status_code=400,
            detail="Invalid gender category.",
        )

    if gender in KID_GENDERS:
        if not age_group or not age_group.strip():
            raise HTTPException(
                status_code=400,
                detail="Age group is required for kids' outfits.",
            )

    else:
        age_group = None

    return gender, age_group.strip() if age_group else None


# =========================================================
# CREATE VENDOR OUTFIT
# =========================================================

@router.post("")
async def create_vendor_outfit(
    name: str = Form(...),
    description: str = Form(...),
    gender: str = Form(...),

    brand: str | None = Form(None),
    occasion: str = Form(...),
    category: str = Form(...),

    outfit_type: str | None = Form(None),
    fit: str | None = Form(None),
    pattern: str | None = Form(None),
    collar: str | None = Form(None),
    age_group: str | None = Form(None),

    rental_price: float = Form(...),
    mrp: float | None = Form(None),
    security_deposit: float = Form(...),

    color_name: str | None = Form(None),
    color_hex: str | None = Form(None),

    size_type: str = Form("standard"),
    sizes: str = Form("[]"),
    measurements: str = Form("{}"),

    material: str | None = Form(None),
    sleeve: str | None = Form(None),

    photos: list[UploadFile] = File(...),

    current_user=Depends(get_current_user),
    vendor: dict = Depends(get_current_vendor),
):
    user_id = get_vendor_user_id(vendor)

    name = name.strip()
    gender, age_group = validate_gender_and_age(gender, age_group)

    if len(name) < 2:
        raise HTTPException(
            status_code=400,
            detail="Outfit name must contain at least 2 characters.",
        )

    if rental_price <= 0:
        raise HTTPException(
            status_code=400,
            detail="Rental price must be greater than zero.",
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

    if not photos:
        raise HTTPException(
            status_code=400,
            detail="Upload at least one outfit photo.",
        )

    # -----------------------------------------------------
    # SUBSCRIPTION CHECKS
    # -----------------------------------------------------

    # Women, Men and Kids share the same outfit quota.
    check_vendor_listing_quota(
        vendor=vendor,
        listing_type="outfit",
    )

    # Enforce the image limit for the vendor's active plan.
    check_vendor_image_limit(
        vendor=vendor,
        image_count=len(photos),
    )

    if gender in KID_GENDERS and size_type != "standard":
        raise HTTPException(
            status_code=400,
            detail="Kids' outfits must use standard sizes.",
        )

    parsed_sizes, parsed_measurements = parse_outfit_sizes(
        sizes,
        measurements,
    )

    validate_size_selection(
        size_type,
        parsed_sizes,
        parsed_measurements,
    )

    # -----------------------------------------------------
    # VALIDATE ALL IMAGES
    # -----------------------------------------------------

    for photo in photos:
        validate_photo(photo)
        await validate_photo_size(photo)

    outfit_id = str(uuid.uuid4())
    uploaded_paths = []
    outfit_created = False

    outfit_data = {
        "id": outfit_id,
        "uploaded_by": user_id,
        "role": "vendor",

        "name": name,
        "description": description.strip(),
        "gender": gender,
        "brand": brand.strip() if brand else None,

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

        "material": material.strip() if material else None,
        "sleeve": sleeve.strip() if sleeve else None,

        "status": "published",
        "is_available": True,

        "outfit_type": outfit_type.strip() if outfit_type else None,
        "fit": fit.strip() if fit else None,
        "pattern": pattern.strip() if pattern else None,
        "collar": collar.strip() if collar else None,
        "age_group": age_group,
    }

    try:
        result = (
            supabase.table("outfits")
            .insert(outfit_data)
            .execute()
        )

        if not result.data:
            raise RuntimeError("Outfit database insert failed.")

        outfit_created = True
        image_records = []

        for index, photo in enumerate(photos):
            extension = Path(photo.filename or "").suffix.lower()

            storage_path = (
                f"{user_id}/{outfit_id}/{index + 1}{extension}"
            )

            contents = await photo.read()

            supabase.storage.from_(BUCKET_NAME).upload(
                storage_path,
                contents,
                {
                    "content-type": photo.content_type,
                    "upsert": "false",
                },
            )

            uploaded_paths.append(storage_path)

            image_url = (
                supabase.storage
                .from_(BUCKET_NAME)
                .get_public_url(storage_path)
            )

            image_records.append({
                "outfit_id": outfit_id,
                "image_url": image_url,
                "storage_path": storage_path,
                "display_order": index,
                "is_cover": index == 0,
            })

        image_result = (
            supabase.table("outfit_images")
            .insert(image_records)
            .execute()
        )

        if not image_result.data:
            raise RuntimeError("Failed to save outfit images.")

        return {
            "success": True,
            "message": "Outfit published successfully.",
            "outfit_id": outfit_id,
            "uploaded_by": user_id,
            "role": "vendor",
            "images": image_result.data,
        }

    except Exception as exc:
        if uploaded_paths:
            try:
                supabase.storage.from_(BUCKET_NAME).remove(
                    uploaded_paths
                )
            except Exception as cleanup_error:
                print("VENDOR OUTFIT STORAGE CLEANUP ERROR:", repr(cleanup_error))

        if outfit_created:
            try:
                (
                    supabase.table("outfits")
                    .delete()
                    .eq("id", outfit_id)
                    .eq("uploaded_by", user_id)
                    .eq("role", "vendor")
                    .execute()
                )
            except Exception as cleanup_error:
                print("VENDOR OUTFIT DB CLEANUP ERROR:", repr(cleanup_error))

        if isinstance(exc, HTTPException):
            raise exc

        print("CREATE VENDOR OUTFIT ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to publish outfit. Please try again.",
        )


# =========================================================
# GET VENDOR OUTFITS
# =========================================================

@router.get("")
async def get_vendor_outfits(
    current_user=Depends(get_current_user),
    vendor: dict = Depends(get_current_vendor),
):
    user_id = get_vendor_user_id(vendor)

    try:
        result = (
            supabase.table("outfits")
            .select("*")
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .order("created_at", desc=True)
            .execute()
        )

        outfits = result.data or []

        if not outfits:
            return {
                "success": True,
                "count": 0,
                "outfits": [],
            }

        outfit_ids = [
            item["id"]
            for item in outfits
            if item.get("id")
        ]

        image_result = (
            supabase.table("outfit_images")
            .select(
                "outfit_id,image_url,storage_path,display_order,is_cover"
            )
            .in_("outfit_id", outfit_ids)
            .order("display_order")
            .execute()
        )

        images_by_outfit = {}

        for image in image_result.data or []:
            images_by_outfit.setdefault(
                image.get("outfit_id"), []
            ).append(image)

        for outfit in outfits:
            images = images_by_outfit.get(outfit.get("id"), [])

            outfit["images"] = images

            cover = next(
                (img for img in images if img.get("is_cover")),
                images[0] if images else None,
            )

            outfit["cover_image_url"] = (
                cover.get("image_url") if cover else None
            )

        return {
            "success": True,
            "count": len(outfits),
            "outfits": outfits,
        }

    except Exception as exc:
        print("GET VENDOR OUTFITS ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to load your outfits. Please try again.",
        )


# =========================================================
# GET ONE VENDOR OUTFIT
# =========================================================

@router.get("/{outfit_id}")
def get_vendor_outfit_details(
    outfit_id: str,
    current_user=Depends(get_current_user),
    vendor: dict = Depends(get_current_vendor),
):
    user_id = get_vendor_user_id(vendor)

    try:
        result = (
            supabase.table("outfits")
            .select("*")
            .eq("id", outfit_id)
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .limit(1)
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=404,
                detail="Outfit not found.",
            )

        outfit = result.data[0]

        image_result = (
            supabase.table("outfit_images")
            .select(
                "id,outfit_id,image_url,storage_path,"
                "display_order,is_cover,created_at"
            )
            .eq("outfit_id", outfit_id)
            .order("display_order")
            .execute()
        )

        images = image_result.data or []

        images.sort(
            key=lambda image: (
                not image.get("is_cover", False),
                image.get("display_order", 0),
            )
        )

        outfit["images"] = images

        cover = next(
            (image for image in images if image.get("is_cover")),
            images[0] if images else None,
        )

        outfit["cover_image_url"] = (
            cover.get("image_url") if cover else None
        )

        return {
            "success": True,
            "outfit": outfit,
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("GET VENDOR OUTFIT DETAILS ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to load outfit details.",
        )


# =========================================================
# UPDATE VENDOR OUTFIT AVAILABILITY
# =========================================================

@router.patch("/{outfit_id}/availability")
def update_vendor_outfit_availability(
    outfit_id: str,
    payload: dict,
    current_user=Depends(get_current_user),
    vendor: dict = Depends(get_current_vendor),
):
    user_id = get_vendor_user_id(vendor)

    if not isinstance(payload.get("is_available"), bool):
        raise HTTPException(
            status_code=400,
            detail="is_available must be true or false.",
        )

    try:
        existing = (
            supabase.table("outfits")
            .select("id")
            .eq("id", outfit_id)
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .limit(1)
            .execute()
        )

        if not existing.data:
            raise HTTPException(
                status_code=404,
                detail="Outfit not found.",
            )

        updated = (
            supabase.table("outfits")
            .update({
                "is_available": payload["is_available"]
            })
            .eq("id", outfit_id)
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .execute()
        )

        if not updated.data:
            raise HTTPException(
                status_code=500,
                detail="Availability could not be updated.",
            )

        return {
            "success": True,
            "is_available": payload["is_available"],
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("UPDATE VENDOR OUTFIT AVAILABILITY ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to update outfit availability.",
        )


# =========================================================
# UPDATE VENDOR OUTFIT
# =========================================================

@router.patch("/{outfit_id}")
async def update_vendor_outfit(
    outfit_id: str,

    name: str = Form(...),
    description: str = Form(...),
    gender: str = Form(...),

    brand: str | None = Form(None),
    occasion: str = Form(...),
    category: str = Form(...),

    rental_price: float = Form(...),
    mrp: float | None = Form(None),
    security_deposit: float = Form(...),

    color_name: str | None = Form(None),
    color_hex: str | None = Form(None),

    outfit_type: str | None = Form(None),
    fit: str | None = Form(None),
    pattern: str | None = Form(None),
    collar: str | None = Form(None),
    age_group: str | None = Form(None),

    size_type: str = Form("standard"),
    sizes: str = Form("[]"),
    measurements: str = Form("{}"),

    material: str | None = Form(None),
    sleeve: str | None = Form(None),

    keep_image_ids: str = Form("[]"),
    photos: list[UploadFile] | None = File(None),

    current_user=Depends(get_current_user),
    vendor: dict = Depends(get_current_vendor),
):
    user_id = get_vendor_user_id(vendor)

    name = name.strip()
    gender, age_group = validate_gender_and_age(gender, age_group)

    if gender in KID_GENDERS and size_type != "standard":
        raise HTTPException(
            status_code=400,
            detail="Kids' outfits must use standard sizes.",
        )

    outfit_type = outfit_type.strip() if outfit_type else None
    fit = fit.strip() if fit else None
    pattern = pattern.strip() if pattern else None
    collar = collar.strip() if collar else None

    # -----------------------------------------------------
    # VERIFY VENDOR OWNERSHIP
    # -----------------------------------------------------

    existing = (
        supabase.table("outfits")
        .select("id")
        .eq("id", outfit_id)
        .eq("uploaded_by", user_id)
        .eq("role", "vendor")
        .limit(1)
        .execute()
    )

    if not existing.data:
        raise HTTPException(
            status_code=404,
            detail="Outfit not found.",
        )

    if len(name) < 2:
        raise HTTPException(
            status_code=400,
            detail="Outfit name must contain at least 2 characters.",
        )

    if rental_price <= 0:
        raise HTTPException(
            status_code=400,
            detail="Rental price must be greater than zero.",
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

    parsed_sizes, parsed_measurements = parse_outfit_sizes(
        sizes,
        measurements,
    )

    validate_size_selection(
        size_type,
        parsed_sizes,
        parsed_measurements,
    )

    try:
        retained_ids = json.loads(keep_image_ids)

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=400,
            detail="Invalid retained image IDs.",
        )

    if (
        not isinstance(retained_ids, list)
        or not all(isinstance(image_id, str) for image_id in retained_ids)
        or len(retained_ids) != len(set(retained_ids))
    ):
        raise HTTPException(
            status_code=400,
            detail="Invalid retained image IDs.",
        )

    # -----------------------------------------------------
    # FETCH EXISTING IMAGES
    # -----------------------------------------------------

    image_result = (
        supabase.table("outfit_images")
        .select("id,storage_path")
        .eq("outfit_id", outfit_id)
        .execute()
    )

    existing_images = image_result.data or []

    existing_ids = {
        str(image["id"])
        for image in existing_images
    }

    if not set(retained_ids).issubset(existing_ids):
        raise HTTPException(
            status_code=400,
            detail="Invalid image selection.",
        )

    new_photos = photos or []

    total_images = len(retained_ids) + len(new_photos)

    if total_images < 1:
        raise HTTPException(
            status_code=400,
            detail="At least one outfit image is required.",
        )

    # Existing images retained + new images must fit the plan.
    # Editing an outfit does not consume another listing slot.
    check_vendor_image_limit(
        vendor=vendor,
        image_count=total_images,
    )

    # -----------------------------------------------------
    # VALIDATE NEW IMAGES
    # -----------------------------------------------------

    for photo in new_photos:
        validate_photo(photo)
        await validate_photo_size(photo)

    uploaded_paths = []
    inserted_image_ids = []

    try:
        update_data = {
            "name": name,
            "description": description.strip(),
            "gender": gender,
            "brand": brand.strip() if brand else None,

            "outfit_type": outfit_type,
            "fit": fit,
            "pattern": pattern,
            "collar": collar,
            "age_group": age_group,

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

            "material": material.strip() if material else None,
            "sleeve": sleeve.strip() if sleeve else None,
        }

        updated = (
            supabase.table("outfits")
            .update(update_data)
            .eq("id", outfit_id)
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .execute()
        )

        if not updated.data:
            raise RuntimeError("Outfit update failed.")

        removed_images = [
            image
            for image in existing_images
            if str(image["id"]) not in retained_ids
        ]

        # -------------------------------------------------
        # UPLOAD NEW IMAGES
        # -------------------------------------------------

        new_records = []

        for index, photo in enumerate(new_photos):
            extension = Path(photo.filename or "").suffix.lower()

            storage_path = (
                f"{user_id}/{outfit_id}/{uuid.uuid4()}{extension}"
            )

            contents = await photo.read()

            supabase.storage.from_(BUCKET_NAME).upload(
                storage_path,
                contents,
                {
                    "content-type": photo.content_type,
                    "upsert": "false",
                },
            )

            uploaded_paths.append(storage_path)

            image_url = (
                supabase.storage
                .from_(BUCKET_NAME)
                .get_public_url(storage_path)
            )

            new_records.append({
                "outfit_id": outfit_id,
                "image_url": image_url,
                "storage_path": storage_path,
                "display_order": len(retained_ids) + index,
                "is_cover": len(retained_ids) == 0 and index == 0,
            })

        if new_records:
            inserted = (
                supabase.table("outfit_images")
                .insert(new_records)
                .execute()
            )

            if not inserted.data:
                raise RuntimeError("Failed to save new images.")

            inserted_image_ids = [
                image["id"]
                for image in inserted.data
            ]

        # -------------------------------------------------
        # DELETE REMOVED IMAGE RECORDS AND FILES
        # -------------------------------------------------

        removed_ids = [
            image["id"]
            for image in removed_images
        ]

        removed_paths = [
            image["storage_path"]
            for image in removed_images
            if image.get("storage_path")
        ]

        if removed_ids:
            (
                supabase.table("outfit_images")
                .delete()
                .in_("id", removed_ids)
                .eq("outfit_id", outfit_id)
                .execute()
            )

        if removed_paths:
            supabase.storage.from_(BUCKET_NAME).remove(
                removed_paths
            )

        # -------------------------------------------------
        # REORDER RETAINED AND NEW IMAGES
        # -------------------------------------------------

        final_images = (
            supabase.table("outfit_images")
            .select("id")
            .eq("outfit_id", outfit_id)
            .execute()
        )

        final_ids = [
            image["id"]
            for image in final_images.data or []
        ]

        for index, image_id in enumerate(final_ids):
            (
                supabase.table("outfit_images")
                .update({
                    "display_order": index,
                    "is_cover": index == 0,
                })
                .eq("id", image_id)
                .eq("outfit_id", outfit_id)
                .execute()
            )

        return {
            "success": True,
            "message": "Outfit updated successfully.",
            "outfit_id": outfit_id,
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("UPDATE VENDOR OUTFIT ERROR:", repr(exc))

        if uploaded_paths:
            try:
                supabase.storage.from_(BUCKET_NAME).remove(
                    uploaded_paths
                )
            except Exception as cleanup_error:
                print("VENDOR OUTFIT UPDATE STORAGE CLEANUP ERROR:", repr(cleanup_error))

        if inserted_image_ids:
            try:
                (
                    supabase.table("outfit_images")
                    .delete()
                    .in_("id", inserted_image_ids)
                    .execute()
                )
            except Exception as cleanup_error:
                print("VENDOR OUTFIT IMAGE RECORD CLEANUP ERROR:", repr(cleanup_error))

        raise HTTPException(
            status_code=500,
            detail="Failed to update outfit. Please try again.",
        )
# =========================================================
# DELETE VENDOR OUTFIT
# =========================================================

@router.delete("/{outfit_id}")
def delete_vendor_outfit(
    outfit_id: str,
    vendor: dict = Depends(get_current_vendor),
):
    user_id = get_vendor_user_id(vendor)

    try:
        # Verify that this outfit belongs to the logged-in vendor.
        existing = (
            supabase.table("outfits")
            .select("id")
            .eq("id", outfit_id)
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .limit(1)
            .execute()
        )

        if not existing.data:
            raise HTTPException(
                status_code=404,
                detail="Outfit not found.",
            )

        # Get actual Storage paths from the database.
        image_result = (
            supabase.table("outfit_images")
            .select("storage_path")
            .eq("outfit_id", outfit_id)
            .execute()
        )

        storage_paths = [
            image["storage_path"]
            for image in (image_result.data or [])
            if image.get("storage_path")
        ]

        # Delete the outfit. Its image database rows are
        # deleted automatically by the foreign-key cascade.
        (
            supabase.table("outfits")
            .delete()
            .eq("id", outfit_id)
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .execute()
        )

        # Delete the actual image files from Supabase Storage.
        if storage_paths:
            try:
                supabase.storage.from_(BUCKET_NAME).remove(storage_paths)
            except Exception as cleanup_error:
                print(
                    "VENDOR OUTFIT STORAGE DELETE ERROR:",
                    repr(cleanup_error),
                )

        return {
            "success": True,
            "message": "Outfit and its images deleted successfully.",
            "outfit_id": outfit_id,
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("DELETE VENDOR OUTFIT ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to delete outfit. Please try again.",
        )
