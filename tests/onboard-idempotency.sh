#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — onboarding idempotency test
#
# Exercises bin/spade-marker-replace against the fixtures under
# tests/fixtures/ and asserts:
#
#   1. Running onboarding twice produces the same output on the second run
#      (no drift, no duplicated marker blocks).
#   2. A fixture with an old v1.0.0 block ends with exactly one block and
#      the current content, not the stale content.
#   3. A clean fixture gains exactly one block.
#   4. Mismatched / duplicate marker files are rejected without modification.
#
# Usage: tests/onboard-idempotency.sh
# Exits non-zero on any failure.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$REPO_ROOT/bin/spade-marker-replace"
FRAG_AGENTS="$REPO_ROOT/fragments/AGENTS-section.md"
FRAG_CLAUDE="$REPO_ROOT/fragments/CLAUDE-section.md"
FIXTURES="$REPO_ROOT/tests/fixtures"
VERSION="1.0.0"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

# Count lines matching the START marker pattern (any version).
count_starts() {
    grep -c -E '^<!-- SPADE-FRAMEWORK-START v[0-9]+\.[0-9]+\.[0-9]+ -->$' "$1" || true
}

count_ends() {
    grep -c -E '^<!-- SPADE-FRAMEWORK-END -->$' "$1" || true
}

# --- Case 1: clean fixture gets one block; second run produces no diff ---
echo
echo "Case 1: clean AGENTS.md, two runs"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp "$FIXTURES/onboard-clean/AGENTS.md" "$tmp/AGENTS.md"
"$HELPER" "$tmp/AGENTS.md" "$FRAG_AGENTS" "$VERSION"
cp "$tmp/AGENTS.md" "$tmp/AGENTS.after-run1.md"
"$HELPER" "$tmp/AGENTS.md" "$FRAG_AGENTS" "$VERSION"
if diff -q "$tmp/AGENTS.after-run1.md" "$tmp/AGENTS.md" >/dev/null; then
    pass "idempotent on clean fixture"
else
    fail "second run drifted on clean fixture"
    diff "$tmp/AGENTS.after-run1.md" "$tmp/AGENTS.md" || true
fi
starts=$(count_starts "$tmp/AGENTS.md")
ends=$(count_ends "$tmp/AGENTS.md")
if [ "$starts" = "1" ] && [ "$ends" = "1" ]; then
    pass "exactly one marker pair present"
else
    fail "expected 1 START / 1 END, got $starts / $ends"
fi

# --- Case 2: existing fixture with stale v1.0.0 block gets refreshed content ---
echo
echo "Case 2: existing AGENTS.md with stale v1.0.0 block"
cp "$FIXTURES/onboard-existing/AGENTS.md" "$tmp/AGENTS2.md"
"$HELPER" "$tmp/AGENTS2.md" "$FRAG_AGENTS" "$VERSION"
cp "$tmp/AGENTS2.md" "$tmp/AGENTS2.after-run1.md"
"$HELPER" "$tmp/AGENTS2.md" "$FRAG_AGENTS" "$VERSION"
if diff -q "$tmp/AGENTS2.after-run1.md" "$tmp/AGENTS2.md" >/dev/null; then
    pass "idempotent on existing-block fixture"
else
    fail "second run drifted on existing-block fixture"
fi
starts=$(count_starts "$tmp/AGENTS2.md")
ends=$(count_ends "$tmp/AGENTS2.md")
if [ "$starts" = "1" ] && [ "$ends" = "1" ]; then
    pass "existing-block fixture ends with exactly one pair (not duplicated)"
else
    fail "existing-block fixture has $starts START / $ends END markers"
fi
if grep -q "OLD AND STALE CONTENT" "$tmp/AGENTS2.md"; then
    fail "stale content was not replaced"
else
    pass "stale content replaced with current fragment"
fi
if grep -q "The block must not swallow this content." "$tmp/AGENTS2.md"; then
    pass "content after the block survived"
else
    fail "content after the block was lost"
fi

# --- Case 3: version bump v1.0.0 -> v1.1.0 re-stamps the START marker ---
echo
echo "Case 3: version bump re-stamps START marker"
cp "$FIXTURES/onboard-existing/AGENTS.md" "$tmp/AGENTS3.md"
"$HELPER" "$tmp/AGENTS3.md" "$FRAG_AGENTS" "1.1.0"
if grep -q '^<!-- SPADE-FRAMEWORK-START v1.1.0 -->$' "$tmp/AGENTS3.md"; then
    pass "START marker updated to v1.1.0"
else
    fail "START marker was not re-stamped"
fi
if grep -q '^<!-- SPADE-FRAMEWORK-START v1.0.0 -->$' "$tmp/AGENTS3.md"; then
    fail "stale v1.0.0 START marker still present"
else
    pass "stale v1.0.0 START marker gone"
fi

# --- Case 4: duplicate markers are rejected without modification ---
echo
echo "Case 4: duplicate markers rejected"
cat > "$tmp/dup.md" <<'EOF'
content
<!-- SPADE-FRAMEWORK-START v1.0.0 -->
block one
<!-- SPADE-FRAMEWORK-END -->
middle content
<!-- SPADE-FRAMEWORK-START v1.0.0 -->
block two
<!-- SPADE-FRAMEWORK-END -->
trailing
EOF
cp "$tmp/dup.md" "$tmp/dup.backup.md"
if "$HELPER" "$tmp/dup.md" "$FRAG_AGENTS" "$VERSION" 2>/dev/null; then
    fail "helper accepted duplicate markers"
else
    pass "helper rejected duplicate markers"
fi
if diff -q "$tmp/dup.backup.md" "$tmp/dup.md" >/dev/null; then
    pass "duplicate-markers file was not modified"
else
    fail "duplicate-markers file was modified despite rejection"
fi

# --- Case 5: mismatched markers rejected ---
echo
echo "Case 5: mismatched markers rejected"
cat > "$tmp/bad.md" <<'EOF'
<!-- SPADE-FRAMEWORK-START v1.0.0 -->
unterminated
EOF
cp "$tmp/bad.md" "$tmp/bad.backup.md"
if "$HELPER" "$tmp/bad.md" "$FRAG_AGENTS" "$VERSION" 2>/dev/null; then
    fail "helper accepted mismatched markers"
else
    pass "helper rejected mismatched markers"
fi
if diff -q "$tmp/bad.backup.md" "$tmp/bad.md" >/dev/null; then
    pass "mismatched-markers file was not modified"
else
    fail "mismatched-markers file was modified despite rejection"
fi

# --- Case 6: CLAUDE.md fixture also idempotent ---
echo
echo "Case 6: CLAUDE.md fixture idempotent"
cp "$FIXTURES/onboard-existing/CLAUDE.md" "$tmp/CLAUDE.md"
"$HELPER" "$tmp/CLAUDE.md" "$FRAG_CLAUDE" "$VERSION"
cp "$tmp/CLAUDE.md" "$tmp/CLAUDE.after-run1.md"
"$HELPER" "$tmp/CLAUDE.md" "$FRAG_CLAUDE" "$VERSION"
if diff -q "$tmp/CLAUDE.after-run1.md" "$tmp/CLAUDE.md" >/dev/null; then
    pass "idempotent on CLAUDE.md existing fixture"
else
    fail "CLAUDE.md drifted on second run"
fi

echo
echo "----------------------------------------"
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
