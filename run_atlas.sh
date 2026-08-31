#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/atlas-app"
PACKAGE_ROOT="${ATLAS_PACKAGE_ROOT:-${SCRIPT_DIR}/Atlas}"

if [[ ! -x "${APP_DIR}/atlas" ]]; then
  echo "Atlas binary not found at ${APP_DIR}/atlas"
  exit 1
fi

if [[ ! -f "${PACKAGE_ROOT}/atlas-manifest.json" ]]; then
  echo "Atlas package not found at ${PACKAGE_ROOT}"
  exit 1
fi

export ATLAS_PACKAGE_ROOT="${PACKAGE_ROOT}"
exec "${APP_DIR}/atlas" "$@"
