from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes.auth import router as auth_router
from app.routes.vendor import router as vendor_router
from app.routes.outfits import router as outfits_router
from app.routes.uoutfits import router as uoutfits_router
from app.routes.user_addresses import router as user_addresses_router
from app.routes.cart import router as cart_router

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
