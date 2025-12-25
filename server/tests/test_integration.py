import os
import json
from datetime import datetime, timedelta, timezone
import uuid

import jwt
from fastapi.testclient import TestClient

from app.main import app

SECRET = os.getenv("SECRET_KEY", "change-this-secret")
ALGO = "HS256"


def _make_jwt(player_uid: str | None = None) -> str:
    sub = player_uid or str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    payload = {
        "sub": sub,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(hours=1)).timestamp()),
    }
    return jwt.encode(payload, SECRET, algorithm=ALGO)


def test_health_returns_ok():
    client = TestClient(app)
    r = client.get("/api/health")
    assert r.status_code == 200
    assert r.json().get("status") == "ok"


def test_analytics_events_best_effort(tmp_path, monkeypatch):
    # Isoler le répertoire analytics pour le test
    analytics_dir = tmp_path / "analytics"
    monkeypatch.setenv("ANALYTICS_DATA_DIR", str(analytics_dir))

    client = TestClient(app)

    payload = {
        "name": "metal_purchased",
        "properties": {"amount": 50, "unitPrice": 0.12},
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    # Sans Authorization: doit accepter en best-effort (202)
    r = client.post("/api/analytics/events", json=payload)
    assert r.status_code == 202

    # Vérifier qu'une ligne a été écrite
    events_file = analytics_dir / "events.jsonl"
    assert events_file.exists()
    content = events_file.read_text(encoding="utf-8").strip().splitlines()
    assert len(content) >= 1
    row = json.loads(content[-1])
    assert row["name"] == "metal_purchased"
    assert row["properties"]["amount"] == 50

    # Avec Authorization valide
    token = _make_jwt()
    r2 = client.post(
        "/api/analytics/events",
        json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r2.status_code == 202


def test_profile_put_get_roundtrip(tmp_path, monkeypatch):
    # Isoler le répertoire profiles pour le test
    profiles_dir = tmp_path / "profiles"
    monkeypatch.setenv("PROFILE_DATA_DIR", str(profiles_dir))

    client = TestClient(app)

    token = _make_jwt()
    state = {
        "money": 123.45,
        "paperclips": 1000.0,
        "metal": 42.0,
        "sell_price": 0.25,
        "upgrades": {"efficiency": 2, "speed": 1},
        "market": {"saturation": 0.5},
        "stats": {"total_paperclips": 1000},
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }

    # PUT (nécessite JWT)
    r_put = client.put(
        "/api/profile/state",
        json=state,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r_put.status_code == 204

    # GET (nécessite JWT) et comparer
    r_get = client.get(
        "/api/profile/state",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r_get.status_code == 200
    data = r_get.json()
    for k in ["money", "paperclips", "metal", "sell_price", "upgrades", "updated_at"]:
        assert k in data
    assert data["upgrades"]["efficiency"] == 2
