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

def test_login_rejects_legacy_playerId_payload_option_a():
    client = build_auth_app()
    # Option A: pas de compat playerId seul
    resp = client.post("/api/auth/login", json={"playerId": "gXYZ"})
    assert resp.status_code == 400


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


def test_verify_jwt_rejects_non_uuid_sub_option_a():
    # Un ancien token avec sub non-UUID doit être rejeté en Option A
    from app.routes import auth as auth_module
    secret = os.getenv("SECRET_KEY")
    old_style_claims = {
        "sub": "g999",  # non-UUID
        "iat": int(iso_now().timestamp()),
        "exp": int((iso_now() + timedelta(hours=1)).timestamp()),
    }
    old_token = jwt.encode(old_style_claims, secret, algorithm=auth_module.ALGORITHM)
    from fastapi import HTTPException
    with pytest.raises(HTTPException) as exc:
        auth_module.verify_jwt(f"Bearer {old_token}")
    assert exc.value.status_code == 401
