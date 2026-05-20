#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — local-mode artefact schema lint (M-1023 AC#1 + AC#2)
#
# Enforces the Scope frontmatter schema and lightly checks Plan
# frontmatter for SPADE local-mode artefacts under .spade/.
#
#   .spade/scopes/*.md  — HARD-fails on an invalid status/type/priority
#                         enum value or a missing core required field
#                         (name, title, status, type, created, updated).
#                         WARNS (never fails) on an unknown field and on
#                         a missing `id` field — the v1.8 addition is
#                         grandfathered on pre-existing files.
#   .spade/plans/*.md   — light, warn-only: the frontmatter must parse;
#                         a missing recognised field only warns.
#                         Historical Plan files (M-323/M-343/M-420 era)
#                         have genuinely inconsistent frontmatter, so
#                         this check never hard-fails them.
#
# Learning files are NOT validated here — lint-learnings.sh already
# covers .spade/learnings/*.md frontmatter.
#
# The canonical enum value sets live in docs/FRAMEWORK.md § Local Layout
# and are mirrored in scripts/lint/frontmatter.py. Extending an enum
# means editing that section AND the validator together — never broaden
# the lists here to silence a real file.
#
# A planted-fixture self-test runs on every invocation so the detection
# logic cannot rot silently: the bad-enum fixture MUST hard-fail and the
# legacy (no-`id`) fixture MUST pass.
#
# Exit codes:
#   0  every Scope and Plan file is schema-valid; the self-test holds
#   1  a hard-fail violation, or the self-test no longer behaves.
#      (Exit 2 is reserved across the lint suite for "skip"; this lint
#      never skips, so it never exits 2 — see scripts/lint/run-all.sh.)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATOR="$REPO_ROOT/scripts/lint/frontmatter.py"
SCOPES_DIR="$REPO_ROOT/.spade/scopes"
PLANS_DIR="$REPO_ROOT/.spade/plans"
FIXTURE_DIR="$REPO_ROOT/tests/fixtures/local-frontmatter"

fail=0
note() { echo "local-frontmatter: $*"; }

# validate <scope|plan> <file> — runs the schema validator, returns its
# exit code, and bumps `fail` on a hard failure.
validate() {
    local kind="$1" file="$2"
    if ! python3 "$VALIDATOR" --schema "$kind" "$file"; then
        fail=$((fail + 1))
        return 1
    fi
    return 0
}

# --- Scopes: hard schema enforcement -------------------------------------
if [ -d "$SCOPES_DIR" ]; then
    shopt -s nullglob
    scopes=("$SCOPES_DIR"/*.md)
    shopt -u nullglob
    if [ "${#scopes[@]}" -eq 0 ]; then
        note "no Scope files under .spade/scopes/"
    fi
    for f in "${scopes[@]}"; do
        validate scope "$f" || true
    done
else
    note "no .spade/scopes/ directory; nothing to validate"
fi

# --- Plans: light, warn-only check ---------------------------------------
if [ -d "$PLANS_DIR" ]; then
    shopt -s nullglob
    plans=("$PLANS_DIR"/*.md)
    shopt -u nullglob
    if [ "${#plans[@]}" -eq 0 ]; then
        note "no Plan files under .spade/plans/"
    fi
    for f in "${plans[@]}"; do
        validate plan "$f" || true
    done
else
    note "no .spade/plans/ directory; nothing to validate"
fi

# --- Self-test: the planted fixtures MUST still behave -------------------
# If the bad-enum fixture stops hard-failing, or the legacy fixture stops
# passing, the schema logic has rotted and the lint is blind — that is
# itself a failure.
echo
BAD_ENUM="$FIXTURE_DIR/bad-enum-scope.md"
LEGACY="$FIXTURE_DIR/legacy-scope.md"

if [ ! -f "$BAD_ENUM" ]; then
    note "FAIL — bad-enum fixture missing: $BAD_ENUM" >&2
    fail=$((fail + 1))
elif python3 "$VALIDATOR" --schema scope "$BAD_ENUM" >/dev/null 2>&1; then
    note "FAIL — bad-enum fixture no longer hard-fails; enum enforcement is broken" >&2
    fail=$((fail + 1))
else
    note "ok   — bad-enum fixture is still rejected"
fi

if [ ! -f "$LEGACY" ]; then
    note "FAIL — legacy fixture missing: $LEGACY" >&2
    fail=$((fail + 1))
elif python3 "$VALIDATOR" --schema scope "$LEGACY" >/dev/null 2>&1; then
    note "ok   — legacy (no-'id') fixture still passes"
else
    note "FAIL — legacy fixture no longer passes; the missing-'id' grandfathering is broken" >&2
    fail=$((fail + 1))
fi

echo
if [ "$fail" -eq 0 ]; then
    note "all local-mode artefacts are schema-valid"
    exit 0
fi
note "$fail failure(s)"
exit 1
