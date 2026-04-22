#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — fragments lint
#
# Fragment files under fragments/ are the raw CONTENT that
# spade-marker-replace wraps with SPADE-FRAMEWORK-START / END markers
# when it inserts them into a consumer repo. They must therefore NOT
# contain any SPADE-FRAMEWORK markers themselves — embedding a marker in
# a fragment would produce a malformed block after insertion.
#
# Checks:
#   1. Every fragments/*.md exists and is non-empty.
#   2. No fragment contains a SPADE-FRAMEWORK-START or -END line.
#   3. The .spade/version file exists and carries a spade_version=X.Y.Z
#      line. (Version drift between fragments and the pin is covered in
#      Bundle E's migration test.)
#
# Exit codes:
#   0  clean
#   1  violation found

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FRAG_DIR="$REPO_ROOT/fragments"
VERSION_FILE="$REPO_ROOT/.spade/version"

fail=0

for frag in "$FRAG_DIR"/AGENTS-section.md "$FRAG_DIR"/CLAUDE-section.md; do
    rel="${frag#$REPO_ROOT/}"
    if [ ! -s "$frag" ]; then
        echo "  FAIL: $rel is missing or empty"
        fail=$((fail + 1))
        continue
    fi
    if grep -qE '^<!-- SPADE-FRAMEWORK-(START|END)' "$frag"; then
        echo "  FAIL: $rel contains a SPADE-FRAMEWORK marker (fragments must be raw content only)"
        fail=$((fail + 1))
    else
        echo "  ok:   $rel has no internal markers"
    fi
done

if [ ! -f "$VERSION_FILE" ]; then
    echo "  FAIL: .spade/version is missing"
    fail=$((fail + 1))
elif ! grep -qE '^spade_version=[0-9]+\.[0-9]+\.[0-9]+$' "$VERSION_FILE"; then
    echo "  FAIL: .spade/version does not carry spade_version=X.Y.Z"
    fail=$((fail + 1))
else
    version_line=$(grep -E '^spade_version=' "$VERSION_FILE")
    echo "  ok:   .spade/version pins $version_line"
fi

echo
echo "lint-fragments: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
