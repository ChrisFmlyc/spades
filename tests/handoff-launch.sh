#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — handoff launcher test
#
# Exercises bin/spade-handoff-launch in --dry-run mode (no terminal is
# spawned, no osascript is called, so this runs headless on any platform)
# and asserts:
#
#   1. The handoff prompt is treated as opaque data — shell metacharacters
#      ($(...), backticks, ;, ") in the prompt are never evaluated, in both
#      --prompt-via arg and --prompt-via stdin modes.
#   2. The worktree-collision guard refuses a same-worktree handoff and is
#      overridable with --force-same-worktree.
#   3. A missing agent binary, bad --terminal / --prompt-via values, a
#      missing required flag, and an empty prompt all fail with the
#      documented exit code.
#   4. The generated run.sh expands the prompt only as "$_spade_prompt".
#
# Usage: tests/handoff-launch.sh
# Exits non-zero on any failure.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="$REPO_ROOT/bin/spade-handoff-launch"

PASS=0
FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

expect_rc() {
    # expect_rc <expected> <actual> <label>
    if [ "$1" = "$2" ]; then
        pass "$3 (rc=$2)"
    else
        fail "$3 (expected rc=$1, got rc=$2)"
    fi
}

[ -f "$LAUNCHER" ] || { echo "launcher not found: $LAUNCHER" >&2; exit 2; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# A prompt loaded with shell metacharacters. The escaped $ and backticks
# keep this heredoc from running them; the file ends up containing the
# literal text, which is what a hostile Linear Scope body could carry.
pwn_cmdsub="$tmp/PWNED_CMDSUB"
pwn_backtick="$tmp/PWNED_BACKTICK"
cat > "$tmp/payload.txt" <<EOF
injection test \$(touch $pwn_cmdsub) and \`touch $pwn_backtick\` ; "quoted" & end
EOF

run_launcher() {
    # run_launcher <stdin-file> <args...> -> sets OUT and RC
    local stdin_file="$1"; shift
    set +e
    OUT="$("$LAUNCHER" "$@" < "$stdin_file" 2>&1)"
    RC=$?
    set -e
}

# --- Case 1: injection-safe, --prompt-via arg --------------------------
echo
echo "Case 1: prompt metacharacters are not evaluated (arg mode)"
run_launcher "$tmp/payload.txt" \
    --terminal iterm --cwd "$tmp" --prompt-via arg --dry-run -- /bin/echo
expect_rc 0 "$RC" "dry run exits 0"
if [ -e "$pwn_cmdsub" ] || [ -e "$pwn_backtick" ]; then
    fail "prompt metacharacters were EXECUTED (PWNED file created)"
    rm -f "$pwn_cmdsub" "$pwn_backtick"
else
    pass "no command substitution / backtick in the prompt was executed"
fi
if printf '%s' "$OUT" | grep -qF 'injection test $(touch'; then
    pass "prompt is reproduced verbatim in the dry-run report"
else
    fail "prompt was not reproduced verbatim"
fi

# --- Case 2: injection-safe, --prompt-via stdin ------------------------
echo
echo "Case 2: prompt metacharacters are not evaluated (stdin mode)"
run_launcher "$tmp/payload.txt" \
    --terminal terminal --cwd "$tmp" --prompt-via stdin --dry-run -- /bin/cat
expect_rc 0 "$RC" "dry run exits 0"
if [ -e "$pwn_cmdsub" ] || [ -e "$pwn_backtick" ]; then
    fail "prompt metacharacters were EXECUTED (PWNED file created)"
    rm -f "$pwn_cmdsub" "$pwn_backtick"
else
    pass "no command substitution / backtick in the prompt was executed"
fi

# --- Case 3: generated run.sh expands the prompt only as a quoted var --
echo
echo "Case 3: generated run.sh keeps the prompt quoted"
printf '%s' "deliver the plan" > "$tmp/plain.txt"
run_launcher "$tmp/plain.txt" \
    --terminal iterm --cwd "$tmp" --prompt-via arg --dry-run \
    -- /bin/echo --permission-mode acceptEdits
expect_rc 0 "$RC" "dry run exits 0"
if printf '%s' "$OUT" | grep -qF 'exec /bin/echo --permission-mode acceptEdits "$_spade_prompt"'; then
    pass "run.sh execs the agent with the prompt as a single quoted argument"
else
    fail "run.sh did not have the expected quoted-prompt exec line"
fi

# --- Case 4: worktree-collision guard refuses --------------------------
echo
echo "Case 4: same-worktree handoff is refused"
git init -q "$tmp/wt"
run_launcher "$tmp/plain.txt" \
    --terminal iterm --cwd "$tmp/wt" --invoked-from "$tmp/wt" \
    --prompt-via arg --dry-run -- /bin/echo
expect_rc 4 "$RC" "same worktree without --force-same-worktree is refused"

# --- Case 5: worktree-collision guard is overridable -------------------
echo
echo "Case 5: --force-same-worktree overrides the guard"
run_launcher "$tmp/plain.txt" \
    --terminal iterm --cwd "$tmp/wt" --invoked-from "$tmp/wt" \
    --prompt-via arg --dry-run --force-same-worktree -- /bin/echo
expect_rc 0 "$RC" "same worktree with --force-same-worktree proceeds"

# --- Case 6: no collision across non-shared directories ----------------
echo
echo "Case 6: distinct directories are not a collision"
mkdir -p "$tmp/dir-a" "$tmp/dir-b"
run_launcher "$tmp/plain.txt" \
    --terminal iterm --cwd "$tmp/dir-a" --invoked-from "$tmp/dir-b" \
    --prompt-via arg --dry-run -- /bin/echo
expect_rc 0 "$RC" "non-shared directories proceed without a collision"

# --- Case 7: missing agent binary --------------------------------------
echo
echo "Case 7: missing agent binary is rejected"
run_launcher "$tmp/plain.txt" \
    --terminal iterm --cwd "$tmp" --prompt-via arg --dry-run \
    -- "$tmp/no-such-agent-xyz"
expect_rc 3 "$RC" "missing agent binary exits 3"

# --- Case 8: bad --terminal value --------------------------------------
echo
echo "Case 8: invalid --terminal value is rejected"
run_launcher "$tmp/plain.txt" \
    --terminal frobnicate --cwd "$tmp" --prompt-via arg --dry-run -- /bin/echo
expect_rc 1 "$RC" "invalid --terminal exits 1"

# --- Case 9: bad --prompt-via value ------------------------------------
echo
echo "Case 9: invalid --prompt-via value is rejected"
run_launcher "$tmp/plain.txt" \
    --terminal iterm --cwd "$tmp" --prompt-via telepathy --dry-run -- /bin/echo
expect_rc 1 "$RC" "invalid --prompt-via exits 1"

# --- Case 10: missing required flag ------------------------------------
echo
echo "Case 10: missing --cwd is rejected"
run_launcher "$tmp/plain.txt" \
    --terminal iterm --prompt-via arg --dry-run -- /bin/echo
expect_rc 1 "$RC" "missing --cwd exits 1"

# --- Case 11: empty prompt ---------------------------------------------
echo
echo "Case 11: empty prompt is rejected"
: > "$tmp/empty.txt"
run_launcher "$tmp/empty.txt" \
    --terminal iterm --cwd "$tmp" --prompt-via arg --dry-run -- /bin/echo
expect_rc 1 "$RC" "empty prompt exits 1"

echo
echo "----------------------------------------"
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
