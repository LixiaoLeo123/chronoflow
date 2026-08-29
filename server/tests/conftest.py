from __future__ import annotations

from pathlib import Path

import pytest

from app.database import Database
from app.main import app


@pytest.fixture
def database(tmp_path: Path) -> Database:
    return Database(tmp_path / "chronoflow.sqlite")


@pytest.fixture
def client(database, monkeypatch):
    from fastapi.testclient import TestClient
    import app.main as main

    monkeypatch.setattr(main, "database", database)
    monkeypatch.setattr(main, "JWT_SECRET", "test-secret")
    with TestClient(app) as test_client:
        yield test_client
