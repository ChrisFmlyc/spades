#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — skill frontmatter lint
#
# Walks every .claude/skills/*/SKILL.md in the repo and asserts the
# frontmatter parses cleanly and carries the required fields.
#
# Required per-skill fields: name, description.
#
# Exit codes:
#   0  all skills valid
#   1  one or more skills failed validation
#   2  repo structure unexpected (no .claude/skills/ directory)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PARSER="$REPO_ROOT/scripts/lint/frontmatter.py"
SKILLS_DIR="$REPO_ROOT/.claude/skills"

if [ ! -d "$SKILLS_DIR" ]; then
    echo "lint-skill-frontmatter: no skills directory at $SKILLS_DIR" >&2
    exit 2
fi

fail=0
checked=0
for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
    [ -f "$skill_md" ] || continue
    checked=$((checked + 1))
    rel="${skill_md#$REPO_ROOT/}"
    if ! python3 "$PARSER" "$skill_md" --require name,description >/dev/null; then
        echo "  FAIL: $rel"
        fail=$((fail + 1))
    else
        echo "  ok:   $rel"
    fi
done

echo
echo "lint-skill-frontmatter: checked $checked skill(s), $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
