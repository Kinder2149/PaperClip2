# server/app/routes/analytics.py
from __future__ import annotations

from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel, Field
from typing import Any, Dict, Optional
from datetime import datetime
import os
import json

from .auth import verify_jwt

router = APIRouter(prefix="/api/analytics", tags=["analytics"])

def _analytics_file_path() -> str:
    analytics_dir = os.getenv("ANALYTICS_DATA_DIR", os.path.join(os.getcwd(), "cloud_data", "analytics"))
    os.makedirs(analytics_dir, exist_ok=True)
    return os.path.join(analytics_dir, "events.jsonl")

class AnalyticsEventIn(BaseModel):
    name: str
    properties: Dict[str, Any] = Field(default_factory=dict)
    timestamp: datetime
    player_id: Optional[str] = None
    session_id: Optional[str] = None


def _append_jsonl(path: str, row: Dict[str, Any]) -> None:
    try:
        with open(path, "a", encoding="utf-8") as f:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")
    except Exception:
        # Best-effort: ne pas empêcher la réponse si l'écriture échoue
        pass


@router.post("/events", status_code=status.HTTP_202_ACCEPTED)
def record_event(event: AnalyticsEventIn, authorization: Optional[str] = Header(default=None)):
    # Auth: JWT recommandé; si fourni, lier le player_uid
    user_claims: Optional[Dict[str, Any]] = None
    if authorization:
        try:
            user_claims = verify_jwt(authorization)
        except HTTPException:
            # Si fourni mais invalide -> 401
            raise
        except Exception:
            raise HTTPException(status_code=401, detail="Invalid Authorization")

    record: Dict[str, Any] = {
        "name": event.name,
        "properties": event.properties,
        "timestamp": event.timestamp.isoformat(),
        "received_at": datetime.utcnow().isoformat(),
    }
    if event.player_id:
        record["player_id"] = event.player_id
    if event.session_id:
        record["session_id"] = event.session_id
    if user_claims and isinstance(user_claims, dict):
        record["jwt_player_uid"] = user_claims.get("player_uid")

    path = _analytics_file_path()
    _append_jsonl(path, record)
    # 202 Accepted sans corps
    return None
