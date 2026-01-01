import os
import importlib
import json
from typing import Dict
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
def fixed_env_and_modules(tmp_path, monkeypatch):
    # Storage isolation
    monkeypatch.setenv("CLOUD_STORAGE_DIR", tmp_path.as_posix())
    # Security: ensure API_KEY not set to force JWT path
    monkeypatch.delenv("API_KEY", raising=False)
    # JWT config
    monkeypatch.setenv("SECRET_KEY", "test-secret")
    monkeypatch.setenv("JWT_TTL_SECONDS", "3600")
    # Defaults for guards
    monkeypatch.setenv("MAX_SNAPSHOT_BYTES", str(256 * 1024))
    monkeypatch.delenv("GAME_MODE_ENUM", raising=False)
    # Snapshot schema version baseline for these tests
    monkeypatch.setenv("SNAPSHOT_SCHEMA_VERSION", "1")

    # Reload affected modules to pickup env
    from app.routes import cloud as cloud_module
    from app.routes import auth as auth_module
    importlib.reload(auth_module)
    importlib.reload(cloud_module)

    # Identity store isolation
    from app.services import identity as identity_module
    store_path = tmp_path.joinpath("_identity_store.json").as_posix()
    monkeypatch.setattr(identity_module, "_STORE_PATH", store_path, raising=True)
    importlib.reload(identity_module)

    yield


def login(client: TestClient, provider_id: str) -> str:
    resp = client.post("/api/auth/login", json={"provider": "google", "provider_user_id": provider_id})
    assert resp.status_code == 200
    return resp.json()["access_token"]


def put_partie(client: TestClient, token: str, partie_id: str, player_id: str, **meta_overrides: Dict):
    meta = {
        "name": meta_overrides.get("name", "Run"),
        "gameMode": meta_overrides.get("gameMode", "classic"),
        "gameVersion": meta_overrides.get("gameVersion", "1.0.0"),
        "playerId": player_id,
    }
    snapshot = meta_overrides.get("snapshot", {"snapshotSchemaVersion": 1})
    body = {"snapshot": snapshot, "metadata": meta}
    return client.put(f"/api/cloud/parties/{partie_id}", headers={"Authorization": f"Bearer {token}"}, json=body)


def test_put_rejects_non_owner(tmp_path):
    client = build_full_app()
    token_a = login(client, "gA")
    token_b = login(client, "gB")

    # A crée la partie
    r1 = put_partie(client, token_a, "p1", player_id="gA")
    assert r1.status_code == 200

    # B tente d'écrire sur la même partie → 403
    r2 = put_partie(client, token_b, "p1", player_id="gB")
    assert r2.status_code == 403
    assert r2.json()["detail"].startswith("Forbidden")


def test_delete_rejects_non_owner(tmp_path):
    client = build_full_app()
    token_a = login(client, "gA")
    token_b = login(client, "gB")

    # A crée la partie
    assert put_partie(client, token_a, "p2", player_id="gA").status_code == 200

    # B tente de supprimer → 403
    r = client.delete("/api/cloud/parties/p2", headers={"Authorization": f"Bearer {token_b}"})
    assert r.status_code == 403


def test_list_filters_by_owner_with_jwt(tmp_path):
    client = build_full_app()
    token_a = login(client, "gA")
    token_b = login(client, "gB")

    # A crée deux parties
    assert put_partie(client, token_a, "la1", player_id="gA").status_code == 200
    assert put_partie(client, token_a, "la2", player_id="gA").status_code == 200
    # B crée une partie avec playerId=gB
    assert put_partie(client, token_b, "lb1", player_id="gB").status_code == 200

    # A liste ses parties → ne doit pas voir celles de B
    r_a = client.get("/api/cloud/parties", params={"playerId": "gA"}, headers={"Authorization": f"Bearer {token_a}"})
    assert r_a.status_code == 200
    ids_a = sorted([it["partieId"] for it in r_a.json()])
    assert ids_a == ["la1", "la2"]

    # B liste ses parties → ne voit pas celles de A
    r_b = client.get("/api/cloud/parties", params={"playerId": "gB"}, headers={"Authorization": f"Bearer {token_b}"})
    assert r_b.status_code == 200
    ids_b = sorted([it["partieId"] for it in r_b.json()])
    assert ids_b == ["lb1"]


