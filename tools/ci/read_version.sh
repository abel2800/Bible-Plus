#!/usr/bin/env bash
# Reads version name and build number from pubspec.yaml.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="$(grep '^version:' "$ROOT/pubspec.yaml" | awk '{print $2}')"

export APP_VERSION="$VERSION"
export APP_VERSION_NAME="${VERSION%%+*}"
export APP_BUILD_NUMBER="${VERSION#*+}"

echo "APP_VERSION=$APP_VERSION"
echo "APP_VERSION_NAME=$APP_VERSION_NAME"
echo "APP_BUILD_NUMBER=$APP_BUILD_NUMBER"
