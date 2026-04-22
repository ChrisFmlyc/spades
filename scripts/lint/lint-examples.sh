#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — examples lint
#
# Validates the shape of examples/example-scope.md and examples/example-plan.md.
# These files are the canonical reference for what a well-formed Scope and
# Plan look like; drift here means agents generate the wrong shape.
#
# Checks:
#   1. examples/example-scope.md carries **Intent:**, **Acceptance Criteria:**,
#      **Constraints:** as Markdown bold section headers.
#   2. examples/example-plan.md carries an "Execution posture:" line for every
#      task (a task is a line beginning with "#### Task ").
#   3. Every posture value is in the locked vocabulary:
#         test-first, characterization-first, refactor-first, spike, straight-through
#      Mixed values are allowed if every token in the value is in the vocab.
#
# Exit codes:
#   0  both examples conform
#   1  one or more violations found
#   2  an example file is missing

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCOPE="$REPO_ROOT/examples/example-scope.md"
PLAN="$REPO_ROOT/examples/example-plan.md"

fail=0

# --- Example scope ---------------------------------------------------------

if [ ! -f "$SCOPE" ]; then
    echo "lint-examples: missing $SCOPE" >&2
    exit 2
fi

require_in_scope() {
    local pattern="$1"
    local label="$2"
    if grep -qE "$pattern" "$SCOPE"; then
        echo "  ok:   example-scope.md has $label"
    else
        echo "  FAIL: example-scope.md missing $label (pattern: $pattern)"
        fail=$((fail + 1))
    fi
}

require_in_scope '\*\*Intent:\*\*' "Intent section"
require_in_scope '\*\*Acceptance Criteria:\*\*' "Acceptance Criteria section"
require_in_scope '\*\*Constraints:\*\*' "Constraints section"

# --- Example plan ----------------------------------------------------------

if [ ! -f "$PLAN" ]; then
    echo "lint-examples: missing $PLAN" >&2
    exit 2
fi

# Every task heading must have a corresponding Execution posture line
# somewhere before the next task heading or EOF.
#
# We implement this with an awk pass that tracks state: when we see
# "#### Task ", set seen_posture=0. When we see "- **Execution posture:**",
# set it to 1. Before moving to the next task heading (or at EOF), if
# seen_posture is 0, print the offending task title.

missing_posture=$(
    awk '
      /^#### Task / {
          if (in_task && !seen_posture) {
              print current_title
          }
          in_task = 1
          seen_posture = 0
          current_title = $0
          next
      }
      /^-[[:space:]]+\*\*Execution posture:\*\*/ && in_task {
          seen_posture = 1
          # Extract the value after "**Execution posture:**" for later.
          # This sub-pattern matches everything up to and including the
          # closing ** then prints the remainder.
          line = $0
          sub(/^-[[:space:]]+\*\*Execution posture:\*\*[[:space:]]*/, "", line)
          print "VALUE:" line > "/dev/stderr"
      }
      END {
          if (in_task && !seen_posture) {
              print current_title
          }
      }
    ' "$PLAN" 2>/tmp/spade-lint-postures.$$
)

if [ -n "$missing_posture" ]; then
    while IFS= read -r task; do
        echo "  FAIL: example-plan.md task without Execution posture: $task"
        fail=$((fail + 1))
    done <<< "$missing_posture"
else
    echo "  ok:   example-plan.md every task carries Execution posture"
fi

# Validate vocabulary.
#
# Allowed tokens. A value may contain multiple tokens separated by " on "
# or "; " (mixed posture syntax); every token must be in the vocab. We
# normalise by extracting the first word of each sub-clause.
vocab_re='^(test-first|characterization-first|refactor-first|spike|straight-through)$'
bad_vocab=0
while IFS= read -r line; do
    # Strip the VALUE: prefix our awk emitted.
    value="${line#VALUE:}"
    # The value often contains justification after an em-dash or plain dash.
    # Take only the first comma-free, dash-free clause as the posture token
    # (or tokens, if mixed).
    clean="${value%% —*}"   # strip em-dash tail
    clean="${clean%% -*}"   # strip plain dash tail
    # Mixed posture: split on ";" and check each token's first word.
    IFS=';' read -r -a parts <<< "$clean"
    for part in "${parts[@]}"; do
        # Take the first word (skip leading spaces, take until first space).
        trimmed="$(echo "$part" | awk '{print $1}')"
        if ! echo "$trimmed" | grep -qE "$vocab_re"; then
            echo "  FAIL: example-plan.md posture not in vocabulary: '$trimmed' (in value: '$value')"
            bad_vocab=$((bad_vocab + 1))
        fi
    done
done < /tmp/spade-lint-postures.$$
rm -f /tmp/spade-lint-postures.$$

if [ "$bad_vocab" -eq 0 ]; then
    echo "  ok:   example-plan.md every posture is in the locked vocabulary"
else
    fail=$((fail + bad_vocab))
fi

echo
echo "lint-examples: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
