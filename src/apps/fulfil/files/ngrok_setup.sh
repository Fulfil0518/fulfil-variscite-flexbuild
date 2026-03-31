#!/usr/bin/env bash
set -euo pipefail

# Simple ngrok setup script for Debian/Ubuntu-like systems.
# Usage:
#   sudo ./setup_ngrok.sh
#
# Optionally override the token via env:
#   NGROK_AUTHTOKEN="your_token" sudo ./setup_ngrok.sh

NGROK_CONFIG_PATH="/etc/ngrok/ngrok.yml"
NGROK_APT_LIST="/etc/apt/sources.list.d/ngrok.list"
NGROK_KEY_PATH="/etc/apt/trusted.gpg.d/ngrok.asc"
if [ "$(id -u)" -ne 0 ]; then
  echo "This script needs to run as root. Try: sudo $0"
  exit 1
fi

echo "[1/5] Installing/ensuring ngrok apt repo and package"

# Add ngrok GPG key (idempotent: overwrite same file)
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | tee "${NGROK_KEY_PATH}" >/dev/null

# Add ngrok apt source (idempotent: overwrite same file)
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  | tee "${NGROK_APT_LIST}" >/dev/null

apt update
apt install -y ngrok


echo "[2/5] Copy ngrok service config to ${NGROK_CONFIG_PATH}"

mkdir -p "$(dirname "${NGROK_CONFIG_PATH}")"
cp /opt/fulfil/ngrok.yml "${NGROK_CONFIG_PATH}"


echo "[3/5] Installing ngrok as a service (idempotent)"

if systemctl is-active --quiet ngrok; then
  echo "ngrok systemd service already installed, skipping ngrok service install"
else
  ngrok service install --config="${NGROK_CONFIG_PATH}"
fi

echo "[4/5] Adding location guard to ngrok service"

install -m 0755 /opt/fulfil/ngrok-location-check.sh /usr/local/sbin/ngrok-location-check.sh

mkdir -p /etc/systemd/system/ngrok.service.d
cat > /etc/systemd/system/ngrok.service.d/location-guard.conf <<'EOF'
[Service]
ExecCondition=/usr/local/sbin/ngrok-location-check.sh
Restart=on-failure
RestartSec=30
EOF

systemctl daemon-reload

echo "[5/5] Starting ngrok service"

ngrok service start || true

echo "Waiting a few seconds for tunnels to come up..."
sleep 5

echo
echo "Querying local ngrok API for SSH tunnel..."

if curl -s http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then
  echo "ngrok is up!"
else
  echo "Could not reach ngrok local API at http://127.0.0.1:4040."
  echo "Service may still be running; check with: systemctl status ngrok"
fi

echo
echo "Done."