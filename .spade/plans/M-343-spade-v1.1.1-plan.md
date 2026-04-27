---
scope: M-343
scope_url: https://linear.app/m-kopa/issue/M-343
title: "SPADE v1.1.1 — Make multi-persona review honest"
plan_version: 1
generated_by: spade-plan (Claude Opus 4.7)
generated_at: 2026-04-22
status: awaiting-approval
---

# Plan — SPADE v1.1.1 (M-343)

## Prior Learnings Considered

- *For review and evaluation gates, a panel of persona-specific reviewers
  beats one generalist*
  (`.spade/learnings/2026-04-22-single-reviewer-is-weaker-than-panel.md`)
  — this Scope **preserves** the panel shape from M-328; it does not
  re-litigate persona set, merge logic, or severity rubric. The work here
  is strictly about making the panel's claims verifiable (dispatch banner,
  schema version, honest header language when degraded). The "Panel without
  confidence" anti-pattern called out in that learning is already mitigated
  by the Bundle E contract; this Plan does not weaken it.

## Summary

Seven tasks in two delivery bundles. Bundle F addresses the adversarial
**blocking** finding (dispatch honesty + schema versioning). Bundle G
addresses the adversarial **major** finding on learnings (cold-start +
logging), and folds in the small `.spade/version` bump + `/spade-update`
note (Scope AC 7 — Bundle H collapsed into G per the Scope's explicit
allowance).

Delivery order: **F → G**. F ships first because the blocking finding is
load-bearing for framework credibility and G's tasks are genuinely
independent. G can follow immediately; no cross-bundle dependency exists
beyond the `.spade/version` bump in G landing last in the v1.1.1 release
train.

## Bundle F — Dispatch honesty + schema versioning

**Label:** `bundle:v111-dispatch-honesty`
**Addresses:** AC 1, 2, 3, and partial 6
**Delivery mode:** AI

### Why this bundle first

The blocking panel finding on M-328 named a specific failure mode: if
`.claude/agents/*.md` dispatch silently degrades, `/spade-review` emits
JSON that *looks* multi-persona but isn't. The longer this goes
unaddressed, the more consumer audit trails cite "multi-persona review"
without the ability to verify. Ship F first, then G.

---

#### Task 1: Dispatch-mode detection and banner in `/spade-review`

- **Mode:** ai-delivered
- **Depends on:** none
- **Effort:** moderate (2–3 hours)
- **Execution posture:** `test-first` — write the detection contract as
  skill prose first, then the runtime-probe pseudocode, then the banner
  emission. The skill is prose so there's no "test" in the code sense,
  but the contract is testable by reading the output: every invocation
  must emit `Dispatch mode: <subagent-dispatch|sequential-inproc|degraded>`
  as the first output line.
- **Description:** Add a deterministic three-value dispatch-mode
  detection contract to `.claude/skills/spade-review/SKILL.md`. The skill
  must: (a) attempt parallel subagent dispatch; (b) fall back to
  sequential-subagent; (c) detect when no isolated-context path was
  available and set mode to `degraded`. The detected mode is emitted as
  the first line of the report header.
- **Approach:** Extend the "Spawning the Panel" section in the skill
  prose. Name the three values explicitly with decision rules for each.
  Add a "Dispatch-mode determination" sub-section that an agent follows
  at runtime. Banner format: `Dispatch mode: <value>` on its own line at
  the top of the `PANEL SECOND OPINION` block.
- **Tests:** Manual — run `/spade-review` against a fixture Scope in the
  smoke test used at end of v1.1. Verify the first line of output names
  one of the three values. Skill-frontmatter lint already covers shape;
  no new lint needed.

#### Task 2: Add `schema_version` and `dispatch_mode` to output contract

- **Mode:** ai-delivered
- **Depends on:** Task 1
- **Effort:** brief (< 1 hour)
- **Execution posture:** `test-first` on the contract shape — the JSON
  schema in the skill prose *is* the test; it's what a downstream tool
  will parse against.
- **Description:** Extend the merged-report output contract so the
  header carries `schema_version: "1.1.1"` and `dispatch_mode: <value>`
  in machine-parseable form (prose table + inline JSON block at the top
  of the merged report). Existing persona-level finding schema stays
  unchanged — this is a *wrapper* schema around the merged report, not a
  change to per-persona findings.
- **Approach:** Add a `## Report envelope` section to
  `.claude/skills/spade-review/SKILL.md` defining the new top-level
  schema. Example:

  ```json
  {
    "schema_version": "1.1.1",
    "dispatch_mode": "subagent-dispatch",
    "personas_spawned": 5,
    "findings": [ /* per Bundle E schema */ ]
  }
  ```

  The skill emits this envelope alongside the existing Markdown report.
