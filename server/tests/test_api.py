from __future__ import annotations

import pytest


def create_admin(client):
    from app.main import database
    from app.security import hash_password, iso_utc
    from app.uuid7 import uuid7

    with database.connect() as connection:
        user_id = uuid7()
        now = iso_utc()
        connection.execute(
            "INSERT INTO users (id, username, password_hash, role, created_at, updated_at) "
            "VALUES (?, ?, ?, 'admin', ?, ?)",
            (user_id, "admin", hash_password("administrator-password"), now, now),
        )
        connection.execute(
            "INSERT INTO invites (code, expires_at, created_at) VALUES (?, ?, ?)",
            ("bootstrap", "2099-01-01T00:00:00Z", now),
        )
    response = client.post(
        "/v1/auth/login",
        json={"username": "admin", "password": "administrator-password"},
    )
    assert response.status_code == 200
    return response.json()


def auth_headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_registration_requires_valid_invite(client, monkeypatch):
    from app.main import JWT_SECRET

    token = create_admin(client)["accessToken"]
    monkeypatch.setenv("CHRONOFLOW_JWT_SECRET", JWT_SECRET)
    response = client.post(
        "/v1/admin/invites", headers=auth_headers(token), params={"days_valid": 2}
    )
    assert response.status_code == 201
    code = response.json()["code"]

    denied = client.post(
        "/v1/auth/register",
        json={"username": "nobody", "password": "not-a-real-password", "invitationCode": "bad"},
    )
    assert denied.status_code == 403

    accepted = client.post(
        "/v1/auth/register",
        json={"username": "member", "password": "a-long-password", "invitationCode": code},
    )
    assert accepted.status_code == 201
    reused = client.post(
        "/v1/auth/register",
        json={"username": "again", "password": "a-long-password", "invitationCode": code},
    )
    assert reused.status_code == 403


def test_non_admin_cannot_create_invites(client):
    admin = create_admin(client)
    invite = client.post(
        "/v1/admin/invites", headers=auth_headers(admin["accessToken"])
    ).json()["code"]
    user = client.post(
        "/v1/auth/register",
        json={"username": "member2", "password": "a-long-password", "invitationCode": invite},
    ).json()
    denied = client.post(
        "/v1/admin/invites", headers=auth_headers(user["accessToken"])
    )
    assert denied.status_code == 403


def test_refresh_and_account_scoped_sync(client):
    admin = create_admin(client)
    admin_headers = auth_headers(admin["accessToken"])
    invite = client.post("/v1/admin/invites", headers=admin_headers).json()["code"]
    alice = client.post(
        "/v1/auth/register",
        json={"username": "alice", "password": "a-long-password", "invitationCode": invite},
    ).json()

    refreshed = client.post("/v1/auth/refresh", json={"refreshToken": alice["refreshToken"]})
    assert refreshed.status_code == 200
    assert refreshed.json()["accessToken"]

    activity = {
        "id": "activity-alice-000001",
        "accountId": alice["user"]["id"],
        "name": "Writing",
        "color": 4280391411,
        "archived": False,
        "deleted": False,
        "createdAt": "2026-08-29T00:00:00Z",
        "updatedAt": "2026-08-29T00:00:00Z",
    }
    block = {
        "id": "block-alice-000000001",
        "accountId": alice["user"]["id"],
        "activityId": activity["id"],
        "kind": "focus",
        "start": "2026-08-29T00:00:00Z",
        "end": "2026-08-29T00:25:00Z",
        "status": "completed",
        "deleted": False,
        "createdAt": "2026-08-29T00:00:00Z",
        "updatedAt": "2026-08-29T00:00:00Z",
    }
    first = client.post(
        "/v1/sync",
        headers=auth_headers(alice["accessToken"]),
        json={"activities": [activity], "timeBlocks": [block]},
    )
    assert first.status_code == 200
    assert first.json()["accepted"] is True

    bob = client.post(
        "/v1/auth/register",
        json={
            "username": "bob",
            "password": "a-long-password",
            "invitationCode": client.post(
                "/v1/admin/invites", headers=admin_headers
            ).json()["code"],
        },
    ).json()
    bob_block = block | {"accountId": bob["user"]["id"]}
    rejected = client.post(
        "/v1/sync",
        headers=auth_headers(bob["accessToken"]),
        json={"timeBlocks": [bob_block]},
    )
    assert rejected.status_code == 403


