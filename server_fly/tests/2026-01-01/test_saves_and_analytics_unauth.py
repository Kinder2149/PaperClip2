import os
import uuid
import requests

BASE_URL = os.getenv("BACKEND_BASE_URL", "https://server-fly-paperclip.fly.dev").rstrip("/")


def test_put_save_unauthorized_without_bearer():
    pid = str(uuid.uuid4())
    r = requests.put(
        f"{BASE_URL}/saves/{pid}",
        json={"snapshot": {"ok": True}},
        timeout=10,
    )
    assert r.status_code == 401


def test_get_latest_save_unauthorized_without_bearer():
    pid = str(uuid.uuid4())
    r = requests.get(f"{BASE_URL}/saves/{pid}/latest", timeout=10)
    assert r.status_code == 401


def test_analytics_unauthorized_without_bearer():
    r = requests.post(
        f"{BASE_URL}/analytics/events",
        json={"name": "test", "properties": {"k": "v"}},
        timeout=10,
    )
    assert r.status_code == 401
