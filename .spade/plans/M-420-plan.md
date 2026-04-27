---
issue: M-420
title: SPADE v1.2.0 — Linear-canonical plan storage (.spade/plans/ becomes fallback-only)
date: 2026-04-23
status: approved
---

## Plan for: SPADE v1.2.0 — Linear-canonical plan storage

> **Dogfood note.** This Plan is deliberately dual-stored (Linear
> comment + this file) because it is the **last Plan under the old
> rule** — the rule change it delivers lands at merge time, after
> which `/spade-plan` will write to the tracker only.

**Technical Approach Summary:**
Flip `/spade-plan`'s "Saving the Plan" semantics from "always both" to
"tracker-first, local fallback". Edit `PATTERNS.md` load-bearing rule
and cascade through `ARCHITECTURE.md` + `docs/FRAMEWORK.md`. Add a
v1.1.1 → v1.2.0 migration note to `/spade-update`. Bump
`.spade/version`. Verify read-path skills (`/spade-approve`,
`/spade-evaluate`, `/spade-status`) still resolve Plans whether they
live in Linear or `.spade/plans/`.

**Risks and Assumptions:**
- **Assumption:** the three read-path skills currently resolve Plans
  primarily from Linear and only consult `.spade/plans/` as fallback.
  If any reads local first, Task 5 expands from verification to a real
  edit.
- **Risk:** a consumer on v1.1.x that never configured Linear is
  silently relying on `.spade/plans/` as primary. The fallback
  behaviour must preserve their experience exactly — otherwise v1.2.0
  breaks them. Covered by AC 2 + AC 7.
- **Risk:** "Linear available" needs a crisp definition. Trigger is
  **"Linear write succeeded with a parent issue ID"**, not merely "MCP
  tool present". Fallback engages when the write fails or there is no
  parent issue in a tracker.
- **No ANTI-PATTERNS.md conflicts.**

### Tasks

#### Task 1: Rewrite `/spade-plan` "Saving the Plan" for tracker-first
- **Mode:** ai-delivered
- **Depends on:** none
- **Effort:** moderate
- **Description:** Replace the "Saving the Plan" section in
  `.claude/skills/spade-plan/SKILL.md` so that:
  - Linear-path (MCP available + parent issue identified + write
    succeeds): create sub-issues, post Plan comment on parent, do NOT
    write to `.spade/plans/`.
  - Fallback-path (Linear unreachable / no tracker parent / write
    failed): write `.spade/plans/<issue-id>-plan.md` with a banner
    line explaining this is a Linear-less fallback artefact.
- **Approach:** Prose edit. Replace "two places" language. Add a
  fallback banner template. Preserve the existing plan-file header
  schema (frontmatter) exactly so historical archives and fallback
  writes are schema-compatible.
- **Tests:** `scripts/lint/lint-skill-frontmatter.sh` passes. Manual:
  read the rewritten section and confirm a consumer could implement
  either path unambiguously.
- **AC covered:** 1, 2

#### Task 2: Replace load-bearing `PATTERNS.md` rule
- **Mode:** ai-delivered
- **Depends on:** none
- **Effort:** brief
- **Description:** In `PATTERNS.md`, replace the current "Every Plan
  lives in two places..." rule with the tracker-canonical policy.
  Keep the cross-reference to `/spade-plan` behaviour.
- **Approach:** Single targeted edit in the Documentation Patterns
  section. New rule: *"The Plan lives in the tracker when one is
  available (today, Linear). `.spade/plans/` is a fallback for
  Linear-less environments and a read-path for historical archives."*
- **Tests:** `scripts/lint/run-all.sh` passes.
- **AC covered:** 4

#### Task 3: Update `ARCHITECTURE.md` and `docs/FRAMEWORK.md` for consistency
- **Mode:** ai-delivered
- **Depends on:** Task 2
- **Effort:** moderate
- **Description:** Update the "Local state" / Storage bullet in
  `ARCHITECTURE.md` to describe `.spade/plans/` as fallback-only.
  Update `docs/FRAMEWORK.md` sections that describe plan storage
  (Tooling and/or Plan Schema) to match.
- **Approach:** Targeted edits. Re-read both files first, identify
  every "two places" / "both Linear and local" phrasing, rewrite in
  place.
- **Tests:** `grep -n "two places\|both Linear" ARCHITECTURE.md
  docs/FRAMEWORK.md PATTERNS.md` returns nothing after the edit. Lint
  suite passes.
