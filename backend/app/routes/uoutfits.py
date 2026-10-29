
from fastapi import APIRouter, HTTPException

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
    Includes outfit images and the cover image URL.
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
                "id,outfit_id,image_url,storage_path,"
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
        print("GET OUTFIT CATALOGUE ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to load the outfit catalogue.",
        )


# ============================================================
# CUSTOMER — GET ONE PUBLISHED, AVAILABLE OUTFIT
# IMPORTANT: Keep this AFTER /catalogue
# ============================================================

@router.get("/{outfit_id}")
async def get_catalogue_outfit_details(outfit_id: str):
    """
    Return one published, available outfit and its ordered images.
    """

    try:
        result = (
            supabase.table("outfits")
            .select("*")
            .eq("id", outfit_id)
            .eq("status", "published")
            .eq("is_available", True)
            .limit(1)
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=404,
                detail="Outfit not found or no longer available.",
            )

        outfit = result.data[0]

        image_result = (
            supabase.table("outfit_images")
            .select(
                "id,outfit_id,image_url,storage_path,"
                "display_order,is_cover"
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
        print("GET CATALOGUE OUTFIT DETAILS ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to load outfit details.",
        )
