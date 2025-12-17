#!/usr/bin/env bash
set -euo pipefail

APP_NAME="pem353"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/cmake-build-release"
DIST_DIR="${ROOT_DIR}/dist"
ZIP_NAME="${APP_NAME}.zip"

echo "==> Cleaning previous build and dist"
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

echo "==> Building Release binary"
cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" -j$(nproc)

BIN="${ROOT_DIR}/bin/${APP_NAME}"
if [[ ! -f "$BIN" ]]; then
  echo "ERROR: Binary not found at $BIN" >&2
  exit 1
fi

echo "==> Creating package structure in dist/"
mkdir -p "${DIST_DIR}/opt/${APP_NAME}/bin"
mkdir -p "${DIST_DIR}/opt/${APP_NAME}/lib"
mkdir -p "${DIST_DIR}/opt/${APP_NAME}/defaults"
mkdir -p "${DIST_DIR}/etc/systemd/system"
mkdir -p "${DIST_DIR}/install"

echo "==> Copying binary"
cp "$BIN" "${DIST_DIR}/opt/${APP_NAME}/bin/"

echo "==> Copying default config"
if [[ -f "${ROOT_DIR}/configs/pemConfigs.json" ]]; then
  cp "${ROOT_DIR}/configs/pemConfigs.json" "${DIST_DIR}/opt/${APP_NAME}/defaults/"
else
  echo "WARNING: No default config found at ${ROOT_DIR}/configs/pemConfigs.json" >&2
fi

echo "==> Bundling shared libraries"
# Get list of shared libraries the binary needs
NEEDED_LIBS=$(ldd "$BIN" | grep "=>" | awk '{print $3}' | grep -v "^$")

# Skip system libraries that should exist everywhere
for lib in $NEEDED_LIBS; do
  libname=$(basename "$lib")
  
  # Skip libc, ld-linux, and other core system libs
  if [[ "$libname" =~ ^(libc\.so|ld-linux|libm\.so|libpthread\.so|libdl\.so|librt\.so) ]]; then
    continue
  fi
  
  # Copy library and any symlinks
  cp -L "$lib" "${DIST_DIR}/opt/${APP_NAME}/lib/" 2>/dev/null || true
  
  # Also copy version symlinks if they exist
  libdir=$(dirname "$lib")
  libbase=$(echo "$libname" | sed 's/\.so.*//')
  cp -P "${libdir}/${libbase}.so"* "${DIST_DIR}/opt/${APP_NAME}/lib/" 2>/dev/null || true
done

echo "==> Setting RPATH on binary"
if command -v patchelf &>/dev/null; then
  patchelf --set-rpath '$ORIGIN/../lib' "${DIST_DIR}/opt/${APP_NAME}/bin/${APP_NAME}"
else
  echo "WARNING: patchelf not found, binary may not find bundled libraries" >&2
fi

echo "==> Copying systemd service file"
cp "${ROOT_DIR}/install/${APP_NAME}.service" "${DIST_DIR}/etc/systemd/system/"

echo "==> Copying install scripts"
cp "${ROOT_DIR}/install/install.sh" "${DIST_DIR}/install/"
cp "${ROOT_DIR}/install/uninstall.sh" "${DIST_DIR}/install/"
chmod +x "${DIST_DIR}/install/install.sh" "${DIST_DIR}/install/uninstall.sh"

echo "==> Creating zip package"
cd "$DIST_DIR"
zip -r "$ZIP_NAME" opt/ etc/ install/ >/dev/null
cd "$ROOT_DIR"

echo ""
echo "✅ DONE: ${DIST_DIR}/${ZIP_NAME}"
echo ""
echo "Package contents:"
unzip -l "${DIST_DIR}/${ZIP_NAME}" | grep -E "(opt|etc|install)"
echo ""
echo "To deploy:"
echo "  1. Copy ${ZIP_NAME} to target machine"
echo "  2. unzip ${ZIP_NAME}"
echo "  3. sudo ./install/install.sh"
