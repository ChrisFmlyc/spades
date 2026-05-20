---
name: harden-local-mode-artefacts
title: Harden SPADE local-mode artefacts — schema enforcement and stable IDs
status: scoped
type: feature
phase: scope
created: 2026-05-18
updated: 2026-05-18
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
linear_issue: M-1023
linear_url: https://linear.app/m-kopa/issue/M-1023/harden-spade-local-mode-artefacts-schema-enforcement-and-stable-ids
panel_review: 2026-05-18 (subagent-dispatch, 14 findings, 0 filtered)
---

## Scope: Harden SPADE local-mode artefacts — schema enforcement and stable IDs

**Intent:** Once M-879 establishes SPADE's local-mode file layout and frontmatter
schema, two gaps still let local state corrupt silently — the schema is documented
but not machine-enforced, and title-derived slugs can collide and overwrite. This
work makes the local-mode schema CI-enforced and gives every local Scope a stable
identity independent of its slug, so parallel local work cannot silently lose or
clobber artefacts.

**Acceptance Criteria:**

1. [ ] The CI frontmatter lint job validates local Scope/Plan/learning files
   against the M-879 §Local Layout schema: **hard-fails** on invalid enum values
   (`status`, `type`, `priority`, learning `area`) and missing required fields,
   and **warns without failing** on unrecognised fields — preserving the
   documented "richer fields may be added" convention.
2. [ ] Enforcement keys off `spade_version`: files written under a `spade_version`
   earlier than the schema version are exempt (M-879's grandfathering rule) and
   the exempt set is bounded by version, not open-ended. A committed
   pre-v1.4-shaped fixture passes the lint; a fixture with a bad enum value
   fails it.
3. [ ] Every local Scope carries a stable short ID in frontmatter, generated at
   creation, distinct from the title-derived slug. The ID format + allocation
   scheme is documented in the `docs/FRAMEWORK.md` §Local Layout section M-879
   owns. IDs are collision-resistant under parallel creation without a central
   allocator, and are correctness-only identifiers — explicitly **not** an
   authorisation or trust primitive.
4. [ ] `/spade-scope` (local/hybrid modes) detects when a new Scope's derived
   slug collides with an existing `.spade/scopes/` file and aborts with a clear
   error instead of overwriting.

**Architectural Constraints:**

- Builds strictly within M-879's contracts — the schema and §Local Layout
  grammar are single-sourced in `docs/FRAMEWORK.md`; this Scope enforces and
  extends that section, never re-specifies it.
- Linter stays stdlib-only Python 3.11 in `scripts/lint/`, extending
  `frontmatter.py` and `.github/workflows/lint.yml` (the CI-only Python
  exception in ARCHITECTURE.md §External Toolchain Policy). Same exit-code
  discipline. No runtime deps, no new dependencies.
- No runtime layer, no database, no centralised state — per ANTI-PATTERNS.md.

**Dependencies:**

- **M-879 (SPADE v1.4 — local mode) — BLOCKING.** M-879 defines the frontmatter
  schema (AC#2), slug grammar (AC#3), and local-mode `/spade-list` /
  `/spade-status` (AC#5) that this Scope enforces and extends. This Scope cannot
  be planned until M-879 is delivered. (At time of filing, M-879 is marked
  "Delivering" in Linear but has no Plan, no sub-issues, and no delivery
  commits — it is effectively still awaiting planning.)
- `scripts/lint/frontmatter.py`, `.github/workflows/lint.yml`.

**Context:**

- **Upstream:** M-879 establishes the local-mode foundation; this Scope hardens
  it. Originating friction: local-mode clunkiness in Linear-less consumer
  projects — frontmatter typos slipping through, slugs silently overwriting.
- **Downstream:** dependable local-mode artefacts for multi-agent work; a
  separate deferred effort decides whether a multi-agent coordination layer
  belongs in SPADE at all.
- **Related:** M-879; existing CI lint jobs; a design discussion (2026-05-18)
  that researched the Beads project and concluded SPADE artefacts stay Markdown.

**Out of Scope:**

- Delivering M-879 itself — local layout, schema definition, slug grammar, and
  local `/spade-list` / `/spade-status` parity are M-879's deliverables.
- The multi-agent coordination layer / live-claiming question — split into a
  separate deferred `/spade-research` + architecture-review effort (it re-opens
  ARCHITECTURE.md's "no database" and ANTI-PATTERNS.md's "no shared database /
  no runtime" rules and may legitimately conclude "no").
- Migrating durable artefacts into any database (Dolt or SQLite) — rejected in
  the design discussion; artefacts stay Markdown.
- Linear-mode behaviour and the HTML renderer — unchanged.

**Origin:** Ad-hoc — design discussion (2026-05-18) on local-mode clunkiness in
consumer projects that cannot use Linear, including research into the Beads
project. A `/spade-review` panel on the first draft (which bundled this with a
coordination-layer architecture decision) returned two blocking findings —
bundling, and overlap with M-879 — prompting this restructure.

**Risk / Unknowns:**

- M-879 is the real foundation and is not yet delivered (and is currently
  mis-statused as "Delivering" with no Plan). If M-879 slips, this Scope cannot
  proceed; delivering M-879 is the bigger lever for local-mode pain.
- Stable-ID generation needs a collision-resistant scheme without a central
  allocator (a short random/hash ID at creation is the likely answer — a
  Plan-level decision).
- Linter tightening risks spurious CI failures on grandfathered files; the
  version-keyed exemption + fixtures mitigate, but fixtures must represent the
  real legacy shapes in `.spade/`.

**Delivery Preference:** Mostly AI-delivered — linter extension, skill-prose
edits, `docs/FRAMEWORK.md` schema-section additions, fixtures. Manual
verification (plant a bad enum value, confirm CI fails) is human-driven.

**Priority:** This cycle — gated behind M-879.

## Panel Review (2026-05-18)

A 4-persona `/spade-review` panel (subagent-dispatch) ran on the first draft,
which bundled this hardening work with an architecture decision on a
multi-agent coordination layer. 14 findings, 0 filtered, 11 after convergence
merge. Disposition:

- **Bundling (blocking — adversarial-reviewer, also architecture-strategist):**
  the combined Scope was split. This Scope is hardening-only; the
  coordination-layer decision is a separate deferred effort.
- **M-879 overlap (blocking — adversarial-reviewer, also scope-guardian):** the
  original Phase 1 re-specified M-879's schema / slug / list / status. Rescoped
  to the genuine delta only — CI enforcement + stable IDs — with M-879 as a
  blocking dependency.
- **Unknown-field rejection (minor — scope-guardian):** changed to warn-only;
  hard-reject reserved for invalid enums + missing required fields.
- **Grandfathering undefined / unbounded (major — scope-guardian, also
  security-lens):** AC#2 now keys the exemption off `spade_version` and requires
  committed fixtures.
- **Stable-ID forgeability (major — security-lens) + undocumented scheme
  (minor — architecture-strategist):** AC#3 now records IDs as correctness-only
  (not an auth primitive) and requires the scheme documented in §Local Layout.

Coordination-layer findings (the P2 criterion presupposed its own outcome; the
ADR must analyse the shared-state trust boundary; "evaluates" was not
measurable; a "no" creates decision-debt) carry forward to the separate
deferred coordination-layer effort.
