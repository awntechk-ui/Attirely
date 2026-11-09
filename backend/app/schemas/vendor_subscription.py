
from pydantic import BaseModel, Field


class VendorPlanSelectionRequest(BaseModel):
    plan_code: str = Field(
        ...,
        min_length=3,
        max_length=30,
        examples=["starter"],
    )
