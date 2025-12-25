import os
import json
import uuid
from datetime import datetime, timezone

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient


def build_app() -> TestClient:
    from app.routes import auth as auth_module
    from app.routes import cloud as cloud_module

    app = FastAPI()
    app.include_router(auth_module.router)
    app.include_router(cloud_module.router)
    return TestClient(app)


@pytest.fixture(autouse=True)
def isolated_env_and_storage(tmp_path, monkeypatch):
    # Secrets et TTL stables
    monkeypatch.setenv("SECRET_KEY", "test-secret")
    monkeypatch.setenv("JWT_TTL_SECONDS", "3600")
    # Désactiver API_KEY fallback pour forcer JWT
    monkeypatch.delenv("API_KEY", raising=False)
    # Répertoire cloud isolé
    cloud_dir = tmp_path.joinpath("cloud_store").as_posix()
    monkeypatch.setenv("CLOUD_STORAGE_DIR", cloud_dir)
    # Ecritures conditionnelles désactivées par défaut
    monkeypatch.setenv("REQUIRE_CONDITIONAL_WRITES", "0")
    yield


def _login(client: TestClient, provider_id: str) -> str:
    resp = client.post("/api/auth/login", json={"provider": "google", "provider_user_id": provider_id})
    assert resp.status_code == 200
    return resp.json()["access_token"]


def _auth_headers(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}


def _sample_payload(player_id: str) -> dict:
    return {
        "snapshot": {
            "snapshotSchemaVersion": 1,
            "nowIso": datetime.now(timezone.utc).isoformat(),
        },
        "metadata": {
            "name": "Test Partie",
            "gameMode": "classic",
            "gameVersion": "1.0.0",
            "playerId": player_id,
        },
    }


def test_put_get_status_list_delete_flow():
    client = build_app()
    token = _login(client, "g123")

    partie_id = str(uuid.uuid4())
    payload = _sample_payload("g123")

    # PUT create
    r_put = client.put(f"/api/cloud/parties/{partie_id}", json=payload, headers=_auth_headers(token))
    assert r_put.status_code == 200

    # GET status
    r_status = client.get(f"/api/cloud/parties/{partie_id}/status", headers=_auth_headers(token))
    assert r_status.status_code == 200
    assert r_status.json()["partieId"] == partie_id

    # LIST by playerId
    r_list = client.get(f"/api/cloud/parties", params={"playerId": "g123"}, headers=_auth_headers(token))
    assert r_list.status_code == 200
    items = r_list.json()
    assert any(it.get("partieId") == partie_id for it in items)

    # GET raw snapshot
    r_get = client.get(f"/api/cloud/parties/{partie_id}", headers=_auth_headers(token))
    assert r_get.status_code == 200
    body = r_get.json()
    assert body.get("snapshot", {}).get("snapshotSchemaVersion") == 1

    # DELETE
    r_del = client.delete(f"/api/cloud/parties/{partie_id}", headers=_auth_headers(token))
    assert r_del.status_code == 200

    # Ensure deletion
    r_status_after = client.get(f"/api/cloud/parties/{partie_id}/status", headers=_auth_headers(token))
    assert r_status_after.status_code == 404


def test_ownership_enforced_between_two_users():
    client = build_app()
    t_owner = _login(client, "gA")
    t_other = _login(client, "gB")

    partie_id = str(uuid.uuid4())
    payload = _sample_payload("gA")

    # Owner creates
    assert client.put(f"/api/cloud/parties/{partie_id}", json=payload, headers=_auth_headers(t_owner)).status_code == 200

    # Other tries to overwrite
    r_put_other = client.put(f"/api/cloud/parties/{partie_id}", json=_sample_payload("gB"), headers=_auth_headers(t_other))
    assert r_put_other.status_code == 403

    # Other tries to delete
    r_del_other = client.delete(f"/api/cloud/parties/{partie_id}", headers=_auth_headers(t_other))
    assert r_del_other.status_code == 403


def test_conditional_writes_when_enabled(monkeypatch):
    # Activer les écritures conditionnelles globales
    monkeypatch.setenv("REQUIRE_CONDITIONAL_WRITES", "1")
    client = build_app()
    token = _login(client, "gC")

    partie_id = str(uuid.uuid4())
    payload = _sample_payload("gC")

    # Création nécessite If-None-Match: *
    r_put_missing_cond = client.put(f"/api/cloud/parties/{partie_id}", json=payload, headers=_auth_headers(token))
    assert r_put_missing_cond.status_code == 428

    r_put_create = client.put(
        f"/api/cloud/parties/{partie_id}",
        json=payload,
        headers={**_auth_headers(token), "If-None-Match": "*"},
    )
    assert r_put_create.status_code == 200

    # Mise à jour nécessite If-Match avec ETag courant
    r_status = client.get(f"/api/cloud/parties/{partie_id}/status", headers=_auth_headers(token))
    assert r_status.status_code == 200
    etag = r_status.headers.get("ETag")
    assert etag

    # Mauvais If-Match -> 412
    r_put_wrong_etag = client.put(
        f"/api/cloud/parties/{partie_id}",
        json=_sample_payload("gC"),
        headers={**_auth_headers(token), "If-Match": '"deadbeef"'},
    )
    assert r_put_wrong_etag.status_code == 412

    # Bon If-Match -> 200
    r_put_ok = client.put(
        f"/api/cloud/parties/{partie_id}",
        json=_sample_payload("gC"),
        headers={**_auth_headers(token), "If-Match": etag},
    )
    assert r_put_ok.status_code == 200
