
import json
import uuid
from pathlib import Path

from fastapi import (
    APIRouter,
    Body,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
)

from app.core.auth_dependency import get_current_vendor
from app.core.supabase import supabase_admin as supabase

from app.services.vendor_subscription_service import (
    check_vendor_listing_quota,
    check_vendor_image_limit,
)


router = APIRouter(
    prefix="/vendor/accessories",
    tags=["Vendor Accessories"],
)

BUCKET_NAME = "accessory-images"
MAX_FILE_SIZE = 5 * 1024 * 1024

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

ALLOWED_COLLECTIONS = {
    "women",
    "men",
    "kids",
    "all",
}


def get_vendor_user_id(vendor: dict) -> str:
    """Return the authenticated user's ID linked to this vendor."""
    user_id = vendor.get("auth_user_id")

    if not user_id:
        raise HTTPException(
            status_code=403,
            detail="Vendor account is not properly configured.",
        )

    return str(user_id)


async def validate_photos(photos: list[UploadFile]) -> None:
    """Validate image extensions, MIME types and file sizes."""
    for photo in photos:
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

        contents = await photo.read()

        if not contents or len(contents) > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=400,
                detail="Each image must be between 1 byte and 5 MB.",
            )

        photo.file.seek(0)


def attach_cover_image(accessory: dict, images: list[dict]) -> None:
    images.sort(
        key=lambda image: (
            not image.get("is_cover", False),
            image.get("display_order", 0),
        )
    )

    accessory["images"] = images

    cover = next(
        (image for image in images if image.get("is_cover")),
        images[0] if images else None,
    )

    accessory["cover_image_url"] = (
        cover.get("image_url") if cover else None
    )


# =========================================================
# CREATE VENDOR ACCESSORY
# =========================================================

