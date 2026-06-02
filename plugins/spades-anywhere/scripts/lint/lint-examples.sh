#!/usr/bin/env bash
set -euo pipefail

# SPADES Framework v2.0 — examples lint
#
# Validates that the worked examples under examples/ conform to the
# v2 frontmatter schemas. The example files are the canonical reference
# for what well-formed SPADES artefacts look like, so drift here means
# AI agents generate the wrong shape.
#
# Checks:
#   1. examples/example-scope.md  — passes the v2 Scope schema
#   2. examples/example-plan.md   — passes the v2 Plan schema
#   3. examples/example-intent.md — has the six locked INTENT.md sections
#      plus a `last_reviewed:` frontmatter key
#   4. examples/fixture-local-mode/.spades/ — contains at least one
#      schema-valid Scope and Plan
#
# Exit codes:
#   0  every example conforms
#   1  one or more violations
#   2  an example file is missing

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PARSER="$REPO_ROOT/scripts/lint/frontmatter.py"
SCOPE="$REPO_ROOT/examples/example-scope.md"
PLAN="$REPO_ROOT/examples/example-plan.md"
INTENT="$REPO_ROOT/examples/example-intent.md"
LOCAL_FIXTURE="$REPO_ROOT/examples/fixture-local-mode/.spades"

fail=0

run_schema() {
    local kind="$1" file="$2" label="$3"
    if [ ! -f "$file" ]; then
        echo "lint-examples: missing $label ($file)" >&2
        exit 2
    fi
    if python3 "$PARSER" --schema "$kind" "$file" >/dev/null 2>&1; then
        echo "  ok:   $label conforms to v2 $kind schema"
    else
        echo "  FAIL: $label does not conform to v2 $kind schema"
        python3 "$PARSER" --schema "$kind" "$file" 2>&1 | sed 's/^/    /'
        fail=$((fail + 1))
    fi
}

run_schema scope "$SCOPE" "examples/example-scope.md"
run_schema plan  "$PLAN"  "examples/example-plan.md"

# --- INTENT.md example: six locked sections + last_reviewed key ----------
if [ ! -f "$INTENT" ]; then
    echo "lint-examples: missing examples/example-intent.md ($INTENT)" >&2
    exit 2
fi

intent_require() {
    local pattern="$1" label="$2"
    if grep -qE "$pattern" "$INTENT"; then
        echo "  ok:   example-intent.md has $label"
    else
        echo "  FAIL: example-intent.md missing $label"
        fail=$((fail + 1))
    fi
}

intent_require '^last_reviewed:' 'last_reviewed frontmatter key'
intent_require '^## Problem[[:space:]]*$' 'Problem section'
intent_require '^## Users[[:space:]]*$' 'Users section'
intent_require '^## What it does[[:space:]]*$' 'What it does section'
intent_require '^## Success[[:space:]]*$' 'Success section'
intent_require '^## Non-goals[[:space:]]*$' 'Non-goals section'
intent_require '^## Maturity[[:space:]]*$' 'Maturity section'

# --- Local-mode fixture: at least one scope and one plan -----------------
if [ -d "$LOCAL_FIXTURE/scopes" ]; then
    shopt -s nullglob
    for f in "$LOCAL_FIXTURE"/scopes/*.md; do
        run_schema scope "$f" "${f#"$REPO_ROOT"/}"
    done
    shopt -u nullglob
fi
if [ -d "$LOCAL_FIXTURE/plans" ]; then
    shopt -s nullglob
    for f in "$LOCAL_FIXTURE"/plans/*.md; do
        run_schema plan "$f" "${f#"$REPO_ROOT"/}"
    done
    shopt -u nullglob
fi

echo
echo "lint-examples: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
