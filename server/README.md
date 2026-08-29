# Chronoflow sync server

FastAPI service backed by SQLite in WAL mode. Authentication uses Argon2 and short-lived JWT access tokens. Account data is scoped at every query, and `/v1/sync` performs timestamp-based last-write-wins with tombstones.

## Run locally

```bash
python3 -m venv .venv
.venv/bin/pip install -e '.[test]'
CHRONOFLOW_JWT_SECRET=$(openssl rand -hex 32) .venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
```

## Tests

```bash
.venv/bin/pytest
```
