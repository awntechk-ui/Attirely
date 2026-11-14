
from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query

from app.core.auth_dependency import get_current_vendor
from app.core.supabase import supabase_admin as supabase


router = APIRouter(
    prefix="/vendor/notifications",
    tags=["Vendor Notifications"],
)


# --------------------------------------------------
# GET ALL NOTIFICATIONS
# --------------------------------------------------

@router.get("")
def get_vendor_notifications(
    limit: int = Query(default=100, ge=1, le=200),
    vendor=Depends(get_current_vendor),
):
    try:
        vendor_id = str(vendor["id"])

        # Remove notifications whose 60-day retention period has ended.
        supabase.table("vendor_notifications") \
            .delete() \
            .eq("vendor_id", vendor_id) \
            .lt("expires_at", datetime.now(timezone.utc).isoformat()) \
            .execute()

        # Fetch this vendor's notifications.
        result = (
            supabase.table("vendor_notifications")
            .select("*")
            .eq("vendor_id", vendor_id)
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )

        # Get the unread count separately.
        unread_result = (
            supabase.table("vendor_notifications")
            .select("id")
            .eq("vendor_id", vendor_id)
            .eq("is_read", False)
            .execute()
        )

        notifications = result.data or []

        return {
            "success": True,
            "total": len(notifications),
            "unread_count": len(unread_result.data or []),
            "notifications": notifications,
        }

    except Exception as e:
        print("GET VENDOR NOTIFICATIONS ERROR:", repr(e))
        raise HTTPException(
            status_code=500,
            detail="Failed to fetch notifications.",
        )


# --------------------------------------------------
# MARK ONE NOTIFICATION AS READ
# --------------------------------------------------

@router.patch("/{notification_id}/read")
def mark_notification_as_read(
    notification_id: UUID,
    vendor=Depends(get_current_vendor),
):
    try:
        vendor_id = str(vendor["id"])

        result = (
            supabase.table("vendor_notifications")
            .update({"is_read": True})
            .eq("id", str(notification_id))
            .eq("vendor_id", vendor_id)
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=404,
                detail="Notification not found.",
            )

        return {
            "success": True,
            "message": "Notification marked as read.",
            "notification": result.data[0],
        }

    except HTTPException:
        raise
    except Exception as e:
        print("MARK NOTIFICATION READ ERROR:", repr(e))
        raise HTTPException(
            status_code=500,
            detail="Failed to update notification.",
        )


# --------------------------------------------------
# MARK ALL NOTIFICATIONS AS READ
# --------------------------------------------------

@router.patch("/read-all")
def mark_all_notifications_as_read(
    vendor=Depends(get_current_vendor),
):
    try:
        vendor_id = str(vendor["id"])

        result = (
            supabase.table("vendor_notifications")
            .update({"is_read": True})
            .eq("vendor_id", vendor_id)
            .eq("is_read", False)
            .execute()
        )

        return {
            "success": True,
            "message": "All notifications marked as read.",
            "updated_count": len(result.data or []),
        }

    except Exception as e:
        print("MARK ALL NOTIFICATIONS READ ERROR:", repr(e))
        raise HTTPException(
            status_code=500,
            detail="Failed to update notifications.",
        )
