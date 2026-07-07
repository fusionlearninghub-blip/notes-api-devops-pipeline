from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health():
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "healthy"


def test_create_and_get_note():
    resp = client.post("/notes", json={"title": "Test", "body": "Body text"})
    assert resp.status_code == 201
    note = resp.json()
    assert note["title"] == "Test"

    resp2 = client.get(f"/notes/{note['id']}")
    assert resp2.status_code == 200
    assert resp2.json()["id"] == note["id"]


def test_get_missing_note_returns_404():
    resp = client.get("/notes/does-not-exist")
    assert resp.status_code == 404


def test_list_notes():
    client.post("/notes", json={"title": "A", "body": "B"})
    resp = client.get("/notes")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_delete_note():
    created = client.post("/notes", json={"title": "X", "body": "Y"}).json()
    resp = client.delete(f"/notes/{created['id']}")
    assert resp.status_code == 204
    assert client.get(f"/notes/{created['id']}").status_code == 404
