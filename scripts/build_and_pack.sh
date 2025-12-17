#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/cmake-build-release"
DIST_DIR="${ROOT_DIR}/dist"
STAGE_DIR="${DIST_DIR}/stage"
APP_NAME="pem353"

rm -rf "$BUILD_DIR" "$STAGE_DIR"
mkdir -p "$BUILD_DIR" "$STAGE_DIR" "$DIST_DIR"

cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" -- -j"$(nproc)"

BIN="${ROOT_DIR}/bin/${APP_NAME}"
if [[ ! -f "$BIN" ]]; then
  echo "Hittar inte binären: $BIN" >&2
  exit 1
fi

# Paketlayout
mkdir -p "${STAGE_DIR}/opt/${APP_NAME}/bin"
mkdir -p "${STAGE_DIR}/opt/${APP_NAME}/lib"
mkdir -p "${STAGE_DIR}/opt/${APP_NAME}/defaults"
mkdir -p "${STAGE_DIR}/etc/systemd/system"
mkdir -p "${STAGE_DIR}/install"

cp -a "$BIN" "${STAGE_DIR}/opt/${APP_NAME}/bin/"

# Default-config från repot
if [[ -f "${ROOT_DIR}/configs/pemConfigs.json" ]]; then
  cp -a "${ROOT_DIR}/configs/pemConfigs.json" "${STAGE_DIR}/opt/${APP_NAME}/defaults/pemConfigs.json"
else
  echo "Varning: hittar inte ${ROOT_DIR}/configs/pemConfigs.json" >&2
fi

# Installfiler
cp -a "${ROOT_DIR}/install/pem353.service" "${STAGE_DIR}/etc/systemd/system/pem353.service"
cp -a "${ROOT_DIR}/install/install.sh" "${STAGE_DIR}/install/install.sh"
cp -a "${ROOT_DIR}/install/uninstall.sh" "${STAGE_DIR}/install/uninstall.sh"
chmod +x "${STAGE_DIR}/install/install.sh" || true
chmod +x "${STAGE_DIR}/install/uninstall.sh" || true

# ... existing code ...
echo "Skapade paket: $ZIP_PATH"
echo "På target:"
echo "  unzip pem353.zip -d pem353_pkg"
echo "  cd pem353_pkg"
echo "  sudo ./install/install.sh [--open-firewall]"
echo "Avinstallera:"
echo "  sudo ./install/uninstall.sh [--remove-logs] [--remove-user]"