#!/usr/bin/env bash
set -euo pipefail

APP_NAME="pem353"
APP_USER="pem353"

INSTALL_ROOT="/opt/${APP_NAME}"
ETC_ROOT="/etc/${APP_NAME}"
LOG_ROOT="/var/log/${APP_NAME}"
UNIT_DST="/etc/systemd/system/${APP_NAME}.service"

REMOVE_LOGS=0
REMOVE_USER=0

usage() {
  echo "Användning: sudo ./install/uninstall.sh [--remove-logs] [--remove-user]" >&2
  echo "  --remove-logs  Tar även bort ${LOG_ROOT}" >&2
  echo "  --remove-user  Tar även bort systemanvändaren ${APP_USER} (om möjligt)" >&2
}

for arg in "$@"; do
  case "$arg" in
    --remove-logs) REMOVE_LOGS=1 ;;
    --remove-user) REMOVE_USER=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Okänd flagga: $arg" >&2; usage; exit 1 ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "Kör som root: sudo ./install/uninstall.sh" >&2
  exit 1
fi

# 1) Stoppa/disable service om den finns
if systemctl list-unit-files | grep -qE "^${APP_NAME}\.service"; then
  systemctl stop "${APP_NAME}.service" || true
  systemctl disable "${APP_NAME}.service" || true
fi

# 2) Ta bort unit-fil och reload systemd
if [[ -f "$UNIT_DST" ]]; then
  rm -f "$UNIT_DST"
  systemctl daemon-reload || true
fi

# 3) Ta bort installerade filer
if [[ -d "$INSTALL_ROOT" ]]; then
  rm -rf "$INSTALL_ROOT"
fi

if [[ -d "$ETC_ROOT" ]]; then
  rm -rf "$ETC_ROOT"
fi

if [[ "$REMOVE_LOGS" -eq 1 ]]; then
  if [[ -d "$LOG_ROOT" ]]; then
    rm -rf "$LOG_ROOT"
  fi
else
  echo "Info: behåller loggar i ${LOG_ROOT} (kör med --remove-logs för att ta bort)." >&2
fi

# 4) Ta bort systemuser (valfritt)
if [[ "$REMOVE_USER" -eq 1 ]]; then
  if id -u "$APP_USER" >/dev/null 2>&1; then
    # userdel kan faila om processen fortfarande kör eller om hemkatalog etc finns
    userdel "$APP_USER" || {
      echo "Varning: kunde inte ta bort user ${APP_USER} (kan vara i bruk). Ta bort manuellt om du vill." >&2
    }
  fi
else
  echo "Info: behåller systemanvändaren ${APP_USER} (kör med --remove-user för att ta bort)." >&2
fi

echo "Avinstallerat ${APP_NAME}."