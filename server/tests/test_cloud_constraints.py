import os
import json
from datetime import datetime, timezone

from fastapi.testclient import TestClient

from app.main import app


def _payload(name="A", gameMode="classic", gameVersion="1.0.0", playerId="p1", snapshot=None):
    snap = {"snapshotSchemaVersion": 1}
    if snapshot:
        snap.update(snapshot)
    return {
        "snapshot": snap,
        "metadata": {
            "name": name,
            "gameMode": gameMode,
            "gameVersion": gameVersion,
            "playerId": playerId,
        },
    }


def test_game_mode_enum_and_length_limits(tmp_path, monkeypatch):
    # Cloud dir isolated
    monkeypatch.setenv("CLOUD_STORAGE_DIR", str(tmp_path))
    # Enforce enum of game modes
    monkeypatch.setenv("GAME_MODE_ENUM", "classic,zen")
    # SECRET for JWT in auth verify (used in cloud._auth)
    monkeypatch.setenv("SECRET_KEY", "change-this-secret")

    client = TestClient(app)

    # Build a valid JWT by calling /auth/login once (no need to inspect response body here)
    r_login = client.post("/api/auth/login", json={"provider": "google", "provider_user_id": "player-123"})
    assert r_login.status_code == 200
    token = r_login.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    pid = "partie-enum-1"

    # Valid gameMode in enum
    r_ok = client.put(
        f"/api/cloud/parties/{pid}",
        json=_payload(gameMode="classic"),
        headers={**headers, "If-None-Match": "*"},
    )
    assert r_ok.status_code == 200

    # Invalid gameMode not in enum -> 422
    r_bad_mode = client.put(
        f"/api/cloud/parties/{pid}",
        json=_payload(gameMode="hardcore", name="B"),
        headers={**headers, "If-Match": r_ok.headers.get("ETag", '"etag"')},
    )
    assert r_bad_mode.status_code == 422

    # Length limits: name>100, gameMode>50, gameVersion>20
    long_name = "n" * 101
    long_mode = "m" * 51
    long_version = "v" * 21

    r_len = client.put(
        f"/api/cloud/parties/{pid}",
        json=_payload(name=long_name, gameMode=long_mode, gameVersion=long_version),
        headers={**headers, "If-Match": r_ok.headers.get("ETag", '"etag"')},
    )
    assert r_len.status_code == 422
