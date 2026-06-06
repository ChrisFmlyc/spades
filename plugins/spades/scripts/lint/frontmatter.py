#!/usr/bin/env python3
"""
SPADES Framework v2.0 — minimal YAML-frontmatter parser and schema validator.

Stdlib only: no PyYAML, no external deps. SPADES frontmatter is intentionally
shallow (flat key: value pairs, optionally with list values like `[a, b, c]`
or dash-prefixed items). If we ever need nested structures we'll either
switch to PyYAML or simplify the schema.

Usage:
    scripts/lint/frontmatter.py <file> [--require KEY[,KEY,...]]
    scripts/lint/frontmatter.py --schema project <file>
    scripts/lint/frontmatter.py --schema scope <file>
    scripts/lint/frontmatter.py --schema plan <file>
    scripts/lint/frontmatter.py --schema learning <file>

Exit codes (plain parse mode):
    0  frontmatter parsed successfully and all required keys present
    1  usage error
    2  file has no frontmatter (no leading '---' line)
    3  frontmatter not terminated (no closing '---')
    4  a required key is missing
    5  frontmatter is malformed

Exit codes (--schema mode):
    0  no hard-fail violations (warnings permitted, printed to stdout)
    1  usage error, or a hard-fail schema violation
"""

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List


_HTML_FRONTMATTER_OPEN_RE = re.compile(
    r'<script\s+type=["\']application/yaml["\']\s+id=["\']spades-frontmatter["\']\s*>',
    re.IGNORECASE,
)
_HTML_FRONTMATTER_CLOSE_RE = re.compile(r"</script>", re.IGNORECASE)


def parse_frontmatter(text: str) -> Dict[str, str]:
    """Extract the YAML frontmatter block as a flat dict of string values.

    Supports two source formats:
      - Markdown `.md` artefacts with traditional `---` delimited frontmatter
        at the top of the file.
      - HTML `.html` artefacts (introduced in v3.0.0) that embed their
        frontmatter inside a `<script type="application/yaml"
        id="spades-frontmatter">…</script>` tag near the top of `<body>`.

    The dual format keeps the lint contract symmetric across CLI mode
    (`.md` artefacts) and HTML mode (`.html` artefacts) — same schema,
    same enums, same field allow-lists, only the source location
    changes.
    """
    body = _extract_yaml_body(text)
    return _parse_yaml_body(body)


def _extract_yaml_body(text: str) -> List[str]:
    """Return the YAML body lines from either a `.md` or `.html` artefact."""
    lines = text.splitlines()

    # Markdown frontmatter — opens with `---` on line 1.
    if lines and lines[0].strip() == "---":
        body: List[str] = []
        closed = False
        for line in lines[1:]:
            if line.strip() == "---":
                closed = True
                break
            body.append(line)
        if not closed:
            raise ValueError("frontmatter not terminated by '---'")
        return body

    # HTML <script type="application/yaml" id="spades-frontmatter"> block.
    m_open = _HTML_FRONTMATTER_OPEN_RE.search(text)
    if m_open:
        after = text[m_open.end():]
        m_close = _HTML_FRONTMATTER_CLOSE_RE.search(after)
        if not m_close:
            raise ValueError(
                'spades-frontmatter <script> tag not closed by </script>'
            )
        return after[: m_close.start()].splitlines()

    raise ValueError("no opening frontmatter delimiter")


def _parse_yaml_body(body: List[str]) -> Dict[str, str]:
    """Parse the YAML body lines (same logic for both source formats)."""

    fields: Dict[str, str] = {}
    key_re = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$")
    current_key: str | None = None
    for raw in body:
        if raw.strip() == "":
            current_key = None
            continue
        # YAML-style line comments — skip whole-line `#` comments inside frontmatter.
        # Lets authors annotate optional fields (e.g. "# strategy_link: ...") without
        # uncommenting; the linter ignores them. Inline trailing comments after a
        # key:value pair stay part of the value (single-line stdlib parser; that's fine).
        if raw.lstrip().startswith("#"):
            current_key = None
            continue
        if raw.lstrip().startswith("- ") and current_key is not None:
            fields[current_key] += "\n" + raw.lstrip()
            continue
        m = key_re.match(raw)
        if not m:
            raise ValueError(f"cannot parse frontmatter line: {raw!r}")
        key, value = m.group(1), m.group(2).rstrip()
        if key in fields:
            raise ValueError(f"duplicate frontmatter key: {key!r}")
        fields[key] = value
        current_key = key
    return fields


