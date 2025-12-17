#!/usr/bin/env bash
set -euo pipefail

APP_NAME="pem353"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/cmake-build-release"
DIST_DIR="${ROOT_DIR}/dist"
STAGE_DIR="${DIST_DIR}/stage"
ZIP_PATH="${DIST_DIR}/${APP_NAME}.zip"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required tool '$1' is missing. Please install it and try again." >&2
    exit 1
  fi
}

require_cmd cmake
require_cmd zip
require_cmd patchelf
require_cmd ldconfig

rm -rf "$BUILD_DIR" "$STAGE_DIR"
mkdir -p "$BUILD_DIR" "$STAGE_DIR" "$DIST_DIR"

echo "==> Building (Release)"
cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" -- -j"$(nproc)"

BIN="${ROOT_DIR}/bin/${APP_NAME}"
if [[ ! -f "$BIN" ]]; then
  echo "ERROR: binary not found: $BIN" >&2
  exit 1
fi

echo "==> Creating staging layout"
mkdir -p "${STAGE_DIR}/opt/${APP_NAME}/bin"
mkdir -p "${STAGE_DIR}/opt/${APP_NAME}/lib"
mkdir -p "${STAGE_DIR}/opt/${APP_NAME}/defaults"
mkdir -p "${STAGE_DIR}/etc/systemd/system"
mkdir -p "${STAGE_DIR}/install"

cp -a "$BIN" "${STAGE_DIR}/opt/${APP_NAME}/bin/"

if [[ -f "${ROOT_DIR}/configs/pemConfigs.json" ]]; then
  cp -a "${ROOT_DIR}/configs/pemConfigs.json" "${STAGE_DIR}/opt/${APP_NAME}/defaults/pemConfigs.json"
else
  echo "WARNING: default config not found: ${ROOT_DIR}/configs/pemConfigs.json" >&2
fi

cp -a "${ROOT_DIR}/install/${APP_NAME}.service" "${STAGE_DIR}/etc/systemd/system/${APP_NAME}.service"
cp -a "${ROOT_DIR}/install/install.sh" "${STAGE_DIR}/install/install.sh"
cp -a "${ROOT_DIR}/install/uninstall.sh" "${STAGE_DIR}/install/uninstall.sh"
chmod +x "${STAGE_DIR}/install/install.sh" "${STAGE_DIR}/install/uninstall.sh" || true

echo "==> Setting RPATH so the binary loads bundled libs from /opt/${APP_NAME}/lib"
patchelf --set-rpath '$ORIGIN/../lib' "${STAGE_DIR}/opt/${APP_NAME}/bin/${APP_NAME}"

echo "==> Bundling runtime shared libraries (NEEDED -> ldconfig -p)"
mapfile -t needed < <(patchelf --print-needed "${STAGE_DIR}/opt/${APP_NAME}/bin/${APP_NAME}" | sort -u)

if [[ "${#needed[@]}" -eq 0 ]]; then
  echo "ERROR: no NEEDED libraries found. Is the binary statically linked?" >&2
  exit 1
fi

skip_lib() {
  case "$1" in
    ld-linux-*.so*|ld-linux*.so*|libc.so.*) return 0 ;;
  esac
  return 1
}

missing=0
for libname in "${needed[@]}"; do
  if skip_lib "$libname"; then
    continue
  fi

  libpath="$(ldconfig -p | awk -v n="$libname" '$1==n {print $NF; exit}')"
  if [[ -z "$libpath" || ! -e "$libpath" ]]; then
    echo "ERROR: could not resolve '$libname' via ldconfig -p" >&2
    missing=1
    continue
  fi

  dir="$(dirname "$libpath")"
  base="$(basename "$libpath")"
  stem="${base%%.so*}"

  cp -a "${dir}/${stem}.so"* "${STAGE_DIR}/opt/${APP_NAME}/lib/" 2>/dev/null || {
    cp -L "$libpath" "${STAGE_DIR}/opt/${APP_NAME}/lib/" || true
  }
done

if [[ "$missing" -ne 0 ]]; then
  echo "ERROR: at least one required runtime library could not be resolved on the build machine." >&2
  echo "       Install the missing runtime libraries on the build machine and rebuild." >&2
  exit 1
fi

echo "==> Verification: ensure staged lib folder contains .so files"
shopt -s nullglob
sofiles=( "${STAGE_DIR}/opt/${APP_NAME}/lib/"*.so* )
shopt -u nullglob
if [[ "${#sofiles[@]}" -eq 0 ]]; then
  echo "ERROR: no .so files were bundled into ${STAGE_DIR}/opt/${APP_NAME}/lib" >&2
  echo "NEEDED libraries were:" >&2
  patchelf --print-needed "${STAGE_DIR}/opt/${APP_NAME}/bin/${APP_NAME}" >&2 || true
  exit 1
fi

echo "==> Verification: ldd with LD_LIBRARY_PATH (must not show 'not found')"
LDD_OUT="$(LD_LIBRARY_PATH="${STAGE_DIR}/opt/${APP_NAME}/lib" ldd "${STAGE_DIR}/opt/${APP_NAME}/bin/${APP_NAME}" || true)"
echo "$LDD_OUT"
if echo "$LDD_OUT" | grep -q "not found"; then
  echo "ERROR: at least one runtime library is still 'not found' after bundling." >&2
  exit 1
fi

echo "==> Creating ZIP package"
rm -f "$ZIP_PATH"
( cd "$STAGE_DIR" && zip -r -9 "$ZIP_PATH" . >/dev/null )

echo "DONE: ${ZIP_PATH}"
echo "Verify contents:"
echo "  unzip -l ${ZIP_PATH} | grep 'opt/${APP_NAME}/lib/'"