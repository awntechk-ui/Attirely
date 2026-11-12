from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes.auth import router as auth_router
from app.routes.vendor_routes import router as vendor_router
from app.routes.outfits import router as outfits_router
from app.routes.uoutfits import router as uoutfits_router
from app.routes.user_addresses import router as user_addresses_router
from app.routes.cart import router as cart_router
from app.routes.accessory import router as accessories_router
from app.routes.user_profile import router as user_profile_router
from app.routes.vendor_subscription import router as vendor_subscription_router
from app.routes.vendor.vendor_outfits import router as vendor_outfits_router
from app.routes.vendor.vendor_accessories import (
    router as vendor_accessories_router,
)
from app.routes.vendor.vendor_trial_requests import (
    router as vendor_trial_requests_router,
)
from app.routes import location
from app.routes.vendor.vendor_notifications import (
    router as vendor_notifications_router,
)


app = FastAPI(
    title="User Backend",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(auth_router)
app.include_router(vendor_router)
app.include_router(outfits_router)
app.include_router(uoutfits_router)
app.include_router(user_addresses_router)
app.include_router(cart_router)
app.include_router(accessories_router)
app.include_router(user_profile_router)
app.include_router(vendor_subscription_router)
app.include_router(vendor_outfits_router)
app.include_router(vendor_accessories_router)
app.include_router(vendor_trial_requests_router)
app.include_router(location.router)
app.include_router(vendor_notifications_router)

@app.get("/")
def root():
    return {
        "message": "User Backend is running"
    }

@app.get("/health")
def health_check():
    return {
        "status": "healthy"
    }