# ---------------------------------------------------------------------------
# v2.0 schemas. The canonical enum value sets MUST mirror
# docs/FRAMEWORK.md § .spades/ Local Layout. Extending an enum means editing
# both this block AND that section together. Do not broaden lists to paper
# over a real file that fails — fix the file or the schema deliberately.
# ---------------------------------------------------------------------------

# --- Project schema ---------------------------------------------------------
PROJECT_CORE_REQUIRED = ("id", "title", "description", "created", "updated")
PROJECT_KNOWN_FIELDS = frozenset(
    PROJECT_CORE_REQUIRED + ("repos", "owners", "linear_project_id")
)
PROJECT_ID_RE = re.compile(r"^[a-z0-9](?:[a-z0-9-]{0,63})$")

# --- Scope schema -----------------------------------------------------------
SCOPE_CORE_REQUIRED = ("id", "title", "project", "status", "type", "created", "updated")
SCOPE_ENUMS = {
    "status": (
        "scoped", "planning", "delivering",
        "evaluating", "shipping", "done", "rejected",
    ),
    "type": (
        "feature", "bug", "chore", "docs", "refactor", "investigation",
    ),
    "priority": (
        "urgent", "high", "this-cycle", "medium", "low", "backlog", "exploratory",
    ),
    "origin": ("okr", "reactive", "ad-hoc"),
}
SCOPE_KNOWN_FIELDS = frozenset(
    SCOPE_CORE_REQUIRED
    + tuple(SCOPE_ENUMS)
    + ("linear_issue_id", "strategy_link")
)
SCOPE_ID_RE = re.compile(r"^S-[a-z0-9](?:[a-z0-9-]{0,63})$")

# --- Plan schema ------------------------------------------------------------
PLAN_CORE_REQUIRED = (
    "id", "id_suffix", "scope", "title", "status",
    "deliverable_type", "created", "updated",
)
PLAN_ENUMS = {
    "status": (
        "draft", "approved", "delivering", "evaluating", "shipped", "rejected",
    ),
    "delivery": ("ai", "human", "hybrid", "undecided"),
    "evaluation": ("ai", "human", "hybrid", "undecided"),
    "deliverable_type": ("code", "artefact", "action"),
}
PLAN_KNOWN_FIELDS = frozenset(
    PLAN_CORE_REQUIRED
    + tuple(PLAN_ENUMS)
    + ("depends_on", "linear_issue_id")
)
PLAN_ID_RE = re.compile(r"^P-[a-z0-9](?:[a-z0-9-]{0,63})-[A-Za-z0-9]{4}$")
PLAN_SUFFIX_RE = re.compile(r"^[A-Za-z0-9]{4}$")

# --- Learning schema --------------------------------------------------------
LEARNING_CORE_REQUIRED = ("title", "area", "created", "status")
LEARNING_ENUMS = {
    "area": ("scope", "plan", "approve", "do", "evaluate", "ship", "other"),
    "status": ("active", "archived"),
}
LEARNING_KNOWN_FIELDS = frozenset(
    LEARNING_CORE_REQUIRED
    + tuple(LEARNING_ENUMS)
    + ("tags", "public_safe", "scope_ref", "plan_ref")
)


def _check_enums(fields, enums, rel):
    fails = []
    for key, allowed in enums.items():
        value = fields.get(key)
        if value and value not in allowed:
            fails.append(
                f"{rel}: invalid '{key}' value {value!r} — "
                f"expected one of: {', '.join(allowed)}"
            )
    return fails


