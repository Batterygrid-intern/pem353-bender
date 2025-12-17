#!/usr/bin/env bash
set -euo pipefail

APP_NAME="pem353"
APP_USER="pem353"

# Installation paths
INSTALL_ROOT="/opt/${APP_NAME}"
CONFIG_ROOT="/etc/${APP_NAME}"
LOG_ROOT="/var/log/${APP_NAME}"
SYSTEMD_UNIT="/etc/systemd/system/${APP_NAME}.service"

# Find where this script is (should be in unzipped package)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Checking root privileges"
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root (use sudo)" >&2
  exit 1
fi

echo "==> Stopping service if running"
if systemctl is-active --quiet "${APP_NAME}.service" 2>/dev/null; then
  systemctl stop "${APP_NAME}.service"
fi

echo "==> Creating service user: ${APP_USER}"
if ! id -u "$APP_USER" &>/dev/null; then
  useradd --system --no-create-home --shell /usr/sbin/nologin "$APP_USER"
fi

echo "==> Adding user to dialout group (for serial port access)"
usermod -a -G dialout "$APP_USER" 2>/dev/null || true

echo "==> Installing application to ${INSTALL_ROOT}"
mkdir -p "$INSTALL_ROOT"
cp -r "${PACKAGE_ROOT}/opt/${APP_NAME}/"* "${INSTALL_ROOT}/"

echo "==> Setting up config directory: ${CONFIG_ROOT}"
mkdir -p "${CONFIG_ROOT}/configs"

if [[ ! -f "${CONFIG_ROOT}/configs/pemConfigs.json" ]]; then
  if [[ -f "${INSTALL_ROOT}/defaults/pemConfigs.json" ]]; then
    cp "${INSTALL_ROOT}/defaults/pemConfigs.json" "${CONFIG_ROOT}/configs/pemConfigs.json"
    echo "    ✓ Installed default config"
  else
    echo "    ✗ WARNING: No default config found" >&2
  fi
else
  echo "    ✓ Existing config preserved"
fi

echo "==> Setting up log directory: ${LOG_ROOT}"
mkdir -p "$LOG_ROOT"
chown "${APP_USER}:${APP_USER}" "$LOG_ROOT"
chmod 755 "$LOG_ROOT"

echo "==> Setting permissions"
chown -R root:root "$INSTALL_ROOT"
chmod 755 "${INSTALL_ROOT}/bin/${APP_NAME}"

if [[ -f "${CONFIG_ROOT}/configs/pemConfigs.json" ]]; then
  chown "${APP_USER}:${APP_USER}" "${CONFIG_ROOT}/configs/pemConfigs.json"
  chmod 644 "${CONFIG_ROOT}/configs/pemConfigs.json"
fi

echo "==> Installing systemd service"
if [[ -f "${PACKAGE_ROOT}/etc/systemd/system/${APP_NAME}.service" ]]; then
  cp "${PACKAGE_ROOT}/etc/systemd/system/${APP_NAME}.service" "$SYSTEMD_UNIT"
  systemctl daemon-reload
else
  echo "ERROR: Service file not found in package" >&2
  exit 1
fi

echo "==> Enabling and starting service"
systemctl enable "${APP_NAME}.service"
systemctl start "${APP_NAME}.service"

echo ""
echo "✅ Installation complete!"
echo ""
echo "Service status:"
systemctl status "${APP_NAME}.service" --no-pager || true
echo ""
echo "View logs:     journalctl -u ${APP_NAME} -f"
echo "Check status:  systemctl status ${APP_NAME}"
echo "Stop service:  sudo systemctl stop ${APP_NAME}"
echo "Start service: sudo systemctl start ${APP_NAME}"
