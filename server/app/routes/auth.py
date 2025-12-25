# server/app/routes/auth.py
from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta, timezone
import os
import jwt
import uuid

router = APIRouter(prefix="/api/auth", tags=["auth"])

SECRET_KEY = os.getenv("SECRET_KEY", "change-this-secret")
ALGORITHM = "HS256"
TOKEN_TTL_SECONDS = int(os.getenv("JWT_TTL_SECONDS", "3600"))

class LoginRequest(BaseModel):
    # Nouveau schéma
    provider: Optional[str] = None  # ex: "google"
    provider_user_id: Optional[str] = None  # ex: Google playerId
    # Compat héritée
    playerId: Optional[str] = None

class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_at: datetime

@router.post("/login", response_model=LoginResponse)
def login(req: LoginRequest):
    # Normalisation des entrées (compat héritée playerId)
    provider = (req.provider or "").strip().lower()
    provider_user_id = (req.provider_user_id or "").strip()
    legacy_player_id = (req.playerId or "").strip()

    if not provider and legacy_player_id:
        provider = "google"
    if not provider_user_id and legacy_player_id:
        provider_user_id = legacy_player_id

    if not provider or not provider_user_id:
        raise HTTPException(status_code=400, detail="provider and provider_user_id (or legacy playerId) required")

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
    # Compat: inclure legacy_playerId si présent (métadonnée non contractuelle)
    if legacy_player_id:
        payload["legacy_playerId"] = legacy_player_id

    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return LoginResponse(access_token=token, expires_at=exp)


def verify_jwt(authorization: Optional[str]) -> Dict[str, Any]:
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization")
    if not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Invalid Authorization scheme")
    token = authorization.split(" ", 1)[1].strip()
    try:
        claims = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        # Normalisation identité: accepter anciens tokens (sub=playerId)
        sub = claims.get("sub")
        # Si sub est un UUID v4 valide, on retourne directement
        try:
            if sub:
                _ = uuid.UUID(str(sub), version=4)
                return claims
        except Exception:
            pass

        # Compat: tenter de résoudre via provider par défaut 'google'
        provider_user_id = claims.get("playerId") or sub
        if not provider_user_id:
            raise HTTPException(status_code=401, detail="Invalid token: missing subject")
        try:
            from ..services.identity import resolve_or_create_player_uid
            player_uid = resolve_or_create_player_uid(provider="google", provider_user_id=str(provider_user_id))
            # On n'altère pas sub dans le token, mais on expose un champ normalisé
            claims["player_uid"] = player_uid
            return claims
        except Exception as e:
            raise HTTPException(status_code=401, detail=f"Identity resolution failed: {e}")
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
