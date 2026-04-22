#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — onboard idempotency lint
#
# Delegates to tests/onboard-idempotency.sh, which exercises the Bundle A
# marker-replace contract against fixtures and asserts running it twice
# produces an unchanged file. Also asserts exit codes 2 (mismatched
# markers), 3 (duplicate markers), and 1 (invalid version).
#
# Exit codes:
#   0  all idempotency assertions pass
#   1  one or more assertions failed
#   2  the underlying test script is missing

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST="$REPO_ROOT/tests/onboard-idempotency.sh"

if [ ! -x "$TEST" ]; then
    echo "lint-onboard-idempotency: test script missing or not executable: $TEST" >&2
    exit 2
fi

echo "Running: $TEST"
if ! "$TEST"; then
    echo
    echo "lint-onboard-idempotency: FAILED"
    exit 1
fi

echo
echo "lint-onboard-idempotency: passed"
