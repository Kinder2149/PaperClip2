import os
from datetime import datetime, timedelta, timezone
import uuid

import jwt
import pytest

from app.routes.auth import verify_jwt
from fastapi import HTTPException

ALGO = "HS256"


def _make_jwt(player_uid: str | None = None, ttl_seconds: int = 3600) -> str:
    secret = os.getenv("SECRET_KEY", "change-this-secret")
    sub = player_uid or str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    payload = {
        "sub": sub,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(seconds=ttl_seconds)).timestamp()),
    }
    return jwt.encode(payload, secret, algorithm=ALGO)


def test_verify_jwt_valid(monkeypatch):
    monkeypatch.setenv("SECRET_KEY", "change-this-secret")
    token = _make_jwt()
    claims = verify_jwt(f"Bearer {token}")
    assert isinstance(claims, dict)
    assert claims.get("player_uid")


def test_verify_jwt_missing_header_raises():
    with pytest.raises(HTTPException) as e:
        verify_jwt(None)
    assert e.value.status_code == 401


def test_verify_jwt_invalid_scheme_raises():
    with pytest.raises(HTTPException) as e:
        verify_jwt("Token abc")
    assert e.value.status_code == 401


def test_verify_jwt_expired(monkeypatch):
    monkeypatch.setenv("SECRET_KEY", "change-this-secret")
    token = _make_jwt(ttl_seconds=-10)
    with pytest.raises(HTTPException) as e:
        verify_jwt(f"Bearer {token}")
    assert e.value.status_code == 401
