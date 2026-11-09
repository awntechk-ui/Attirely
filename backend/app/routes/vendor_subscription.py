from fastapi import APIRouter, Depends

from app.core.auth_dependency import get_current_vendor

from app.schemas.vendor_subscription import (
    VendorPlanSelectionRequest,
)

from app.services.vendor_subscription_service import (
    select_vendor_plan,
    get_current_vendor_subscription,
)


router = APIRouter(
    prefix="/vendor/subscription",
    tags=["Vendor Subscription"],
)


# =========================================
# SELECT / ACTIVATE PLAN
# =========================================

@router.post("/select")
def select_plan(
    request: VendorPlanSelectionRequest,
    vendor: dict = Depends(get_current_vendor),
):
    return select_vendor_plan(
        vendor=vendor,
        plan_code=request.plan_code.strip().lower(),
    )


# =========================================
# GET CURRENT VENDOR SUBSCRIPTION
# =========================================

@router.get("/current")
def get_current_subscription(
    vendor: dict = Depends(get_current_vendor),
):
    return get_current_vendor_subscription(vendor=vendor)