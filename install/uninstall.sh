#!/usr/bin/env bash
set -euo pipefail

APP_NAME="pem353"
APP_USER="pem353"

INSTALL_ROOT="/opt/${APP_NAME}"
ETC_ROOT="/etc/${APP_NAME}"
LOG_ROOT="/var/log/${APP_NAME}"
UNIT_DST="/etc/systemd/system/${APP_NAME}.service"

REMOVE_LOGS=0
REMOVE_CONFIG=0
REMOVE_USER=0

usage() {
  echo "Usage: sudo ./install/uninstall.sh [--remove-logs] [--remove-config] [--remove-user]" >&2
}

for arg in "$@"; do
  case "$arg" in
    --remove-logs) REMOVE_LOGS=1 ;;
    --remove-config) REMOVE_CONFIG=1 ;;
    --remove-user) REMOVE_USER=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown flag: $arg" >&2; usage; exit 1 ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: please run as root: sudo ./install/uninstall.sh" >&2
  exit 1
fi

echo "==> Stopping and disabling service (if present)"
systemctl stop "${APP_NAME}.service" || true
systemctl disable "${APP_NAME}.service" || true

echo "==> Removing systemd unit (if present)"
if [[ -f "$UNIT_DST" ]]; then
  rm -f "$UNIT_DST"
fi
systemctl daemon-reload || true

echo "==> Removing installed files from ${INSTALL_ROOT}"
rm -rf "$INSTALL_ROOT" || true

if [[ "$REMOVE_CONFIG" -eq 1 ]]; then
  echo "==> Removing config directory ${ETC_ROOT}"
  rm -rf "$ETC_ROOT" || true
else
  echo "INFO: keeping config directory ${ETC_ROOT} (use --remove-config to delete it)." >&2
fi

if [[ "$REMOVE_LOGS" -eq 1 ]]; then
  echo "==> Removing log directory ${LOG_ROOT}"
  rm -rf "$LOG_ROOT" || true
else
  echo "INFO: keeping log directory ${LOG_ROOT} (use --remove-logs to delete it)." >&2
fi

if [[ "$REMOVE_USER" -eq 1 ]]; then
  echo "==> Removing service user '${APP_USER}' (if possible)"
  if id -u "$APP_USER" >/dev/null 2>&1; then
    userdel "$APP_USER" || true
  fi
else
  echo "INFO: keeping service user '${APP_USER}' (use --remove-user to delete it)." >&2
fi

echo "DONE: ${APP_NAME} uninstalled."