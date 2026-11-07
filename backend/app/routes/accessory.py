
import uuid
from pathlib import Path
import json
from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
)

from app.core.auth_dependency import get_current_user
from app.core.supabase import supabase_admin as supabase


router = APIRouter(
    prefix="/accessories",
    tags=["Accessories"],
)

BUCKET_NAME = "accessory-images"
MAX_IMAGES = 5
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


def get_uploader(user_id: str):
    """Resolve uploader role from existing user/vendor profiles."""

    vendor = (
        supabase.table("vendors")
        .select("id")
        .eq("auth_user_id", user_id)
        .limit(1)
        .execute()
    )

    if vendor.data:
        return "vendor"

    user = (
        supabase.table("users")
        .select("id")
        .eq("id", user_id)
        .limit(1)
        .execute()
    )

    if user.data:
        return "user"

    raise HTTPException(
        status_code=403,
        detail="No registered user or vendor profile found.",
    )


# =========================================
# CREATE ACCESSORY
# =========================================

@router.post("")
async def create_accessory(
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
    current_user=Depends(get_current_user),
):
    name = name.strip()

    if len(name) < 2:
        raise HTTPException(
            status_code=400,
            detail="Accessory name must contain at least 2 characters.",
        )

    if not description.strip():
        raise HTTPException(
            status_code=400,
            detail="Description is required.",
        )

    if not category.strip() or not accessory_type.strip():
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

    if not photos or len(photos) > MAX_IMAGES:
        raise HTTPException(
            status_code=400,
            detail="Upload between 1 and 5 accessory photos.",
        )

    user_id = str(current_user.id)

    try:
        uploader_role = get_uploader(user_id)
    except HTTPException:
        raise
    except Exception as exc:
        print("ACCESSORY UPLOADER ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to verify uploader profile.",
        )

    # Validate all images before database insertion.
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

    accessory_id = str(uuid.uuid4())
    uploaded_paths = []
    accessory_created = False

    accessory_data = {
        "id": accessory_id,
        "uploaded_by": user_id,
        "role": uploader_role,
        "name": name,
        "description": description.strip(),
        "category": category.strip(),
        "accessory_type": accessory_type.strip(),
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
            "role": uploader_role,
            "images": image_result.data,
        }

    except Exception as exc:
        if uploaded_paths:
            try:
                supabase.storage.from_(BUCKET_NAME).remove(
                    uploaded_paths
                )
            except Exception as cleanup_error:
                print("ACCESSORY STORAGE CLEANUP ERROR:", repr(cleanup_error))

        if accessory_created:
            try:
                (
                    supabase.table("accessories")
                    .delete()
                    .eq("id", accessory_id)
                    .execute()
                )
            except Exception as cleanup_error:
                print("ACCESSORY DB CLEANUP ERROR:", repr(cleanup_error))

        print("CREATE ACCESSORY ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to publish accessory. Please try again.",
        )


# =========================================
# GET MY ACCESSORIES
# =========================================

