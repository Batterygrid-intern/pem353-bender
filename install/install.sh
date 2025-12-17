#!/usr/bin/env bash
set -euo pipefail

APP_NAME="pem353"
APP_USER="pem353"
APP_GROUP="pem353"

INSTALL_ROOT="/opt/${APP_NAME}"
ETC_DIR="/etc/${APP_NAME}/configs"
LOG_DIR="/var/log/${APP_NAME}"

UNIT_NAME="${APP_NAME}.service"
UNIT_DST="/etc/systemd/system/${UNIT_NAME}"

PKG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OPEN_FIREWALL=0
for arg in "$@"; do
  case "$arg" in
    --open-firewall) OPEN_FIREWALL=1 ;;
    -h|--help)
      echo "Usage: sudo ./install/install.sh [--open-firewall]"
      exit 0
      ;;
    *) echo "Okänd flagga: $arg" >&2; exit 1 ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "Kör som root: sudo ./install/install.sh [--open-firewall]" >&2
  exit 1
fi

echo "==> Installerar ${APP_NAME} från: ${PKG_ROOT}"

# 1) Skapa grupp + user (system)
if ! getent group "$APP_GROUP" >/dev/null 2>&1; then
  groupadd --system "$APP_GROUP"
fi

if ! id -u "$APP_USER" >/dev/null 2>&1; then
  useradd --system --no-create-home --shell /usr/sbin/nologin --gid "$APP_GROUP" "$APP_USER"
fi

# 2) Ge tjänsteanvändaren seriellport-access (Modbus RTU)
# Raspberry Pi OS: /dev/ttyAMA0 brukar vara root:dialout 0660
if getent group dialout >/dev/null 2>&1; then
  usermod -a -G dialout "$APP_USER" || true
else
  echo "Varning: gruppen 'dialout' finns inte. RTU kan fortfarande få permission denied." >&2
fi

# 3) Lägg install-usern (SUDO_USER) i pem353-gruppen så du kan läsa loggar utan sudo
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  usermod -a -G "$APP_GROUP" "$SUDO_USER" || true
  echo "Info: lade till ${SUDO_USER} i gruppen ${APP_GROUP}. Logga ut/in för att det ska gälla." >&2
fi

# 4) Skapa kataloger
mkdir -p "$INSTALL_ROOT" "$ETC_DIR" "$LOG_DIR"

# /opt/pem353 ägs av root
chown -R root:root "$INSTALL_ROOT"
chmod 0755 "$INSTALL_ROOT"

# /etc/pem353 ägs av root
chown -R root:root "/etc/${APP_NAME}"
chmod 0755 "/etc/${APP_NAME}"
chmod 0755 "$ETC_DIR"

# /var/log/pem353: skrivbar för pem353 och läsbar för gruppen pem353
chown -R "$APP_USER":"$APP_GROUP" "$LOG_DIR"
chmod 2775 "$LOG_DIR"   # setgid så nya filer får pem353-grupp automatiskt

# 5) Kopiera program + bundlade libs från paketet
if [[ ! -d "${PKG_ROOT}/opt/${APP_NAME}" ]]; then
  echo "Fel: Hittar inte ${PKG_ROOT}/opt/${APP_NAME}. Kör scriptet från uppackat paket." >&2
  exit 1
fi

rsync -a --delete "${PKG_ROOT}/opt/${APP_NAME}/" "${INSTALL_ROOT}/"

# Säkerställ att binären finns
BIN="${INSTALL_ROOT}/bin/${APP_NAME}"
if [[ ! -f "$BIN" ]]; then
  echo "Fel: binären saknas efter kopiering: $BIN" >&2
  exit 1
fi

# 6) Installera config på exakt sökväg som programmet använder
DEFAULT_CFG="${INSTALL_ROOT}/defaults/pemConfigs.json"
TARGET_CFG="${ETC_DIR}/pemConfigs.json"

if [[ -f "$DEFAULT_CFG" ]]; then
  if [[ ! -f "$TARGET_CFG" ]]; then
    cp -a "$DEFAULT_CFG" "$TARGET_CFG"
  fi
  chown root:root "$TARGET_CFG"
  chmod 0644 "$TARGET_CFG"
else
  echo "Varning: default config saknas i paketet: $DEFAULT_CFG" >&2
fi

# Patcha LOGGER.PATH till /var/log/pem353/pemlog.txt (så logg hamnar korrekt)
if [[ -f "$TARGET_CFG" ]]; then
  sed -i 's|"PATH"[[:space:]]*:[[:space:]]*"\./logs/[^"]*"|"PATH": "/var/log/pem353/pemlog.txt"|g' "$TARGET_CFG" || true
fi

# 7) Port 502 utan root
if command -v setcap >/dev/null 2>&1; then
  setcap 'cap_net_bind_service=+ep' "$BIN" || true
else
  echo "Varning: setcap saknas. Installera: sudo apt-get install libcap2-bin" >&2
fi

# 8) Installera systemd unit
UNIT_SRC="${PKG_ROOT}/etc/systemd/system/${UNIT_NAME}"
if [[ ! -f "$UNIT_SRC" ]]; then
  echo "Fel: systemd unit saknas i paketet: $UNIT_SRC" >&2
  exit 1
fi

cp -a "$UNIT_SRC" "$UNIT_DST"
chmod 0644 "$UNIT_DST"
chown root:root "$UNIT_DST"

systemctl daemon-reload
systemctl enable "$UNIT_NAME"
systemctl restart "$UNIT_NAME"

# 9) Brandvägg (endast om --open-firewall)
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

echo "==> Klart."
echo "Service: systemctl status ${UNIT_NAME}"
echo "Config:  ${TARGET_CFG}"
echo "Loggar:  ${LOG_DIR} (t.ex. ${LOG_DIR}/pemlog.txt)"
echo "RTU dev (kontrollera permissions): ls -l /dev/ttyAMA0"
echo "pem353 grupper: $(id -nG "${APP_USER}" 2>/dev/null || true)"