# server/app/routes/auth.py
from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime, timedelta, timezone
import os
import jwt

router = APIRouter(prefix="/api/auth", tags=["auth"])

SECRET_KEY = os.getenv("SECRET_KEY", "change-this-secret")
ALGORITHM = "HS256"
TOKEN_TTL_SECONDS = int(os.getenv("JWT_TTL_SECONDS", "3600"))

class LoginRequest(BaseModel):
    playerId: str

class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_at: datetime

@router.post("/login", response_model=LoginResponse)
def login(req: LoginRequest):
    player_id = (req.playerId or "").strip()
    if not player_id:
        raise HTTPException(status_code=400, detail="playerId required")
    now = datetime.now(timezone.utc)
    exp = now + timedelta(seconds=TOKEN_TTL_SECONDS)
    payload: Dict[str, Any] = {
        "sub": player_id,
        "playerId": player_id,
        "iat": int(now.timestamp()),
        "exp": int(exp.timestamp()),
    }
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
        return claims
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
