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
    scripts/lint/frontmatter.py --schema scope <file>
    scripts/lint/frontmatter.py --schema plan  <file>

Exit codes (plain parse mode):
    0  frontmatter parsed successfully and all required keys present
    1  usage error
    2  file has no frontmatter (no leading '---' line)
    3  frontmatter not terminated (no closing '---')
    4  a required key is missing
    5  frontmatter is malformed (e.g. tab indentation, non key:value line)

Exit codes (--schema mode):
    0  no hard-fail violations (warnings permitted, printed to stdout)
    1  usage error, or a hard-fail schema violation
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
        # Reject duplicate keys loudly: YAML rejects them, and silently
        # overwriting hides skill-authoring mistakes like two copies of
        # `name:` or `description:`.
        if key in fields:
            raise ValueError(f"duplicate frontmatter key: {key!r}")
        fields[key] = value
        current_key = key
    return fields


# --------------------------------------------------------------------------
# Schema validation for SPADE local-mode artefacts (M-1023).
#
# The canonical enum value sets below MUST mirror docs/FRAMEWORK.md
# § Local Layout → "Scope frontmatter". That section is the single
# source of truth; extending an enum means editing this block AND that
# section together. Do not broaden these lists to paper over a real
# file that fails — fix the file or the schema deliberately.
# --------------------------------------------------------------------------

# Scope: hard-required core fields. Missing any of these is a hard fail.
SCOPE_CORE_REQUIRED = ("name", "title", "status", "type", "created", "updated")

# Scope: the `id` field (v1.8 addition) is required on files created at
# v1.8+ but warn-only on pre-existing files (§ Local Layout grandfathering).
SCOPE_ID_FIELD = "id"

# Scope: canonical enum value sets (§ Local Layout). An out-of-set value
# for any of these is a hard fail.
SCOPE_ENUMS = {
    "status": ("scoped", "planning", "approval", "delivering", "evaluating", "done"),
    "type": ("feature", "bug", "chore", "docs", "refactor", "investigation"),
    "priority": (
        "urgent", "high", "this-cycle", "medium", "low", "backlog", "exploratory",
    ),
}

# Scope: every field the schema recognises. An unknown field is warn-only.
SCOPE_KNOWN_FIELDS = frozenset(
    SCOPE_CORE_REQUIRED
    + (SCOPE_ID_FIELD,)
    + tuple(SCOPE_ENUMS)
    + ("phase", "origin", "delivery", "linear_issue", "linear_url", "panel_review")
)

# Plan: recognised fields. The Plan check is light and warn-only —
# historical Plan files (M-323/M-343/M-420 era) have genuinely
# inconsistent frontmatter, so a missing recognised field only warns.
PLAN_KNOWN_FIELDS = frozenset(
    (
        "scope", "issue", "scope_url", "linear_url", "scope_ref",
        "title", "date", "generated_at", "generated_by",
        "plan_version", "status", "bundle",
    )
)


def validate_scope(fields: Dict[str, str], rel: str, enforce_scope_id: bool = False) -> tuple[list[str], list[str]]:
    """Validate a `.spade/scopes/*.md` frontmatter dict against the schema.

    Returns (hard_failures, warnings). A non-empty hard_failures list
    means the file must fail the lint; warnings never fail it.

    Args:
        fields: Parsed frontmatter fields
        rel: Relative file path for error messages
        enforce_scope_id: If True, missing SCOPE_ID_FIELD is a hard fail;
                          if False (default), it's grandfathered (warn-only)
    """
    fails: List[str] = []
    warns: List[str] = []

    # (a) Hard-fail: a missing core required field.
    for key in SCOPE_CORE_REQUIRED:
        if not fields.get(key):
            fails.append(f"{rel}: missing required Scope field: {key}")

    # (b) Hard-fail: an invalid status / type / priority enum value.
    #     priority is optional — only checked when present.
    for key, allowed in SCOPE_ENUMS.items():
        value = fields.get(key)
        if value and value not in allowed:
            fails.append(
                f"{rel}: invalid '{key}' value {value!r} — "
                f"expected one of: {', '.join(allowed)}"
            )

    # Missing `id` field (v1.8 addition): policy-driven validation.
    # When enforce_scope_id=False (default), grandfathered (warn-only);
    # when enforce_scope_id=True, hard-fail.
    if not fields.get(SCOPE_ID_FIELD):
        if enforce_scope_id:
            fails.append(f"{rel}: missing required Scope field: {SCOPE_ID_FIELD}")
        else:
            warns.append(
                f"{rel}: no '{SCOPE_ID_FIELD}' field — grandfathered "
                f"(pre-v1.8 file); /spade-scope adds it to new Scopes"
            )

    # Warn-only: an unrecognised/unknown field.
    for key in fields:
        if key not in SCOPE_KNOWN_FIELDS:
            warns.append(f"{rel}: unrecognised Scope field: {key}")

    return fails, warns


def validate_plan(fields: Dict[str, str], rel: str) -> tuple[list[str], list[str]]:
    """Light, warn-only validation of a `.spade/plans/*.md` frontmatter dict.

    The frontmatter must parse (the caller guarantees that), and an
    unrecognised field only warns. Never returns a hard failure —
    historical Plan files have inconsistent frontmatter by design.
    """
    warns: List[str] = []
    for key in fields:
        if key not in PLAN_KNOWN_FIELDS:
            warns.append(f"{rel}: unrecognised Plan field: {key}")
    return [], warns


def run_schema(kind: str, file: Path, enforce_scope_id: bool = False) -> int:
    """Validate one file against the `scope` or `plan` schema.

    Exit 0 = no hard failures (warnings allowed); exit 1 = a hard
    failure. A Scope file with no frontmatter block at all is treated as
    a grandfathered legacy artefact (warn-only) rather than a hard fail,
    so the lint never breaks on a pre-contract prose-only Scope.

    Args:
        kind: "scope" or "plan"
        file: Path to the file to validate
        enforce_scope_id: If True, missing SCOPE_ID_FIELD is a hard fail
                          in scope validation; if False (default), it's
                          grandfathered (warn-only)
    """
    if not file.is_file():
        print(f"frontmatter: not a file: {file}", file=sys.stderr)
        return 1

    rel = str(file)
    text = file.read_text(encoding="utf-8")
    try:
        fields = parse_frontmatter(text)
    except ValueError as exc:
        msg = str(exc)
        if "no opening" in msg:
            # No frontmatter at all — a pre-contract prose-only artefact.
            # Grandfathered: warn, never hard-fail.
            print(f"  warn: {rel}: no frontmatter block — grandfathered (pre-contract file)")
            return 0
        # A frontmatter block that exists but is malformed (unterminated,
        # tab-indented, duplicate key) is a real, fixable defect.
        print(f"  FAIL: {rel}: malformed frontmatter — {msg}", file=sys.stderr)
        return 1

    if kind == "scope":
        fails, warns = validate_scope(fields, rel, enforce_scope_id)
    elif kind == "plan":
        fails, warns = validate_plan(fields, rel)
    else:
        print(f"frontmatter: unknown schema kind: {kind}", file=sys.stderr)
        return 1

    for w in warns:
        print(f"  warn: {w}")
    for f in fails:
        print(f"  FAIL: {f}", file=sys.stderr)

    if fails:
        return 1
    print(f"  ok:   {rel}")
    return 0


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
    p.add_argument(
        "--schema",
        choices=("scope", "plan"),
        help="validate the file against a SPADE local-mode artefact schema",
    )
    args = p.parse_args()

    # Schema mode is a distinct, self-contained validator.
    if args.schema:
        return run_schema(args.schema, args.file)

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
