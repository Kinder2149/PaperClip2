import os
import importlib
from datetime import datetime, timedelta, timezone
import uuid

import jwt
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient


def build_auth_app() -> TestClient:
    from app.routes import auth as auth_module
    app = FastAPI()
    app.include_router(auth_module.router)
    return TestClient(app)


def iso_now():
    return datetime.now(timezone.utc)


@pytest.fixture(autouse=True)
def isolated_identity_store(tmp_path, monkeypatch):
    # Isoler le store JSON d'identité pour chaque test
    from app.services import identity as identity_module
    store_path = tmp_path.joinpath("_identity_store.json").as_posix()
    monkeypatch.setattr(identity_module, "_STORE_PATH", store_path, raising=True)
    # Recharger le module pour repartir sur un store vierge
    importlib.reload(identity_module)
    yield


@pytest.fixture(autouse=True)
def fixed_secret_env(monkeypatch):
    # Fixer la clé et un TTL court pour les tests
    monkeypatch.setenv("SECRET_KEY", "test-secret")
    monkeypatch.setenv("JWT_TTL_SECONDS", "3600")
    # Recharger le module d'auth pour prendre en compte les env
    from app.routes import auth as auth_module
    importlib.reload(auth_module)
    yield


def test_login_with_provider_returns_jwt_with_sub_uuid_and_providers():
    client = build_auth_app()

    body = {"provider": "google", "provider_user_id": "g123"}
    resp = client.post("/api/auth/login", json=body)
    assert resp.status_code == 200
    data = resp.json()

    assert "access_token" in data
    token = data["access_token"]

    # Décoder pour vérifier les claims
    from app.routes import auth as auth_module
    claims = jwt.decode(token, os.getenv("SECRET_KEY"), algorithms=[auth_module.ALGORITHM])

    # sub doit être un UUID v4
    sub = claims.get("sub")
    uuid_obj = uuid.UUID(str(sub), version=4)
    assert str(uuid_obj) == sub

    # providers doit contenir l'entrée google g123
    providers = claims.get("providers") or []
    assert any(p.get("provider") == "google" and p.get("id") == "g123" for p in providers)


def test_login_legacy_playerId_maps_to_same_player_uid_and_sets_legacy_claim():
    client = build_auth_app()

    # 1) Login avec schéma recommandé
    resp1 = client.post("/api/auth/login", json={"provider": "google", "provider_user_id": "gXYZ"})
    assert resp1.status_code == 200
    token1 = resp1.json()["access_token"]

    from app.routes import auth as auth_module
    claims1 = jwt.decode(token1, os.getenv("SECRET_KEY"), algorithms=[auth_module.ALGORITHM])
    sub1 = claims1["sub"]

    # 2) Login compat héritée avec playerId identique
    resp2 = client.post("/api/auth/login", json={"playerId": "gXYZ"})
    assert resp2.status_code == 200
    token2 = resp2.json()["access_token"]

    claims2 = jwt.decode(token2, os.getenv("SECRET_KEY"), algorithms=[auth_module.ALGORITHM])
    sub2 = claims2["sub"]

    # Même player_uid attendu
    assert sub1 == sub2
    # legacy_playerId présent pour la requête héritée
    assert claims2.get("legacy_playerId") == "gXYZ"


def test_verify_jwt_accepts_uuid_sub_and_rejects_expired():
    client = build_auth_app()

    # Token normal via login
    resp = client.post("/api/auth/login", json={"provider": "google", "provider_user_id": "userA"})
    assert resp.status_code == 200
    token = resp.json()["access_token"]

    # Vérification via endpoint protégé factice: on appelle verify_jwt directement
    from app.routes import auth as auth_module
    claims = auth_module.verify_jwt(f"Bearer {token}")
    assert claims["sub"]

    # Créer un token expiré et s'assurer que verify_jwt renvoie 401
    now = iso_now()
    expired_claims = {
        "sub": claims["sub"],
        "iat": int((now - timedelta(hours=2)).timestamp()),
        "exp": int((now - timedelta(hours=1)).timestamp()),
    }
    expired_token = jwt.encode(expired_claims, os.getenv("SECRET_KEY"), algorithm=auth_module.ALGORITHM)

    from fastapi import HTTPException
    with pytest.raises(HTTPException) as exc:
        auth_module.verify_jwt(f"Bearer {expired_token}")
    assert exc.value.status_code == 401


def test_verify_jwt_legacy_sub_provider_id_is_resolved_to_player_uid():
    # Simuler un ancien token où sub = id google non-UUID
    from app.routes import auth as auth_module
    secret = os.getenv("SECRET_KEY")

    # D'abord, créer un mapping en faisant un login pour g999
    client = build_auth_app()
    resp = client.post("/api/auth/login", json={"provider": "google", "provider_user_id": "g999"})
    assert resp.status_code == 200

    old_style_claims = {
        "sub": "g999",  # non-UUID
        "iat": int(iso_now().timestamp()),
        "exp": int((iso_now() + timedelta(hours=1)).timestamp()),
    }
    old_token = jwt.encode(old_style_claims, secret, algorithm=auth_module.ALGORITHM)

    claims = auth_module.verify_jwt(f"Bearer {old_token}")
    # verify_jwt doit exposer player_uid normalisé
    assert "player_uid" in claims
    # Doit être un uuid valide
    uuid_obj = uuid.UUID(str(claims["player_uid"]), version=4)
    assert str(uuid_obj) == claims["player_uid"]
