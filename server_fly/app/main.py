# Minimal FastAPI app that verifies Firebase ID Tokens and rejects unauthenticated requests
from fastapi import FastAPI, Depends, Header, HTTPException, status
from typing import Optional, Dict, Any
import os

from firebase_admin import auth as fb_auth, credentials as fb_credentials, initialize_app as fb_initialize_app
from sqlalchemy import (
    create_engine, text, String, Integer, DateTime, ForeignKey, func, BigInteger, UniqueConstraint
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship, Session
from sqlalchemy.dialects.postgresql import JSONB, UUID
from pydantic import BaseModel
from datetime import datetime

# Initialize Firebase Admin using Application Default Credentials (ADC)
# Expect GOOGLE_APPLICATION_CREDENTIALS to be set to a service account JSON path at runtime (via Fly secrets/volume)
if True:
    # Initialize Admin SDK using one of (in order):
    # 1) FIREBASE_CREDENTIALS_JSON env (service account JSON content)
    # 2) GOOGLE_APPLICATION_CREDENTIALS file path
    # 3) Application Default Credentials
    json_env = os.getenv("FIREBASE_CREDENTIALS_JSON")
    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    try:
        if json_env:
            import json as _json
            obj = _json.loads(json_env)
            fb_initialize_app(fb_credentials.Certificate(obj))
        elif cred_path:
            fb_initialize_app(fb_credentials.Certificate(cred_path))
        else:
            fb_initialize_app()
    except Exception:
        # defer failure; requests will 401 if verification cannot occur
        pass

app = FastAPI(title="PaperClip Minimal Auth API")

async def verify_firebase_bearer(authorization: Optional[str] = Header(default=None)) -> Dict[str, Any]:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing or invalid Authorization header")
    token = authorization.split(" ", 1)[1].strip()
    try:
        decoded = fb_auth.verify_id_token(token)
        return decoded  # contains 'uid', 'email', etc.
    except fb_auth.InvalidIdTokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid ID token")
    except fb_auth.ExpiredIdTokenError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Expired ID token")
    except Exception as e:
        # Do not leak internal details
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication failed")

# ----------------- Database (Postgres) minimal wiring -----------------

DATABASE_URL = os.getenv("DATABASE_URL", "")
engine = create_engine(DATABASE_URL, pool_pre_ping=True) if DATABASE_URL else None


class Base(DeclarativeBase):
    pass


class Player(Base):
    __tablename__ = "players"
    uid: Mapped[str] = mapped_column(String(128), primary_key=True)
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    # relationship example (not used by endpoints)
    saves: Mapped[list["Save"]] = relationship(back_populates="player")


class Save(Base):
    __tablename__ = "saves"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    player_uid: Mapped[str] = mapped_column(String(128), ForeignKey("players.uid", ondelete="CASCADE"), nullable=False)
    partie_id: Mapped[str] = mapped_column(UUID(as_uuid=False), nullable=False)
    version: Mapped[int] = mapped_column(Integer, nullable=False)
    snapshot: Mapped[dict] = mapped_column(JSONB, nullable=False)
    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    __table_args__ = (
        UniqueConstraint("player_uid", "partie_id", "version", name="uq_save_version"),
    )

    player: Mapped[Player] = relationship(back_populates="saves")


class AnalyticsEvent(Base):
    __tablename__ = "analytics_events"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    player_uid: Mapped[str] = mapped_column(String(128), nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    properties: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    timestamp: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    received_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)


@app.on_event("startup")
def _startup_create_schema_if_needed() -> None:
    if engine is None:
        return
    Base.metadata.create_all(bind=engine)


@app.get("/health")
async def health() -> Dict[str, str]:
    return {"status": "ok"}

@app.get("/health/auth")
async def health_auth(claims: Dict[str, Any] = Depends(verify_firebase_bearer)) -> Dict[str, Any]:
    return {"status": "ok", "uid": claims.get("uid")}


@app.get("/db/health")
async def db_health(claims: Dict[str, Any] = Depends(verify_firebase_bearer)) -> Dict[str, Any]:
    if engine is None:
        raise HTTPException(status_code=500, detail="DATABASE_URL not configured")
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "ok"}
    except Exception:
        raise HTTPException(status_code=500, detail="DB connection failed")


