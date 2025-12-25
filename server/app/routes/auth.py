# server/app/routes/auth.py
from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta, timezone
import os
import jwt
import uuid

router = APIRouter(prefix="/api/auth", tags=["auth"])

ALGORITHM = "HS256"
TOKEN_TTL_SECONDS = int(os.getenv("JWT_TTL_SECONDS", "3600"))

def _get_secret() -> str:
    return os.getenv("SECRET_KEY", "change-this-secret")

class LoginRequest(BaseModel):
    # Schéma strict Option A (clean): provider requis, aucun champ legacy
    provider: Optional[str] = None  # ex: "google"
    provider_user_id: Optional[str] = None  # ex: identifiant côté provider

class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_at: datetime

@router.post("/login", response_model=LoginResponse)
def login(req: LoginRequest):
    # Entrées strictes: pas de compat legacy
    provider = (req.provider or "").strip().lower()
    provider_user_id = (req.provider_user_id or "").strip()

    if not provider or not provider_user_id:
        raise HTTPException(status_code=400, detail="provider and provider_user_id are required")

    # Résoudre ou créer un player_uid souverain
    try:
        from ..services.identity import resolve_or_create_player_uid, list_provider_links
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"identity service unavailable: {e}")

    player_uid = resolve_or_create_player_uid(provider=provider, provider_user_id=provider_user_id)

    # Préparer le JWT (sub = player_uid)
    now = datetime.now(timezone.utc)
    exp = now + timedelta(seconds=TOKEN_TTL_SECONDS)
    providers: List[Dict[str, Any]] = list_provider_links(player_uid)
    payload: Dict[str, Any] = {
        "sub": player_uid,
        "providers": providers,
        "iat": int(now.timestamp()),
        "exp": int(exp.timestamp()),
    }

    token = jwt.encode(payload, _get_secret(), algorithm=ALGORITHM)
    return LoginResponse(access_token=token, expires_at=exp)


def verify_jwt(authorization: Optional[str]) -> Dict[str, Any]:
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization")
    if not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Invalid Authorization scheme")
    token = authorization.split(" ", 1)[1].strip()
    try:
        claims = jwt.decode(token, _get_secret(), algorithms=[ALGORITHM])
        # Option A: exiger sub = player_uid (UUID v4) sans compat legacy
        sub = claims.get("sub")
        try:
            if not sub:
                raise ValueError("missing sub")
            _ = uuid.UUID(str(sub), version=4)
        except Exception:
            raise HTTPException(status_code=401, detail="Invalid token: subject is not a valid player_uid")
        # Exposer explicitement player_uid pour les consommateurs
        claims["player_uid"] = str(sub)
        return claims
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
