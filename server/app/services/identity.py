# server/app/services/identity.py
# Service d'identité avec double backend:
# - Postgres (production via Supabase) si DATABASE_URL est défini
# - Fallback JSON store (développement) sinon
# Fournit un mapping souverain player_uid (UUID v4) ↔ comptes provider externes

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from typing import Dict, Any, List
import uuid

# DB backend (optionnel)
_DATABASE_URL = os.getenv("DATABASE_URL") or os.getenv("SUPABASE_DATABASE_URL")
try:
    if _DATABASE_URL:
        import psycopg2  # type: ignore
        import psycopg2.extras  # type: ignore
    else:
        psycopg2 = None  # type: ignore
except Exception:
    psycopg2 = None  # type: ignore

_STORE_DIR = os.path.dirname(__file__)
_STORE_PATH = os.path.join(_STORE_DIR, "_identity_store.json")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _init_store_if_needed() -> None:
    if not os.path.exists(_STORE_PATH):
        data = {"links": []}  # list of {provider, provider_user_id, player_uid, created_at}
        with open(_STORE_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f)


def _load_store() -> Dict[str, Any]:
    _init_store_if_needed()
    try:
        with open(_STORE_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {"links": []}


def _save_store(data: Dict[str, Any]) -> None:
    tmp_path = _STORE_PATH + ".tmp"
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(data, f)
    os.replace(tmp_path, _STORE_PATH)


# ---------- Postgres helpers (si DATABASE_URL défini) ----------

def _db_available() -> bool:
    return bool(_DATABASE_URL and psycopg2)


def _db_connect():
    if not _db_available():
        raise RuntimeError("Database not available")
    return psycopg2.connect(_DATABASE_URL)  # type: ignore


def _db_init_schema_if_needed() -> None:
    if not _db_available():
        return
    # Création tables minimales si absentes
    sql_players = """
    CREATE TABLE IF NOT EXISTS players (
        id UUID PRIMARY KEY,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
    """
    sql_links = """
    CREATE TABLE IF NOT EXISTS identity_provider_links (
        id BIGSERIAL PRIMARY KEY,
        player_uid UUID NOT NULL REFERENCES players(id) ON DELETE CASCADE,
        provider TEXT NOT NULL,
        provider_user_id TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE(provider, provider_user_id)
    );
    CREATE INDEX IF NOT EXISTS idx_links_player_uid ON identity_provider_links(player_uid);
    """
    conn = _db_connect()
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(sql_players)
                cur.execute(sql_links)
    finally:
        conn.close()


def resolve_or_create_player_uid(*, provider: str, provider_user_id: str) -> str:
    """
    Retourne un player_uid (UUID v4 string) en résolvant le couple (provider, provider_user_id).
    Crée un nouvel utilisateur souverain si le lien n'existe pas encore.
    """
    provider = (provider or "").strip().lower()
    provider_user_id = (provider_user_id or "").strip()
    if not provider or not provider_user_id:
        raise ValueError("provider and provider_user_id are required")

    # Mode DB
    if _db_available():
        _db_init_schema_if_needed()
        conn = _db_connect()
        try:
            with conn:
                with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:  # type: ignore
                    # Chercher lien existant
                    cur.execute(
                        "SELECT player_uid FROM identity_provider_links WHERE provider=%s AND provider_user_id=%s",
                        (provider, provider_user_id),
                    )
                    row = cur.fetchone()
                    if row:
                        return str(row[0])
                    # Créer player si besoin
                    player_uid = str(uuid.uuid4())
                    # Upsert joueur (si jamais déjà créé ailleurs)
                    cur.execute(
                        "INSERT INTO players(id) VALUES (%s) ON CONFLICT (id) DO NOTHING",
                        (player_uid,),
                    )
                    # Créer lien
                    cur.execute(
                        "INSERT INTO identity_provider_links(player_uid, provider, provider_user_id) VALUES (%s, %s, %s)",
                        (player_uid, provider, provider_user_id),
                    )
                    return player_uid
        finally:
            conn.close()

    # Fallback JSON store
    data = _load_store()
    links: List[Dict[str, Any]] = data.get("links", [])
    for link in links:
        if link.get("provider") == provider and link.get("provider_user_id") == provider_user_id:
            return link.get("player_uid")
    player_uid = str(uuid.uuid4())
    links.append({
        "provider": provider,
        "provider_user_id": provider_user_id,
        "player_uid": player_uid,
        "created_at": _now_iso(),
    })
    data["links"] = links
    _save_store(data)
    return player_uid


essential_provider_fields = ("provider", "provider_user_id")


def list_provider_links(player_uid: str) -> List[Dict[str, Any]]:
    """
    Retourne les liaisons provider connues pour un player_uid.
    Format: [{"provider": "google", "id": "<provider_user_id>"}, ...]
    """
    if not player_uid:
        return []
    # Mode DB
    if _db_available():
        _db_init_schema_if_needed()
        conn = _db_connect()
        try:
            with conn:
                with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:  # type: ignore
                    cur.execute(
                        "SELECT provider, provider_user_id FROM identity_provider_links WHERE player_uid=%s",
                        (player_uid,),
                    )
                    rows = cur.fetchall() or []
                    return [{"provider": r[0], "id": r[1]} for r in rows]
        finally:
            conn.close()
    # Fallback JSON
    data = _load_store()
    links: List[Dict[str, Any]] = data.get("links", [])
    out: List[Dict[str, Any]] = []
    for link in links:
        if link.get("player_uid") == player_uid:
            out.append({"provider": link.get("provider"), "id": link.get("provider_user_id")})
    return out


def resolve_existing_player_uid(*, provider: str, provider_user_id: str) -> Optional[str]:
    """
    Retourne le player_uid existant pour (provider, provider_user_id) sans créer de lien.
    Renvoie None si aucun lien n'existe.
    """
    provider = (provider or "").strip().lower()
    provider_user_id = (provider_user_id or "").strip()
    if not provider or not provider_user_id:
        return None
    # Mode DB
    if _db_available():
        _db_init_schema_if_needed()
        conn = _db_connect()
        try:
            with conn:
                with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:  # type: ignore
                    cur.execute(
                        "SELECT player_uid FROM identity_provider_links WHERE provider=%s AND provider_user_id=%s",
                        (provider, provider_user_id),
                    )
                    row = cur.fetchone()
                    return str(row[0]) if row else None
        finally:
            conn.close()
    # Fallback JSON
    data = _load_store()
    links: List[Dict[str, Any]] = data.get("links", [])
    for link in links:
        if link.get("provider") == provider and link.get("provider_user_id") == provider_user_id:
            return link.get("player_uid")
    return None
