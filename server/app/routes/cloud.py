# server/app/routes/cloud.py
from fastapi import APIRouter, HTTPException, Header, Depends, Query
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
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

class PartiesListItem(BaseModel):
    # Champs du contrat minimal. Certains proviennent de metadata.
    # Pour éviter toute valeur implicite, les champs non stockés sont null.
    partieId: str
    name: Optional[str] = None
    gameMode: Optional[str] = None
    gameVersion: Optional[str] = None
    remoteVersion: Optional[int] = None
    lastPushAt: Optional[datetime] = None
    lastPullAt: Optional[datetime] = None
    playerId: Optional[str] = None

def _path(partie_id: str) -> str:
    safe = partie_id.replace("/", "_")
    return os.path.join(CLOUD_ROOT, f"{safe}.json")

def _auth(
    authorization: Optional[str] = Header(default=None),
    x_authorization: Optional[str] = Header(default=None),
):
    """
    Authentification hybride:
    - Préférence: JWT via header Authorization: Bearer <jwt> (routes.auth.verify_jwt)
    - Fallback DEV: API_KEY via header X-Authorization: Bearer <API_KEY>
    """
    # 1) JWT si présent
    try:
        from .auth import verify_jwt  # import local pour éviter cycles au démarrage
        if authorization:
            verify_jwt(authorization)
            return True
    except HTTPException:
        raise
    except Exception:
        # Si Authorization présent mais invalide, on renvoie 401
        if authorization:
            raise HTTPException(status_code=401, detail="Invalid Authorization")

    # 2) Fallback API_KEY (DEV)
    if API_KEY:
        if not x_authorization:
            raise HTTPException(status_code=401, detail="Missing Authorization")
        token = x_authorization.replace("Bearer ", "").strip()
        if token != API_KEY:
            raise HTTPException(status_code=403, detail="Invalid token")
        return True

    # 3) Rien fourni
    raise HTTPException(status_code=401, detail="Missing Authorization")

def _safe_read_json(path: str) -> Optional[Dict[str, Any]]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None

@router.put("/{partie_id}")
def put_partie(partie_id: str, payload: CloudSnapshotPayload, _=Depends(_auth)):
    p = _path(partie_id)
    now = datetime.now(timezone.utc).isoformat()
    # Validation stricte des métadonnées requises
    meta = payload.metadata or {}
    def _is_non_empty_str(v):
        return isinstance(v, str) and v.strip() != ""
    required_fields = ["name", "gameMode", "gameVersion", "playerId"]
    missing = [k for k in required_fields if k not in meta or not _is_non_empty_str(meta.get(k))]
    if missing:
        raise HTTPException(status_code=422, detail=f"Missing or empty metadata fields: {', '.join(missing)}")
    # Normalisation minimale
    meta["name"] = meta["name"].strip()
    meta["gameMode"] = meta["gameMode"].strip()
    meta["gameVersion"] = meta["gameVersion"].strip()
    meta["playerId"] = meta["playerId"].strip()
    # Réparation: si un snapshot existe sans playerId, rattacher automatiquement
    if os.path.exists(p):
        try:
            with open(p, "r", encoding="utf-8") as f:
                existing = json.load(f)
            existing_meta = existing.get("metadata", {}) or {}
            if not _is_non_empty_str(existing_meta.get("playerId")):
                existing_meta["playerId"] = meta["playerId"]
                existing["metadata"] = existing_meta
                with open(p, "w", encoding="utf-8") as f:
                    json.dump(existing, f, ensure_ascii=False)
        except Exception:
            # Best-effort: en cas d'erreur de lecture, on continue avec l'écriture normale plus bas
            pass
    data = {
        "partieId": partie_id,
        "snapshot": payload.snapshot,
        "metadata": meta,
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
    now = datetime.now(timezone.utc).isoformat()
    data["lastPullAt"] = now
    with open(p, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)
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
        syncState="unknown",
        remoteVersion=data.get("remoteVersion"),
        lastPushAt=data.get("lastPushAt"),
        lastPullAt=data.get("lastPullAt"),
    )

@router.get("", response_model=List[PartiesListItem])
def list_parties(playerId: str = Query(..., description="Identifiant joueur (Google account or internal player id)"), _=Depends(_auth)):
    """
    Liste toutes les parties cloud pour un playerId.
    - Index strict par playerId (filtre sur metadata.playerId)
    - Aucune mutation ni suppression
    - Retourne aussi les parties cloud-only
    """
    items: List[PartiesListItem] = []
    # Parcours des fichiers JSON dans CLOUD_ROOT
    for filename in os.listdir(CLOUD_ROOT):
        if not filename.endswith(".json"):
            continue
        path = os.path.join(CLOUD_ROOT, filename)
        data = _safe_read_json(path)
        if not data:
            continue
        meta = data.get("metadata", {}) or {}
        if meta.get("playerId") != playerId:
            continue
        partie_id = data.get("partieId") or filename[:-5]
        items.append(
            PartiesListItem(
                partieId=partie_id,
                name=meta.get("name"),
                gameMode=meta.get("gameMode"),
                gameVersion=meta.get("gameVersion"),
                remoteVersion=data.get("remoteVersion"),
                lastPushAt=data.get("lastPushAt"),
                lastPullAt=data.get("lastPullAt"),
                playerId=meta.get("playerId"),
            )
        )
    return items

@router.delete("/{partie_id}")
def delete_partie(partie_id: str, _=Depends(_auth)):
    """
    Supprime définitivement l'entrée cloud pour un partieId.
    - N'affecte pas les backups locaux ni d'autres parties.
    """
    p = _path(partie_id)
    if not os.path.exists(p):
        raise HTTPException(status_code=404, detail="Not found")
    try:
        os.remove(p)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Delete failed: {e}")
    return {"ok": True}
