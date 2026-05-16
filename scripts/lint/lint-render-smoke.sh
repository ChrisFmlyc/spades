#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — render smoke test
#
# Renders every fixture under tests/fixtures/render/ via spade-render
# and asserts the renderer succeeds and produces a non-empty,
# self-contained HTML document.
#
# This is a functional regression guard — it catches Pandoc-version
# breakage and template errors. It is NOT a security scan: spade-render
# turns the user's own Markdown into a local HTML file the user opens
# themselves, so there is no XSS/CSP threat model to enforce.
#
# Exit codes:
#   0  every fixture rendered cleanly
#   1  a fixture failed to render or produced invalid output
#   2  pandoc missing — skip (run-all treats exit 2 as a skip)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RENDERER="$REPO_ROOT/bin/spade-render"
FIXTURE_DIR="$REPO_ROOT/tests/fixtures/render"

fail=0
note() { echo "render-smoke: $*"; }
problem() { echo "render-smoke: FAIL — $*" >&2; fail=1; }

if [ ! -x "$RENDERER" ]; then
    note "renderer not executable: $RENDERER" >&2
    exit 1
fi
if ! command -v pandoc >/dev/null 2>&1; then
    note "SKIP — pandoc not installed (run-all treats exit 2 as a skip)"
    exit 2
fi
if [ ! -d "$FIXTURE_DIR" ]; then
    note "fixture directory missing: $FIXTURE_DIR" >&2
    exit 1
fi

shopt -s nullglob
fixtures=("$FIXTURE_DIR"/*.md)
shopt -u nullglob

if [ "${#fixtures[@]}" -eq 0 ]; then
    note "no fixtures found under $FIXTURE_DIR" >&2
    exit 1
fi

for fixture in "${fixtures[@]}"; do
    name="$(basename "$fixture")"
    note "rendering $name"
    out="$(mktemp -t spade-render-XXXXXX).html"

    if ! "$RENDERER" "$fixture" --output "$out" >/dev/null; then
        problem "$name: renderer exited non-zero"
        rm -f "$out"
        continue
    fi
    if [ ! -s "$out" ]; then
        problem "$name: output is empty"
        rm -f "$out"
        continue
    fi
    # Standalone document: spade-render passes --embed-resources, so the
    # stylesheet must be inlined (no external <link> dependency).
    if ! grep -qi "<!doctype html>" "$out"; then
        problem "$name: output is not a standalone HTML document"
    fi
    if ! grep -q "<style" "$out"; then
        problem "$name: stylesheet was not inlined into the output"
    fi

    rm -f "$out"
done

if [ "$fail" -ne 0 ]; then
    exit 1
fi

note "all fixtures rendered cleanly"
exit 0