- **Tests:** Manual — inspect skill output JSON block; verify the two
  required fields. Lint-skill-frontmatter stays green (skill's own
  frontmatter unchanged).

#### Task 3: Honest header language when `dispatch_mode == "degraded"` + docs refresh

- **Mode:** ai-delivered
- **Depends on:** Tasks 1, 2
- **Effort:** moderate (1–2 hours)
- **Execution posture:** `test-first` against the prose — the test is
  that the skill prose contains explicit "do not use the word 'panel' or
  'multi-persona' when degraded" language. PR review verifies.
- **Description:** When dispatch mode is `degraded`, the skill MUST NOT
  use "panel" or "multi-persona" in the report section title. Title
  becomes `SINGLE-CONTEXT SIMULATION (degraded)` instead of `PANEL
  SECOND OPINION`. Skill prose explicitly forbids the coordinator agent
  from using those words under degraded mode. Also refresh
  `docs/FRAMEWORK.md#multi-persona-review` to document the banner, the
  schema version, and the degraded-header constraint.
- **Approach:** Edit the `## Presenting the Report` section in
  `.claude/skills/spade-review/SKILL.md` to add the degraded branch.
  Add to `## What This Skill Must Never Do` a new rule: "Claim
  'multi-persona' or 'panel' in report output when dispatch_mode is
  'degraded' — the whole point of the banner is that the coordinator
  must not launder a single-context simulation as a panel." Then update
  `docs/FRAMEWORK.md` accordingly.
- **Tests:** Manual — run `/spade-review` and force-simulate `degraded`
  mode (by editing fixture); verify header omits "panel" and
  "multi-persona".

---

## Bundle G — Learnings cold-start + matched-learnings log + v1.1.1 release

**Label:** `bundle:v111-learnings-observability`
**Addresses:** AC 4, 5, partial 6, AC 7
**Delivery mode:** AI

### Why this bundle second

G's tasks are genuinely independent of F's. The Scope's suggested "Bundle H
= version bump" is folded in here as Task 7 — it's two files of change and
there's no reason to separate it from the G docs refresh that already
touches `docs/FRAMEWORK.md`.

---

#### Task 4: Cold-start threshold in `/spade-plan` learnings-match

- **Mode:** ai-delivered
- **Depends on:** none (independent of Bundle F)
- **Effort:** brief (< 1 hour)
- **Execution posture:** `test-first` on the deterministic cutover — the
  skill prose must name the exact rule: count active non-archived
  learnings, apply threshold `1` when `< 20`, else `≥ 2`.
- **Description:** Update `.claude/skills/spade-plan/SKILL.md` "Before
  You Start" step 3 (the learnings-match prose) so the threshold is
  deterministically derived from the count of active non-archived
  entries: `1` until the count hits `20`, `≥ 2` from `20` onwards. The
  cutover is named, not configurable.
- **Approach:** Replace the current "At least two of the entry's tags
  appear" rule with conditional prose. Count entries by globbing
  `.spade/learnings/*.md` and filtering those with `status: active`
  (skip private/ per existing rule). Keep the `scope_ref` path
  unchanged — exact scope_ref match is always ≥ 1 match regardless of
  count.
- **Tests:** Manual — run `/spade-plan` on a fresh fixture repo with 0
  learnings (must behave identically: nothing to match). Add one
  learning sharing one tag with the Scope; verify it surfaces (threshold=1
  at count=1 < 20). Scale to ≥ 20 learnings in another fixture; verify
  ≥ 2 required.

#### Task 5: Matched-learnings log in `/spade-plan` output

- **Mode:** ai-delivered
- **Depends on:** Task 4
- **Effort:** brief (< 1 hour)
- **Execution posture:** `test-first` on output shape.
- **Description:** When `/spade-plan` surfaces prior learnings, the
  output includes a `Learnings matched` subsection enumerating each:
  filename and match reason (`scope_ref: <ID>` OR
  `tags: <comma-separated matched tags>`). If zero matches, the
  subsection is omitted (silence, not "no matches" padding).
- **Approach:** Add prose under the "Prior Learnings Considered"
  subsection in `spade-plan/SKILL.md` defining the log shape. The
  existing "Prior Learnings Considered" section already lists matched
  learnings by title; this task adds structured match-reason data
  underneath each entry so a human scanning the Plan can see *why* a
  learning surfaced.
