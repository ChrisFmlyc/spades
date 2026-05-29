---
id: S-spades-v2-rework
title: "SPADES v2.0 — Project layer, pluggable backends, six-phase loop"
project: spades-framework
status: delivering
type: refactor
priority: high
origin: ad-hoc
created: 2026-05-29
updated: 2026-05-29
---

# SPADES v2.0 — Project layer, pluggable backends, six-phase loop

## Statement of Intent

v2.0 restructures SPADES from a 5-phase Linear-or-local framework into
a 6-phase backend-agnostic framework with an explicit Project layer.
The loop becomes Scope → Plan → Approve → Do → Evaluate → Ship; a
Project record groups Scopes; backends become pluggable behind a
documented contract.

## Acceptance Criteria

- [x] Six phases documented in `docs/FRAMEWORK.md`
- [x] Project record schema defined and lint-enforced
- [x] Scope IDs use `S-<description-slug>` form
- [x] Plan IDs use `P-<description-slug>-<4-char-suffix>[-<dep>...]` form
- [x] `setup` skill replaces `init`; backend selection is explicit
- [x] `newproject` skill creates project records
- [x] `do` and `ship` skills exist with documented routing and
      deliverable-type semantics
- [x] Templates are embedded inside the producing skill's body — no
      separate `templates/` or `fragments/` directories
- [x] `docs/EXTENDING-BACKENDS.md` describes the contract drivers must
      satisfy
- [x] Lint passes (`bash plugins/spades/scripts/lint/run-all.sh`)
- [ ] Dogfood flow end-to-end on this scope (P-spades-v2-rework-…)
- [ ] Marketplace install from a fresh test directory installs cleanly

## Architectural Constraints

Pure Markdown. No bash entry points. No external setup. The plugin
must install cleanly via the Claude Code marketplace.

## Dependencies

- Marketplace conversion completed on `refactor/pure-plugin-install`
- Linear MCP available (for the framework's own dogfood)

## Context

- **Upstream:** Repackaging as a marketplace plugin landed in PR #22.
- **Downstream:** Consumer repos using SPADES will need to re-run
  `/spades:setup` to get the new schema.
- **Related:** The framework's own README, CHANGELOG, ARCHITECTURE.md
  will need follow-up updates to match v2.

## Out of Scope

- Notion / Confluence MCP drivers (documented as extension points only)
- Migration tooling for v1 → v2 artefacts (fresh start; no v1 users
  affected)
- HTML rendering (already removed before v2)

## Risk / Unknowns

- The dependency-chain-in-filename pattern is novel; if `ls`-based
  reading proves awkward in practice, fall back to relying on
  `depends_on:` frontmatter only.
- Plan suffix collisions in a 4-char base62 space are unlikely but not
  impossible — collision check is built into `/spades:plan`.

## Delivery Preference

Mostly AI-delivered. Human reviews each phase gate.

## Audit Trail

<!-- Auto-appended by SPADES skills. -->
- 2026-05-29: Scope created (v2 schema).
- 2026-05-29: Plan drafted — P-spades-v2-rework-2v0R.
- 2026-05-29: Plan approved (routing: ai).
- 2026-05-29: Do phase complete (ai-delivered).
