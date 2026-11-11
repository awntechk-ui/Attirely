from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.auth_dependency import (
    get_current_user,
    get_current_vendor,
)
from app.core.supabase import supabase_admin


router = APIRouter(
    prefix="/vendor",
    tags=["Vendor"],
)


# ============================================================
# VENDOR PROFILE RESPONSE
# ============================================================

@router.get("/me")
def get_vendor_profile(
    vendor=Depends(get_current_vendor),
):
    return {
        "success": True,
        "vendor": vendor,
    }


# ============================================================
# UPDATE VENDOR PROFILE
# ============================================================

class VendorUpdateRequest(BaseModel):
    full_name: str | None = None

    store_name: str | None = None
    business_description: str | None = None
    owner_type: str | None = None

    phone_number: str | None = None

    address: str | None = None
    city: str | None = None
    state: str | None = None
    pincode: str | None = None

    instagram: str | None = None

    aadhaar: str | None = None
    pan: str | None = None


@router.put("/me")
def update_vendor_profile(
    data: VendorUpdateRequest,
    current_user=Depends(get_current_user),
):
    user_id = str(current_user.id)

    # ========================================================
    # CHECK VENDOR EXISTS
    # ========================================================

    existing = (
        supabase_admin
        .table("vendors")
        .select("id")
        .eq("auth_user_id", user_id)
        .limit(1)
        .execute()
    )

    if not existing.data:
        raise HTTPException(
            status_code=403,
            detail="Vendor profile not found",
        )

    # ========================================================
    # VALIDATE OWNER TYPE
    # ========================================================

    if (
        data.owner_type is not None
        and data.owner_type
        not in ["individual", "store_owner"]
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "owner_type must be "
                "'individual' or 'store_owner'"
            ),
        )

    # ========================================================
    # BUILD UPDATE DATA
    # ========================================================

    update_data = {
        key: value
        for key, value in data.model_dump().items()
        if value is not None
    }

    if not update_data:
        raise HTTPException(
            status_code=400,
            detail="No fields to update",
        )

    # ========================================================
    # UPDATE
    # ========================================================

    response = (
        supabase_admin
        .table("vendors")
        .update(update_data)
        .eq("auth_user_id", user_id)
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=500,
            detail="Failed to update vendor profile",
        )

    return {
        "success": True,
        "message": "Vendor profile updated successfully",
        "vendor": response.data[0],
    }


# ============================================================
# CHECK CURRENT USER'S VENDOR STATUS
# ============================================================

@router.get("/status")
def vendor_status(
    current_user=Depends(get_current_user),
):
    user_id = str(current_user.id)

    response = (
        supabase_admin
        .table("vendors")
        .select("id, store_name, owner_type")
        .eq("auth_user_id", user_id)
        .limit(1)
        .execute()
    )

    if not response.data:
        return {
            "is_vendor": False,
            "vendor": None,
        }

    return {
        "is_vendor": True,
        "vendor": response.data[0],
    }   

# =========================================================
# PERMANENTLY DELETE VENDOR ACCOUNT
# =========================================================

