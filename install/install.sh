#!/usr/bin/env bash
set -euo pipefail

APP_NAME="pem353"
APP_USER="pem353"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_ROOT="/opt/${APP_NAME}"
ETC_ROOT="/etc/${APP_NAME}"
LOG_ROOT="/var/log/${APP_NAME}"
UNIT_DST="/etc/systemd/system/${APP_NAME}.service"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: please run as root: sudo ./install/install.sh" >&2
  exit 1
fi

if systemctl is-active --quiet "${APP_NAME}.service" 2>/dev/null; then
  echo "==> Stopping service (if already running)"
  systemctl stop "${APP_NAME}.service"
fi

echo "==> Creating service user '${APP_USER}' (if missing)"
if ! id -u "$APP_USER" >/dev/null 2>&1; then
  useradd --system --no-create-home --shell /usr/sbin/nologin --gid dialout "$APP_USER" 2>/dev/null || \
  useradd --system --no-create-home --shell /usr/sbin/nologin "$APP_USER" 2>/dev/null || true
fi

echo "==> Adding user to dialout group (for serial port access)"
usermod -a -G dialout "$APP_USER" 2>/dev/null || true

echo "==> Installing files to ${INSTALL_ROOT}"
mkdir -p "$INSTALL_ROOT"
cp -r "${SCRIPT_DIR}/../opt/${APP_NAME}/"* "$INSTALL_ROOT/"

echo "==> Setting up config directory ${ETC_ROOT}"
mkdir -p "${ETC_ROOT}/configs"
if [[ ! -f "${ETC_ROOT}/configs/pemConfigs.json" && -f "${INSTALL_ROOT}/defaults/pemConfigs.json" ]]; then
  cp -a "${INSTALL_ROOT}/defaults/pemConfigs.json" "${ETC_ROOT}/configs/pemConfigs.json"
  echo "INFO: installed default config to ${ETC_ROOT}/configs/pemConfigs.json"
else
  echo "INFO: existing config preserved at ${ETC_ROOT}/configs/pemConfigs.json"
fi

echo "==> Setting up log directory ${LOG_ROOT}"
mkdir -p "$LOG_ROOT"
chown "${APP_USER}:${APP_USER}" "$LOG_ROOT"
chmod 755 "$LOG_ROOT"

echo "==> Setting ownership"
chown -R root:root "$INSTALL_ROOT"
chmod +x "${INSTALL_ROOT}/bin/${APP_NAME}"
chown "${APP_USER}:${APP_USER}" "${ETC_ROOT}/configs/pemConfigs.json"
chmod 644 "${ETC_ROOT}/configs/pemConfigs.json"

echo "==> Installing systemd service"
if [[ -f "${SCRIPT_DIR}/../etc/systemd/system/${APP_NAME}.service" ]]; then
  cp -a "${SCRIPT_DIR}/../etc/systemd/system/${APP_NAME}.service" "$UNIT_DST"
else
  echo "ERROR: systemd service file not found in package" >&2
  exit 1
fi

echo "==> Reloading systemd and enabling service"
systemctl daemon-reload
systemctl enable "${APP_NAME}.service"

echo "==> Starting service"
systemctl start "${APP_NAME}.service"

echo "DONE: ${APP_NAME} installed and started."
echo "Check status: systemctl status ${APP_NAME}"
echo "View logs: journalctl -u ${APP_NAME} -f"