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
chmod +x "${STAGE_DIR}/install/install.sh" || true

echo "Bundlar runtime-bibliotek via ldd..."
mapfile -t deps < <(ldd "$BIN" | awk '
  $3 ~ /^\// { print $3 }
  $1 ~ /^\// { print $1 }
' | sort -u)

for so in "${deps[@]}"; do
  case "$so" in
    *linux-vdso.so*|*ld-linux*|*/ld-*.so*) continue ;;
  esac
  case "$so" in
    /lib/*|/usr/lib/*)
      cp -L "$so" "${STAGE_DIR}/opt/${APP_NAME}/lib/" || true
      ;;
  esac
done

# Sätt RPATH så binären hittar libs i /opt/pem353/lib
if command -v patchelf >/dev/null 2>&1; then
  patchelf --set-rpath '$ORIGIN/../lib' "${STAGE_DIR}/opt/${APP_NAME}/bin/${APP_NAME}"
else
  echo "Fel: patchelf saknas. Installera: sudo apt-get install patchelf" >&2
  exit 1
fi

echo "Verifiering 1: säkerställ att binären hittar alla libs i staged miljö..."
LDD_OUT="$(LD_LIBRARY_PATH="${STAGE_DIR}/opt/${APP_NAME}/lib" ldd "${STAGE_DIR}/opt/${APP_NAME}/bin/${APP_NAME}" || true)"
echo "$LDD_OUT"
if echo "$LDD_OUT" | grep -q "not found"; then
  echo "Fel: minst ett runtime-bibliotek är 'not found' efter bundling." >&2
  exit 1
fi

echo "Verifiering 2: säkerställ att staged/lib innehåller de libs som ldd pekar på (så långt det går)..."
# plocka ut basnamn på libs som faktiskt laddas, och kontrollera att de finns i staged/lib
while read -r libname; do
  [[ -z "$libname" ]] && continue
  if [[ ! -e "${STAGE_DIR}/opt/${APP_NAME}/lib/${libname}" ]]; then
    # vissa libs kan resolve:a till system även om de också finns i staged;
    # detta är en varning, inte hårt fel.
    echo "Varning: saknar ${libname} i staged lib-folder." >&2
  fi
done < <(echo "$LDD_OUT" | awk '/=>/ {print $1}' | sort -u)

echo "Verifiering 3: arkitektur-check (aarch64 rekommenderas på buildmaskinen)..."
if command -v file >/dev/null 2>&1; then
  FILE_OUT="$(file "${STAGE_DIR}/opt/${APP_NAME}/bin/${APP_NAME}" || true)"
  echo "$FILE_OUT"
  if ! echo "$FILE_OUT" | grep -qiE "aarch64|ARM aarch64"; then
    echo "Varning: binären ser inte ut att vara aarch64. Bygger du verkligen på Raspberry Pi OS aarch64?" >&2
  fi
fi

ZIP_PATH="${DIST_DIR}/pem353.zip"
rm -f "$ZIP_PATH"

if ! command -v zip >/dev/null 2>&1; then
  echo "Fel: zip saknas. Installera: sudo apt-get install zip" >&2
  exit 1
fi

( cd "$STAGE_DIR" && zip -r -9 "$ZIP_PATH" . >/dev/null )

echo "Skapade paket: $ZIP_PATH"
echo "På target:"
echo "  unzip pem353.zip -d pem353_pkg"
echo "  cd pem353_pkg"
echo "  sudo ./install/install.sh [--open-firewall]"