from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.supabase import supabase


security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    access_token = credentials.credentials

    try:
        response = supabase.auth.get_user(access_token)

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