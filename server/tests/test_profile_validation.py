import os
from datetime import datetime, timezone

from fastapi.testclient import TestClient

from app.main import app


def _login_token(client: TestClient) -> str:
    os.environ.setdefault("SECRET_KEY", "change-this-secret")
    r = client.post("/api/auth/login", json={"provider": "google", "provider_user_id": "p-1"})
    assert r.status_code == 200
    return r.json()["access_token"]


def test_profile_put_invalid_payload_returns_422(tmp_path, monkeypatch):
    monkeypatch.setenv("PROFILE_DATA_DIR", str(tmp_path))
    client = TestClient(app)
    token = _login_token(client)

    # invalid types: money should be float, provide string
    bad_state = {
        "money": "abc",
        "paperclips": 1000.0,
        "metal": 10.0,
        "sell_price": 0.25,
        "upgrades": {"efficiency": 1},
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }

    r = client.put(
        "/api/profile/state",
        json=bad_state,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 422


def test_profile_get_404_when_missing(tmp_path, monkeypatch):
    monkeypatch.setenv("PROFILE_DATA_DIR", str(tmp_path))
    client = TestClient(app)
    token = _login_token(client)

    r = client.get(
        "/api/profile/state",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 404
