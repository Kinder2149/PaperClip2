# server/app/routes/cloud.py
from fastapi import APIRouter, HTTPException, Header, Depends, Query, Response
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime, timezone
import os
import json
import hashlib

CLOUD_ROOT = os.getenv("CLOUD_STORAGE_DIR", "cloud_data")

os.makedirs(CLOUD_ROOT, exist_ok=True)

router = APIRouter(prefix="/api/cloud/parties", tags=["cloud"]) 

# Garde-fous configurables
MAX_SNAPSHOT_BYTES = int(os.getenv("MAX_SNAPSHOT_BYTES", str(256 * 1024)))  # 256 KiB par défaut
# Enum fermée optionnelle pour gameMode, via env "GAME_MODE_ENUM" = "classic,zen"; si vide => pas de contrainte
GAME_MODE_ENUM = [m.strip() for m in os.getenv("GAME_MODE_ENUM", "").split(",") if m.strip()]
# Version de schéma attendue pour les snapshots
CURRENT_SNAPSHOT_SCHEMA_VERSION = int(os.getenv("SNAPSHOT_SCHEMA_VERSION", "1"))
# Concurrence: activation de l'écriture conditionnelle (évaluée dynamiquement)
def _require_conditional_writes() -> bool:
    return os.getenv("REQUIRE_CONDITIONAL_WRITES", "0").lower() in ("1", "true", "yes")

class CloudSnapshotPayload(BaseModel):
    snapshot: Dict[str, Any] = Field(default_factory=dict)
    metadata: Dict[str, Any] = Field(default_factory=dict)

