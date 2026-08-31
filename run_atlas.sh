#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/atlas-app"
PACKAGE_ROOT="${ATLAS_PACKAGE_ROOT:-${SCRIPT_DIR}/Atlas}"
APP_BINARY="${APP_DIR}/atlas.exe"

if [[ ! -x "${APP_BINARY}" && -x "${APP_DIR}/atlas" ]]; then
  APP_BINARY="${APP_DIR}/atlas"
fi

if [[ ! -e "${APP_BINARY}" ]]; then
  echo "Atlas binary not found at ${APP_DIR}/atlas or ${APP_DIR}/atlas.exe"
  exit 1
fi

if [[ ! -f "${PACKAGE_ROOT}/atlas-manifest.json" ]]; then
  echo "Atlas package not found at ${PACKAGE_ROOT}"
  exit 1
fi

export ATLAS_PACKAGE_ROOT="${PACKAGE_ROOT}"
exec "${APP_BINARY}" "$@"
