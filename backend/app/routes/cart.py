
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.auth_dependency import get_current_user
from app.core.supabase import supabase_admin as supabase


router = APIRouter(
    prefix="/cart",
    tags=["Cart"],
)


# ============================================================
# REQUEST MODEL
# ============================================================

class AddToCartRequest(BaseModel):
    outfit_id: UUID


# ============================================================
# VERIFY NORMAL USER ACCOUNT
# ============================================================

def _get_user_id(current_user):
    user_id = str(current_user.id)

    try:
        result = (
            supabase.table("users")
            .select("id")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=403,
                detail="Only registered users can use the cart.",
            )

        return user_id

    except HTTPException:
        raise

    except Exception as exc:
        print("CART USER VALIDATION ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to verify user account.",
        )


# ============================================================
# FORMAT CART ITEM
# ============================================================

def _format_cart_item(cart_row, outfit, images):

    cover = next(
        (image for image in images if image.get("is_cover")),
        images[0] if images else None,
    )

    is_available = outfit.get("is_available") is True
    is_published = outfit.get("status") == "published"

    outfit["images"] = images
    outfit["cover_image_url"] = (
        cover.get("image_url") if cover else None
    )

    return {
        "cart_item_id": cart_row.get("id"),
        "added_at": cart_row.get("created_at"),
        "outfit": outfit,
        "can_rent": is_available and is_published,
    }


# ============================================================
# GET USER CART
# ============================================================

@router.get("")
def get_cart(
    current_user=Depends(get_current_user),
):
    user_id = _get_user_id(current_user)

    try:
        cart_result = (
            supabase.table("cart_items")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )

        cart_rows = cart_result.data or []

        if not cart_rows:
            return {
                "success": True,
                "cart_count": 0,
                "items": [],
            }

        outfit_ids = [
            row["outfit_id"]
            for row in cart_rows
        ]

        outfit_result = (
            supabase.table("outfits")
            .select("*")
            .in_("id", outfit_ids)
            .execute()
        )

        outfits = {
            str(outfit["id"]): outfit
            for outfit in (outfit_result.data or [])
        }

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
            outfit_id = str(image.get("outfit_id"))

            images_by_outfit.setdefault(
                outfit_id, []
            ).append(image)

        items = []

        for cart_row in cart_rows:

            outfit_id = str(cart_row["outfit_id"])
            outfit = outfits.get(outfit_id)

            if outfit is None:
                continue

            images = images_by_outfit.get(
                outfit_id, []
            )

            items.append(
                _format_cart_item(
                    cart_row,
                    outfit,
                    images,
                )
            )

        return {
            "success": True,
            "cart_count": len(items),
            "items": items,
        }

    except Exception as exc:
        print("GET CART ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to load cart.",
        )


# ============================================================
# ADD OUTFIT TO CART
# ============================================================

@router.post("/items", status_code=201)
def add_to_cart(
    data: AddToCartRequest,
    current_user=Depends(get_current_user),
):
    user_id = _get_user_id(current_user)
    outfit_id = str(data.outfit_id)

    try:

        # ----------------------------------------
        # CHECK OUTFIT EXISTS
        # ----------------------------------------

        outfit_result = (
            supabase.table("outfits")
            .select("*")
            .eq("id", outfit_id)
            .limit(1)
            .execute()
        )

        if not outfit_result.data:
            raise HTTPException(
                status_code=404,
                detail="Outfit not found.",
            )

        outfit = outfit_result.data[0]

        # ----------------------------------------
        # CHECK AVAILABILITY
        # ----------------------------------------

        if (
            outfit.get("status") != "published"
            or outfit.get("is_available") is not True
        ):
            raise HTTPException(
                status_code=409,
                detail="This outfit is currently unavailable.",
            )

        # ----------------------------------------
        # CHECK DUPLICATE
        # ----------------------------------------

        existing = (
            supabase.table("cart_items")
            .select("id")
            .eq("user_id", user_id)
            .eq("outfit_id", outfit_id)
            .limit(1)
            .execute()
        )

        if existing.data:
            raise HTTPException(
                status_code=409,
                detail="Already in cart.",
            )

        # ----------------------------------------
        # INSERT CART ITEM
        # ----------------------------------------

        insert_result = (
            supabase.table("cart_items")
            .insert({
                "user_id": user_id,
                "outfit_id": outfit_id,
            })
            .execute()
        )

        if not insert_result.data:
            raise HTTPException(
                status_code=500,
                detail="Could not add outfit to cart.",
            )

        cart_row = insert_result.data[0]

        # ----------------------------------------
        # FETCH OUTFIT IMAGES
        # ----------------------------------------

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

        return {
            "success": True,
            "message": "Outfit added to cart.",
            "cart_item": _format_cart_item(
                cart_row,
                outfit,
                images,
            ),
        }

    except HTTPException:
        raise

    except Exception as exc:
        error_text = str(exc)

        print("ADD TO CART ERROR:", repr(exc))

        # Handle duplicate insertion race condition
        if "23505" in error_text:
            raise HTTPException(
                status_code=409,
                detail="Already in cart.",
            )

        raise HTTPException(
            status_code=500,
            detail="Failed to add outfit to cart.",
        )


# ============================================================
# REMOVE ONE OUTFIT
# ============================================================

@router.delete("/items/{outfit_id}")
def remove_from_cart(
    outfit_id: UUID,
    current_user=Depends(get_current_user),
):
    user_id = _get_user_id(current_user)

    try:

        result = (
            supabase.table("cart_items")
            .delete()
            .eq("user_id", user_id)
            .eq("outfit_id", str(outfit_id))
            .execute()
        )

        return {
            "success": True,
            "message": "Outfit removed from cart.",
        }

    except Exception as exc:
        print("REMOVE CART ITEM ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to remove outfit from cart.",
        )


# ============================================================
# CLEAR ENTIRE CART
# ============================================================

@router.delete("")
def clear_cart(
    current_user=Depends(get_current_user),
):
    user_id = _get_user_id(current_user)

    try:

        supabase.table("cart_items").delete().eq(
            "user_id", user_id
        ).execute()

        return {
            "success": True,
            "message": "Cart cleared successfully.",
        }

    except Exception as exc:
        print("CLEAR CART ERROR:", repr(exc))

        raise HTTPException(
            status_code=500,
            detail="Failed to clear cart.",
        )
