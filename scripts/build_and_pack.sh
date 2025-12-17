#!/usr/bin/env bash
set -euo pipefail

APP_NAME="pem353"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/cmake-build-release"
DEPLOY_DIR="${ROOT_DIR}/deploy"
BINARY_PATH="${ROOT_DIR}/bin/${APP_NAME}"

echo "==========================================="
echo "PEM353 Build and Package Script"
echo "==========================================="
echo ""

# Clean and build
echo "[1/4] Building Release binary..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" -j$(nproc)

if [[ ! -f "$BINARY_PATH" ]]; then
  echo "ERROR: Binary not found at $BINARY_PATH" >&2
  exit 1
fi
echo "✓ Binary built: $BINARY_PATH"

# Create deploy structure
echo ""
echo "[2/4] Creating deployment structure..."
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/bin"
mkdir -p "$DEPLOY_DIR/lib"

# Copy binary
cp "$BINARY_PATH" "$DEPLOY_DIR/bin/"
chmod +x "$DEPLOY_DIR/bin/${APP_NAME}"

# Copy config
if [[ -f "${ROOT_DIR}/configs/pemConfigs.json" ]]; then
  cp "${ROOT_DIR}/configs/pemConfigs.json" "$DEPLOY_DIR/"
else
  echo "WARNING: No default config found" >&2
fi

# Bundle shared libraries
echo ""
echo "[3/4] Bundling shared libraries..."
NEEDED_LIBS=$(ldd "$BINARY_PATH" | grep '/usr/local/lib' | awk '{print $3}')

if [[ -n "$NEEDED_LIBS" ]]; then
  while IFS= read -r lib; do
    if [[ -f "$lib" ]]; then
      lib_dir=$(dirname "$lib")
      lib_base=$(basename "$lib" | sed 's/\.so\..*//')
      
      # Copy all related .so files and symlinks
      find "$lib_dir" -name "${lib_base}.so*" \( -type f -o -type l \) -exec cp -P {} "$DEPLOY_DIR/lib/" \;
      echo "  ✓ $(basename "$lib")"
    fi
  done <<< "$NEEDED_LIBS"
else
  echo "  ⚠ No libraries found in /usr/local/lib"
fi

# Set RPATH
if command -v patchelf &>/dev/null; then
  patchelf --set-rpath '$ORIGIN/../lib:/usr/local/lib' "$DEPLOY_DIR/bin/${APP_NAME}"
fi

# Copy installation scripts
cp "${ROOT_DIR}/install/${APP_NAME}.service" "$DEPLOY_DIR/"
cp "${ROOT_DIR}/install/install.sh" "$DEPLOY_DIR/"
cp "${ROOT_DIR}/install/uninstall.sh" "$DEPLOY_DIR/"
chmod +x "$DEPLOY_DIR/install.sh" "$DEPLOY_DIR/uninstall.sh"

# Create package
echo ""
echo "[4/4] Creating deployment package..."
VERSION=$(date +%Y%m%d_%H%M%S)
PACKAGE_NAME="${APP_NAME}-deploy-${VERSION}.zip"

# Create zip from inside deploy directory
cd "$DEPLOY_DIR"
zip -r "$ROOT_DIR/$PACKAGE_NAME" ./* >/dev/null
cd "$ROOT_DIR"

echo ""
echo "==========================================="
echo "✓ Package created: $PACKAGE_NAME"
echo "==========================================="
echo ""
echo "Package contents:"
unzip -l "$PACKAGE_NAME" | head -20
echo ""
echo "Size: $(du -h "$PACKAGE_NAME" | cut -f1)"
echo ""
echo "Deploy instructions:"
echo "  1. scp $PACKAGE_NAME user@target:/tmp/"
echo "  2. cd /tmp && unzip $PACKAGE_NAME"
echo "  3. sudo bash install.sh"
