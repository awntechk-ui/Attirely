from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.supabase import (
    supabase_admin,
    supabase_auth,
)

security = HTTPBearer()


# ============================================================
# GET CURRENT AUTH USER
# ============================================================

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    access_token = credentials.credentials

    try:
        response = supabase_auth.auth.get_user(access_token)

        if response.user is None:
            raise HTTPException(
                status_code=401,
                detail="Invalid or expired access token",
            )

        return response.user

    except HTTPException:
        raise

    except Exception:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired access token",
        )


# ============================================================
# GET CURRENT VENDOR
# ============================================================

def get_current_vendor(
    current_user=Depends(get_current_user),
):
    try:
        user_id = str(current_user.id)

        response = (
            supabase_admin
            .table("vendors")
            .select("*")
            .eq("auth_user_id", user_id)
            .limit(1)
            .execute()
        )

        if not response.data:
            raise HTTPException(
                status_code=403,
                detail="Vendor profile not found",
            )

        return response.data[0]

    except HTTPException:
        raise

    except Exception as e:
        print(
            "VENDOR PROFILE ERROR:",
            repr(e),
        )

        raise HTTPException(
            status_code=500,
            detail="Failed to fetch vendor profile",
        )