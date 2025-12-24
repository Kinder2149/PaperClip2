import os
import json
import importlib
from datetime import datetime, timezone

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient


def build_app_with_cloud_dir(tmp_dir: str, api_key: str = "test-key") -> TestClient:
    # Configure environment for router module
    os.environ["CLOUD_STORAGE_DIR"] = tmp_dir
    os.environ["API_KEY"] = api_key

    # Reload router to pick up new env values
    from app.routes import cloud as cloud_module
    importlib.reload(cloud_module)

    app = FastAPI()
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


def auth_headers(api_key: str = "test-key"):
    return {"X-Authorization": f"Bearer {api_key}"}


def test_list_zero_parties_returns_empty(tmp_path):
    client = build_app_with_cloud_dir(tmp_path.as_posix())
    resp = client.get("/api/cloud/parties", params={"playerId": "playerA"}, headers=auth_headers())
    assert resp.status_code == 200
    assert resp.json() == []


def test_list_single_partie(tmp_path):
    client = build_app_with_cloud_dir(tmp_path.as_posix())
    write_partie_file(tmp_path.as_posix(), "p1", "playerA", name="Run A", gameMode="classic", gameVersion="1.0.0")

    resp = client.get("/api/cloud/parties", params={"playerId": "playerA"}, headers=auth_headers())
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
    write_partie_file(tmp_path.as_posix(), "p1", "playerA", name="A1")
    write_partie_file(tmp_path.as_posix(), "p2", "playerA", name="A2")
    write_partie_file(tmp_path.as_posix(), "p3", "playerB", name="B1")

    resp_a = client.get("/api/cloud/parties", params={"playerId": "playerA"}, headers=auth_headers())
    assert resp_a.status_code == 200
    data_a = resp_a.json()
    assert sorted([d["partieId"] for d in data_a]) == ["p1", "p2"]

    resp_b = client.get("/api/cloud/parties", params={"playerId": "playerB"}, headers=auth_headers())
    assert resp_b.status_code == 200
    data_b = resp_b.json()
    assert [d["partieId"] for d in data_b] == ["p3"]


def test_lists_cloud_only_party(tmp_path):
    # cloud-only means present in cloud storage regardless of any local state
    client = build_app_with_cloud_dir(tmp_path.as_posix())
    write_partie_file(tmp_path.as_posix(), "cloudOnly1", "playerA", name=None, gameMode=None, gameVersion=None)

    resp = client.get("/api/cloud/parties", params={"playerId": "playerA"}, headers=auth_headers())
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 1
    item = data[0]
    assert item["partieId"] == "cloudOnly1"
    assert item["playerId"] == "playerA"
