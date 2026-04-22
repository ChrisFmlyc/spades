#!/usr/bin/env python3
"""
SPADE Framework — minimal YAML-frontmatter parser.

Stdlib only: no PyYAML, no external deps. SPADE skill frontmatter is
intentionally shallow (flat key: value pairs, optionally with list values
like `[a, b, c]` or dash-prefixed items). This parser only supports that
shape — if we ever need nested structures we will either switch to PyYAML
or simplify the schema. That trade-off is recorded in ANTI-PATTERNS.md
(no runtime dependencies).

Usage:
    scripts/lint/frontmatter.py <file> [--require KEY[,KEY,...]]

Exit codes:
    0  frontmatter parsed successfully and all required keys present
    1  usage error
    2  file has no frontmatter (no leading '---' line)
    3  frontmatter not terminated (no closing '---')
    4  a required key is missing
    5  frontmatter is malformed (e.g. tab indentation, non key:value line)
"""

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List


def parse_frontmatter(text: str) -> Dict[str, str]:
    """Extract the YAML frontmatter block as a flat dict of string values.

    Raises ValueError on malformed input (no opening ---, no closing ---,
    lines inside the block that don't look like 'key: value').
    """
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise ValueError("no opening frontmatter delimiter")

    body: List[str] = []
    closed = False
    for line in lines[1:]:
        if line.strip() == "---":
            closed = True
            break
        body.append(line)
    if not closed:
        raise ValueError("frontmatter not terminated by '---'")

    fields: Dict[str, str] = {}
    key_re = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$")
    current_key: str | None = None
    for raw in body:
        # Skip blank lines inside the block.
        if raw.strip() == "":
            current_key = None
            continue
        # Dash-prefixed continuation of a list value under the current key.
        if raw.lstrip().startswith("- ") and current_key is not None:
            fields[current_key] += "\n" + raw.lstrip()
            continue
        m = key_re.match(raw)
        if not m:
            raise ValueError(f"cannot parse frontmatter line: {raw!r}")
        key, value = m.group(1), m.group(2).rstrip()
        fields[key] = value
        current_key = key
    return fields


def main() -> int:
    p = argparse.ArgumentParser(description="Parse and validate SPADE frontmatter.")
    p.add_argument("file", type=Path)
    p.add_argument(
        "--require",
        default="",
        help="comma-separated list of keys that must be present and non-empty",
    )
    p.add_argument(
        "--print",
        action="store_true",
        help="print parsed key=value pairs to stdout",
    )
    args = p.parse_args()

    if not args.file.is_file():
        print(f"frontmatter: not a file: {args.file}", file=sys.stderr)
        return 1

    text = args.file.read_text(encoding="utf-8")
    try:
        fm = parse_frontmatter(text)
    except ValueError as exc:
        msg = str(exc)
        if "no opening" in msg:
            print(f"{args.file}: {msg}", file=sys.stderr)
            return 2
        if "not terminated" in msg:
            print(f"{args.file}: {msg}", file=sys.stderr)
            return 3
        print(f"{args.file}: {msg}", file=sys.stderr)
        return 5

    required = [k.strip() for k in args.require.split(",") if k.strip()]
    missing = [k for k in required if not fm.get(k)]
    if missing:
        for k in missing:
            print(f"{args.file}: missing required frontmatter field: {k}", file=sys.stderr)
        return 4

    if args.print:
        for k, v in fm.items():
            print(f"{k}={v}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
