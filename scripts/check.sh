#!/usr/bin/env bash
# Quality checks shared by git hooks and CI.
#
# Usage: scripts/check.sh <step>...
#   format   fail if any Dart file is not formatted
#   analyze  flutter analyze with zero issues allowed
#   test     unit + widget tests
#   build    release APK build
#   offline  fail if the release APK requests the INTERNET permission
#   all      every step above, in order
set -euo pipefail

cd "$(dirname "$0")/.."

step_format() {
  echo "▸ dart format"
  dart format --output=none --set-exit-if-changed lib test integration_test
}

step_analyze() {
  echo "▸ flutter analyze"
  flutter analyze --fatal-infos --fatal-warnings
}

step_test() {
  echo "▸ flutter test"
  flutter test
}

step_build() {
  echo "▸ flutter build apk --release"
  flutter build apk --release
}

step_offline() {
  echo "▸ offline check"
  local apk="build/app/outputs/flutter-apk/app-release.apk"
  if [[ ! -f "$apk" ]]; then
    echo "  $apk not found; run 'scripts/check.sh build' first" >&2
    exit 1
  fi
  local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  if [[ -z "$sdk" && -f android/local.properties ]]; then
    sdk="$(sed -n 's/^sdk\.dir=//p' android/local.properties)"
  fi
  if [[ -z "$sdk" ]]; then
    echo "  Android SDK not found: set ANDROID_HOME" >&2
    exit 1
  fi
  local aapt2
  aapt2="$(ls -d "$sdk"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1)"
  if [[ -z "$aapt2" ]]; then
    echo "  aapt2 not found under $sdk/build-tools" >&2
    exit 1
  fi
  if "$aapt2" dump permissions "$apk" | grep -q 'android.permission.INTERNET'; then
    echo "  ✗ release APK requests android.permission.INTERNET; the app must stay offline" >&2
    exit 1
  fi
  echo "  ✓ no INTERNET permission"
}

if [[ $# -eq 0 ]]; then
  set -- all
fi

for s in "$@"; do
  case "$s" in
    format) step_format ;;
    analyze) step_analyze ;;
    test) step_test ;;
    build) step_build ;;
    offline) step_offline ;;
    all) step_format; step_analyze; step_test; step_build; step_offline ;;
    *) echo "unknown step: $s" >&2; exit 2 ;;
  esac
done
