#!/usr/bin/env bash
# Quality checks shared by git hooks and CI.
#
# Usage: scripts/check.sh <step>...
#   format   fail if any Dart file is not formatted
#   analyze  flutter analyze with zero issues allowed
#   test     unit + widget tests
#   build    release APK build
#   permissions  fail if the release APK asks for anything outside the allowlist
#   resources    fail if resources looked up by name were shrunk away
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

# Permissions the release APK may request; anything else fails the build.
ALLOWED_PERMISSIONS=(
  android.permission.POST_NOTIFICATIONS
  android.permission.SCHEDULE_EXACT_ALARM
  android.permission.USE_FULL_SCREEN_INTENT
  android.permission.RECEIVE_BOOT_COMPLETED
  android.permission.VIBRATE
  android.permission.WAKE_LOCK
  android.permission.INTERNET
  android.permission.REQUEST_INSTALL_PACKAGES
  io.github.saranshsinhaa.hydrate_sir.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
)

step_permissions() {
  echo "▸ permission check"
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
  local bad=0 p
  while read -r p; do
    [[ -z "$p" ]] && continue
    if [[ ! " ${ALLOWED_PERMISSIONS[*]} " == *" $p "* ]]; then
      echo "  ✗ unexpected permission: $p" >&2
      bad=1
    fi
  done < <("$aapt2" dump permissions "$apk" | sed -n "s/.*name='\([^']*\)'.*/\1/p")
  [[ $bad -eq 0 ]] || exit 1
  echo "  ✓ only the allowed permissions"
}

# Resources the Dart code looks up by name. Release builds shrink away
# anything that looks unused, so make sure these survived.
REQUIRED_DRAWABLES=(ic_stat_bowtie)

step_resources() {
  echo "▸ resource check"
  local apk="build/app/outputs/flutter-apk/app-release.apk"
  local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  if [[ -z "$sdk" && -f android/local.properties ]]; then
    sdk="$(sed -n 's/^sdk\.dir=//p' android/local.properties)"
  fi
  local aapt2
  aapt2="$(ls -d "$sdk"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1)"
  local dump bad=0 d
  dump="$("$aapt2" dump resources "$apk")"
  for d in "${REQUIRED_DRAWABLES[@]}"; do
    if ! grep -q "drawable/$d\$" <<<"$dump"; then
      echo "  ✗ drawable/$d is missing from the release APK" >&2
      bad=1
    fi
  done
  [[ $bad -eq 0 ]] || exit 1
  echo "  ✓ required resources present"
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
    permissions | offline) step_permissions ;;
    resources) step_resources ;;
    all) step_format; step_analyze; step_test; step_build; step_permissions; step_resources ;;
    *) echo "unknown step: $s" >&2; exit 2 ;;
  esac
done
