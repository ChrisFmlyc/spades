#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — handoff launcher lint
#
# Delegates to tests/handoff-launch.sh, which exercises
# bin/spade-handoff-launch in --dry-run mode (headless — no terminal is
# spawned and osascript is never called) and asserts injection-safety of
# the handoff prompt, the worktree-collision guard, and the documented
# failure exit codes.
#
# Exit codes:
#   0  all assertions pass
#   1  one or more assertions failed
#   2  the underlying test script is missing

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST="$REPO_ROOT/tests/handoff-launch.sh"

if [ ! -x "$TEST" ]; then
    echo "lint-handoff: test script missing or not executable: $TEST" >&2
    exit 2
fi

echo "Running: $TEST"
if ! "$TEST"; then
    echo
    echo "lint-handoff: FAILED"
    exit 1
fi

echo
echo "lint-handoff: passed"