@router.post("")
async def create_vendor_accessory(
    name: str = Form(...),
    description: str = Form(...),
    category: str = Form(...),
    accessory_type: str = Form(...),
    collection: str = Form(...),
    rental_price: float = Form(...),
    mrp: float | None = Form(None),
    security_deposit: float = Form(...),
    brand: str | None = Form(None),
    color_name: str | None = Form(None),
    color_hex: str | None = Form(None),
    material: str | None = Form(None),
    quantity: int = Form(1),
    photos: list[UploadFile] = File(...),
    vendor: dict = Depends(get_current_vendor),
):
    name = name.strip()
    description = description.strip()
    category = category.strip()
    accessory_type = accessory_type.strip()
    collection = collection.strip().lower()

    if len(name) < 2:
        raise HTTPException(
            status_code=400,
            detail="Accessory name must contain at least 2 characters.",
        )

    if not description:
        raise HTTPException(
            status_code=400,
            detail="Description is required.",
        )

    if not category or not accessory_type:
        raise HTTPException(
            status_code=400,
            detail="Category and accessory type are required.",
        )

    if collection not in ALLOWED_COLLECTIONS:
        raise HTTPException(
            status_code=400,
            detail="Invalid collection. Choose women, men, kids or all.",
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

    if quantity < 0:
        raise HTTPException(
            status_code=400,
            detail="Quantity cannot be negative.",
        )

    if not photos:
        raise HTTPException(
            status_code=400,
            detail="At least one accessory photo is required.",
        )

    # Subscription checks: backend is authoritative.
    check_vendor_listing_quota(vendor, "accessory")
    check_vendor_image_limit(vendor, len(photos))

    await validate_photos(photos)

    user_id = get_vendor_user_id(vendor)
    accessory_id = str(uuid.uuid4())

    uploaded_paths = []
    accessory_created = False

    accessory_data = {
        "id": accessory_id,
        "uploaded_by": user_id,
        "role": "vendor",
        "name": name,
        "description": description,
        "category": category,
        "accessory_type": accessory_type,
        "collection": collection,
        "brand": brand.strip() if brand else None,
        "rental_price": rental_price,
        "mrp": mrp,
        "security_deposit": security_deposit,
        "color_name": color_name,
        "color_hex": color_hex,
        "material": material,
        "quantity": quantity,
        "status": "published",
        "is_available": quantity > 0,
    }

    try:
        result = (
            supabase.table("accessories")
            .insert(accessory_data)
            .execute()
        )

        if not result.data:
            raise RuntimeError("Accessory database insert failed.")

        accessory_created = True
        image_records = []

        for index, photo in enumerate(photos):
            extension = Path(photo.filename or "").suffix.lower()

            storage_path = (
                f"{user_id}/{accessory_id}/{index + 1}{extension}"
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
                "accessory_id": accessory_id,
                "image_url": image_url,
                "storage_path": storage_path,
                "display_order": index,
                "is_cover": index == 0,
            })

        image_result = (
            supabase.table("accessory_images")
            .insert(image_records)
            .execute()
        )

        if not image_result.data:
            raise RuntimeError("Failed to save accessory images.")

        return {
            "success": True,
            "message": "Accessory published successfully.",
            "accessory_id": accessory_id,
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
                print(
                    "VENDOR ACCESSORY STORAGE CLEANUP ERROR:",
                    repr(cleanup_error),
                )

        if accessory_created:
            try:
                (
                    supabase.table("accessories")
                    .delete()
                    .eq("id", accessory_id)
                    .eq("uploaded_by", user_id)
                    .eq("role", "vendor")
                    .execute()
                )
            except Exception as cleanup_error:
                print(
                    "VENDOR ACCESSORY DB CLEANUP ERROR:",
                    repr(cleanup_error),
                )

        if isinstance(exc, HTTPException):
            raise exc

        print("CREATE VENDOR ACCESSORY ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to publish accessory. Please try again.",
        )


# =========================================================
# GET MY VENDOR ACCESSORIES
# =========================================================

@router.get("")
def get_my_vendor_accessories(
    vendor: dict = Depends(get_current_vendor),
):
    user_id = get_vendor_user_id(vendor)

    try:
        result = (
            supabase.table("accessories")
            .select("*")
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .order("created_at", desc=True)
            .execute()
        )

        accessories = result.data or []

        if not accessories:
            return {
                "success": True,
                "count": 0,
                "accessories": [],
            }

        accessory_ids = [
            item["id"] for item in accessories if item.get("id")
        ]

        image_result = (
            supabase.table("accessory_images")
            .select(
                "accessory_id,image_url,storage_path,display_order,is_cover"
            )
            .in_("accessory_id", accessory_ids)
            .order("display_order")
            .execute()
        )

        images_by_accessory = {}

        for image in image_result.data or []:
            images_by_accessory.setdefault(
                image.get("accessory_id"), []
            ).append(image)

        for accessory in accessories:
            attach_cover_image(
                accessory,
                images_by_accessory.get(accessory.get("id"), []),
            )

        return {
            "success": True,
            "count": len(accessories),
            "accessories": accessories,
        }

    except Exception as exc:
        print("GET MY VENDOR ACCESSORIES ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to load your accessories.",
        )


# =========================================================
# GET VENDOR ACCESSORY DETAILS
# =========================================================

@router.get("/{accessory_id}")
def get_vendor_accessory_details(
    accessory_id: str,
    vendor: dict = Depends(get_current_vendor),
):
    user_id = get_vendor_user_id(vendor)

    try:
        result = (
            supabase.table("accessories")
            .select("*")
            .eq("id", accessory_id)
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .limit(1)
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=404,
                detail="Accessory not found.",
            )

        accessory = result.data[0]

        image_result = (
            supabase.table("accessory_images")
            .select("*")
            .eq("accessory_id", accessory_id)
            .order("display_order")
            .execute()
        )

        attach_cover_image(
            accessory,
            image_result.data or [],
        )

        return {
            "success": True,
            "accessory": accessory,
        }

    except HTTPException:
        raise
    except Exception as exc:
        print("GET VENDOR ACCESSORY DETAILS ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to load accessory details.",
        )


# =========================================================
# UPDATE VENDOR ACCESSORY
# =========================================================

@router.patch("/{accessory_id}")
async def update_vendor_accessory(
    accessory_id: str,
    name: str = Form(...),
    description: str = Form(...),
    category: str = Form(...),
    accessory_type: str = Form(...),
    collection: str = Form(...),
    rental_price: float = Form(...),
    mrp: str = Form(""),
    security_deposit: float = Form(...),
    brand: str = Form(""),
    color_name: str = Form(""),
    color_hex: str = Form(""),
    material: str = Form(""),
    quantity: int = Form(1),
    keep_image_ids: str = Form(...),
    photos: list[UploadFile] | None = File(None),
    vendor: dict = Depends(get_current_vendor),
):
    user_id = get_vendor_user_id(vendor)

    name = name.strip()
    description = description.strip()
    category = category.strip()
    accessory_type = accessory_type.strip()
    collection = collection.strip().lower()

    if len(name) < 2:
        raise HTTPException(
            status_code=400,
            detail="Accessory name must contain at least 2 characters.",
        )

    if not description:
        raise HTTPException(
            status_code=400,
            detail="Description is required.",
        )

    if not category or not accessory_type:
        raise HTTPException(
            status_code=400,
            detail="Category and accessory type are required.",
        )

    if collection not in ALLOWED_COLLECTIONS:
        raise HTTPException(
            status_code=400,
            detail="Invalid collection. Choose women, men, kids or all.",
        )

    if rental_price <= 0:
        raise HTTPException(
            status_code=400,
            detail="Rental price must be greater than zero.",
        )

    try:
        mrp_value = float(mrp.strip()) if mrp.strip() else None
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="Enter a valid MRP.",
        )

    if mrp_value is not None and mrp_value < rental_price:
        raise HTTPException(
            status_code=400,
            detail="MRP cannot be lower than rental price.",
        )

    if security_deposit < 0:
        raise HTTPException(
            status_code=400,
            detail="Security deposit cannot be negative.",
        )

    if quantity < 0:
        raise HTTPException(
            status_code=400,
            detail="Quantity cannot be negative.",
        )

    try:
        retained_ids = json.loads(keep_image_ids)

        if (
            not isinstance(retained_ids, list)
            or not all(isinstance(image_id, str) for image_id in retained_ids)
            or len(retained_ids) != len(set(retained_ids))
        ):
            raise ValueError("Invalid image ID list.")

    except (json.JSONDecodeError, ValueError):
        raise HTTPException(
            status_code=400,
            detail="Invalid image selection.",
        )

    new_photos = photos or []

    if len(retained_ids) + len(new_photos) < 1:
        raise HTTPException(
            status_code=400,
            detail="At least one accessory photo is required.",
        )

    uploaded_paths = []
    inserted_image_ids = []
    update_committed = False

    try:
        existing_result = (
            supabase.table("accessories")
            .select("id,quantity,is_available")
            .eq("id", accessory_id)
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .limit(1)
            .execute()
        )

        if not existing_result.data:
            raise HTTPException(
                status_code=404,
                detail="Accessory not found.",
            )

        image_result = (
            supabase.table("accessory_images")
            .select("id,storage_path,display_order,is_cover")
            .eq("accessory_id", accessory_id)
            .execute()
        )

        existing_images = image_result.data or []

        existing_ids = {
            str(image["id"]) for image in existing_images
        }

        if not set(retained_ids).issubset(existing_ids):
            raise HTTPException(
                status_code=400,
                detail="One or more selected images do not belong to this accessory.",
            )

        # Allow an existing listing to be edited after a downgrade
        # without forcing the vendor to remove its existing images.
        # New photos must still respect the current plan's image cap.
        if new_photos:
            check_vendor_image_limit(
                vendor,
                len(retained_ids) + len(new_photos),
            )

        await validate_photos(new_photos)

        images_to_delete = [
            image for image in existing_images
            if str(image["id"]) not in set(retained_ids)
        ]

        new_image_records = []

        for index, photo in enumerate(new_photos):
            extension = Path(photo.filename or "").suffix.lower()

            storage_path = (
                f"{user_id}/{accessory_id}/{uuid.uuid4().hex}{extension}"
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

            new_image_records.append({
                "accessory_id": accessory_id,
                "image_url": image_url,
                "storage_path": storage_path,
                "display_order": len(retained_ids) + index,
                "is_cover": len(retained_ids) == 0 and index == 0,
            })

        for index, image_id in enumerate(retained_ids):
            (
                supabase.table("accessory_images")
                .update({
                    "display_order": index,
                    "is_cover": index == 0,
                })
                .eq("id", image_id)
                .eq("accessory_id", accessory_id)
                .execute()
            )

        if new_image_records:
            inserted_result = (
                supabase.table("accessory_images")
                .insert(new_image_records)
                .execute()
            )

            if not inserted_result.data:
                raise RuntimeError("Failed to save new accessory images.")

            inserted_image_ids = [
                str(image["id"]) for image in inserted_result.data
            ]

        updated_data = {
            "name": name,
            "description": description,
            "category": category,
            "accessory_type": accessory_type,
            "collection": collection,
            "brand": brand.strip() or None,
            "rental_price": rental_price,
            "mrp": mrp_value,
            "security_deposit": security_deposit,
            "color_name": color_name.strip() or None,
            "color_hex": color_hex.strip() or None,
            "material": material.strip() or None,
            "quantity": quantity,
        }

        # Do not automatically enable availability.
        if quantity == 0:
            updated_data["is_available"] = False

        update_result = (
            supabase.table("accessories")
            .update(updated_data)
            .eq("id", accessory_id)
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .execute()
        )

        if not update_result.data:
            raise RuntimeError("Accessory details could not be updated.")

        update_committed = True

        deleted_paths = [
            image["storage_path"]
            for image in images_to_delete
            if image.get("storage_path")
        ]

        if images_to_delete:
            (
                supabase.table("accessory_images")
                .delete()
                .eq("accessory_id", accessory_id)
                .in_(
                    "id",
                    [str(image["id"]) for image in images_to_delete],
                )
                .execute()
            )

        if deleted_paths:
            try:
                supabase.storage.from_(BUCKET_NAME).remove(deleted_paths)
            except Exception as cleanup_error:
                print(
                    "OLD VENDOR ACCESSORY IMAGE CLEANUP ERROR:",
                    repr(cleanup_error),
                )

        return {
            "success": True,
            "message": "Accessory updated successfully.",
            "accessory_id": accessory_id,
            "images": retained_ids + inserted_image_ids,
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("UPDATE VENDOR ACCESSORY ERROR:", repr(exc))

        if not update_committed:
            if inserted_image_ids:
                try:
                    (
                        supabase.table("accessory_images")
                        .delete()
                        .in_("id", inserted_image_ids)
                        .execute()
                    )
                except Exception as cleanup_error:
                    print(
                        "VENDOR ACCESSORY IMAGE ROW CLEANUP ERROR:",
                        repr(cleanup_error),
                    )

            if uploaded_paths:
                try:
                    supabase.storage.from_(BUCKET_NAME).remove(
                        uploaded_paths
                    )
                except Exception as cleanup_error:
                    print(
                        "VENDOR ACCESSORY STORAGE CLEANUP ERROR:",
                        repr(cleanup_error),
                    )

        raise HTTPException(
            status_code=500,
            detail="Failed to update accessory. Please try again.",
        )


# =========================================================
# UPDATE VENDOR ACCESSORY AVAILABILITY
# =========================================================

@router.patch("/{accessory_id}/availability")
def update_vendor_accessory_availability(
    accessory_id: str,
    payload: dict = Body(...),
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
            supabase.table("accessories")
            .select("id,quantity")
            .eq("id", accessory_id)
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .limit(1)
            .execute()
        )

        if not existing.data:
            raise HTTPException(
                status_code=404,
                detail="Accessory not found.",
            )

        if (
            payload["is_available"]
            and existing.data[0]["quantity"] <= 0
        ):
            raise HTTPException(
                status_code=400,
                detail="Cannot enable availability when quantity is zero.",
            )

        updated = (
            supabase.table("accessories")
            .update({"is_available": payload["is_available"]})
            .eq("id", accessory_id)
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .execute()
        )

        if not updated.data:
            raise HTTPException(
                status_code=500,
                detail="Accessory availability could not be updated.",
            )

        return {
            "success": True,
            "is_available": payload["is_available"],
        }

    except HTTPException:
        raise
    except Exception as exc:
        print("UPDATE VENDOR ACCESSORY AVAILABILITY ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to update accessory availability.",
        )
# =========================================================
# DELETE VENDOR ACCESSORY
# =========================================================

@router.delete("/{accessory_id}")
def delete_vendor_accessory(
    accessory_id: str,
    vendor: dict = Depends(get_current_vendor),
):
    user_id = get_vendor_user_id(vendor)

    try:
        # Verify that this accessory belongs to the logged-in vendor.
        existing = (
            supabase.table("accessories")
            .select("id")
            .eq("id", accessory_id)
            .eq("uploaded_by", user_id)
            .eq("role", "vendor")
            .limit(1)
            .execute()
        )

        if not existing.data:
            raise HTTPException(
                status_code=404,
                detail="Accessory not found.",
            )

        # Get actual Storage paths from the database.
        image_result = (
            supabase.table("accessory_images")
            .select("storage_path")
            .eq("accessory_id", accessory_id)
            .execute()
        )

        storage_paths = [
            image["storage_path"]
            for image in (image_result.data or [])
            if image.get("storage_path")
        ]

        # Delete the accessory and cascade-delete its image rows.
        (
            supabase.table("accessories")
            .delete()
            .eq("id", accessory_id)
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
                    "VENDOR ACCESSORY STORAGE DELETE ERROR:",
                    repr(cleanup_error),
                )

        return {
            "success": True,
            "message": "Accessory and its images deleted successfully.",
            "accessory_id": accessory_id,
        }

    except HTTPException:
        raise

    except Exception as exc:
        print("DELETE VENDOR ACCESSORY ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to delete accessory. Please try again.",
        )