class AnalyticsEventIn(BaseModel):
    name: str
    properties: Dict[str, Any] | None = None
    timestamp: str | None = None  # ISO8601 optionnel


@app.post("/analytics/events", status_code=202)
async def record_event(event: AnalyticsEventIn, claims: Dict[str, Any] = Depends(verify_firebase_bearer)) -> None:
    # Best-effort: tenter d'écrire, ne jamais impacter le gameplay; requiert tout de même l'auth Firebase
    if engine is None:
        return None
    uid = claims.get("uid")
    if not uid:
        return None
    # Parse timestamp si fourni (best-effort)
    ts: datetime | None = None
    if event.timestamp:
        try:
            ts = datetime.fromisoformat(event.timestamp.replace("Z", "+00:00"))
        except Exception:
            ts = None
    try:
        with engine.begin() as conn:
            conn.execute(
                text(
                    """
                    INSERT INTO analytics_events(player_uid, name, properties, timestamp)
                    VALUES (:uid, :name, :props::jsonb, :ts)
                    """
                ),
                {"uid": uid, "name": event.name, "props": event.properties or {}, "ts": ts},
            )
    except Exception:
        # Best-effort: ne pas faire échouer la requête
        return None


# ----------------- Cloud Saves (secured, versioned JSON) -----------------

class SavePayload(BaseModel):
    snapshot: Dict[str, Any]


def _ensure_player(conn, uid: str) -> None:
    conn.execute(
        text(
            """
            INSERT INTO players(uid) VALUES (:uid)
            ON CONFLICT (uid) DO NOTHING
            """
        ),
        {"uid": uid},
    )


@app.put("/saves/{partie_id}")
async def put_save(
    partie_id: str,
    payload: SavePayload,
    claims: Dict[str, Any] = Depends(verify_firebase_bearer),
) -> Dict[str, Any]:
    if engine is None:
        raise HTTPException(status_code=500, detail="DATABASE_URL not configured")
    uid = claims.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Invalid auth context")
    try:
        with engine.begin() as conn:
            _ensure_player(conn, uid)
            # Get next version for (uid, partie_id)
            res = conn.execute(
                text(
                    """
                    SELECT COALESCE(MAX(version), 0) AS v
                    FROM saves
                    WHERE player_uid = :uid AND partie_id = :pid::uuid
                    """
                ),
                {"uid": uid, "pid": partie_id},
            ).mappings().first()
            next_v = int(res["v"]) + 1 if res else 1
            conn.execute(
                text(
                    """
                    INSERT INTO saves(player_uid, partie_id, version, snapshot)
                    VALUES (:uid, :pid::uuid, :v, :snap::jsonb)
                    """
                ),
                {"uid": uid, "pid": partie_id, "v": next_v, "snap": payload.snapshot},
            )
        return {"ok": True, "version": next_v}
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Save failed")


@app.get("/saves/{partie_id}/latest")
async def get_latest_save(
    partie_id: str,
    claims: Dict[str, Any] = Depends(verify_firebase_bearer),
) -> Dict[str, Any]:
    if engine is None:
        raise HTTPException(status_code=500, detail="DATABASE_URL not configured")
    uid = claims.get("uid")
    if not uid:
        raise HTTPException(status_code=401, detail="Invalid auth context")
    try:
        with engine.connect() as conn:
            row = conn.execute(
                text(
                    """
                    SELECT version, snapshot, created_at
                    FROM saves
                    WHERE player_uid = :uid AND partie_id = :pid::uuid
                    ORDER BY version DESC
                    LIMIT 1
                    """
                ),
                {"uid": uid, "pid": partie_id},
            ).mappings().first()
            if not row:
                raise HTTPException(status_code=404, detail="Not found")
            return {
                "partieId": partie_id,
                "version": int(row["version"]),
                "snapshot": row["snapshot"],
                "createdAt": row["created_at"].isoformat() if row["created_at"] else None,
            }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Load failed")
