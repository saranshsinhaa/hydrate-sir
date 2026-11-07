#!/usr/bin/env bash
# Prints the CHANGELOG.md section for a version, without its heading.
# Fails if the version has no entry, so no release goes out undocumented.
#
# Usage: scripts/changelog.sh 1.0.1
set -euo pipefail

cd "$(dirname "$0")/.."

version="${1:?usage: scripts/changelog.sh <version>}"
version="${version#v}"

notes="$(awk -v v="$version" '
  /^## \[/ {
    if (found) exit
    if (index($0, "## [" v "]") == 1) { found = 1; next }
  }
  /^\[[^]]+\]: / { if (found) exit }
  found { print }
' CHANGELOG.md)"

# Trim blank lines at either end.
notes="$(printf '%s\n' "$notes" | sed -e '/./,$!d' | sed -e ':a' -e '/^\n*$/{$d;N;ba' -e '}')"

if [[ -z "$notes" ]]; then
  echo "✗ CHANGELOG.md has no entry for $version" >&2
  exit 1
fi
printf '%s\n' "$notes"
