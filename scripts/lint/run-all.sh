#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — run every lint in order.
#
# Runs each scripts/lint/lint-*.sh in a stable order, prints a compact
# summary at the end, and exits non-zero if any script failed. Use this
# locally as a pre-PR check; CI (.github/workflows/lint.yml) runs the
# same scripts as separate jobs for clearer red/green signalling.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LINT_DIR="$REPO_ROOT/scripts/lint"

scripts=(
    "lint-skill-frontmatter.sh"
    "lint-examples.sh"
    "lint-fragments.sh"
    "lint-onboard-idempotency.sh"
)

overall=0
for s in "${scripts[@]}"; do
    echo
    echo "=== $s ==="
    if ! "$LINT_DIR/$s"; then
        overall=$((overall + 1))
    fi
done

echo
echo "=========================================="
if [ "$overall" -eq 0 ]; then
    echo "All ${#scripts[@]} lint checks passed."
else
    echo "$overall lint check(s) failed."
    exit 1
fi
