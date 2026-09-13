#!/usr/bin/env bash
set -euo pipefail

# SPADES Framework v2.0 — local-mode artefact schema lint.
#
# Enforces frontmatter schemas under .spades/:
#
#   .spades/projects/*.md  — Project schema (id, title, description,
#                            created, updated required; id must match
#                            [a-z0-9][a-z0-9-]{0,63}; optional lead is a
#                            non-empty string; linear_lead_id is a UUID
#                            and requires lead)
#   .spades/scopes/S-*.md  — Scope schema (id, title, project, status,
#                            type, created, updated required; id must
#                            match S-[a-z0-9][a-z0-9-]{0,63}; status/
#                            type/priority/origin enums hard-checked)
#   .spades/plans/P-*.md   — Plan schema (id, id_suffix, scope, title,
#                            status, deliverable_type, created, updated
#                            required; id must match P-<slug>-<4char>;
#                            id_suffix must be 4 chars [A-Za-z0-9])
#
# Learning files (.spades/learnings/*.md) are covered by lint-learnings.sh.
#
# Canonical schemas live in docs/FRAMEWORK.md § .spades/ Local Layout and
# are mirrored in scripts/lint/frontmatter.ts. Extending an enum means
# editing both — never broaden lists here to silence a real file.
#
# A planted-fixture self-test runs on every invocation so the detection
# logic cannot rot silently.
#
# Exit codes:
#   0  every artefact is schema-valid; the self-test holds
#   1  a hard-fail violation, or the self-test no longer behaves

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATOR="$REPO_ROOT/scripts/lint/frontmatter.ts"
PROJECTS_DIR="$REPO_ROOT/.spades/projects"
SCOPES_DIR="$REPO_ROOT/.spades/scopes"
PLANS_DIR="$REPO_ROOT/.spades/plans"
FIXTURE_DIR="$REPO_ROOT/tests/fixtures/local-frontmatter"

fail=0
note() { echo "local-frontmatter: $*"; }

# validate <project|scope|plan> <file>
validate() {
    local kind="$1" file="$2"
    if ! node "$VALIDATOR" --schema "$kind" "$file"; then
        fail=$((fail + 1))
        return 1
    fi
    return 0
}

run_dir() {
    local kind="$1" dir="$2"
    if [ ! -d "$dir" ]; then
        note "no ${dir#"$REPO_ROOT"/} directory; skipping ${kind}s"
        return
    fi
    shopt -s nullglob
    # Walk both .md (CLI-mode artefacts) and .html (HTML-mode artefacts,
    # introduced in v3.0.0). The validator parses YAML frontmatter from
    # either source format — see scripts/lint/frontmatter.ts.
    local files=("$dir"/*.md "$dir"/*.html)
    shopt -u nullglob
    if [ "${#files[@]}" -eq 0 ]; then
        note "no ${kind} files under ${dir#"$REPO_ROOT"/}"
        return
    fi
    for f in "${files[@]}"; do
        validate "$kind" "$f" || true
    done
}

run_dir project "$PROJECTS_DIR"
run_dir scope   "$SCOPES_DIR"
run_dir plan    "$PLANS_DIR"

# --- Self-test ----------------------------------------------------------
# Valid Project, Scope and Plan fixtures pass; malformed fixtures fail.
echo
self_test() {
    local kind="$1" fixture="$2" expect="$3"
    local path="$FIXTURE_DIR/$fixture"
    if [ ! -f "$path" ]; then
        note "FAIL — fixture missing: $fixture" >&2
        fail=$((fail + 1))
        return
    fi
    if node "$VALIDATOR" --schema "$kind" "$path" >/dev/null 2>&1; then
        if [ "$expect" = "pass" ]; then
            note "ok   — $fixture still passes"
        else
            note "FAIL — $fixture should hard-fail but doesn't" >&2
            fail=$((fail + 1))
        fi
    else
        if [ "$expect" = "fail" ]; then
            note "ok   — $fixture still rejected"
        else
            note "FAIL — $fixture should pass but doesn't" >&2
            fail=$((fail + 1))
        fi
    fi
}

self_test project good-project.md pass
self_test project good-project-local-lead.md pass
self_test project good-project-linear-lead.md pass
self_test project bad-project-lead-escaped-newline.md fail
self_test project bad-project-lead-escaped-return.md fail
self_test project bad-project-lead-unicode-newline.md fail
self_test project bad-project-lead-unicode-return.md fail
self_test project good-project-lead-literal-backslashes.md pass
self_test project bad-project-lead-list.md fail
self_test project bad-project-lead-map.md fail
self_test project bad-project-lead-boolean.md fail
self_test project bad-project-lead-number.md fail
self_test project bad-project-lead-empty.md fail
self_test project bad-project-lead-null.md fail
self_test project bad-project-linear-lead-type.md fail
self_test project bad-project-linear-lead-id.md fail
self_test project bad-project-linear-lead-without-lead.md fail

self_test scope bad-scope.md  fail
self_test scope good-scope.md pass
self_test plan  bad-plan.md   fail
self_test plan  good-plan.md  pass
self_test plan  good-shipping-plan.md pass

echo
if [ "$fail" -eq 0 ]; then
    note "all v2 artefacts are schema-valid"
    exit 0
fi
note "$fail failure(s)"
exit 1
