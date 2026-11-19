
from uuid import UUID

from pydantic import BaseModel, Field


class VendorPlanSelectionRequest(BaseModel):
    plan_code: str = Field(
        ...,
        min_length=3,
        max_length=30,
        examples=["starter"],
    )


class VerifyVendorPlanPayment(BaseModel):
    checkout_id: UUID
    razorpay_payment_id: str = Field(pattern=r"^pay_[a-zA-Z0-9]+$")
    razorpay_signature: str = Field(pattern=r"^[a-f0-9]{64}$")
