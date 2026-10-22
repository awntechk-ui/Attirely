


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

from app.core.auth_dependency import get_current_user
from app.core.supabase import supabase_admin as supabase


router = APIRouter(
    prefix="/outfits",
    tags=["Outfits"],
)

BUCKET_NAME = "outfit-images"
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


def get_uploader(user_id: str):
    """Resolve uploader role from database profiles."""

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


@router.post("")
async def create_outfit(
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
    size_type: str = Form("standard"),
    sizes: str = Form("[]"),
    measurements: str = Form("{}"),
    material: str = Form(...),
    sleeve: str = Form(...),
    photos: list[UploadFile] = File(...),
    current_user=Depends(get_current_user),
):
    name = name.strip()

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

    if not photos or len(photos) > MAX_IMAGES:
        raise HTTPException(
            status_code=400,
            detail="Upload between 1 and 5 outfit photos.",
        )

    if size_type not in {"standard", "measurements"}:
        raise HTTPException(
            status_code=400,
            detail="Invalid size type.",
        )

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

    user_id = str(current_user.id)

    try:
        uploader_role = get_uploader(user_id)
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Failed to verify uploader profile.",
        )

    # Validate all files before creating database records.
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

    outfit_id = str(uuid.uuid4())
    uploaded_paths = []
    outfit_created = False

    outfit_data = {
        "id": outfit_id,
        "uploaded_by": user_id,
        "role": uploader_role,
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
        "material": material,
        "sleeve": sleeve,
        "status": "published",
        "is_available": True,
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
            "role": uploader_role,
            "images": image_result.data,
        }

    except Exception as exc:
        # Best-effort cleanup of files if any stage fails.
        if uploaded_paths:
            try:
                supabase.storage.from_(BUCKET_NAME).remove(
                    uploaded_paths
                )
            except Exception as cleanup_error:
                print("STORAGE CLEANUP ERROR:", repr(cleanup_error))

        if outfit_created:
            try:
                supabase.table("outfits").delete().eq(
                    "id", outfit_id
                ).execute()
            except Exception as cleanup_error:
                print("OUTFIT CLEANUP ERROR:", repr(cleanup_error))

        print("CREATE OUTFIT ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to publish outfit. Please try again.",
        )


@router.get("")
async def get_my_outfits(current_user=Depends(get_current_user)):
    """Return outfits uploaded by the authenticated vendor, with their images."""
    user_id = str(current_user.id)

    try:
        result = (
            supabase.table("outfits")
            .select("*")
            .eq("uploaded_by", user_id)
            # .eq("role", "vendor")
            .order("created_at", desc=True)
            .execute()
        )
        outfits = result.data or []

        if not outfits:
            return {"success": True, "count": 0, "outfits": []}

        outfit_ids = [item["id"] for item in outfits if item.get("id")]
        image_result = (
            supabase.table("outfit_images")
            .select("outfit_id,image_url,storage_path,display_order,is_cover")
            .in_("outfit_id", outfit_ids)
            .order("display_order")
            .execute()
        )
        images_by_outfit = {}
        for image in (image_result.data or []):
            images_by_outfit.setdefault(image.get("outfit_id"), []).append(image)

        for outfit in outfits:
            images = images_by_outfit.get(outfit.get("id"), [])
            outfit["images"] = images
            cover = next((img for img in images if img.get("is_cover")), None)
            if cover is None and images:
                cover = images[0]
            outfit["cover_image_url"] = cover.get("image_url") if cover else None

        return {"success": True, "count": len(outfits), "outfits": outfits}

    except Exception as exc:
        print("GET MY OUTFITS ERROR:", repr(exc))
        raise HTTPException(
            status_code=500,
            detail="Failed to load your outfits. Please try again.",
        )

# import json
# import uuid
# from pathlib import Path

# from fastapi import (
#     APIRouter,
#     Depends,
#     File,
#     Form,
#     HTTPException,
#     UploadFile,
# )

