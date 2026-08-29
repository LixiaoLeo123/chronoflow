from __future__ import annotations

import os
import secrets
import sqlite3
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

from fastapi import Depends, FastAPI, HTTPException, Query, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field

from .database import Database
from .schemas import Credentials, RefreshRequest, Registration, SyncRequest
from .security import (
    create_access_token,
    decode_access_token,
    generate_refresh_token,
    hash_password,
    hash_refresh_token,
    iso_utc,
    utc_now,
    verify_password,
)
from .uuid7 import uuid7


JWT_SECRET = os.environ.get("CHRONOFLOW_JWT_SECRET", secrets.token_urlsafe(48))
DATABASE_PATH = Path(os.environ.get("CHRONOFLOW_DB", "./data/chronoflow.db"))
ACCESS_MINUTES = int(os.environ.get("CHRONOFLOW_ACCESS_MINUTES", "30"))
REFRESH_DAYS = int(os.environ.get("CHRONOFLOW_REFRESH_DAYS", "30"))

app = FastAPI(title="Chronoflow Sync API", version="v1")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        origin.strip()
        for origin in os.environ.get("CHRONOFLOW_CORS", "*").split(",")
        if origin.strip()
    ] or ["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
database = Database(DATABASE_PATH) if os.environ.get("CHRONOFLOW_DB") else Database(DATABASE_PATH)
bearer = HTTPBearer(auto_error=False)


class InviteResponse(BaseModel):
    code: str
    expiresAt: str


class TokenPair(BaseModel):
    accessToken: str
    refreshToken: str
    user: dict[str, str | int]


def parse_datetime(value: str, field: str) -> datetime:
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"Invalid {field}") from exc
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def get_connection():
    with database.connect() as connection:
        yield connection


def issue_tokens(connection: sqlite3.Connection, user: sqlite3.Row) -> TokenPair:
    refresh, refresh_hash = generate_refresh_token()
    expires = utc_now() + timedelta(days=REFRESH_DAYS)
    connection.execute(
        "INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at, created_at) "
        "VALUES (?, ?, ?, ?, ?)",
        (uuid7(), user["id"], refresh_hash, iso_utc(expires), iso_utc()),
    )
    return TokenPair(
        accessToken=create_access_token(user["id"], user["role"], JWT_SECRET, ACCESS_MINUTES),
        refreshToken=refresh,
        user={"id": user["id"], "username": user["username"], "role": user["role"]},
    )


def require_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    connection: sqlite3.Connection = Depends(get_connection),
) -> Any:
    if credentials is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Missing bearer token")
    try:
        payload = decode_access_token(credentials.credentials, JWT_SECRET)
    except Exception as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid access token") from exc
    user = connection.execute("SELECT * FROM users WHERE id = ?", (payload["sub"],)).fetchone()
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Account not found")
    return user, connection


def require_admin(user: Any = Depends(require_user)) -> Any:
    current, connection = user
    if current["role"] != "admin":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Administrator access required")
    return current, connection


@app.get("/healthz")
def healthz(connection: sqlite3.Connection = Depends(get_connection)) -> dict[str, str]:
    connection.execute("SELECT 1")
    return {"status": "ok"}


@app.post("/v1/auth/register", response_model=TokenPair, status_code=201)
def register(request: Registration, connection: sqlite3.Connection = Depends(get_connection)) -> TokenPair:
    now = utc_now()
    invite = connection.execute(
        "SELECT * FROM invites WHERE code = ? AND used_by IS NULL AND expires_at > ?",
        (request.invitationCode, iso_utc(now)),
    ).fetchone()
    if invite is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Invalid or expired invitation")
    if connection.execute("SELECT 1 FROM users WHERE username = ?", (request.username,)).fetchone():
        raise HTTPException(status.HTTP_409_CONFLICT, "Username already exists")

    user_id = uuid7()
    timestamp = iso_utc(now)
    try:
        connection.execute(
            "INSERT INTO users (id, username, password_hash, role, created_at, updated_at) "
            "VALUES (?, ?, ?, 'user', ?, ?)",
            (user_id, request.username, hash_password(request.password), timestamp, timestamp),
        )
        connection.execute(
            "UPDATE invites SET used_by = ?, used_at = ? WHERE code = ?",
            (user_id, timestamp, request.invitationCode),
        )
    except sqlite3.IntegrityError as exc:
        raise HTTPException(status.HTTP_409_CONFLICT, "Registration conflict") from exc
    return issue_tokens(connection, connection.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone())


