# server/app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes.cloud import router as cloud_router

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
app.include_router(cloud_router)

@app.get("/api/health")
def health():
    return {"status": "ok"}