- **Tests:** Manual — Plan generation on a Scope that matches a
  learning via tags should show the tag list; Plan on a Scope with
  matching scope_ref should show that.

#### Task 6: Docs refresh for learnings cold-start + logging

- **Mode:** ai-delivered
- **Depends on:** Tasks 4, 5
- **Effort:** brief (< 1 hour)
- **Execution posture:** `straight-through` — pure docs change
  mirroring skill prose already written in Tasks 4/5.
- **Description:** Update `docs/FRAMEWORK.md#learnings` to document the
  cold-start threshold (1 until 20 entries, ≥ 2 after) and the
  matched-learnings log. Call out the `20` as deliberate — changing it
  requires a new Scope.
- **Approach:** Edit the existing "### Plan-time integration"
  sub-section. Keep the rest of the learnings doc unchanged.
- **Tests:** `./scripts/lint/run-all.sh` — learnings lint green (no
  schema change), examples lint green (no posture change),
  framework docs still parse.

#### Task 7: `.spade/version` → 1.1.1 + `/spade-update` v1.1.0→v1.1.1 note

- **Mode:** ai-delivered
- **Depends on:** Tasks 1-6 (lands last in the v1.1.1 release train)
- **Effort:** brief (< 1 hour)
- **Execution posture:** `straight-through` — two tiny doc + version
  changes.
- **Description:** Bump `.spade/version` from `1.1.0` to `1.1.1`. Update
  `.claude/skills/spade-update/SKILL.md` to describe v1.1.0 → v1.1.1 as
  a "version-pin-only, no fragment content change" upgrade — consumers
  still run the helper for consistency (re-stamps the marker version),
  but no `AGENTS.md` / `CLAUDE.md` content changes on their end.
- **Approach:** Two small edits. Add a short "v1.1.0 → v1.1.1 upgrade"
  subsection to the existing "Consumer-repo migration" section in
  `/spade-update` that states: same command as before (invoke
  `spade-marker-replace` with `1.1.1`), outcome is a version-pin-only
  re-stamp.
- **Tests:** Run the existing `tests/onboard-idempotency.sh` Case 3
  (version bump) with `1.1.1` as the new version string — already works
  generically (the test uses the helper contract which accepts any
  `X.Y.Z`).

---

## Cross-bundle risks

| # | Risk                                                                 | Mitigation                                                                         |
|---|----------------------------------------------------------------------|------------------------------------------------------------------------------------|
| C1 | Skill prose is the contract, not executable code                     | PR review is the test; both bundles touch skills, not new scripts.                 |
| C2 | Dispatch-mode detection prose is untested against real Claude Code   | Bundle F Task 1 asks for a smoke test: run `/spade-review` after merge and confirm banner emits. If banner is wrong, iterate.  |
| C3 | `20`-entry cold-start threshold is another judgement call            | Same pedigree as the original `≥2` choice — documented as deliberate, changeable only via new Scope. Lowered risk vs. the original M-328 issue because the matched-learnings log (Task 5) makes mismatches visible. |
| C4 | Consumer upgrades v1.1.0 → v1.1.1 must be a no-op on fragment content | Task 7 explicitly scopes this; no fragment file changes in Bundle F or G.          |

## Approval checklist

Before approving, verify:

- [ ] Each acceptance criterion in M-343 maps to at least one task
  (AC1→T1, AC2→T3, AC3→T2, AC4→T4, AC5→T5, AC6→T3+T6, AC7→T7).
- [ ] No task violates `ANTI-PATTERNS.md` — no runtime, no new
  integration, no build step. Verified: all tasks are skill-prose +
  docs changes, plus a trivial `.spade/version` bump.
- [ ] Delivery order F → G is defensible (blocking finding first).
- [ ] Each task has concrete files, risks, and verification steps.
- [ ] Dependencies between tasks are linear and stated.
- [ ] No new skill is introduced (Scope mandates skill-count discipline;
  this Plan only extends existing skills).
- [ ] PS parity not triggered (no setup script changes).

## Sub-issue layout (to create in Linear)

| Bundle | Sub-issue title                                                            | Labels                                                |
|--------|----------------------------------------------------------------------------|-------------------------------------------------------|
| F      | Bundle F — dispatch-mode banner + schema version + degraded-header honesty | `ai-planned`, `bundle:v111-dispatch-honesty`          |
| G      | Bundle G — learnings cold-start + matched-learnings log + v1.1.1 bump      | `ai-planned`, `bundle:v111-learnings-observability`   |

Linking each sub-issue to this Plan document and to parent Scope M-343.