# from app.core.auth_dependency import get_current_user
# from app.core.supabase import supabase_admin as supabase


# router = APIRouter(
#     prefix="/outfits",
#     tags=["Outfits"],
# )

# BUCKET_NAME = "outfit-images"
# MAX_IMAGES = 5
# MAX_FILE_SIZE = 5 * 1024 * 1024

# ALLOWED_TYPES = {
#     "image/jpeg",
#     "image/png",
#     "image/webp",
# }

# ALLOWED_EXTENSIONS = {
#     ".jpg",
#     ".jpeg",
#     ".png",
#     ".webp",
# }


# def get_uploader(user_id: str):
#     """Resolve uploader role from database profiles."""

#     vendor = (
#         supabase.table("vendors")
#         .select("id")
#         .eq("auth_user_id", user_id)
#         .limit(1)
#         .execute()
#     )

#     if vendor.data:
#         return "vendor"

#     user = (
#         supabase.table("users")
#         .select("id")
#         .eq("id", user_id)
#         .limit(1)
#         .execute()
#     )

#     if user.data:
#         return "user"

#     raise HTTPException(
#         status_code=403,
#         detail="No registered user or vendor profile found.",
#     )


# @router.post("")
# async def create_outfit(
#     name: str = Form(...),
#     description: str = Form(...),
#     gender: str = Form(...),
#     brand: str | None = Form(None),
#     occasion: str = Form(...),
#     category: str = Form(...),
#     rental_price: float = Form(...),
#     mrp: float | None = Form(None),
#     security_deposit: float = Form(...),
#     color_name: str | None = Form(None),
#     color_hex: str | None = Form(None),
#     size_type: str = Form("standard"),
#     sizes: str = Form("[]"),
#     measurements: str = Form("{}"),
#     material: str = Form(...),
#     sleeve: str = Form(...),
#     photos: list[UploadFile] = File(...),
#     current_user=Depends(get_current_user),
# ):
#     name = name.strip()

#     if len(name) < 2:
#         raise HTTPException(
#             status_code=400,
#             detail="Outfit name must contain at least 2 characters.",
#         )

#     if rental_price <= 0:
#         raise HTTPException(
#             status_code=400,
#             detail="Rental price must be greater than zero.",
#         )

#     if mrp is not None and mrp < rental_price:
#         raise HTTPException(
#             status_code=400,
#             detail="MRP cannot be lower than rental price.",
#         )

#     if security_deposit < 0:
#         raise HTTPException(
#             status_code=400,
#             detail="Security deposit cannot be negative.",
#         )

#     if not photos or len(photos) > MAX_IMAGES:
#         raise HTTPException(
#             status_code=400,
#             detail="Upload between 1 and 5 outfit photos.",
#         )

#     if size_type not in {"standard", "measurements"}:
#         raise HTTPException(
#             status_code=400,
#             detail="Invalid size type.",
#         )

#     try:
#         parsed_sizes = json.loads(sizes)
#         parsed_measurements = json.loads(measurements)
#     except json.JSONDecodeError:
#         raise HTTPException(
#             status_code=400,
#             detail="Invalid sizes or measurements JSON.",
#         )

#     if not isinstance(parsed_sizes, list):
#         raise HTTPException(
#             status_code=400,
#             detail="Sizes must be a JSON array.",
#         )

#     if not isinstance(parsed_measurements, dict):
#         raise HTTPException(
#             status_code=400,
#             detail="Measurements must be a JSON object.",
#         )

#     if size_type == "standard" and not parsed_sizes:
#         raise HTTPException(
#             status_code=400,
#             detail="Select at least one standard size.",
#         )

#     if size_type == "measurements" and not parsed_measurements:
#         raise HTTPException(
#             status_code=400,
#             detail="Provide outfit measurements.",
#         )

#     user_id = str(current_user.id)

#     try:
#         uploader_role = get_uploader(user_id)
#     except HTTPException:
#         raise
#     except Exception:
#         raise HTTPException(
#             status_code=500,
#             detail="Failed to verify uploader profile.",
#         )

