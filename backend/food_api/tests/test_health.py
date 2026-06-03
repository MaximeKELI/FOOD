import pytest


@pytest.mark.django_db
def test_health_ok(api_client):
    res = api_client.get("/health/")
    assert res.status_code == 200
    assert res.json()["status"] == "ok"


@pytest.mark.django_db
def test_api_root(api_client):
    res = api_client.get("/")
    assert res.status_code == 200
    assert "endpoints" in res.json()
