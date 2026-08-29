from __future__ import annotations

import argparse
import os
import secrets
import sqlite3
from datetime import timedelta

from .database import Database
from .security import hash_password, iso_utc, utc_now
from .uuid7 import uuid7


def bootstrap_admin(username: str, password: str) -> str:
    database = Database(os.environ.get("CHRONOFLOW_DB", "./data/chronoflow.db"))
    user_id = uuid7()
    now = iso_utc()
    code = secrets.token_urlsafe(24)
    with database.connect() as connection:
        if connection.execute("SELECT 1 FROM users WHERE username = ?", (username,)).fetchone():
            raise SystemExit(f"Username {username!r} already exists")
        connection.execute(
            "INSERT INTO users (id, username, password_hash, role, created_at, updated_at) "
            "VALUES (?, ?, ?, 'admin', ?, ?)",
            (user_id, username, hash_password(password), now, now),
        )
        connection.execute(
            "INSERT INTO invites (code, created_by, expires_at, created_at) VALUES (?, ?, ?, ?)",
            (code, user_id, iso_utc(utc_now() + timedelta(days=7)), now),
        )
    return code


def main() -> None:
    parser = argparse.ArgumentParser(description="Chronoflow server administration")
    commands = parser.add_subparsers(dest="command", required=True)
    admin = commands.add_parser("bootstrap-admin")
    admin.add_argument("--username", required=True)
    admin.add_argument("--password-env", default="CHRONOFLOW_ADMIN_PASSWORD")
    args = parser.parse_args()
    if args.command == "bootstrap-admin":
        password = os.environ.get(args.password_env)
        if not password or len(password) < 10:
            raise SystemExit(f"{args.password_env} must contain at least 10 characters")
        print(bootstrap_admin(args.username, password))


if __name__ == "__main__":
    main()
