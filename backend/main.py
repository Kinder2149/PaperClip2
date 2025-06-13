import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.db.database import engine, Base
from app.routes import auth, users, storage, analytics, config, social, user_saves

# Création des tables dans la base de données
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="PaperClip2 Backend API",
    description="API de remplacement pour Firebase pour l'application PaperClip2",
    version="1.0.0"
)

# Configuration CORS pour permettre les requêtes depuis l'application Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, spécifier les domaines exacts
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inclusion des routes
app.include_router(auth.router, prefix="/api", tags=["Authentication"])
app.include_router(users.router, prefix="/api", tags=["Users"])
app.include_router(storage.router, prefix="/api", tags=["Storage"])
app.include_router(analytics.router, prefix="/api", tags=["Analytics"])
app.include_router(config.router, prefix="/api", tags=["Remote Config"])
app.include_router(social.router, prefix="/api", tags=["Social"])
app.include_router(user_saves.router, prefix="/api", tags=["User Profile"])

@app.get("/", tags=["Root"])
async def root():
    return {"message": "Bienvenue sur l'API PaperClip2"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
