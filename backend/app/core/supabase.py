from supabase import create_client, Client

from app.core.config import (
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
)

if not SUPABASE_URL:
    raise RuntimeError("SUPABASE_URL is missing")

if not SUPABASE_SERVICE_ROLE_KEY:
    raise RuntimeError("SUPABASE_SERVICE_ROLE_KEY is missing")


# ============================================================
# ADMIN CLIENT
# ============================================================
# Used ONLY for backend database + storage operations.
#
# This client must NEVER be used for sign_in_with_password()
# because authentication can change the client's session.
# ============================================================

supabase_admin: Client = create_client(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
)


# ============================================================
# AUTH CLIENT
# ============================================================
# Separate client for Supabase authentication.
#
# Its session state cannot affect supabase_admin.
# ============================================================

supabase_auth: Client = create_client(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
)

# from supabase import create_client, Client

# from app.core.config import (
#     SUPABASE_URL,
#     SUPABASE_SERVICE_ROLE_KEY,
# )

# if not SUPABASE_URL:
#     raise RuntimeError("SUPABASE_URL is missing")

# if not SUPABASE_SERVICE_ROLE_KEY:
#     raise RuntimeError("SUPABASE_SERVICE_ROLE_KEY is missing")

# supabase: Client = create_client(
#     SUPABASE_URL,
#     SUPABASE_SERVICE_ROLE_KEY,
# )
