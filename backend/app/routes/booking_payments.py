from uuid import UUID

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.core.auth_dependency import get_current_user
from app.services.booking_payments import verify_checkout


router = APIRouter(prefix="/payments", tags=["Booking payments"])


class VerifyBookingPayment(BaseModel):
    checkout_id: UUID
    razorpay_payment_id: str = Field(pattern=r"^pay_[a-zA-Z0-9]+$")
    razorpay_signature: str = Field(pattern=r"^[a-f0-9]{64}$")


@router.post("/verify")
def verify_booking_payment(
    payload: VerifyBookingPayment,
    current_user=Depends(get_current_user),
):
    return verify_checkout(
        str(current_user.id),
        str(payload.checkout_id),
        payload.razorpay_payment_id,
        payload.razorpay_signature,
    )
