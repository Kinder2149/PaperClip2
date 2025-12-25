import os
import json
import importlib
from datetime import datetime, timezone

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient


def build_app_with_cloud_dir(tmp_dir: str) -> TestClient:
    # Configure environment for router module
    os.environ["CLOUD_STORAGE_DIR"] = tmp_dir
    # Ensure no API_KEY path (Option A)
    os.environ.pop("API_KEY", None)

    # Reload routers to pick up new env values
    from app.routes import cloud as cloud_module
    from app.routes import auth as auth_module
    importlib.reload(auth_module)
    importlib.reload(cloud_module)

    app = FastAPI()
    app.include_router(auth_module.router)
    app.include_router(cloud_module.router)
    client = TestClient(app)
    return client


def write_partie_file(root: str, partie_id: str, player_id: str, **meta):
    path = os.path.join(root, f"{partie_id}.json")
    now_iso = datetime.now(timezone.utc).isoformat()
    payload = {
        "partieId": partie_id,
        "snapshot": {},
        "metadata": {"playerId": player_id, **meta},
        "remoteVersion": int(datetime.now(timezone.utc).timestamp()),
        "lastPushAt": now_iso,
        "lastPullAt": None,
    }
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False)


def login(client: TestClient, provider_user_id: str) -> str:
    resp = client.post("/api/auth/login", json={"provider": "google", "provider_user_id": provider_user_id})
    assert resp.status_code == 200
    return resp.json()["access_token"]

def put_partie(client: TestClient, token: str, partie_id: str, player_id: str, **meta):
    meta_payload = {
        "name": meta.get("name", "Run"),
        "gameMode": meta.get("gameMode", "classic"),
        "gameVersion": meta.get("gameVersion", "1.0.0"),
        "playerId": player_id,
    }
    body = {"snapshot": {"snapshotSchemaVersion": 1}, "metadata": meta_payload}
    return client.get("/api/cloud/parties") if False else client.put(
        f"/api/cloud/parties/{partie_id}", headers={"Authorization": f"Bearer {token}"}, json=body
    )


def test_list_zero_parties_returns_empty(tmp_path):
    client = build_app_with_cloud_dir(tmp_path.as_posix())
    token = login(client, "playerA")
    resp = client.get("/api/cloud/parties", params={"playerId": "playerA"}, headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json() == []


def test_list_single_partie(tmp_path):
    client = build_app_with_cloud_dir(tmp_path.as_posix())
    token = login(client, "playerA")
    assert put_partie(client, token, "p1", "playerA", name="Run A", gameMode="classic", gameVersion="1.0.0").status_code == 200

    resp = client.get("/api/cloud/parties", params={"playerId": "playerA"}, headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 1
    item = data[0]
    assert item["partieId"] == "p1"
    assert item["playerId"] == "playerA"
    assert item["name"] == "Run A"
    assert item["gameMode"] == "classic"
    assert item["gameVersion"] == "1.0.0"
    assert isinstance(item["remoteVersion"], int)


def test_list_multiple_parties_filtered_by_player(tmp_path):
    client = build_app_with_cloud_dir(tmp_path.as_posix())
    token_a = login(client, "playerA")
    token_b = login(client, "playerB")
    assert put_partie(client, token_a, "p1", "playerA", name="A1").status_code == 200
    assert put_partie(client, token_a, "p2", "playerA", name="A2").status_code == 200
    assert put_partie(client, token_b, "p3", "playerB", name="B1").status_code == 200

    resp_a = client.get("/api/cloud/parties", params={"playerId": "playerA"}, headers={"Authorization": f"Bearer {token_a}"})
    assert resp_a.status_code == 200
    data_a = resp_a.json()
    assert sorted([d["partieId"] for d in data_a]) == ["p1", "p2"]

    resp_b = client.get("/api/cloud/parties", params={"playerId": "playerB"}, headers={"Authorization": f"Bearer {token_b}"})
    assert resp_b.status_code == 200
    data_b = resp_b.json()
    assert [d["partieId"] for d in data_b] == ["p3"]


def test_lists_cloud_only_party(tmp_path):
    # cloud-only means present in cloud storage regardless of any local state
    client = build_app_with_cloud_dir(tmp_path.as_posix())
    token = login(client, "playerA")
    assert put_partie(client, token, "cloudOnly1", "playerA", name="Run", gameMode="classic", gameVersion="1.0.0").status_code == 200

    resp = client.get("/api/cloud/parties", params={"playerId": "playerA"}, headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 1
    item = data[0]
    assert item["partieId"] == "cloudOnly1"
    assert item["playerId"] == "playerA"
