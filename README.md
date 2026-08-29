# Chronoflow

Chronoflow is a local-first Pomodoro and 24-hour timeline app for Android and Linux. SQLite stores every row by account, timestamps are normalized to UTC for persistence, and the UI renders them in the device timezone.

## Repository layout

- `client/` — Flutter client (Material 3, Riverpod, GoRouter, Drift).
- `server/` — FastAPI SQLite/WAL sync API.
- `deploy/` — dedicated non-root systemd deployment on TCP 9443.

## Client

```bash
cd client
dart run build_runner build
flutter test
flutter analyze
flutter build linux --release \
  --dart-define=CHRONOFLOW_API_URL=https://javamc.top:9443 \
  --dart-define=CHRONOFLOW_CERT_SHA256=<CERT_SHA256>
flutter build apk --release \
  --dart-define=CHRONOFLOW_API_URL=https://javamc.top:9443 \
  --dart-define=CHRONOFLOW_CERT_SHA256=<CERT_SHA256>
```

Use `--dart-define=CHRONOFLOW_ALLOW_UNPINNED=true` only for local development against `127.0.0.1`.

## Server

```bash
python3 -m venv .venv
.venv/bin/pip install -e 'server[test]'
.venv/bin/pytest
```

The API exposes `/v1/auth/register`, `/v1/auth/login`, `/v1/auth/refresh`, `/v1/me`, `/v1/sync`, and admin-only `/v1/admin/invites`. Registration rejects missing, reused, and expired invitations.

## Production deployment

The installer creates a dedicated `chronoflow` system account and `/opt/chronoflow`, generates a self-signed `javamc.top` certificate, installs TLS-only uvicorn on port 9443, refuses to start if that port is occupied, and enables a nightly SQLite backup timer. It does not restart or modify nginx.

```bash
sudo CHRONOFLOW_ADMIN_USERNAME=admin \
  CHRONOFLOW_ADMIN_PASSWORD='a-long-admin-password' \
  ./deploy/install_server.sh
```

After deployment, verify with:

```bash
curl --cacert /opt/chronoflow/tls/chronoflow.crt https://javamc.top:9443/healthz
```

## Sync behavior

Rows use UUIDs and millisecond-precision `updatedAt` values. Every sync sends local deltas and receives account-scoped server deltas. Tombstones prevent deletes from being resurrected, and last-write-wins uses server timestamps as the tie-breaker. The current version automatically triggers sync at repository calls through the configured `SyncEngine`; background work can call `SyncEngine.synchronize(accountId)` from Android WorkManager.
