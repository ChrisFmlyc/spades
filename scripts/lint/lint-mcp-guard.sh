#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — MCP guard lint (M-879 AC#5)
#
# Every skill that can touch the Linear tracker MUST resolve the
# operating mode first (see docs/FRAMEWORK.md section Mode Resolver), so
# that `local` mode makes zero Linear MCP calls. This lint fails when a
# skill names a Linear MCP tool but carries no "## Mode Resolution"
# section — an unguarded MCP call.
#
# This is a known-bad-pattern grep, not a parser: it cannot prove a
# given call sits inside a mode-gated block, but it does prove the
# skill resolves a mode at all, and it catches a future skill (or edit)
# that reaches for MCP without wiring the resolver. A planted-violation
# fixture is exercised on every run so the detection logic cannot rot
# silently — the failure mode M-879 was scoped to close.
#
# Exit codes:
#   0  every skill that uses MCP resolves a mode; the fixture still trips
#   1  a violation — an unguarded skill, a missing skill file, or the
#      planted fixture no longer tripping. (Exit 2 is reserved across
#      the lint suite for "skip"; this lint never skips, so it never
#      exits 2 — see scripts/lint/run-all.sh.)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILLS_DIR="$REPO_ROOT/.claude/skills"

# The nine skills M-879 AC#5 names. Each must resolve a mode.
SKILLS="spade-scope spade-plan spade-approve spade-evaluate spade-list spade-status spade-learn spade-quick spade-onboard"

# Linear MCP tool tokens, as they appear bare in skill prose. Extend
# this list when a skill starts using a new Linear MCP tool.
MCP_TOOLS='list_teams|list_issues|get_issue|save_issue|save_comment|list_projects|list_comments|create_attachment|create_issue_label|list_issue_statuses|list_issue_labels'

GUARD='^## Mode Resolution'

fail=0
note() { echo "mcp-guard: $*"; }

uses_mcp()  { grep -Eqw "($MCP_TOOLS)" "$1"; }
has_guard() { grep -Eq "$GUARD" "$1"; }

for s in $SKILLS; do
    f="$SKILLS_DIR/$s/SKILL.md"
    if [ ! -f "$f" ]; then
        note "FAIL — missing skill file: $f" >&2
        fail=$((fail + 1))
        continue
    fi
    if uses_mcp "$f"; then
        if has_guard "$f"; then
            note "ok   — $s resolves a mode before MCP use"
        else
            note "FAIL — $s names a Linear MCP tool but has no '## Mode Resolution' section (unguarded MCP call)" >&2
            fail=$((fail + 1))
        fi
    else
        note "ok   — $s makes no MCP calls"
    fi
done

# Self-test: the planted-violation fixture MUST still trip the check.
# If it stops tripping, the detection logic has rotted and the lint is
# blind — that is itself a failure.
FIXTURE="$REPO_ROOT/tests/fixtures/mcp-guard/unguarded-skill.md"
if [ ! -f "$FIXTURE" ]; then
    note "FAIL — planted-violation fixture missing: $FIXTURE" >&2
    fail=$((fail + 1))
elif uses_mcp "$FIXTURE" && ! has_guard "$FIXTURE"; then
    note "ok   — planted-violation fixture is still detected as unguarded"
else
    note "FAIL — planted-violation fixture no longer trips the check; detection logic is broken" >&2
    fail=$((fail + 1))
fi

echo
if [ "$fail" -eq 0 ]; then
    note "all skills resolve a mode before any Linear MCP call"
    exit 0
fi
note "$fail failure(s)"
exit 1