@app.post("/v1/auth/login", response_model=TokenPair)
def login(request: Credentials, connection: sqlite3.Connection = Depends(get_connection)) -> TokenPair:
    user = connection.execute("SELECT * FROM users WHERE username = ?", (request.username,)).fetchone()
    if user is None or not verify_password(request.password, user["password_hash"]):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid username or password")
    return issue_tokens(connection, user)


@app.post("/v1/auth/refresh", response_model=TokenPair)
def refresh(request: RefreshRequest, connection: sqlite3.Connection = Depends(get_connection)) -> TokenPair:
    token_hash = hash_refresh_token(request.refreshToken)
    row = connection.execute(
        "SELECT rt.id AS token_id, rt.expires_at, rt.revoked_at, u.* FROM refresh_tokens rt "
        "JOIN users u ON u.id = rt.user_id WHERE rt.token_hash = ?",
        (token_hash,),
    ).fetchone()
    if row is None or row["revoked_at"] is not None or parse_datetime(row["expires_at"], "expiry") <= utc_now():
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid refresh token")
    connection.execute(
        "UPDATE refresh_tokens SET revoked_at = ? WHERE id = ?", (iso_utc(), row["token_id"])
    )
    return issue_tokens(connection, row)


@app.get("/v1/me")
def me(user: Any = Depends(require_user)) -> dict[str, str]:
    current, _ = user
    return {"id": current["id"], "username": current["username"], "role": current["role"]}


def upsert_activity(connection: sqlite3.Connection, account_id: str, item) -> bool:
    incoming_updated = parse_datetime(item.updatedAt, "updatedAt")
    existing = connection.execute(
        "SELECT updated_at FROM activities WHERE id = ? AND account_id = ?",
        (item.id, account_id),
    ).fetchone()
    if existing and parse_datetime(existing["updated_at"], "updatedAt") >= incoming_updated:
        return False
    if item.accountId != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cross-account data rejected")
    if not item.deleted:
        conflict = connection.execute(
            "SELECT 1 FROM activities WHERE account_id = ? AND color = ? "
            "AND deleted = 0 AND archived = 0 AND id != ?",
            (account_id, item.color, item.id),
        ).fetchone()
        if conflict and not item.archived:
            raise HTTPException(status.HTTP_409_CONFLICT, "Activity color already in use")
    connection.execute(
        "INSERT INTO activities (id, account_id, name, color, archived, deleted, created_at, updated_at) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?) "
        "ON CONFLICT(id) DO UPDATE SET name=excluded.name, color=excluded.color, "
        "archived=excluded.archived, deleted=excluded.deleted, updated_at=excluded.updated_at",
        (
            item.id,
            account_id,
            item.name,
            item.color,
            int(item.archived),
            int(item.deleted),
            parse_datetime(item.createdAt, "createdAt").isoformat(),
            incoming_updated.isoformat(),
        ),
    )
    return True


