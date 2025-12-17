#!/usr/bin/env bash
set -euo pipefail

APP_NAME="pem353"
APP_USER="pem353"
APP_GROUP="pem353"

INSTALL_ROOT="/opt/${APP_NAME}"
ETC_DIR="/etc/${APP_NAME}/configs"
LOG_DIR="/var/log/${APP_NAME}"

PKG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OPEN_FIREWALL=0
for arg in "$@"; do
  case "$arg" in
    --open-firewall) OPEN_FIREWALL=1 ;;
    *) echo "Okänd flagga: $arg" >&2; exit 1 ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "Kör som root: sudo ./install/install.sh [--open-firewall]" >&2
  exit 1
fi

# Skapa systemuser
if ! id -u "$APP_USER" >/dev/null 2>&1; then
  useradd --system --no-create-home --shell /usr/sbin/nologin "$APP_USER"
fi
if ! getent group "$APP_GROUP" >/dev/null 2>&1; then
  groupadd --system "$APP_GROUP" || true
fi

# Kataloger
mkdir -p "$INSTALL_ROOT" "$ETC_DIR" "$LOG_DIR"
chown -R root:root "$INSTALL_ROOT"
chown -R root:root "/etc/${APP_NAME}"
chown -R "$APP_USER":"$APP_GROUP" "$LOG_DIR"
chmod 0750 "$LOG_DIR"

# Kopiera program + libs
if [[ ! -d "${PKG_ROOT}/opt/${APP_NAME}" ]]; then
  echo "Hittar inte ${PKG_ROOT}/opt/${APP_NAME}. Kör från uppackat paket." >&2
  exit 1
fi
rsync -a --delete "${PKG_ROOT}/opt/${APP_NAME}/" "${INSTALL_ROOT}/"

# Installera config på hårdkodad path
DEFAULT_CFG="${INSTALL_ROOT}/defaults/pemConfigs.json"
TARGET_CFG="${ETC_DIR}/pemConfigs.json"

if [[ -f "$DEFAULT_CFG" ]]; then
  # skriv bara om den inte finns
  if [[ ! -f "$TARGET_CFG" ]]; then
    cp -a "$DEFAULT_CFG" "$TARGET_CFG"
  fi
  chown root:root "$TARGET_CFG"
  chmod 0644 "$TARGET_CFG"
else
  echo "Varning: default config saknas: $DEFAULT_CFG" >&2
fi

# Patcha LOGGER.PATH i config till /var/log/pem353/pemlog.txt
if [[ -f "$TARGET_CFG" ]]; then
  sed -i 's|"PATH"[[:space:]]*:[[:space:]]*"\./logs/[^"]*"|"PATH": "/var/log/pem353/pemlog.txt"|g' "$TARGET_CFG" || true
fi

# Port 502 utan root
BIN="${INSTALL_ROOT}/bin/${APP_NAME}"
if [[ -f "$BIN" ]]; then
  if command -v setcap >/dev/null 2>&1; then
    setcap 'cap_net_bind_service=+ep' "$BIN" || true
  else
    echo "Varning: setcap saknas. Installera: sudo apt-get install libcap2-bin" >&2
  fi
fi

# Systemd
UNIT_SRC="${PKG_ROOT}/etc/systemd/system/${APP_NAME}.service"
UNIT_DST="/etc/systemd/system/${APP_NAME}.service"
cp -a "$UNIT_SRC" "$UNIT_DST"

systemctl daemon-reload
systemctl enable "${APP_NAME}.service"
systemctl restart "${APP_NAME}.service"

# Brandvägg (valfritt, endast om --open-firewall)
if [[ "$OPEN_FIREWALL" -eq 1 ]]; then
  if command -v ufw >/dev/null 2>&1; then
    ufw allow 502/tcp || true
  elif command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port=502/tcp || true
    firewall-cmd --reload || true
  else
    echo "Info: ingen stödd brandvägg hittades (ufw/firewalld). Hoppar över." >&2
  fi
else
  echo "Info: brandvägg ändras inte. Kör med --open-firewall om du vill öppna 502/tcp." >&2
fi

echo "Klart."
echo "Config:  /etc/pem353/configs/pemConfigs.json"
echo "Loggar:  /var/log/pem353/"
echo "Status:  systemctl status pem353.service"