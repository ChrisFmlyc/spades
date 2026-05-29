#!/usr/bin/env bash
set -euo pipefail

# SPADES Framework — skill frontmatter lint
#
# Walks every skills/*/SKILL.md in the repo and asserts the
# frontmatter parses cleanly and carries the required fields.
#
# Required per-skill fields: name, description, version.
#
# The version: field carries the skill's own semver (e.g. 2.0.0). It
# bumps only when that skill's body or frontmatter changes — the
# overall plugin version (in .claude-plugin/plugin.json) bumps on
# every merged PR. See AGENTS.md § Versioning for the full policy.
#
# Format check: a basic semver-shaped value (X.Y.Z, digits and dots).
# Pre-release / build-metadata suffixes (1.2.3-rc.1, 1.2.3+build.42)
# are not used by this plugin and are rejected by the regex below.
# Loosen the regex if that policy changes.
#
# Exit codes:
#   0  all skills valid
#   1  one or more skills failed validation
#   2  repo structure unexpected (no skills/ directory)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PARSER="$REPO_ROOT/scripts/lint/frontmatter.py"
SKILLS_DIR="$REPO_ROOT/skills"

if [ ! -d "$SKILLS_DIR" ]; then
    echo "lint-skill-frontmatter: no skills directory at $SKILLS_DIR" >&2
    exit 2
fi

SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+$'
fail=0
checked=0
for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
    [ -f "$skill_md" ] || continue
    checked=$((checked + 1))
    rel="${skill_md#"$REPO_ROOT"/}"
    # name, description, version must all be present.
    if ! python3 "$PARSER" "$skill_md" --require name,description,version >/dev/null; then
        echo "  FAIL: $rel (missing required field)"
        fail=$((fail + 1))
        continue
    fi
    # Validate the version: field is a plain X.Y.Z semver.
    version=$(python3 "$PARSER" "$skill_md" --print | awk -F= '/^version=/ {sub("^version=", ""); print; exit}')
    if ! echo "$version" | grep -qE "$SEMVER_RE"; then
        echo "  FAIL: $rel (version='$version' is not X.Y.Z semver)"
        fail=$((fail + 1))
    else
        echo "  ok:   $rel (v$version)"
    fi
done

echo
echo "lint-skill-frontmatter: checked $checked skill(s), $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
