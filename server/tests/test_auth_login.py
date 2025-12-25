import os
from datetime import datetime, timedelta, timezone

from fastapi.testclient import TestClient

from app.main import app


def test_auth_login_happy_path(monkeypatch):
    # Ensure SECRET is set for deterministic signing
    monkeypatch.setenv("SECRET_KEY", "change-this-secret")

    client = TestClient(app)

    payload = {
        "provider": "google",
        "provider_user_id": "player-xyz",
    }
    r = client.post("/api/auth/login", json=payload)
    assert r.status_code == 200
    data = r.json()
    assert "access_token" in data
    assert "expires_at" in data


def test_auth_login_missing_fields():
    client = TestClient(app)

    r1 = client.post("/api/auth/login", json={"provider": "google"})
    assert r1.status_code == 400

    r2 = client.post("/api/auth/login", json={"provider_user_id": "abc"})
    assert r2.status_code == 400

    r3 = client.post("/api/auth/login", json={})
    assert r3.status_code == 400
