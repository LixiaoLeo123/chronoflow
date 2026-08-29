# Chronoflow sync server

FastAPI service backed by SQLite in WAL mode. Authentication uses Argon2 and short-lived JWT access tokens. Account data is scoped at every query, and `/v1/sync` performs timestamp-based last-write-wins with tombstones.

## Run locally

```bash
python3 -m venv .venv
.venv/bin/pip install -e '.[test]'
CHRONOFLOW_JWT_SECRET=$(openssl rand -hex 32) .venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
```

## Account administration

The first account is bootstrapped as an administrator. Sign in with that account, open **Settings → Generate invitation code**, and share the one-time code with the next user. You can also call the authenticated endpoint:

```bash
curl -X POST 'https://javamc.top:9443/v1/admin/invites?days_valid=7' \
  -H 'Authorization: Bearer ACCESS_TOKEN'
```

## Tests

```bash
.venv/bin/pytest
```
