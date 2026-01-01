# server/app/routes/profile.py
from __future__ import annotations

from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel, Field, ValidationError
from typing import Any, Dict, Optional
from datetime import datetime
import os
import json

from .auth import verify_jwt

router = APIRouter(prefix="/api/profile", tags=["profile"])

PROFILE_DIR = os.getenv("PROFILE_DATA_DIR", os.path.join(os.getcwd(), "cloud_data", "profiles"))
os.makedirs(PROFILE_DIR, exist_ok=True)

class UserProfileState(BaseModel):
    money: float
    paperclips: float
    metal: float
    sell_price: float
    upgrades: Dict[str, int] = Field(default_factory=dict)
    market: Optional[Dict[str, Any]] = None
    stats: Optional[Dict[str, Any]] = None
    updated_at: datetime


def _path(player_uid: str) -> str:
    safe = player_uid.replace("/", "_")
    return os.path.join(PROFILE_DIR, f"{safe}.json")


def _safe_read(path: str) -> Optional[Dict[str, Any]]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def _safe_write(path: str, payload: Dict[str, Any]) -> None:
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, default=str)
    os.replace(tmp, path)


@router.get("/state", response_model=UserProfileState)
def get_state(authorization: Optional[str] = Header(default=None, alias="Authorization")):
    claims = verify_jwt(authorization)
    player_uid = claims["player_uid"]
    p = _path(player_uid)
    data = _safe_read(p)
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No state")
    try:
        return UserProfileState(**data)
    except ValidationError as e:
        raise HTTPException(status_code=422, detail=str(e))


@router.put("/state", status_code=status.HTTP_204_NO_CONTENT)
def put_state(state: UserProfileState, authorization: Optional[str] = Header(default=None, alias="Authorization")):
    claims = verify_jwt(authorization)
    player_uid = claims["player_uid"]
    p = _path(player_uid)
    # Écrire l'état tel quel (snake_case), cloud-first minimal
    _safe_write(p, state.dict())
    return None
