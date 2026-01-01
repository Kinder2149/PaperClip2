# server/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes.cloud import router as cloud_router
from .routes.auth import router as auth_router
from .routes.analytics import router as analytics_router
from .routes.profile import router as profile_router

app = FastAPI(title="PaperClip2 API")

# CORS: restreindre en production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
app.include_router(auth_router)
app.include_router(cloud_router)
app.include_router(analytics_router)
app.include_router(profile_router)

@app.get("/api/health")
def health():
    return {"status": "ok"}
