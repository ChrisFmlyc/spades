---
title: Any write into a consumer file must be idempotent via delimited markers, never append
area: onboarding
tags: onboarding, fragments, markers, idempotency, agents-md, claude-md
created: 2026-04-22
status: active
public_safe: true
scope_ref: M-323
---

## What we learned

During the M-323 recon on this very repo, we found `AGENTS.md` and
`CLAUDE.md` each carrying duplicated `<!-- SPADE-FRAMEWORK-START v1.0.0 -->`
blocks. Cause: the original `/spade-onboard` skill said *"if SPADE section
exists, leave it alone"* — but teams kept running onboarding and it kept
appending fresh blocks, drifting the docs over time. The bug sat in a
framework that claims to value auditable state.

Bundle A fixed it with a deterministic marker-replace contract in
`bin/spade-marker-replace`:

- Target absent → create with markers.
- Target has no markers → append with markers.
- Target has one marker pair → replace block in place, re-stamping version.
- Target has mismatched markers → exit 2, no modification.
- Target has duplicate pairs → exit 3, no modification.
- Invalid version string → exit 1, no modification.

Two runs with the same inputs produce an unchanged file on the second
run. That property is now locked in by `tests/onboard-idempotency.sh`
(15 assertions) and a CI job in `.github/workflows/lint.yml`.

## Why it matters for future work

This is the pattern for **every** future skill that mutates a file the
consumer already owns. `AGENTS.md`, `CLAUDE.md`, `.gitignore` sections,
pre-commit configs, GitHub Action workflows — any artefact where we want
to refresh our own content without stomping on the human's content needs
the same shape:

1. A delimited region (start marker with version + end marker).
2. A helper that implements create / append / replace-in-place / refuse-on-
   malformed as distinct paths with distinct exit codes.
3. A fixture test that proves idempotency on at least two shapes:
   "clean file" and "file with existing block at the previous version".

Do not add a new skill that writes into an existing consumer file
without referencing this contract. Prefer to extend the
`spade-marker-replace` helper over inventing a new mechanism.

Related: `bin/spade-marker-replace`, `.claude/skills/spade-onboard/SKILL.md`,
`tests/onboard-idempotency.sh`, `.github/workflows/lint.yml`.