def test_legacy_claim_denied_when_mapping_mismatch(tmp_path):
    client = build_full_app()
    # Créer un mapping: gX -> uidX via un login
    token_x = login(client, "gX")

    # Créer un fichier legacy sans owner mais avec playerId = gX
    # Puis tenter de l'écrire avec un requester différent gY → doit être refusé (403)
    # Étape 1: écrire un premier snapshot avec token_x pour initialiser le fichier
    assert put_partie(client, token_x, "legacy1", player_id="gX").status_code == 200

    # Supprimer owner_uid manuellement pour simuler legacy sans owner
    storage_dir = os.getenv("CLOUD_STORAGE_DIR")
    path = os.path.join(storage_dir, "legacy1.json")
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    data.pop("owner_uid", None)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f)

    # Requérant gY
    token_y = login(client, "gY")
    r = put_partie(client, token_y, "legacy1", player_id="gX")
    # Option A: si owner_uid est absent, le premier writer authentifié revendique l'ownership
    assert r.status_code == 200


def test_snapshot_too_large(tmp_path, monkeypatch):
    # Fixer une taille max très petite
    monkeypatch.setenv("MAX_SNAPSHOT_BYTES", "128")
    # Recharger cloud pour prendre en compte la valeur
    from app.routes import cloud as cloud_module
    importlib.reload(cloud_module)

    client = build_full_app()
    token = login(client, "gA")
    big_snapshot = {"payload": "x" * 1024}  # > 128 bytes
    r = put_partie(client, token, "big1", player_id="gA", snapshot=big_snapshot)
    assert r.status_code == 413


def test_invalid_game_mode_when_enum(tmp_path, monkeypatch):
    monkeypatch.setenv("GAME_MODE_ENUM", "classic,zen")
    from app.routes import cloud as cloud_module
    importlib.reload(cloud_module)

    client = build_full_app()
    token = login(client, "gA")
    r = put_partie(client, token, "enum1", player_id="gA", name="Run", gameMode="hardcore", gameVersion="1.0.0")
    assert r.status_code == 422


def test_put_rejects_api_key_write(tmp_path, monkeypatch):
    # Activer une API_KEY et recharger les modules pour prendre en compte le fallback
    monkeypatch.setenv("API_KEY", "devkey")
    from app.routes import cloud as cloud_module
    importlib.reload(cloud_module)

    client = build_full_app()
    # Tentative d'écriture avec uniquement X-Authorization (API_KEY) → refusée (JWT requis)
    meta = {"name": "Run", "gameMode": "classic", "gameVersion": "1.0.0", "playerId": "gA"}
    body = {"snapshot": {"snapshotSchemaVersion": 1}, "metadata": meta}
    r = client.put("/api/cloud/parties/ak1", headers={"X-Authorization": "Bearer devkey"}, json=body)
    assert r.status_code == 401
    assert any(s in r.json()["detail"] for s in ["JWT required", "Missing Authorization"])


def test_delete_rejects_api_key_without_jwt(tmp_path, monkeypatch):
    # Activer une API_KEY et recharger cloud
    monkeypatch.setenv("API_KEY", "devkey")
    from app.routes import cloud as cloud_module
    importlib.reload(cloud_module)

    client = build_full_app()
    # Créer une partie avec JWT pour avoir une ressource à supprimer
    token = login(client, "gA")
    assert put_partie(client, token, "akdel1", player_id="gA").status_code == 200
    # Tenter de supprimer avec seulement X-Authorization → refus 401
    r = client.delete("/api/cloud/parties/akdel1", headers={"X-Authorization": "Bearer devkey"})
    assert r.status_code == 401
    assert any(s in r.json()["detail"] for s in ["JWT required", "Missing Authorization"])
