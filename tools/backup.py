from __future__ import annotations

import os
import sqlite3
from datetime import datetime
from pathlib import Path


def backup(database_path: str, output_dir: str) -> Path:
    source = Path(database_path)
    destination_dir = Path(output_dir)
    destination_dir.mkdir(parents=True, exist_ok=True)
    destination = destination_dir / f"chronoflow-{datetime.now():%Y%m%d-%H%M%S}.db"
    with sqlite3.connect(source) as source_connection, sqlite3.connect(destination) as target:
        source_connection.backup(target)
        target.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    return destination


if __name__ == "__main__":
    path = backup(
        os.environ.get("CHRONOFLOW_DB", "/opt/chronoflow/data/chronoflow.db"),
        os.environ.get("CHRONOFLOW_BACKUP_DIR", "/opt/chronoflow/data/backups"),
    )
    print(path)
