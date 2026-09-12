#!/usr/bin/env bash
# Local/CI verification entrypoint for Bible Plus.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "==> flutter pub get"
flutter pub get

echo "==> dart format"
dart format --output=none --set-exit-if-changed lib test

echo "==> flutter analyze"
flutter analyze lib test --no-fatal-infos

echo "==> flutter test"
flutter test --exclude-tags golden

echo "==> validate content manifest"
python tools/content/validate_manifest.py

echo "==> flutter build web (release smoke test)"
flutter build web --release

echo "All verification checks passed."