class CloudStatusResponse(BaseModel):
    partieId: str
    syncState: str = "unknown"  # in_sync | ahead_local | ahead_remote | diverged | unknown
    remoteVersion: Optional[int] = None
    lastPushAt: Optional[datetime] = None
    lastPullAt: Optional[datetime] = None
    etag: Optional[str] = None

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
    Authentification JWT uniquement:
    - JWT via header Authorization: Bearer <jwt> (routes.auth.verify_jwt)
    """
    # 1) JWT si présent
    try:
        from .auth import verify_jwt  # import local pour éviter cycles au démarrage
        if authorization:
            claims = verify_jwt(authorization)
            return claims  # retourner les claims pour vérification d'ownership
    except HTTPException:
        raise
    except Exception:
        # Si Authorization présent mais invalide, on renvoie 401
        if authorization:
            raise HTTPException(status_code=401, detail="Invalid Authorization")
    # Rien fourni
    raise HTTPException(status_code=401, detail="Missing Authorization")

def _safe_read_json(path: str) -> Optional[Dict[str, Any]]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None

@router.put("/{partie_id}")
def put_partie(
    partie_id: str,
    payload: CloudSnapshotPayload,
    auth_ctx=Depends(_auth),
    response: Response = None,
    if_match: Optional[str] = Header(default=None, alias="If-Match"),
    if_none_match: Optional[str] = Header(default=None, alias="If-None-Match"),
):
    p = _path(partie_id)
    now = datetime.now(timezone.utc).isoformat()
    # JWT obligatoire pour toute écriture (pas de fallback API_KEY)
    if not isinstance(auth_ctx, dict):
        raise HTTPException(status_code=401, detail="JWT required for write operations")
    # Validation stricte des métadonnées requises
    meta = payload.metadata or {}
    def _is_non_empty_str(v):
        return isinstance(v, str) and v.strip() != ""
    required_fields = ["name", "gameMode", "gameVersion", "playerId"]
    missing = [k for k in required_fields if k not in meta or not _is_non_empty_str(meta.get(k))]
    if missing:
        raise HTTPException(status_code=422, detail=f"Missing or empty metadata fields: {', '.join(missing)}")
    # Taille snapshot maximale
    try:
        snapshot_bytes = len(json.dumps(payload.snapshot, sort_keys=True).encode("utf-8"))
    except Exception:
        snapshot_bytes = 0
    if snapshot_bytes > MAX_SNAPSHOT_BYTES:
        raise HTTPException(status_code=413, detail="Snapshot too large")
    # Version de schéma obligatoire et bornée
    raw_version = (payload.snapshot or {}).get("snapshotSchemaVersion", None)
    if raw_version is None:
        raise HTTPException(status_code=422, detail="Missing snapshotSchemaVersion in snapshot")
    try:
        version = int(raw_version)
    except Exception:
        raise HTTPException(status_code=422, detail="snapshotSchemaVersion must be an integer")
    if version > CURRENT_SNAPSHOT_SCHEMA_VERSION:
        raise HTTPException(status_code=422, detail="Snapshot schema version is newer than server supports")
    # Normalisation minimale
    meta["name"] = meta["name"].strip()
    meta["gameMode"] = meta["gameMode"].strip()
    meta["gameVersion"] = meta["gameVersion"].strip()
    meta["playerId"] = meta["playerId"].strip()
    # Enums fermées optionnelles
    if GAME_MODE_ENUM and meta["gameMode"] not in GAME_MODE_ENUM:
        raise HTTPException(status_code=422, detail=f"Invalid gameMode: {meta['gameMode']}")
    # Longueurs raisonnables
    if len(meta["name"]) > 100 or len(meta["gameMode"]) > 50 or len(meta["gameVersion"]) > 20:
        raise HTTPException(status_code=422, detail="Metadata fields too long")

    # Vérification d'ownership via JWT
    requester_uid: Optional[str] = auth_ctx.get("player_uid") or auth_ctx.get("sub")

    # Gestion ownership sans compat legacy: pas de revendication via Google playerId
    exists = os.path.exists(p)
    if exists:
        try:
            with open(p, "r", encoding="utf-8") as f:
                existing = json.load(f)
            existing_meta = existing.get("metadata", {}) or {}
            existing_owner = existing.get("owner_uid")
            existing_hash = existing.get("hash")
            # Ownership: si owner_uid présent et JWT dispo, vérifier possession
            if requester_uid and existing_owner and existing_owner != requester_uid:
                raise HTTPException(status_code=403, detail="Forbidden: not the owner of this partie")
            # Si owner_uid manquant et JWT dispo, lier explicitement à ce requester (greenfield)
            if requester_uid and not existing_owner:
                existing["owner_uid"] = requester_uid
                with open(p, "w", encoding="utf-8") as f:
                    json.dump(existing, f, ensure_ascii=False)
        except HTTPException:
            # Ne pas avaler les erreurs d'ownership explicites
            raise
        except HTTPException:
            raise
        except Exception:
            # Best-effort: en cas d'erreur de lecture, on continue avec l'écriture normale plus bas
            pass
    # Concurrence: contrôle conditionnel via If-Match/If-None-Match
    if exists:
        # Si enforcé globalement ou si le client fournit If-Match, on exige la correspondance avec le hash courant
        try:
            with open(p, "r", encoding="utf-8") as f:
                prev_for_etag = json.load(f)
            current_etag = prev_for_etag.get("hash")
        except Exception:
            current_etag = None
        enforce = _require_conditional_writes() or (if_match is not None)
        if enforce:
            # Exiger If-Match si fichier existe
            if not if_match:
                raise HTTPException(status_code=428, detail="Precondition Required: If-Match header is required")
            # L'entête peut être quoté
            normalized = if_match.strip().strip('"')
            current_norm = (current_etag or "").strip().strip('"')
            if not current_norm or normalized != current_norm:
                raise HTTPException(status_code=412, detail="Precondition Failed: ETag does not match")
    else:
        # Création: si enforcé globalement ou si If-None-Match fourni, exiger If-None-Match: *
        enforce = _require_conditional_writes() or (if_none_match is not None)
        if enforce and (if_none_match or "") != "*":
            raise HTTPException(status_code=428, detail="Precondition Required: If-None-Match: * required for creation")
        # Création: associer strictement partie_id -> requester_uid (sans validation par provider)

    # À l'écriture, si fichier existe et ownership ne correspond pas, refuser
    if exists:
        try:
            with open(p, "r", encoding="utf-8") as f:
                prev = json.load(f)
            prev_owner = prev.get("owner_uid")
            if prev_owner and prev_owner != requester_uid:
                raise HTTPException(status_code=403, detail="Forbidden: not the owner of this partie")
        except HTTPException:
            raise
        except Exception:
            # si lecture échoue, on laisse la suite gérer (écriture atomique)
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
    # Définir owner_uid lors de la création
    if not os.path.exists(p):
        data["owner_uid"] = requester_uid
    with open(p, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)
    # Exposer ETag / X-Remote-Version
    try:
        if response is not None:
            response.headers["ETag"] = data.get("hash", "")
            response.headers["X-Remote-Version"] = str(data.get("remoteVersion", ""))
            # Header alternatif non-strip par certains proxies
            response.headers["X-Entity-Tag"] = data.get("hash", "")
    except Exception:
        pass
    return {"ok": True}

@router.get("/{partie_id}")
def get_partie(partie_id: str, _=Depends(_auth), response: Response = None):
    p = _path(partie_id)
    if not os.path.exists(p):
        raise HTTPException(status_code=404, detail="Not found")
    with open(p, "r", encoding="utf-8") as f:
        data = json.load(f)
    now = datetime.now(timezone.utc).isoformat()
    data["lastPullAt"] = now
    with open(p, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)
    # ETag/X-Remote-Version
    try:
        if response is not None:
            response.headers["ETag"] = data.get("hash", "")
            response.headers["X-Remote-Version"] = str(data.get("remoteVersion", ""))
            response.headers["X-Entity-Tag"] = data.get("hash", "")
    except Exception:
        pass
    return {"snapshot": data.get("snapshot", {}), "metadata": data.get("metadata", {})}

@router.get("/{partie_id}/status", response_model=CloudStatusResponse)
def get_status(partie_id: str, _=Depends(_auth), response: Response = None):
    p = _path(partie_id)
    if not os.path.exists(p):
        raise HTTPException(status_code=404, detail="Not found")
    with open(p, "r", encoding="utf-8") as f:
        data = json.load(f)
    try:
        if response is not None:
            response.headers["ETag"] = data.get("hash", "")
            response.headers["X-Remote-Version"] = str(data.get("remoteVersion", ""))
            response.headers["X-Entity-Tag"] = data.get("hash", "")
    except Exception:
        pass
    return CloudStatusResponse(
        partieId=partie_id,
        syncState="unknown",
        remoteVersion=data.get("remoteVersion"),
        lastPushAt=data.get("lastPushAt"),
        lastPullAt=data.get("lastPullAt"),
        etag=data.get("hash"),
    )

@router.get("", response_model=List[PartiesListItem])
def list_parties(playerId: str = Query(..., description="Identifiant joueur (Google account or internal player id)"), auth_ctx=Depends(_auth)):
    """
    Liste toutes les parties cloud pour un playerId.
    - Index strict par playerId (filtre sur metadata.playerId)
    - Aucune mutation ni suppression
    - Retourne aussi les parties cloud-only
    """
    items: List[PartiesListItem] = []
    # Pour la consultation d'index, la visibilité est basée sur playerId uniquement.
    # L'ownership (owner_uid) est contrôlé strictement sur PUT/DELETE.
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
        # Ne pas filtrer par owner_uid ici, pour permettre l'accès aux parties du même playerId
        # sur plusieurs appareils/sessions.
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
def delete_partie(partie_id: str, auth_ctx=Depends(_auth)):
    """
    Supprime définitivement l'entrée cloud pour un partieId.
    - N'affecte pas les backups locaux ni d'autres parties.
    """
    p = _path(partie_id)
    if not os.path.exists(p):
        raise HTTPException(status_code=404, detail="Not found")
    # JWT obligatoire pour suppression (pas de fallback API_KEY)
    if not isinstance(auth_ctx, dict):
        raise HTTPException(status_code=401, detail="JWT required for delete operations")
    requester_uid = auth_ctx.get("player_uid") or auth_ctx.get("sub")
    try:
        with open(p, "r", encoding="utf-8") as f:
            data = json.load(f)
        owner = data.get("owner_uid")
        if owner and owner != requester_uid:
            raise HTTPException(status_code=403, detail="Forbidden: not the owner of this partie")
    except HTTPException:
        raise
    except Exception:
        pass
    try:
        os.remove(p)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Delete failed: {e}")
    return {"ok": True}
