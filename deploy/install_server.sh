#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo ./deploy/install_server.sh" >&2
  exit 1
fi

if ! command -v python3 >/dev/null || ! command -v openssl >/dev/null; then
  echo "python3 and openssl are required" >&2
  exit 1
fi

if systemctl list-unit-files chronoflow.service --no-legend 2>/dev/null | grep -q .; then
  systemctl stop chronoflow.service
fi

if ss -ltnH 'sport = :9443' | grep -q .; then
  echo "TCP port 9443 is already in use; refusing to modify existing services." >&2
  exit 1
fi

APP_DIR=/opt/chronoflow
DATA_DIR="$APP_DIR/data"
TLS_DIR="$APP_DIR/tls"
SERVICE_USER=chronoflow

if ! id "$SERVICE_USER" &>/dev/null; then
  useradd --system --home-dir "$APP_DIR" --shell /usr/sbin/nologin "$SERVICE_USER"
fi

install -d -o "$SERVICE_USER" -g "$SERVICE_USER" -m 0750 "$APP_DIR" "$DATA_DIR" "$TLS_DIR"
rsync -a --delete "$(dirname "$0")/../server/app/" "$APP_DIR/app/"
rsync -a --delete "$(dirname "$0")/../server/migrations/" "$APP_DIR/migrations/"
install -m 0750 -o "$SERVICE_USER" -g "$SERVICE_USER" \
  "$(dirname "$0")/../tools/backup.py" "$APP_DIR/backup.py"
install -m 0640 -o "$SERVICE_USER" -g "$SERVICE_USER" \
  "$(dirname "$0")/../server/requirements.txt" "$APP_DIR/requirements.txt"

if [[ ! -d "$APP_DIR/venv" ]]; then
  python3 -m venv "$APP_DIR/venv"
fi
"$APP_DIR/venv/bin/pip" install --upgrade pip
"$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"

if [[ ! -s "$TLS_DIR/chronoflow.key" || ! -s "$TLS_DIR/chronoflow.crt" ]]; then
  openssl req -x509 -newkey rsa:3072 -sha256 -days 3650 -nodes \
    -keyout "$TLS_DIR/chronoflow.key" -out "$TLS_DIR/chronoflow.crt" \
    -subj "/CN=javamc.top/O=Chronoflow" \
    -addext "subjectAltName=DNS:javamc.top"
fi
chown "$SERVICE_USER:$SERVICE_USER" "$TLS_DIR"/*
chmod 0600 "$TLS_DIR/chronoflow.key"
chmod 0644 "$TLS_DIR/chronoflow.crt"

if [[ ! -s "$APP_DIR/.env" ]]; then
  JWT_SECRET=$(openssl rand -hex 32)
  cat > "$APP_DIR/.env" <<EOF
CHRONOFLOW_DB=$DATA_DIR/chronoflow.db
CHRONOFLOW_JWT_SECRET=$JWT_SECRET
CHRONOFLOW_CORS=
EOF
  chown root:"$SERVICE_USER" "$APP_DIR/.env"
  chmod 0640 "$APP_DIR/.env"
fi

install -m 0644 "$(dirname "$0")/../deploy/systemd/chronoflow.service" /etc/systemd/system/chronoflow.service
install -m 0644 "$(dirname "$0")/../deploy/systemd/chronoflow-backup.service" /etc/systemd/system/chronoflow-backup.service
install -m 0644 "$(dirname "$0")/../deploy/systemd/chronoflow-backup.timer" /etc/systemd/system/chronoflow-backup.timer
systemctl daemon-reload
systemctl enable --now chronoflow-backup.timer
systemctl enable chronoflow.service
systemctl restart chronoflow.service

if [[ -n "${CHRONOFLOW_ADMIN_USERNAME:-}" ]]; then
  (
    cd "$APP_DIR"
    runuser -u "$SERVICE_USER" -- \
      env CHRONOFLOW_DB="$DATA_DIR/chronoflow.db" \
          CHRONOFLOW_ADMIN_PASSWORD="${CHRONOFLOW_ADMIN_PASSWORD:-}" \
      "$APP_DIR/venv/bin/python" -m app.cli bootstrap-admin \
        --username "$CHRONOFLOW_ADMIN_USERNAME"
  )
fi

CERT_SHA=$(openssl x509 -in "$TLS_DIR/chronoflow.crt" -outform DER | openssl dgst -sha256 -binary | od -An -tx1 | tr -d ' \n')
echo "Chronoflow is listening on https://javamc.top:9443"
echo "Certificate SHA-256: $CERT_SHA"
echo "Build Flutter with --dart-define=CHRONOFLOW_CERT_SHA256=$CERT_SHA"
