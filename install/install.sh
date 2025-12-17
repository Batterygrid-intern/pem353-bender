#!/usr/bin/env bash
set -euo pipefail

APP_NAME="pem353"
APP_USER="pem353"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==========================================="
echo "PEM353 Service Installation"
echo "==========================================="
echo ""

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root (use sudo)" >&2
  exit 1
fi

# Stop service if running
if systemctl is-active --quiet "${APP_NAME}.service" 2>/dev/null; then
  echo "[1/8] Stopping existing service..."
  systemctl stop "${APP_NAME}.service"
else
  echo "[1/8] No existing service found"
fi

# Create user
echo ""
echo "[2/8] Creating service user: ${APP_USER}"
if ! id -u "$APP_USER" &>/dev/null; then
  useradd --system --no-create-home --shell /usr/sbin/nologin "$APP_USER"
  echo "  ✓ User created"
else
  echo "  ✓ User already exists"
fi

# Add to dialout group for serial port access
echo ""
echo "[3/8] Adding user to dialout group..."
usermod -a -G dialout "$APP_USER" 2>/dev/null || true
echo "  ✓ Added to dialout group"

# Install binary
echo ""
echo "[4/8] Installing binary to /usr/local/bin..."
cp "$SCRIPT_DIR/bin/${APP_NAME}" /usr/local/bin/
chmod 755 "/usr/local/bin/${APP_NAME}"

# Grant capability for port 502
if command -v setcap &>/dev/null; then
  setcap 'cap_net_bind_service=+ep' "/usr/local/bin/${APP_NAME}"
  echo "  ✓ Port 502 capability granted"
fi

# Install libraries
echo ""
echo "[5/8] Installing libraries to /opt/${APP_NAME}/lib..."
mkdir -p "/opt/${APP_NAME}/lib"
if [ -d "$SCRIPT_DIR/lib" ] && [ "$(ls -A "$SCRIPT_DIR/lib" 2>/dev/null)" ]; then
  cp -P "$SCRIPT_DIR/lib/"* "/opt/${APP_NAME}/lib/"
  ldconfig "/opt/${APP_NAME}/lib"
  echo "  ✓ Libraries installed"
else
  echo "  ⚠ No libraries to install"
fi

# Install config
echo ""
echo "[6/8] Setting up configuration..."
mkdir -p /etc/${APP_NAME}/configs
if [[ ! -f "/etc/${APP_NAME}/configs/pemConfigs.json" ]]; then
  if [[ -f "$SCRIPT_DIR/pemConfigs.json" ]]; then
    cp "$SCRIPT_DIR/pemConfigs.json" "/etc/${APP_NAME}/configs/pemConfigs.json"
    chown "${APP_USER}:${APP_USER}" "/etc/${APP_NAME}/configs/pemConfigs.json"
    chmod 644 "/etc/${APP_NAME}/configs/pemConfigs.json"
    echo "  ✓ Config installed"
  else
    echo "  ⚠ No config file found in package"
  fi
else
  echo "  ✓ Existing config preserved"
fi

# Create working directory
echo ""
echo "[7/9] Creating working directory..."
mkdir -p "/var/lib/${APP_NAME}"
chown "${APP_USER}:${APP_USER}" "/var/lib/${APP_NAME}"
echo "  ✓ Working directory ready"

# Create log directory
echo ""
echo "[8/9] Creating log directory..."
mkdir -p "/var/log/${APP_NAME}"
chown "${APP_USER}:${APP_USER}" "/var/log/${APP_NAME}"
chmod 755 "/var/log/${APP_NAME}"
echo "  ✓ Log directory ready"

# Install systemd service
echo ""
echo "[9/9] Installing systemd service..."
if [[ -f "$SCRIPT_DIR/${APP_NAME}.service" ]]; then
  cp "$SCRIPT_DIR/${APP_NAME}.service" "/etc/systemd/system/${APP_NAME}.service"
  systemctl daemon-reload
  systemctl enable "${APP_NAME}.service"
  systemctl start "${APP_NAME}.service"
  echo "  ✓ Service installed and started"
else
  echo "  ✗ ERROR: Service file not found" >&2
  exit 1
fi

echo ""
echo "==========================================="
echo "✓ Installation complete!"
echo "==========================================="
echo ""
echo "Service status:"
systemctl status "${APP_NAME}.service" --no-pager || true
echo ""
echo "Useful commands:"
echo "  sudo systemctl status ${APP_NAME}    - Check status"
echo "  sudo systemctl restart ${APP_NAME}   - Restart service"
echo "  sudo journalctl -u ${APP_NAME} -f    - View live logs"
echo "  cat /var/log/${APP_NAME}/*.txt       - View log files"
