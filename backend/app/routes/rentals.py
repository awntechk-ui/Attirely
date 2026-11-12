
from fastapi import APIRouter, Depends

from app.schemas.rentals import (
    RentalCheckoutRequest,
    RentalCheckoutResponse,
    RentalAvailabilityRequest,
    RentalAvailabilityResponse,
    RentalActionRequest
)

from app.services.rentals_service import (
    check_rental_availability,
    create_rental_booking,
    manage_rental_status,
    get_customer_rentals,
    get_vendor_rentals,
    get_owner_rentals,
)

from app.core.auth_dependency import (
    get_current_user,
    get_current_vendor,
)


router = APIRouter(
    prefix="/rentals",
    tags=["Rentals"]
)


# ==========================================================
# CHECK AVAILABILITY
# ==========================================================

@router.post(
    "/check-availability",
    response_model=RentalAvailabilityResponse
)
def check_availability(
    request: RentalAvailabilityRequest,
    current_user=Depends(get_current_user)
):

    return check_rental_availability(request.items)


# ==========================================================
# CREATE RENTAL BOOKING
# ==========================================================

@router.post(
    "/create",
    response_model=RentalCheckoutResponse
)
def create_rental(
    request: RentalCheckoutRequest,
    current_user=Depends(get_current_user)
):

    return create_rental_booking(
        user_id=current_user.id,
        request=request
    )


# ==========================================================
# CUSTOMER RENTALS
# ==========================================================

@router.get("/my-rentals")
def my_rentals(
    current_user=Depends(get_current_user)
):

    return {
        "success": True,
        "rentals": get_customer_rentals(
            current_user.id
        )
    }


# ==========================================================
# VENDOR RENTAL REQUESTS
# ==========================================================

@router.get("/vendor/requests")
def vendor_rental_requests(
    current_vendor=Depends(get_current_vendor)
):

    return {
        "success": True,
        "rentals": get_vendor_rentals(
            current_vendor["id"]
        )
    }


# ==========================================================
# CUSTOMER OUTFIT OWNER REQUESTS
# ==========================================================

@router.get("/owner/requests")
def owner_rental_requests(
    current_user=Depends(get_current_user)
):

    return {
        "success": True,
        "rentals": get_owner_rentals(
            current_user.id
        )
    }



# ==========================================================
# ACCEPT RENTAL
# ==========================================================

@router.patch("/{rental_id}/accept")
def accept_rental(
    rental_id: str,
    current_user=Depends(get_current_user)
):

    return manage_rental_status(
        rental_id=rental_id,
        actor_user_id=current_user.id,
        action="accept"
    )


# ==========================================================
# REJECT RENTAL
# ==========================================================

@router.patch("/{rental_id}/reject")
def reject_rental(
    rental_id: str,
    request: RentalActionRequest,
    current_user=Depends(get_current_user)
):

    return manage_rental_status(
        rental_id=rental_id,
        actor_user_id=current_user.id,
        action="reject",
        reason=request.reason
    )


# ==========================================================
# CANCEL RENTAL
# ==========================================================

@router.patch("/{rental_id}/cancel")
def cancel_rental(
    rental_id: str,
    request: RentalActionRequest,
    current_user=Depends(get_current_user)
):

    return manage_rental_status(
        rental_id=rental_id,
        actor_user_id=current_user.id,
        action="cancel",
        reason=request.reason
    )


# ==========================================================
# START RENTAL
# ==========================================================

@router.patch("/{rental_id}/start")
def start_rental(
    rental_id: str,
    current_user=Depends(get_current_user)
):

    return manage_rental_status(
        rental_id=rental_id,
        actor_user_id=current_user.id,
        action="start"
    )


# ==========================================================
# COMPLETE RENTAL
# ==========================================================

@router.patch("/{rental_id}/complete")
def complete_rental(
    rental_id: str,
    current_user=Depends(get_current_user)
):

    return manage_rental_status(
        rental_id=rental_id,
        actor_user_id=current_user.id,
        action="complete"
    )
