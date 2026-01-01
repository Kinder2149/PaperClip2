import os
import json
from datetime import datetime, timedelta, timezone
import uuid

import jwt
from fastapi.testclient import TestClient

from app.main import app

ALGO = "HS256"


def _make_jwt(player_uid: str | None = None) -> str:
    secret = os.getenv("SECRET_KEY", "change-this-secret")
    sub = player_uid or str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    payload = {
        "sub": sub,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(hours=1)).timestamp()),
    }
    return jwt.encode(payload, secret, algorithm=ALGO)


def _payload(snapshot: dict | None = None, meta: dict | None = None):
    snap = {"snapshotSchemaVersion": 1}
    if snapshot:
        snap.update(snapshot)
    metadata = {
        "name": "Partie A",
        "gameMode": "classic",
        "gameVersion": "1.0.0",
        "playerId": "player-123",
    }
    if meta:
        metadata.update(meta)
    return {"snapshot": snap, "metadata": metadata}


def test_put_get_delete_lifecycle(tmp_path, monkeypatch):
    monkeypatch.setenv("CLOUD_STORAGE_DIR", str(tmp_path))
    monkeypatch.setenv("SECRET_KEY", "change-this-secret")

    client = TestClient(app)
    token = _make_jwt()
    pid = "partie-1"

    # Create (no ETag required by default)
    r_put = client.put(
        f"/api/cloud/parties/{pid}",
        json=_payload(),
        headers={"Authorization": f"Bearer {token}", "If-None-Match": "*"},
    )
    assert r_put.status_code == 200

    # Get returns snapshot + metadata and ETag headers
    r_get = client.get(f"/api/cloud/parties/{pid}", headers={"Authorization": f"Bearer {token}"})
    assert r_get.status_code == 200
    body = r_get.json()
    assert "snapshot" in body and "metadata" in body
    etag = r_get.headers.get("ETag")
    assert etag

    # Update requires If-Match when header is provided/enforced
    r_put2 = client.put(
        f"/api/cloud/parties/{pid}",
        json=_payload(meta={"name": "Partie A2"}),
        headers={"Authorization": f"Bearer {token}", "If-Match": etag},
    )
    assert r_put2.status_code == 200

    # Status
    r_status = client.get(f"/api/cloud/parties/{pid}/status", headers={"Authorization": f"Bearer {token}"})
    assert r_status.status_code == 200
    assert r_status.json().get("partieId") == pid

    # List by playerId
    r_list = client.get(
        "/api/cloud/parties",
        params={"playerId": "player-123"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r_list.status_code == 200
    items = r_list.json()
    assert any(it.get("partieId") == pid for it in items)

    # Delete
    r_del = client.delete(f"/api/cloud/parties/{pid}", headers={"Authorization": f"Bearer {token}"})
    assert r_del.status_code == 200

    # 404 after delete
    r_get_404 = client.get(f"/api/cloud/parties/{pid}", headers={"Authorization": f"Bearer {token}"})
    assert r_get_404.status_code == 404


def test_put_validations_and_etag_enforced(tmp_path, monkeypatch):
    monkeypatch.setenv("CLOUD_STORAGE_DIR", str(tmp_path))
    monkeypatch.setenv("SECRET_KEY", "change-this-secret")
    # Enforce conditional writes globally
    monkeypatch.setenv("REQUIRE_CONDITIONAL_WRITES", "1")

    client = TestClient(app)
    token = _make_jwt()
    pid = "partie-2"

    # Creation must provide If-None-Match: *
    r_bad_create = client.put(
        f"/api/cloud/parties/{pid}",
        json=_payload(),
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r_bad_create.status_code == 428

    r_create = client.put(
        f"/api/cloud/parties/{pid}",
        json=_payload(),
        headers={"Authorization": f"Bearer {token}", "If-None-Match": "*"},
    )
    assert r_create.status_code == 200

    # Update without If-Match should fail (since enforced)
    r_missing_if_match = client.put(
        f"/api/cloud/parties/{pid}",
        json=_payload(meta={"name": "x"}),
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r_missing_if_match.status_code == 428

    # With wrong ETag -> 412
    # Get etag
    r_get = client.get(f"/api/cloud/parties/{pid}", headers={"Authorization": f"Bearer {token}"})
    etag = r_get.headers.get("ETag")
    assert etag
    wrong = '"deadbeef"'
    r_precond_failed = client.put(
        f"/api/cloud/parties/{pid}",
        json=_payload(meta={"name": "y"}),
        headers={"Authorization": f"Bearer {token}", "If-Match": wrong},
    )
    assert r_precond_failed.status_code == 412


def test_put_metadata_and_snapshot_constraints(tmp_path, monkeypatch):
    monkeypatch.setenv("CLOUD_STORAGE_DIR", str(tmp_path))
    monkeypatch.setenv("SECRET_KEY", "change-this-secret")

    client = TestClient(app)
    token = _make_jwt()
    pid = "partie-3"

    # Missing metadata field
    bad_meta = {"name": "A", "gameMode": "classic", "gameVersion": "1.0.0"}  # no playerId
    r_meta = client.put(
        f"/api/cloud/parties/{pid}",
        json={"snapshot": {"snapshotSchemaVersion": 1}, "metadata": bad_meta},
        headers={"Authorization": f"Bearer {token}", "If-None-Match": "*"},
    )
    assert r_meta.status_code == 422

    # Snapshot too large
    huge = {"snapshotSchemaVersion": 1, "data": "x" * (300 * 1024)}
    r_large = client.put(
        f"/api/cloud/parties/{pid}",
        json={"snapshot": huge, "metadata": {"name": "A", "gameMode": "classic", "gameVersion": "1.0.0", "playerId": "p"}},
        headers={"Authorization": f"Bearer {token}", "If-None-Match": "*"},
    )
    assert r_large.status_code in (413, 422)  # depending on json dumps size rounding

    # Future schema version rejected
    future = {"snapshotSchemaVersion": 999}
    r_schema = client.put(
        f"/api/cloud/parties/{pid}",
        json={"snapshot": future, "metadata": {"name": "B", "gameMode": "classic", "gameVersion": "1.0.0", "playerId": "p"}},
        headers={"Authorization": f"Bearer {token}", "If-None-Match": "*"},
    )
    assert r_schema.status_code == 422


def test_ownership_forbidden_on_update_by_other_user(tmp_path, monkeypatch):
    monkeypatch.setenv("CLOUD_STORAGE_DIR", str(tmp_path))
    monkeypatch.setenv("SECRET_KEY", "change-this-secret")

    client = TestClient(app)
    pid = "partie-4"

    t_owner = _make_jwt(player_uid=str(uuid.uuid4()))
    t_other = _make_jwt(player_uid=str(uuid.uuid4()))

    # Create by owner
    r_create = client.put(
        f"/api/cloud/parties/{pid}",
        json=_payload(meta={"playerId": "owner-player"}),
        headers={"Authorization": f"Bearer {t_owner}", "If-None-Match": "*"},
    )
    assert r_create.status_code == 200

    # Update by other -> 403
    r_update = client.put(
        f"/api/cloud/parties/{pid}",
        json=_payload(meta={"name": "mut"}),
        headers={"Authorization": f"Bearer {t_other}", "If-Match": r_create.headers.get("ETag", '"x"')},
    )
    assert r_update.status_code == 403

    # Delete by other -> 403
    r_del = client.delete(f"/api/cloud/parties/{pid}", headers={"Authorization": f"Bearer {t_other}"})
    assert r_del.status_code == 403

    # Delete by owner -> 200
    r_del_ok = client.delete(f"/api/cloud/parties/{pid}", headers={"Authorization": f"Bearer {t_owner}"})
    assert r_del_ok.status_code == 200