def upsert_time_block(connection: sqlite3.Connection, account_id: str, item) -> bool:
    incoming_updated = parse_datetime(item.updatedAt, "updatedAt")
    existing = connection.execute(
        "SELECT updated_at FROM time_blocks WHERE id = ? AND account_id = ?",
        (item.id, account_id),
    ).fetchone()
    if existing and parse_datetime(existing["updated_at"], "updatedAt") >= incoming_updated:
        return False
    if item.accountId != account_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cross-account data rejected")
    activity = connection.execute(
        "SELECT 1 FROM activities WHERE id = ? AND account_id = ?",
        (item.activityId, account_id),
    ).fetchone()
    if activity is None:
        foreign = connection.execute(
            "SELECT 1 FROM activities WHERE id = ?", (item.activityId,)
        ).fetchone()
        if foreign:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Cross-account data rejected")
        raise HTTPException(status.HTTP_409_CONFLICT, "Unknown activity")
    start = parse_datetime(item.start, "start")
    end = parse_datetime(item.end, "end")
    if end <= start:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Block end must be after start")
    overlap = connection.execute(
        "SELECT 1 FROM time_blocks WHERE account_id = ? AND id != ? "
        "AND start_at < ? AND end_at > ? LIMIT 1",
        (account_id, item.id, end.isoformat(), start.isoformat()),
    ).fetchone()
    if overlap and not item.deleted:
        raise HTTPException(status.HTTP_409_CONFLICT, "Time blocks overlap")
    connection.execute(
        "INSERT INTO time_blocks "
        "(id, account_id, activity_id, kind, start_at, end_at, status, deleted, created_at, updated_at) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) "
        "ON CONFLICT(id) DO UPDATE SET activity_id=excluded.activity_id, kind=excluded.kind, "
        "start_at=excluded.start_at, end_at=excluded.end_at, status=excluded.status, "
        "deleted=excluded.deleted, updated_at=excluded.updated_at",
        (
            item.id,
            account_id,
            item.activityId,
            item.kind,
            start.isoformat(),
            end.isoformat(),
        item.status,
        int(item.deleted),
            parse_datetime(item.createdAt, "createdAt").isoformat(),
            incoming_updated.isoformat(),
        ),
    )
    return True


@app.post("/v1/sync")
def sync(
    request: SyncRequest,
    user: Any = Depends(require_user),
) -> dict[str, object]:
    current, connection = user
    account_id = current["id"]
    changed = False
    try:
        for item in request.activities:
            changed = upsert_activity(connection, account_id, item) or changed
        for item in request.timeBlocks:
            changed = upsert_time_block(connection, account_id, item) or changed
    except sqlite3.IntegrityError as exc:
        raise HTTPException(status.HTTP_409_CONFLICT, "Sync conflict") from exc

    since = parse_datetime(request.since, "since") if request.since else datetime.min.replace(tzinfo=timezone.utc)
    activity_rows = connection.execute(
        "SELECT * FROM activities WHERE account_id = ? AND updated_at > ? ORDER BY updated_at",
        (account_id, since.isoformat()),
    ).fetchall()
    block_rows = connection.execute(
        "SELECT * FROM time_blocks WHERE account_id = ? AND updated_at > ? ORDER BY updated_at",
        (account_id, since.isoformat()),
    ).fetchall()

    cursor = iso_utc()
    if activity_rows or block_rows:
        timestamps = [
            rows[-1]["updated_at"]
            for rows in (activity_rows, block_rows)
            if rows
        ]
        cursor = max(timestamps)
    return {
        "accepted": changed,
        "syncCursor": cursor,
        "serverTime": iso_utc(),
        "activities": [
            {
                "id": row["id"],
                "accountId": row["account_id"],
                "name": row["name"],
                "color": row["color"],
                "archived": bool(row["archived"]),
                "deleted": bool(row["deleted"]),
                "createdAt": row["created_at"],
                "updatedAt": row["updated_at"],
            }
            for row in activity_rows
        ],
        "timeBlocks": [
            {
                "id": row["id"],
                "accountId": row["account_id"],
                "activityId": row["activity_id"],
                "kind": row["kind"],
                "start": row["start_at"],
                "end": row["end_at"],
                "status": row["status"],
                "deleted": bool(row["deleted"]),
                "createdAt": row["created_at"],
                "updatedAt": row["updated_at"],
            }
            for row in block_rows
        ],
    }


@app.post("/v1/admin/invites", response_model=InviteResponse, status_code=201)
def create_invite(
    days_valid: int = Query(default=7, ge=1, le=365),
    user: Any = Depends(require_admin),
) -> InviteResponse:
    _, connection = user
    code = secrets.token_urlsafe(24)
    expires = utc_now() + timedelta(days=days_valid)
    connection.execute(
        "INSERT INTO invites (code, created_by, expires_at, created_at) VALUES (?, ?, ?, ?)",
        (code, user[0]["id"], iso_utc(expires), iso_utc()),
    )
    return InviteResponse(code=code, expiresAt=iso_utc(expires))
