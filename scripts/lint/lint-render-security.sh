#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — render-security lint
#
# Renders every fixture under tests/fixtures/render/ via spade-render
# and asserts the output contains no dangerous content:
#
#   1. No raw <script tags
#   2. No `on*=` event handlers
#   3. No javascript: URLs
#   4. No filesystem paths leaked into the body (/Users/, /home/)
#   5. The exact CSP meta string from AC#2 IS present
#
# Exit codes:
#   0  clean
#   1  violation found
#   2  pandoc missing — skip with a clear message (CI must install
#      pandoc; local runs without pandoc are not enforced)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RENDERER="$REPO_ROOT/bin/spade-render"
FIXTURE_DIR="$REPO_ROOT/tests/fixtures/render"

CSP_LITERAL="default-src 'none'; style-src 'unsafe-inline'; img-src data:; base-uri 'none'; form-action 'none'"

fail=0
note() { echo "render-security: $*"; }
violation() { echo "render-security: VIOLATION — $*" >&2; fail=1; }

if [ ! -x "$RENDERER" ]; then
    note "renderer not executable: $RENDERER" >&2
    exit 1
fi
if ! command -v pandoc >/dev/null 2>&1; then
    note "SKIP — pandoc not installed (CI installs pandoc; run-all treats exit 2 as a skip)"
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
        violation "$name: renderer failed"
        rm -f "$out"
        continue
    fi

    # 1. No raw <script tags (any case)
    if grep -qi "<script" "$out"; then
        violation "$name: contains <script tag"
    fi

    # 2. No event handlers (on*= where * is lowercase letters)
    # Match: ` onclick=`, ` onerror=`, etc. — leading space + on + letters + =
    if grep -qE " on[a-z]+=" "$out"; then
        violation "$name: contains on*= event handler"
    fi

    # 3. No javascript: URLs (anywhere)
    if grep -qi "javascript:" "$out"; then
        violation "$name: contains javascript: URL"
    fi

    # 4. No leaked filesystem paths
    if grep -qE "/Users/|/home/[a-z]" "$out"; then
        violation "$name: contains leaked filesystem path"
    fi

    # 5. CSP meta MUST be present (literal string match)
    if ! grep -qF "$CSP_LITERAL" "$out"; then
        violation "$name: missing CSP meta tag"
    fi

    rm -f "$out"
done

if [ "$fail" -ne 0 ]; then
    exit 1
fi

note "all fixtures clean"
exit 0
