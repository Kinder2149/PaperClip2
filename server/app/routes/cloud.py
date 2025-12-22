# server/app/routes/cloud.py
from fastapi import APIRouter, HTTPException, Header, Depends
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime, timezone
import os
import json
import hashlib

CLOUD_ROOT = os.getenv("CLOUD_STORAGE_DIR", "cloud_data")
API_KEY = os.getenv("API_KEY")  # Optionnel: simple protection par token

os.makedirs(CLOUD_ROOT, exist_ok=True)

router = APIRouter(prefix="/api/cloud/parties", tags=["cloud"]) 

class CloudSnapshotPayload(BaseModel):
    snapshot: Dict[str, Any] = Field(default_factory=dict)
    metadata: Dict[str, Any] = Field(default_factory=dict)

class CloudStatusResponse(BaseModel):
    partieId: str
    syncState: str = "unknown"  # in_sync | ahead_local | ahead_remote | diverged | unknown
    remoteVersion: Optional[int] = None
    lastPushAt: Optional[datetime] = None
    lastPullAt: Optional[datetime] = None

def _path(partie_id: str) -> str:
    safe = partie_id.replace("/", "_")
    return os.path.join(CLOUD_ROOT, f"{safe}.json")

def _auth(x_authorization: Optional[str] = Header(default=None)):
    if API_KEY:
        if not x_authorization:
            raise HTTPException(status_code=401, detail="Missing Authorization")
        token = x_authorization.replace("Bearer ", "").strip()
        if token != API_KEY:
            raise HTTPException(status_code=403, detail="Invalid token")
    return True

@router.put("/{partie_id}")
def put_partie(partie_id: str, payload: CloudSnapshotPayload, _=Depends(_auth)):
    p = _path(partie_id)
    now = datetime.now(timezone.utc).isoformat()
    data = {
        "partieId": partie_id,
        "snapshot": payload.snapshot,
        "metadata": payload.metadata,
        "remoteVersion": int(datetime.now(timezone.utc).timestamp()),
        "lastPushAt": now,
        "lastPullAt": None,
        "hash": hashlib.sha256(json.dumps(payload.snapshot, sort_keys=True).encode("utf-8")).hexdigest(),
    }
    with open(p, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)
    return {"ok": True}

@router.get("/{partie_id}")
def get_partie(partie_id: str, _=Depends(_auth)):
    p = _path(partie_id)
    if not os.path.exists(p):
        raise HTTPException(status_code=404, detail="Not found")
    with open(p, "r", encoding="utf-8") as f:
        data = json.load(f)
    return {"snapshot": data.get("snapshot", {}), "metadata": data.get("metadata", {})}

@router.get("/{partie_id}/status", response_model=CloudStatusResponse)
def get_status(partie_id: str, _=Depends(_auth)):
    p = _path(partie_id)
    if not os.path.exists(p):
        raise HTTPException(status_code=404, detail="Not found")
    with open(p, "r", encoding="utf-8") as f:
        data = json.load(f)
    return CloudStatusResponse(
        partieId=partie_id,
        syncState="in_sync",
        remoteVersion=data.get("remoteVersion"),
        lastPushAt=data.get("lastPushAt"),
        lastPullAt=data.get("lastPullAt"),
    )
