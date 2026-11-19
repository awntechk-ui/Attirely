from fastapi import APIRouter, Depends

from app.core.auth_dependency import get_current_vendor

from app.schemas.vendor_subscription import (
    VendorPlanSelectionRequest,
    VerifyVendorPlanPayment,
)
from app.services.vendor_plan_payments import (
    start_vendor_plan_checkout,
    verify_vendor_plan_checkout,
)

from app.services.vendor_subscription_service import (
    select_vendor_plan,
    get_current_vendor_subscription,
    get_active_vendor_plans,
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


@router.post("/checkout")
def create_plan_checkout(
    request: VendorPlanSelectionRequest,
    vendor: dict = Depends(get_current_vendor),
):
    return start_vendor_plan_checkout(vendor, request.plan_code.strip().lower())


@router.post("/checkout/verify")
def verify_plan_checkout(
    request: VerifyVendorPlanPayment,
    vendor: dict = Depends(get_current_vendor),
):
    return verify_vendor_plan_checkout(
        vendor,
        str(request.checkout_id),
        request.razorpay_payment_id,
        request.razorpay_signature,
    )


# =========================================
# GET CURRENT VENDOR SUBSCRIPTION
# =========================================

@router.get("/current")
def get_current_subscription(
    vendor: dict = Depends(get_current_vendor),
):
    return get_current_vendor_subscription(vendor=vendor)


# GET ALL ACTIVE VENDOR PLANS
@router.get("/plans")
def get_vendor_plans(
    vendor: dict = Depends(get_current_vendor)
):
    return get_active_vendor_plans()
