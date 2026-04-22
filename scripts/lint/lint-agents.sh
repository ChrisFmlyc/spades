#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — agent (subagent) frontmatter lint
#
# Walks every .claude/agents/*.md in the repo and asserts the
# frontmatter parses cleanly and carries the required fields for a
# SPADE-defined persona subagent.
#
# Required fields:
#   - name         — e.g. spade-review-scope-guardian
#   - description  — tells Claude Code when to spawn this subagent
#   - model        — e.g. opus
#   - tools        — the subagent's tool allowlist (comma-separated
#                    string; we only check presence)
#
# Required SPADE-specific fields:
#   - persona      — short key matching the agent's role
#   - focus        — one-line focus statement
#
# Exit codes:
#   0  all agents valid
#   1  one or more agents failed validation
#   2  repo has no .claude/agents/ directory (fine for pre-v1.1.0
#      consumers; exits 0 with a skip message in that case)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PARSER="$REPO_ROOT/scripts/lint/frontmatter.py"
AGENTS_DIR="$REPO_ROOT/.claude/agents"

if [ ! -d "$AGENTS_DIR" ]; then
    echo "lint-agents: no .claude/agents/ directory; nothing to validate"
    exit 0
fi

shopt -s nullglob
files=("$AGENTS_DIR"/*.md)
shopt -u nullglob

if [ "${#files[@]}" -eq 0 ]; then
    echo "lint-agents: .claude/agents/ exists but is empty; nothing to validate"
    exit 0
fi

fail=0
for f in "${files[@]}"; do
    rel="${f#"$REPO_ROOT"/}"
    if ! python3 "$PARSER" "$f" \
        --require name,description,model,tools,persona,focus >/dev/null; then
        echo "  FAIL: $rel"
        fail=$((fail + 1))
    else
        echo "  ok:   $rel"
    fi
done

echo
echo "lint-agents: checked ${#files[@]} agent file(s), $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