@router.get("")
def get_my_accessories(
    current_user=Depends(get_current_user),
):
    user_id = str(current_user.id)

    try:
        result = (
            supabase.table("accessories")
            .select("*")
            .eq("uploaded_by", user_id)
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
            images = images_by_accessory.get(
                accessory.get("id"), []
            )

            accessory["images"] = images

            cover = next(
                (img for img in images if img.get("is_cover")),
                images[0] if images else None,
            )

            accessory["cover_image_url"] = (
                cover.get("image_url") if cover else None
            )

        return {
            "success": True,
            "count": len(accessories),
            "accessories": accessories,
        }

    except Exception as exc:
        print("GET MY ACCESSORIES ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to load your accessories.",
        )

# =========================================
# PUBLIC ACCESSORIES CATALOGUE
# =========================================

@router.get("/catalogue")
def get_accessories_catalogue():
    try:
        result = (
            supabase.table("accessories")
            .select("*")
            .eq("status", "published")
            .eq("is_available", True)
            .gt("quantity", 0)
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

        accessory_ids = [item["id"] for item in accessories]

        image_result = (
            supabase.table("accessory_images")
            .select(
                "accessory_id,image_url,display_order,is_cover"
            )
            .in_("accessory_id", accessory_ids)
            .order("display_order")
            .execute()
        )

        images_by_accessory = {}

        for image in image_result.data or []:
            images_by_accessory.setdefault(
                image["accessory_id"], []
            ).append(image)

        for accessory in accessories:
            images = images_by_accessory.get(
                accessory["id"], []
            )

            accessory["images"] = images

            cover = next(
                (img for img in images if img.get("is_cover")),
                images[0] if images else None,
            )

            accessory["cover_image_url"] = (
                cover.get("image_url") if cover else None
            )

        return {
            "success": True,
            "count": len(accessories),
            "accessories": accessories,
        }

    except Exception as exc:
        print("PUBLIC ACCESSORIES CATALOGUE ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to load accessories catalogue.",
        )



# =========================================
# GET ACCESSORY DETAILS
# =========================================

@router.get("/{accessory_id}")
def get_accessory_details(
    accessory_id: str,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user.id)

    try:
        result = (
            supabase.table("accessories")
            .select("*")
            .eq("id", accessory_id)
            .eq("uploaded_by", user_id)
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

        images = image_result.data or []

        images.sort(
            key=lambda image: (
                not image.get("is_cover", False),
                image.get("display_order", 0),
            )
        )

        accessory["images"] = images

        cover = next(
            (img for img in images if img.get("is_cover")),
            images[0] if images else None,
        )

        accessory["cover_image_url"] = (
            cover.get("image_url") if cover else None
        )

        return {
            "success": True,
            "accessory": accessory,
        }

    except HTTPException:
        raise
    except Exception as exc:
        print("GET ACCESSORY DETAILS ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to load accessory details.",
        )

# =========================================
# UPDATE ACCESSORY
# =========================================

@router.patch("/{accessory_id}")
async def update_accessory(
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
    current_user=Depends(get_current_user),
):
    user_id = str(current_user.id)

    # ---------- Validate fields ----------

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

    # ---------- Parse retained image IDs ----------

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

    if len(retained_ids) + len(new_photos) > MAX_IMAGES:
        raise HTTPException(
            status_code=400,
            detail="You can keep a maximum of 5 accessory photos.",
        )

    # ---------- Verify ownership and existing images ----------

    uploaded_paths = []
    inserted_image_ids = []
    update_committed = False

    try:
        existing_result = (
            supabase.table("accessories")
            .select("id,quantity,is_available")
            .eq("id", accessory_id)
            .eq("uploaded_by", user_id)
            .limit(1)
            .execute()
        )

        if not existing_result.data:
            raise HTTPException(
                status_code=404,
                detail="Accessory not found.",
            )

        existing_accessory = existing_result.data[0]

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

        images_to_delete = [
            image for image in existing_images
            if str(image["id"]) not in set(retained_ids)
        ]

        # ---------- Validate all new photos ----------

        for photo in new_photos:
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

        # ---------- Upload new photos ----------

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

        # ---------- Update retained image ordering ----------

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

        # ---------- Insert new image records ----------

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

        # ---------- Update accessory details ----------

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
        # Only turn it off if quantity becomes zero.
        if quantity == 0:
            updated_data["is_available"] = False

        update_result = (
            supabase.table("accessories")
            .update(updated_data)
            .eq("id", accessory_id)
            .eq("uploaded_by", user_id)
            .execute()
        )

        if not update_result.data:
            raise RuntimeError("Accessory details could not be updated.")
        update_committed = True

        # ---------- Delete removed images after successful update ----------

        # ---------- Delete removed images after successful update ----------

        deleted_paths = [
            image["storage_path"]
            for image in images_to_delete
            if image.get("storage_path")
        ]

        # First delete removed image records from the database.
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

        # Then remove their files from Supabase Storage.
        # If storage cleanup fails, do not undo the successful listing update.
        if deleted_paths:
            try:
                supabase.storage.from_(BUCKET_NAME).remove(deleted_paths)
            except Exception as cleanup_error:
                print(
                    "OLD ACCESSORY IMAGE CLEANUP ERROR:",
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
        print("UPDATE ACCESSORY ERROR:", repr(exc))

        # Clean up newly inserted image records if the update failed.
        # Clean up newly uploaded images only if the listing update failed.
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
                    "ACCESSORY IMAGE ROW CLEANUP ERROR:",
                    repr(cleanup_error),
                )

        if uploaded_paths:
            try:
                supabase.storage.from_(BUCKET_NAME).remove(uploaded_paths)
            except Exception as cleanup_error:
                print(
                    "ACCESSORY STORAGE CLEANUP ERROR:",
                    repr(cleanup_error),
                )


        raise HTTPException(
            status_code=500,
            detail="Failed to update accessory. Please try again.",
        )
# =========================================
# UPDATE ACCESSORY AVAILABILITY
# =========================================

@router.patch("/{accessory_id}/availability")
def update_accessory_availability(
    accessory_id: str,
    payload: dict,
    current_user=Depends(get_current_user),
):
    if not isinstance(payload.get("is_available"), bool):
        raise HTTPException(
            status_code=400,
            detail="is_available must be true or false.",
        )

    user_id = str(current_user.id)

    try:
        existing = (
            supabase.table("accessories")
            .select("id,quantity")
            .eq("id", accessory_id)
            .eq("uploaded_by", user_id)
            .limit(1)
            .execute()
        )

        if not existing.data:
            raise HTTPException(
                status_code=404,
                detail="Accessory not found.",
            )

        if payload["is_available"] and existing.data[0]["quantity"] <= 0:
            raise HTTPException(
                status_code=400,
                detail="Cannot enable availability when quantity is zero.",
            )

        updated = (
            supabase.table("accessories")
            .update({
                "is_available": payload["is_available"],
            })
            .eq("id", accessory_id)
            .eq("uploaded_by", user_id)
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
        print("UPDATE ACCESSORY AVAILABILITY ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to update accessory availability.",
        )
