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
    prefix="/uoutfits",
    tags=["Uoutfits"],
)

# ============================================================
# CUSTOMER CATALOGUE — ALL PUBLISHED, AVAILABLE OUTFITS
# ============================================================

@router.get("/catalogue")
async def get_outfit_catalogue():
    """
    Return published, available outfits uploaded by users and vendors.
    This endpoint is separate from GET /outfits, which returns
    only outfits belonging to the authenticated uploader.
    """

    try:
        result = (
            supabase.table("outfits")
            .select("*")
            .eq("status", "published")
            .eq("is_available", True)
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
            outfit["id"]
            for outfit in outfits
            if outfit.get("id")
        ]

        image_result = (
            supabase.table("outfit_images")
            .select(
                "outfit_id,image_url,storage_path,"
                "display_order,is_cover"
            )
            .in_("outfit_id", outfit_ids)
            .order("display_order")
            .execute()
        )

        images_by_outfit = {}

        for image in image_result.data or []:
            outfit_id = image.get("outfit_id")
            images_by_outfit.setdefault(outfit_id, []).append(image)

        for outfit in outfits:
            images = images_by_outfit.get(outfit.get("id"), [])
            outfit["images"] = images

            cover = next(
                (image for image in images if image.get("is_cover")),
                None,
            )

            if cover is None and images:
                cover = images[0]

            outfit["cover_image_url"] = (
                cover.get("image_url") if cover else None
            )

        return {
            "success": True,
            "count": len(outfits),
            "outfits": outfits,
        }

    except Exception as exc:
        print("GET OUTFIT CATALOGUE ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to load the outfit catalogue.",
        )