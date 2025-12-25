import os
import importlib
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient


def build_full_app() -> TestClient:
    from app.routes import cloud as cloud_module
    from app.routes import auth as auth_module
    app = FastAPI()
    app.include_router(auth_module.router)
    app.include_router(cloud_module.router)
    return TestClient(app)


@pytest.fixture(autouse=True)
def fixed_env(tmp_path, monkeypatch):
    # isolate storage and identity
    monkeypatch.setenv("CLOUD_STORAGE_DIR", tmp_path.as_posix())
    monkeypatch.delenv("API_KEY", raising=False)
    monkeypatch.setenv("SECRET_KEY", "test-secret")
    monkeypatch.setenv("JWT_TTL_SECONDS", "3600")
    monkeypatch.setenv("SNAPSHOT_SCHEMA_VERSION", "2")

    # reload modules
    from app.routes import auth as auth_module
    from app.routes import cloud as cloud_module
    importlib.reload(auth_module)
    importlib.reload(cloud_module)

    from app.services import identity as identity_module
    store_path = tmp_path.joinpath("_identity_store.json").as_posix()
    importlib.reload(identity_module)
    yield


def login(client: TestClient, provider_id: str) -> str:
    resp = client.post("/api/auth/login", json={"provider": "google", "provider_user_id": provider_id})
    assert resp.status_code == 200
    return resp.json()["access_token"]


def put_partie(client: TestClient, token: str, partie_id: str, snapshot: dict, meta_overrides: dict = None):
    meta_overrides = meta_overrides or {}
    meta = {
        "name": meta_overrides.get("name", "Run"),
        "gameMode": meta_overrides.get("gameMode", "classic"),
        "gameVersion": meta_overrides.get("gameVersion", "1.0.0"),
        "playerId": meta_overrides.get("playerId", "gA"),
    }
    body = {"snapshot": snapshot, "metadata": meta}
    return client.put(f"/api/cloud/parties/{partie_id}", headers={"Authorization": f"Bearer {token}"}, json=body)


def test_missing_snapshot_schema_version_is_rejected(tmp_path):
    client = build_full_app()
    token = login(client, "gA")
    r = put_partie(client, token, "v1", snapshot={})
    assert r.status_code == 422
    assert "snapshotSchemaVersion" in r.json()["detail"]


def test_future_snapshot_schema_version_is_rejected(tmp_path):
    client = build_full_app()
    token = login(client, "gA")
    # server expects 2, future is 3
    r = put_partie(client, token, "v2", snapshot={"snapshotSchemaVersion": 3})
    assert r.status_code == 422


def test_supported_snapshot_schema_version_is_accepted(tmp_path):
    client = build_full_app()
    token = login(client, "gA")
    r = put_partie(client, token, "v3", snapshot={"snapshotSchemaVersion": 2})
    assert r.status_code == 200