@router.delete("/account")
def permanently_delete_vendor_account(
    current_user=Depends(get_current_user),
    vendor: dict = Depends(get_current_vendor),
):
    auth_user_id = str(current_user.id)
    vendor_id = str(vendor.get("id") or "")

    # ========================================================
    # VERIFY VENDOR OWNERSHIP
    # ========================================================

    if (
        not vendor_id
        or str(vendor.get("auth_user_id")) != auth_user_id
    ):
        raise HTTPException(
            status_code=403,
            detail="Vendor account ownership could not be verified.",
        )

    try:
        # ====================================================
        # STEP 1: TRANSACTIONAL DATABASE CLEANUP
        # ====================================================

        supabase_admin.rpc(
            "prepare_vendor_account_deletion",
            {
                "p_auth_user_id": auth_user_id,
                "p_vendor_id": vendor_id,
            },
        ).execute()

        # ====================================================
        # STEP 2: FETCH DELETION JOB
        # ====================================================

        job_response = (
            supabase_admin
            .table("vendor_account_deletion_jobs")
            .select("*")
            .eq("auth_user_id", auth_user_id)
            .execute()
        )

        jobs = job_response.data or []

        if not jobs:
            raise Exception(
                "Vendor deletion job could not be retrieved."
            )

        job = jobs[0]

        outfit_paths = job.get("outfit_storage_paths") or []
        accessory_paths = job.get("accessory_storage_paths") or []

        # ====================================================
        # STEP 3: VERIFY STORAGE PATH OWNERSHIP
        # ====================================================

        all_paths = outfit_paths + accessory_paths

        if any(
            not isinstance(path, str)
            or not path.startswith(f"{auth_user_id}/")
            for path in all_paths
        ):
            raise Exception(
                "Storage path ownership verification failed."
            )

        # ====================================================
        # STEP 4: DELETE OUTFIT IMAGES IN BATCHES
        # ====================================================

        if outfit_paths:
            unique_outfit_paths = list(set(outfit_paths))

            for i in range(0, len(unique_outfit_paths), 1000):
                batch = unique_outfit_paths[i:i + 1000]

                supabase_admin.storage.from_(
                    "outfit-images"
                ).remove(batch)

        # ====================================================
        # STEP 5: DELETE ACCESSORY IMAGES IN BATCHES
        # ====================================================

        if accessory_paths:
            unique_accessory_paths = list(set(accessory_paths))

            for i in range(0, len(unique_accessory_paths), 1000):
                batch = unique_accessory_paths[i:i + 1000]

                supabase_admin.storage.from_(
                    "accessory-images"
                ).remove(batch)

        # ====================================================
        # STEP 6: MARK STORAGE CLEANUP COMPLETE
        # ====================================================

        (
            supabase_admin
            .table("vendor_account_deletion_jobs")
            .update({
                "status": "storage_cleaned",
                "last_error": None,
            })
            .eq("auth_user_id", auth_user_id)
            .execute()
        )

        # ====================================================
        # STEP 7: DELETE SUPABASE AUTH USER
        # ====================================================

        supabase_admin.auth.admin.delete_user(auth_user_id)

        # ====================================================
        # STEP 8: MARK DELETION JOB COMPLETED
        # ====================================================

        try:
            (
                supabase_admin
                .table("vendor_account_deletion_jobs")
                .update({
                    "status": "completed",
                    "last_error": None,
                })
                .eq("auth_user_id", auth_user_id)
                .execute()
            )

        except Exception as status_error:
            print(
                "VENDOR DELETION FINAL STATUS UPDATE ERROR:",
                repr(status_error),
            )

        # ====================================================
        # SUCCESS RESPONSE
        # ====================================================

        return {
            "success": True,
            "message": "Vendor account permanently deleted.",
            "archived_trial_requests": job.get(
                "archived_trial_requests", 0
            ),
            "deleted_outfits": job.get(
                "deleted_outfits", 0
            ),
            "deleted_accessories": job.get(
                "deleted_accessories", 0
            ),
        }

    except HTTPException:
        raise

    except Exception as exc:

        print(
            "PERMANENT VENDOR ACCOUNT DELETION ERROR:",
            repr(exc),
        )

        # ====================================================
        # PRESERVE DELETION JOB FOR RECOVERY
        # ====================================================

        try:
            (
                supabase_admin
                .table("vendor_account_deletion_jobs")
                .update({
                    "last_error": str(exc)[:1000],
                })
                .eq("auth_user_id", auth_user_id)
                .execute()
            )

        except Exception as job_error:
            print(
                "VENDOR DELETION JOB UPDATE ERROR:",
                repr(job_error),
            )

        raise HTTPException(
            status_code=500,
            detail=(
                "Account deletion could not be completed. "
                "Your deletion progress has been retained "
                "where possible. Please contact support "
                "if the issue continues."
            ),
        )
