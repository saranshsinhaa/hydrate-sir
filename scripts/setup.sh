#!/usr/bin/env bash
# One-time local setup. Checks your tools (it never installs anything),
# fetches packages and turns on the repo's git hooks.
set -euo pipefail

cd "$(dirname "$0")/.."

missing=0
need() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "✓ $1"
  else
    echo "✗ $1 not found: $2"
    missing=1
  fi
}

need flutter "see docs/SETUP.md"
need java "install JDK 17, see docs/SETUP.md"
need adb "install Android platform-tools, see docs/SETUP.md"

if [[ -z "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}" ]]; then
  echo "✗ ANDROID_HOME is not set, see docs/SETUP.md"
  missing=1
fi

[[ $missing -eq 0 ]] || { echo; echo "Fix the items above, then run this again."; exit 1; }

want="$(sed -n 's/^  flutter: *\([0-9.]*\).*/\1/p' pubspec.yaml)"
have="$(flutter --version --machine 2>/dev/null | sed -n 's/.*"frameworkVersion": *"\([^"]*\)".*/\1/p')"
if [[ -n "$want" && "$have" != "$want" ]]; then
  echo "! Flutter $have found, project is pinned to $want (pubspec.yaml). Builds may differ."
fi

chmod +x scripts/*.sh .githooks/*
git config core.hooksPath .githooks
echo "✓ git hooks enabled (.githooks)"

flutter pub get
echo
echo "Done. Plug in your phone and run: flutter run"
