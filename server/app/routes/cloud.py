# server/app/routes/cloud.py
from fastapi import APIRouter, HTTPException, Header, Depends, Query, Response
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

# Garde-fous configurables
MAX_SNAPSHOT_BYTES = int(os.getenv("MAX_SNAPSHOT_BYTES", str(256 * 1024)))  # 256 KiB par défaut
# Enum fermée optionnelle pour gameMode, via env "GAME_MODE_ENUM" = "classic,zen"; si vide => pas de contrainte
GAME_MODE_ENUM = [m.strip() for m in os.getenv("GAME_MODE_ENUM", "").split(",") if m.strip()]
# Version de schéma attendue pour les snapshots
CURRENT_SNAPSHOT_SCHEMA_VERSION = int(os.getenv("SNAPSHOT_SCHEMA_VERSION", "1"))
# Concurrence: activation de l'écriture conditionnelle
REQUIRE_CONDITIONAL_WRITES = os.getenv("REQUIRE_CONDITIONAL_WRITES", "0").lower() in ("1", "true", "yes")

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
            claims = verify_jwt(authorization)
            return claims  # retourner les claims pour vérification d'ownership
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
        return True  # mode DEV: pas de claims JWT disponibles

    # 3) Rien fourni
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

    # Vérification d'ownership via JWT si disponible
    requester_uid: Optional[str] = None
    if isinstance(auth_ctx, dict):
        requester_uid = auth_ctx.get("player_uid") or auth_ctx.get("sub")

    # Réparation: si un snapshot existe sans playerId, rattacher automatiquement
    exists = os.path.exists(p)
    if exists:
        try:
            with open(p, "r", encoding="utf-8") as f:
                existing = json.load(f)
            existing_meta = existing.get("metadata", {}) or {}
            existing_owner = existing.get("owner_uid")
            existing_hash = existing.get("hash")
            if not _is_non_empty_str(existing_meta.get("playerId")):
                existing_meta["playerId"] = meta["playerId"]
                existing["metadata"] = existing_meta
                with open(p, "w", encoding="utf-8") as f:
                    json.dump(existing, f, ensure_ascii=False)
            # Ownership: si owner_uid présent et JWT dispo, vérifier possession
            if requester_uid and existing_owner and existing_owner != requester_uid:
                raise HTTPException(status_code=403, detail="Forbidden: not the owner of this partie")
            # Si owner_uid manquant et JWT dispo, tenter revendication sécurisée si playerId → requester_uid
            if requester_uid and not existing_owner:
                try:
                    from ..services.identity import resolve_existing_player_uid
                    mapped_uid = resolve_existing_player_uid(provider="google", provider_user_id=str(existing_meta.get("playerId", "")))
                except Exception:
                    mapped_uid = None
                if mapped_uid and mapped_uid == requester_uid:
                    existing["owner_uid"] = requester_uid
                    with open(p, "w", encoding="utf-8") as f:
                        json.dump(existing, f, ensure_ascii=False)
                elif mapped_uid and mapped_uid != requester_uid:
                    # Un autre propriétaire est implicite via playerId → refuser l'écriture
                    raise HTTPException(status_code=403, detail="Forbidden: not the owner of this partie")
                elif mapped_uid is None:
                    # Fallback: vérifier via claims.providers si l'id google correspond au requester
                    try:
                        req_providers = (auth_ctx or {}).get("providers", []) if isinstance(auth_ctx, dict) else []
                    except Exception:
                        req_providers = []
                    legacy_pid = str(existing_meta.get("playerId", ""))
                    if legacy_pid:
                        owns_legacy = any(
                            (isinstance(p, dict) and p.get("provider") == "google" and str(p.get("id")) == legacy_pid)
                            for p in req_providers
                        )
                        if not owns_legacy:
                            raise HTTPException(status_code=403, detail="Forbidden: not the owner of this partie")
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
        enforce = REQUIRE_CONDITIONAL_WRITES or (if_match is not None)
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
        enforce = REQUIRE_CONDITIONAL_WRITES or (if_none_match is not None)
        if enforce and (if_none_match or "") != "*":
            raise HTTPException(status_code=428, detail="Precondition Required: If-None-Match: * required for creation")

    # À l'écriture, si fichier existe et ownership ne correspond pas, refuser (uniquement si JWT dispo)
    if requester_uid and exists:
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
    # Définir owner_uid lors de la création si JWT présent
    if requester_uid and not os.path.exists(p):
        data["owner_uid"] = requester_uid
    with open(p, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)
    # Exposer ETag / X-Remote-Version
    try:
        if response is not None:
            response.headers["ETag"] = data.get("hash", "")
            response.headers["X-Remote-Version"] = str(data.get("remoteVersion", ""))
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
    except Exception:
        pass
    return CloudStatusResponse(
        partieId=partie_id,
        syncState="unknown",
        remoteVersion=data.get("remoteVersion"),
        lastPushAt=data.get("lastPushAt"),
        lastPullAt=data.get("lastPullAt"),
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
    requester_uid: Optional[str] = None
    if isinstance(auth_ctx, dict):
        requester_uid = auth_ctx.get("player_uid") or auth_ctx.get("sub")
    # si JWT dispo, on réduit la visibilité aux parties dont owner_uid == requester
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
        if requester_uid:
            owner = data.get("owner_uid")
            if owner and owner != requester_uid:
                continue
            if not owner:
                # Support legacy: autoriser si playerId correspond au requester via identité
                try:
                    from ..services.identity import resolve_existing_player_uid
                    mapped_uid = resolve_existing_player_uid(provider="google", provider_user_id=str(meta.get("playerId", "")))
                except Exception:
                    mapped_uid = None
                if mapped_uid and mapped_uid != requester_uid:
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
def delete_partie(partie_id: str, auth_ctx=Depends(_auth)):
    """
    Supprime définitivement l'entrée cloud pour un partieId.
    - N'affecte pas les backups locaux ni d'autres parties.
    """
    p = _path(partie_id)
    if not os.path.exists(p):
        raise HTTPException(status_code=404, detail="Not found")
    # Enforcer ownership si JWT disponible
    if isinstance(auth_ctx, dict):
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