- **AC covered:** 5, 6

#### Task 4: Add v1.1.1 → v1.2.0 migration note to `/spade-update`
- **Mode:** ai-delivered
- **Depends on:** none
- **Effort:** brief
- **Description:** Extend `.claude/skills/spade-update/SKILL.md` with
  a v1.1.1 → v1.2.0 subsection that explains: fragment content
  unchanged, no re-stamp required, version pin is the only mechanical
  step, skill behaviour for `/spade-plan` changes at next invocation.
- **Approach:** Follow the existing v1.1.0 → v1.1.1 subsection as the
  template — same shape (version-pin-only bump with a skill behaviour
  change). Reuse its language.
- **Tests:** Lint suite. Manual: subsection reads consistently with
  the v1.1.0 → v1.1.1 one.
- **AC covered:** 8 (partial — update-path prose)

#### Task 5: Verify read-path in `/spade-approve`, `/spade-evaluate`, `/spade-status`
- **Mode:** ai-delivered
- **Depends on:** none
- **Effort:** brief
- **Description:** Read the three skill files. Confirm each resolves
  the Plan from Linear primarily with `.spade/plans/` as fallback.
  Edit only if a skill reads local-first or doesn't fall through
  correctly. Document findings in the PR description.
- **Approach:** Read-only pass first. If any skill requires edits to
  preserve read-path behaviour, fold the edit into this task and note
  it in the PR body.
- **Tests:** Lint suite. If any edit is made, confirm `/spade-status`
  and `/spade-evaluate` can still locate existing
  `.spade/plans/M-323-spade-v1.1-plan.md` and
  `.spade/plans/M-343-spade-v1.1.1-plan.md` as fallback reads.
- **AC covered:** 7

#### Task 6: Bump `.spade/version` to 1.2.0 + full lint
- **Mode:** ai-delivered
- **Depends on:** Tasks 1-5
- **Effort:** brief
- **Description:** Update `.spade/version` from `spade_version=1.1.1`
  to `spade_version=1.2.0`. Run `scripts/lint/run-all.sh` as the final
  gate. Skim the diff end-to-end for any "two places" stragglers or
  version mismatches.
- **Approach:** One-line edit + full lint sweep.
- **Tests:** `scripts/lint/run-all.sh` green. `grep -rn "two places\|both Linear and local" .`
  returns nothing outside this Plan artefact.
- **AC covered:** 8

### Execution Posture

| Task | Posture |
|------|---------|
| 1    | straight-through — prose edit, no tests to write first |
| 2    | straight-through — single targeted prose edit |
| 3    | straight-through — consistency cascade |
| 4    | straight-through — template-shaped prose addition |
| 5    | characterization-first — read current behaviour before touching |
| 6    | straight-through — one-line pin + lint gate |

### Delivery Sequence

1. Tasks 1, 2, 4, 5 in parallel (all independent).
2. Task 3 after Task 2 (cascades from PATTERNS.md canonical prose).
3. Task 6 last (seals with version pin + final lint).

### Delivery Bundles

#### Bundle I: `spade-v1.2.0-tracker-canonical` (single bundle)
- **Branch:** `spade/M-420-tracker-canonical-plans`
- **PR title:** `SPADE v1.2.0: Linear-canonical plan storage`
- **Tasks:** 1, 2, 3, 4, 5, 6
- **Label:** `bundle:v120-tracker-canonical`
- **Rationale:** Every task is a facet of the same semantic change.
  The `/spade-plan` behaviour (Task 1), the `PATTERNS.md` rule
  (Task 2), the cascading doc edits (Task 3), the update-path
  migration note (Task 4), the read-path verification (Task 5), and
  the version pin (Task 6) must land atomically — otherwise a
  consumer pulling mid-bundle sees behaviour-vs-docs drift, or a
  version pin that doesn't match the skill prose. Matches the Scope's
  "single bundle is defensible" signal.

### Matched prior learnings

None. The three existing learnings under `.spade/learnings/` cover
onboarding idempotency and panel-review shape — zero tag overlap with
this Scope's concerns (plan-storage, tracker-canonical, dual-write).
Worth capturing **on delivery** is a new learning on *"duplicate state
between tracker and local = drift risk"* so future Scopes introducing
a dual-write pattern surface it automatically.
