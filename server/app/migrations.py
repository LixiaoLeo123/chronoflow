from __future__ import annotations

import sqlite3
from pathlib import Path


def migration_files() -> list[Path]:
    migrations = Path(__file__).resolve().parents[1] / "migrations"
    return sorted(migrations.glob("*.sql"))


def run_migrations(connection: sqlite3.Connection) -> list[str]:
    connection.execute(
        "CREATE TABLE IF NOT EXISTS schema_migrations ("
        "version TEXT PRIMARY KEY, applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)"
    )
    applied: list[str] = []
    for path in migration_files():
        version = path.stem
        already = connection.execute(
            "SELECT 1 FROM schema_migrations WHERE version = ?", (version,)
        ).fetchone()
        if already:
            continue
        connection.executescript(path.read_text(encoding="utf-8"))
        connection.execute("INSERT INTO schema_migrations (version) VALUES (?)", (version,))
        applied.append(version)
    connection.commit()
    return applied
