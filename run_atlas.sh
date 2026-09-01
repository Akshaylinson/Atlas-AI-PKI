#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/atlas-app"
PACKAGE_ROOT="${ATLAS_PACKAGE_ROOT:-${SCRIPT_DIR}/Atlas}"

if [[ ! -f "${PACKAGE_ROOT}/atlas-manifest.json" ]]; then
  echo "Atlas package not found at ${PACKAGE_ROOT}"
  exit 1
fi

# FAT32/noexec: copy app bundle to /tmp and run from there
TMP_APP="/tmp/atlas-run"
echo "→ Syncing app to /tmp/atlas-run ..."
rsync -a --delete "${APP_DIR}/" "${TMP_APP}/"
chmod +x "${TMP_APP}/atlas"

export ATLAS_PACKAGE_ROOT="${PACKAGE_ROOT}"
exec "${TMP_APP}/atlas" "$@"
