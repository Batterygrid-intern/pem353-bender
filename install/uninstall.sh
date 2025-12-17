#!/usr/bin/env bash
set -euo pipefail

APP_NAME="pem353"
APP_USER="pem353"

INSTALL_ROOT="/opt/${APP_NAME}"
CONFIG_ROOT="/etc/${APP_NAME}"
LOG_ROOT="/var/log/${APP_NAME}"
SYSTEMD_UNIT="/etc/systemd/system/${APP_NAME}.service"

# Parse flags
REMOVE_CONFIG=false
REMOVE_LOGS=false
REMOVE_USER=false

for arg in "$@"; do
  case "$arg" in
    --remove-config) REMOVE_CONFIG=true ;;
    --remove-logs) REMOVE_LOGS=true ;;
    --remove-user) REMOVE_USER=true ;;
    -h|--help)
      echo "Usage: sudo $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --remove-config   Also remove config directory ${CONFIG_ROOT}"
      echo "  --remove-logs     Also remove log directory ${LOG_ROOT}"
      echo "  --remove-user     Also remove service user ${APP_USER}"
      echo ""
      echo "By default, config, logs, and user are preserved."
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $arg" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

echo "==> Checking root privileges"
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root (use sudo)" >&2
  exit 1
fi

echo "==> Stopping and disabling service"
systemctl stop "${APP_NAME}.service" 2>/dev/null || true
systemctl disable "${APP_NAME}.service" 2>/dev/null || true

echo "==> Removing systemd unit"
if [[ -f "$SYSTEMD_UNIT" ]]; then
  rm -f "$SYSTEMD_UNIT"
  systemctl daemon-reload
fi

echo "==> Removing binary from /usr/local/bin"
rm -f "/usr/local/bin/${APP_NAME}"

echo "==> Removing libraries: ${INSTALL_ROOT}"
rm -rf "$INSTALL_ROOT"

echo "==> Removing working directory: /var/lib/${APP_NAME}"
rm -rf "/var/lib/${APP_NAME}"

if [[ "$REMOVE_CONFIG" == true ]]; then
  echo "==> Removing config: ${CONFIG_ROOT}"
  rm -rf "$CONFIG_ROOT"
else
  echo "==> Keeping config: ${CONFIG_ROOT} (use --remove-config to delete)"
fi

if [[ "$REMOVE_LOGS" == true ]]; then
  echo "==> Removing logs: ${LOG_ROOT}"
  rm -rf "$LOG_ROOT"
else
  echo "==> Keeping logs: ${LOG_ROOT} (use --remove-logs to delete)"
fi

if [[ "$REMOVE_USER" == true ]]; then
  echo "==> Removing user: ${APP_USER}"
  if id -u "$APP_USER" &>/dev/null; then
    userdel "$APP_USER" 2>/dev/null || true
    groupdel "$APP_USER" 2>/dev/null || true
  fi
else
  echo "==> Keeping user: ${APP_USER} (use --remove-user to delete)"
fi

echo ""
echo "✅ Uninstall complete!"