def _check_required(fields, required, rel, kind):
    return [
        f"{rel}: missing required {kind} field: {key}"
        for key in required
        if not fields.get(key)
    ]


def _check_unknown(fields, known, rel, kind):
    return [
        f"{rel}: unrecognised {kind} field: {key}"
        for key in fields
        if key not in known
    ]


def validate_project(fields, rel):
    fails = _check_required(fields, PROJECT_CORE_REQUIRED, rel, "Project")
    warns = _check_unknown(fields, PROJECT_KNOWN_FIELDS, rel, "Project")
    pid = fields.get("id")
    if pid and not PROJECT_ID_RE.match(pid):
        fails.append(
            f"{rel}: invalid project id {pid!r} — must match [a-z0-9][a-z0-9-]{{0,63}}"
        )
    return fails, warns


def validate_scope(fields, rel):
    fails = _check_required(fields, SCOPE_CORE_REQUIRED, rel, "Scope")
    fails += _check_enums(fields, SCOPE_ENUMS, rel)
    warns = _check_unknown(fields, SCOPE_KNOWN_FIELDS, rel, "Scope")
    sid = fields.get("id")
    if sid and not SCOPE_ID_RE.match(sid):
        fails.append(
            f"{rel}: invalid scope id {sid!r} — must match S-[a-z0-9][a-z0-9-]{{0,63}}"
        )
    return fails, warns


def validate_plan(fields, rel):
    fails = _check_required(fields, PLAN_CORE_REQUIRED, rel, "Plan")
    fails += _check_enums(fields, PLAN_ENUMS, rel)
    warns = _check_unknown(fields, PLAN_KNOWN_FIELDS, rel, "Plan")
    pid = fields.get("id")
    if pid and not PLAN_ID_RE.match(pid):
        fails.append(
            f"{rel}: invalid plan id {pid!r} — must match P-<slug>-<4char-suffix>"
        )
    suf = fields.get("id_suffix")
    if suf and not PLAN_SUFFIX_RE.match(suf):
        fails.append(
            f"{rel}: invalid id_suffix {suf!r} — must be 4 chars [A-Za-z0-9]"
        )
    return fails, warns


def validate_learning(fields, rel):
    fails = _check_required(fields, LEARNING_CORE_REQUIRED, rel, "Learning")
    fails += _check_enums(fields, LEARNING_ENUMS, rel)
    warns = _check_unknown(fields, LEARNING_KNOWN_FIELDS, rel, "Learning")
    return fails, warns


_VALIDATORS = {
    "project": validate_project,
    "scope": validate_scope,
    "plan": validate_plan,
    "learning": validate_learning,
}


def run_schema(kind, file):
    if not file.is_file():
        print(f"frontmatter: not a file: {file}", file=sys.stderr)
        return 1
    rel = str(file)
    text = file.read_text(encoding="utf-8")
    try:
        fields = parse_frontmatter(text)
    except ValueError as exc:
        print(f"  FAIL: {rel}: malformed frontmatter — {exc}", file=sys.stderr)
        return 1
    if kind not in _VALIDATORS:
        print(f"frontmatter: unknown schema kind: {kind}", file=sys.stderr)
        return 1
    fails, warns = _VALIDATORS[kind](fields, rel)
    for w in warns:
        print(f"  warn: {w}")
    for f in fails:
        print(f"  FAIL: {f}", file=sys.stderr)
    if fails:
        return 1
    print(f"  ok:   {rel}")
    return 0


def main():
    p = argparse.ArgumentParser(description="Parse and validate SPADES frontmatter.")
    p.add_argument("file", type=Path)
    p.add_argument("--require", default="")
    p.add_argument("--print", action="store_true")
    p.add_argument(
        "--schema",
        choices=tuple(_VALIDATORS),
        help="validate the file against a SPADES v2 schema",
    )
    args = p.parse_args()

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