def test_overlap_conflict(client):
    admin = create_admin(client)
    invite = client.post(
        "/v1/admin/invites", headers=auth_headers(admin["accessToken"])
    ).json()["code"]
    user = client.post(
        "/v1/auth/register",
        json={"username": "overlap", "password": "a-long-password", "invitationCode": invite},
    ).json()
    activity = {
        "id": "activity-overlap-00001",
        "accountId": user["user"]["id"],
        "name": "Deep work",
        "color": 1,
        "archived": False,
        "deleted": False,
        "createdAt": "2026-08-29T00:00:00Z",
        "updatedAt": "2026-08-29T00:00:00Z",
    }
    client.post(
        "/v1/sync", headers=auth_headers(user["accessToken"]), json={"activities": [activity]}
    )
    base = {
        "accountId": user["user"]["id"],
        "activityId": activity["id"],
        "kind": "focus",
        "status": "completed",
        "deleted": False,
        "createdAt": "2026-08-29T00:00:00Z",
        "updatedAt": "2026-08-29T00:00:00Z",
    }
    first = base | {"id": "block-overlap-00000001", "start": "2026-08-29T10:00:00Z", "end": "2026-08-29T10:25:00Z"}
    second = base | {"id": "block-overlap-00000002", "start": "2026-08-29T10:20:00Z", "end": "2026-08-29T10:45:00Z"}
    ok = client.post("/v1/sync", headers=auth_headers(user["accessToken"]), json={"timeBlocks": [first]})
    conflict = client.post("/v1/sync", headers=auth_headers(user["accessToken"]), json={"timeBlocks": [second]})
    assert ok.status_code == 200
    assert conflict.status_code == 409


def test_last_write_wins_and_block_tombstones(client):
    admin = create_admin(client)
    invite = client.post(
        "/v1/admin/invites", headers=auth_headers(admin["accessToken"])
    ).json()["code"]
    user = client.post(
        "/v1/auth/register",
        json={"username": "lww", "password": "a-long-password", "invitationCode": invite},
    ).json()
    headers = auth_headers(user["accessToken"])
    activity = {
        "id": "activity-lww-000000001",
        "accountId": user["user"]["id"],
        "name": "Original",
        "color": 7,
        "archived": False,
        "deleted": False,
        "createdAt": "2026-08-29T00:00:00Z",
        "updatedAt": "2026-08-29T00:00:00Z",
    }
    created = client.post("/v1/sync", headers=headers, json={"activities": [activity]})
    assert created.status_code == 200
    stale = activity | {"name": "Stale", "updatedAt": "2026-08-29T00:00:00Z"}
    stale_result = client.post("/v1/sync", headers=headers, json={"activities": [stale]})
    assert stale_result.status_code == 200
    assert stale_result.json()["accepted"] is False
    assert stale_result.json()["activities"][0]["name"] == "Original"

    block = {
        "id": "block-lww-00000000001",
        "accountId": user["user"]["id"],
        "activityId": activity["id"],
        "kind": "focus",
        "start": "2026-08-29T11:00:00Z",
        "end": "2026-08-29T11:25:00Z",
        "status": "completed",
        "deleted": False,
        "createdAt": "2026-08-29T11:00:00Z",
        "updatedAt": "2026-08-29T11:25:00Z",
    }
    block_created = client.post("/v1/sync", headers=headers, json={"timeBlocks": [block]})
    assert block_created.status_code == 200
    tombstone = block | {"deleted": True, "updatedAt": "2026-08-29T11:26:00Z"}
    tombstoned = client.post("/v1/sync", headers=headers, json={"timeBlocks": [tombstone]})
    assert tombstoned.status_code == 200
    assert tombstoned.json()["timeBlocks"][0]["deleted"] is True
