import os
import requests

BASE_URL = os.getenv("BACKEND_BASE_URL", "https://server-fly-paperclip.fly.dev").rstrip("/")


def test_health_public_ok():
    r = requests.get(f"{BASE_URL}/health", timeout=10)
    assert r.status_code == 200


def test_health_auth_unauthorized_without_bearer():
    r = requests.get(f"{BASE_URL}/health/auth", timeout=10)
    assert r.status_code == 401


def test_db_health_unauthorized_without_bearer():
    r = requests.get(f"{BASE_URL}/db/health", timeout=10)
    assert r.status_code == 401
