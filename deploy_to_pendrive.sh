#!/usr/bin/env bash
set -euo pipefail

PENDRIVE="/run/media/akshay-linson/UBUNTU 26_0"
PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/atlas" && pwd)"
BUNDLE="$PROJECT/build/linux/x64/release/bundle"

if [[ ! -d "$PENDRIVE" ]]; then
  echo "Pendrive not mounted at: $PENDRIVE"
  exit 1
fi

echo "→ Building..."
cd "$PROJECT"
flutter build linux --release

echo "→ Deploying app bundle..."
rsync -a --delete "$BUNDLE/" "$PENDRIVE/atlas-app/"
chmod +x "$PENDRIVE/atlas-app/atlas"

echo "→ Copying launcher..."
cp "$(dirname "$PROJECT")/run_atlas.sh" "$PENDRIVE/"
chmod +x "$PENDRIVE/run_atlas.sh"

echo "✓ Done. Run: bash run_atlas.sh from the pendrive."