#     # Validate all files before creating database records.
#     for photo in photos:
#         extension = Path(photo.filename or "").suffix.lower()

#         if extension not in ALLOWED_EXTENSIONS:
#             raise HTTPException(
#                 status_code=400,
#                 detail=f"Unsupported image file: {photo.filename}",
#             )

#         if photo.content_type not in ALLOWED_TYPES:
#             raise HTTPException(
#                 status_code=400,
#                 detail=f"Unsupported image type: {photo.filename}",
#             )

#         contents = await photo.read()

#         if not contents or len(contents) > MAX_FILE_SIZE:
#             raise HTTPException(
#                 status_code=400,
#                 detail="Each image must be between 1 byte and 5 MB.",
#             )

#         photo.file.seek(0)

#     outfit_id = str(uuid.uuid4())
#     uploaded_paths = []
#     outfit_created = False

#     outfit_data = {
#         "id": outfit_id,
#         "uploaded_by": user_id,
#         "role": uploader_role,
#         "name": name,
#         "description": description.strip(),
#         "gender": gender,
#         "brand": brand.strip() if brand else None,
#         "occasion": occasion,
#         "category": category,
#         "rental_price": rental_price,
#         "mrp": mrp,
#         "security_deposit": security_deposit,
#         "color_name": color_name,
#         "color_hex": color_hex,
#         "size_type": size_type,
#         "sizes": parsed_sizes,
#         "measurements": parsed_measurements,
#         "material": material,
#         "sleeve": sleeve,
#         "status": "published",
#         "is_available": True,
#     }

#     try:
#         result = (
#             supabase.table("outfits")
#             .insert(outfit_data)
#             .execute()
#         )

#         if not result.data:
#             raise RuntimeError("Outfit database insert failed.")

#         outfit_created = True
#         image_records = []

#         for index, photo in enumerate(photos):
#             extension = Path(photo.filename or "").suffix.lower()
#             storage_path = (
#                 f"{user_id}/{outfit_id}/{index + 1}{extension}"
#             )

#             contents = await photo.read()

#             supabase.storage.from_(BUCKET_NAME).upload(
#                 storage_path,
#                 contents,
#                 {
#                     "content-type": photo.content_type,
#                     "upsert": "false",
#                 },
#             )

#             uploaded_paths.append(storage_path)

#             image_url = (
#                 supabase.storage
#                 .from_(BUCKET_NAME)
#                 .get_public_url(storage_path)
#             )

#             image_records.append({
#                 "outfit_id": outfit_id,
#                 "image_url": image_url,
#                 "storage_path": storage_path,
#                 "display_order": index,
#                 "is_cover": index == 0,
#             })

#         image_result = (
#             supabase.table("outfit_images")
#             .insert(image_records)
#             .execute()
#         )

#         if not image_result.data:
#             raise RuntimeError("Failed to save outfit images.")

#         return {
#             "success": True,
#             "message": "Outfit published successfully.",
#             "outfit_id": outfit_id,
#             "uploaded_by": user_id,
#             "role": uploader_role,
#             "images": image_result.data,
#         }

#     except Exception as exc:
#         # Best-effort cleanup of files if any stage fails.
#         if uploaded_paths:
#             try:
#                 supabase.storage.from_(BUCKET_NAME).remove(
#                     uploaded_paths
#                 )
#             except Exception as cleanup_error:
#                 print("STORAGE CLEANUP ERROR:", repr(cleanup_error))

#         if outfit_created:
#             try:
#                 supabase.table("outfits").delete().eq(
#                     "id", outfit_id
#                 ).execute()
#             except Exception as cleanup_error:
#                 print("OUTFIT CLEANUP ERROR:", repr(cleanup_error))

#         print("CREATE OUTFIT ERROR:", repr(exc))

#         raise HTTPException(
#             status_code=500,
#             detail="Failed to publish outfit. Please try again.",
#         )



