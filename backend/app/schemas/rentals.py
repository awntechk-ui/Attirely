
from datetime import date
from typing import Any, Dict, List
from uuid import UUID

from pydantic import BaseModel, Field


# ==========================================================
# RENTAL ITEM REQUEST
# ==========================================================

class RentalItemRequest(BaseModel):
    outfit_id: UUID
    selected_size: str = Field(min_length=1, max_length=50)
    rental_start_date: date
    rental_days: int = Field(gt=0, le=365)


# ==========================================================
# RENTAL CHECKOUT REQUEST
# ==========================================================

class RentalCheckoutRequest(BaseModel):
    items: List[RentalItemRequest] = Field(
        min_length=1,
        max_length=20
    )
    payment_method: str = Field(
        default="demo",
        min_length=1,
        max_length=50
    )
    delivery_address: Dict[str, Any]


# ==========================================================
# RENTAL CHECKOUT RESPONSE
# ==========================================================

class RentalCheckoutResponse(BaseModel):
    success: bool
    partial_success: bool

    booking_reference: UUID
    transaction_reference: str

    total_outfits: int
    successful_count: int
    failed_count: int

    rental_ids: List[UUID]

    successful_items: List[dict]
    failed_items: List[dict]

    message: str


# ==========================================================
# CHECK AVAILABILITY
# ==========================================================

class RentalAvailabilityRequest(BaseModel):
    items: List[RentalItemRequest] = Field(
        min_length=1,
        max_length=20
    )


class RentalAvailabilityItem(BaseModel):
    outfit_id: UUID
    selected_size: str
    rental_start_date: date
    rental_return_date: date
    rental_days: int
    available: bool
    message: str


class RentalAvailabilityResponse(BaseModel):
    all_available: bool
    items: List[RentalAvailabilityItem]


# ==========================================================
# RENTAL ACTION REQUEST
# ==========================================================

class RentalActionRequest(BaseModel):
    reason: str = Field(
        min_length=3,
        max_length=500
    )
