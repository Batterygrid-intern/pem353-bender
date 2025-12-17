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

# Verktygskrav
if ! command -v patchelf >/dev/null 2>&1; then
  echo "Fel: patchelf saknas. Installera: sudo apt-get install patchelf" >&2
  exit 1
fi
if ! command -v ldconfig >/dev/null 2>&1; then
  echo "Fel: ldconfig saknas (ovanligt). Kan inte resolve:a libs." >&2
  exit 1
fi
if ! command -v zip >/dev/null 2>&1; then
  echo "Fel: zip saknas. Installera: sudo apt-get install zip" >&2
  exit 1
fi

echo "Sätter RPATH..."
patchelf --set-rpath '$ORIGIN/../lib' "${STAGE_DIR}/opt/${APP_NAME}/bin/${APP_NAME}"

echo "Bundlar runtime-bibliotek via patchelf --print-needed + ldconfig -p..."
mapfile -t needed < <(patchelf --print-needed "${STAGE_DIR}/opt/${APP_NAME}/bin/${APP_NAME}" | sort -u)

if [[ "${#needed[@]}" -eq 0 ]]; then
  echo "Fel: inga NEEDED-bibliotek hittades. Är binären statiskt länkad?" >&2
  echo "Testa: ldd ${BIN}" >&2
  exit 1
fi

missing=0
for libname in "${needed[@]}"; do
  libpath="$(ldconfig -p | awk -v n="$libname" '$1==n {print $NF; exit}')"
  if [[ -z "$libpath" || ! -e "$libpath" ]]; then
    echo "Fel: kunde inte resolve:a $libname via ldconfig -p" >&2
    missing=1
    continue
  fi

  dir="$(dirname "$libpath")"
  base="$(basename "$libpath")"
  stem="${base%%.so*}"

  # kopiera både versionsfil(er) och ev symlänkar (så gott det går)
  cp -a "${dir}/${stem}.so"* "${STAGE_DIR}/opt/${APP_NAME}/lib/" 2>/dev/null || {
    cp -L "$libpath" "${STAGE_DIR}/opt/${APP_NAME}/lib/" || true
  }
done

if [[ "$missing" -ne 0 ]]; then
  echo "Fel: minst ett NEEDED-bibliotek kunde inte resolve:as." >&2
  echo "Installera runtime-libs på buildmaskinen och bygg om." >&2
  exit 1
fi

echo "Verifiering 1: staged lib-folder innehåller .so-filer?"
shopt -s nullglob
sofiles=( "${STAGE_DIR}/opt/${APP_NAME}/lib/"*.so* )
shopt -u nullglob
if [[ "${#sofiles[@]}" -eq 0 ]]; then
  echo "Fel: inga .so-filer bundlades till ${STAGE_DIR}/opt/${APP_NAME}/lib" >&2
  echo "NEEDED var:" >&2
  patchelf --print-needed "${STAGE_DIR}/opt/${APP_NAME}/bin/${APP_NAME}" >&2 || true
  exit 1
fi

echo "Verifiering 2: ldd med LD_LIBRARY_PATH mot staged libs (ska inte visa 'not found')..."
LDD_OUT="$(LD_LIBRARY_PATH="${STAGE_DIR}/opt/${APP_NAME}/lib" ldd "${STAGE_DIR}/opt/${APP_NAME}/bin/${APP_NAME}" || true)"
echo "$LDD_OUT"
if echo "$LDD_OUT" | grep -q "not found"; then
  echo "Fel: minst ett runtime-bibliotek är 'not found' efter bundling." >&2
  exit 1
fi

ZIP_PATH="${DIST_DIR}/pem353.zip"
rm -f "$ZIP_PATH"
( cd "$STAGE_DIR" && zip -r -9 "$ZIP_PATH" . >/dev/null )

echo "Skapade paket: $ZIP_PATH"
echo "Kontrollera innehåll (ska visa opt/pem353/lib/...):"
echo "  unzip -l ${ZIP_PATH} | grep 'opt/pem353/lib/'"