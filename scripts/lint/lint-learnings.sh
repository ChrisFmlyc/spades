#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — learnings lint
#
# Validates the shape of files under .spade/learnings/:
#
#   1. Every .spade/learnings/*.md parses and carries the required
#      frontmatter fields: title, area, tags, created, status,
#      public_safe.
#   2. `area` is one of: onboarding, planning, delivery, review, other.
#   3. `status` is one of: active, archived.
#   4. `public_safe` is either "true" or "false" (string).
#   5. `created` parses as YYYY-MM-DD.
#   6. Warns (does not fail) on active entries older than 180 days —
#      candidates for `/spade-learn --refresh`.
#
# Does NOT recurse into .spade/learnings/private/: that directory is
# gitignored and never runs through CI. Local developers who want to
# validate private entries can call this with `--include-private`.
#
# Exit codes:
#   0  clean (warnings permitted)
#   1  violation

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PARSER="$REPO_ROOT/scripts/lint/frontmatter.py"
LEARN_DIR="$REPO_ROOT/.spade/learnings"

include_private=0
if [ "${1:-}" = "--include-private" ]; then
    include_private=1
fi

# If the learnings directory doesn't exist at all, that's fine —
# a brand-new consumer repo won't have one yet.
if [ ! -d "$LEARN_DIR" ]; then
    echo "lint-learnings: no .spade/learnings/ directory; nothing to validate"
    exit 0
fi

shopt -s nullglob
files=("$LEARN_DIR"/*.md)
if [ "$include_private" -eq 1 ] && [ -d "$LEARN_DIR/private" ]; then
    files+=("$LEARN_DIR"/private/*.md)
fi
shopt -u nullglob

if [ "${#files[@]}" -eq 0 ]; then
    echo "lint-learnings: no learning files to validate"
    exit 0
fi

fail=0
warn=0
today_epoch=$(date +%s)
one_eighty_days=$((180 * 24 * 60 * 60))

for f in "${files[@]}"; do
    rel="${f#"$REPO_ROOT"/}"
    # Required frontmatter: title, area, tags, created, status, public_safe.
    if ! python3 "$PARSER" "$f" --require title,area,tags,created,status,public_safe >/dev/null; then
        echo "  FAIL: $rel (frontmatter missing required fields or malformed)"
        fail=$((fail + 1))
        continue
    fi

    # Re-parse to inspect values (cheap: same parser, --print).
    parsed=$(python3 "$PARSER" "$f" --require title,area,tags,created,status,public_safe --print) || {
        echo "  FAIL: $rel (re-parse failed)"
        fail=$((fail + 1))
        continue
    }

    area=$(echo "$parsed" | awk -F= '/^area=/ {sub("^area=", ""); print; exit}')
    status=$(echo "$parsed" | awk -F= '/^status=/ {sub("^status=", ""); print; exit}')
    public_safe=$(echo "$parsed" | awk -F= '/^public_safe=/ {sub("^public_safe=", ""); print; exit}')
    created=$(echo "$parsed" | awk -F= '/^created=/ {sub("^created=", ""); print; exit}')

    case "$area" in
        onboarding|planning|delivery|review|other) ;;
        *)
            echo "  FAIL: $rel area='$area' not in (onboarding, planning, delivery, review, other)"
            fail=$((fail + 1))
            continue
            ;;
    esac
    case "$status" in
        active|archived) ;;
        *)
            echo "  FAIL: $rel status='$status' not in (active, archived)"
            fail=$((fail + 1))
            continue
            ;;
    esac
    case "$public_safe" in
        true|false) ;;
        *)
            echo "  FAIL: $rel public_safe='$public_safe' must be 'true' or 'false'"
            fail=$((fail + 1))
            continue
            ;;
    esac

    # Security gate (M-341): a learning with public_safe=false is private
    # content and must live under .spade/learnings/private/. If it lands in
    # the public directory, it can reach a public fork via a merged PR —
    # fail CI loudly so mis-classification can't ship. We compare against
    # the literal absolute path prefix (no glob interpretation).
    private_prefix="$LEARN_DIR/private/"
    case "$f" in
        "$private_prefix"*) ;;  # under private/; public_safe=false is fine
        *)
            if [ "$public_safe" = "false" ]; then
                echo "  FAIL: $rel has public_safe=false but is NOT under .spade/learnings/private/ — move it to private/ or change public_safe to true"
                fail=$((fail + 1))
                continue
            fi
            ;;
    esac
    if ! echo "$created" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
        echo "  FAIL: $rel created='$created' must be YYYY-MM-DD"
        fail=$((fail + 1))
        continue
    fi

    echo "  ok:   $rel"

    # Staleness warning: active entries older than 180 days.
    if [ "$status" = "active" ]; then
        if [ "$(uname)" = "Darwin" ]; then
            created_epoch=$(date -j -f "%Y-%m-%d" "$created" +%s 2>/dev/null || echo 0)
        else
            created_epoch=$(date -d "$created" +%s 2>/dev/null || echo 0)
        fi
        if [ "$created_epoch" -gt 0 ]; then
            age=$((today_epoch - created_epoch))
            if [ "$age" -gt "$one_eighty_days" ]; then
                days=$((age / 86400))
                echo "  warn: $rel is $days days old and still active — candidate for /spade-learn --refresh"
                warn=$((warn + 1))
            fi
        fi
    fi
done

echo
echo "lint-learnings: $fail failure(s), $warn warning(s)"
[ "$fail" -eq 0 ] || exit 1
