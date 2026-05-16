---
issue: M-951
title: SPADE v1.7 — Project Intent (INTENT.md) and /spade-intent skill
date: 2026-05-16
status: approved
---

# Plan for: SPADE v1.7 — Project Intent (INTENT.md) and /spade-intent skill

**Scope:** [M-951](https://linear.app/m-kopa/issue/M-951) · **Bundles:** 2 · **Tasks:** 7 (M-952–M-958)

**Technical Approach Summary:** Ship a marker-bearing `INTENT.md` template + worked example with a locked six-section schema, a new prose skill `/spade-intent` that facilitates filling it, and idempotent scaffolding through both `/spade-onboard` and `/spade-update`. Then wire three existing skills to read it — a once-per-session staleness nudge in `/spade-plan`, a non-goal-expansion suggestion in `/spade-evaluate`, and a bounded non-goal contradiction check in the `scope-guardian` review persona. Everything is Markdown + shell; no runtime, no new dependency.

## Risks and Assumptions

- **R1 (open — human decision before T1 implementation):** SPADE's architecture-template distribution is ambiguous. `/spade-onboard` copies `ARCHITECTURE.md` from `~/.spade/` but this repo's copy is filled in. `INTENT.md` faces the same fork: the framework's own dogfooded `INTENT.md` (T2) and the consumer template (T3) cannot be the same file. T1 must decide: (a) follow the `ARCHITECTURE.md` precedent as-is, or (b) ship the distributable template at a distinct path. Plan recommends (b).
- **R2:** SPADE's posture vocabulary is code-centric; most tasks edit skill *prose*, which has no executable surface to unit-test (ANTI-PATTERNS: "behaviour is prose, not code"). Several tasks are `straight-through` with explicit justification — flagged so Approve does not read it as rubber-stamping.
- **R3:** `scope-guardian`'s agent file has a closed finding-`category` enum guarded by `lint-agents.sh`. T6 must decide reuse-`out-of-scope` vs add a category; adding one ripples to the lint and possibly `/spade-review` merge logic.
- **R4 (carried from Scope):** Adoption — consumers may carry unfilled templates. Dogfooding (T2) mitigates for this repo; broader adoption is a v1.7-Evaluate question.
- **A1:** `setup` / `setup.ps1` pick up a new `spade-*` skill directory by glob. T2 verifies; if false, both setup scripts get a one-line addition (dual-shell parity).

## Prior Learnings Considered

- *Any write into a consumer file must be idempotent via delimited markers, never append* (`2026-04-22-onboarding-must-be-idempotent.md`) — T3 honours the idempotency principle, but **deliberately not via `spade-marker-replace`**: `INTENT.md` is a standalone whole-file artefact (like `ARCHITECTURE.md`), not a framework region embedded in a human-owned file, so the correct mechanism is create-if-absent + never-overwrite, verified by extending the `onboard-idempotency` fixture suite.
  Match reason: tags matched [markers]

## Tasks

### T1 — INTENT.md template, worked example, and schema lint — `M-952`
- **Mode:** ai-delivered · **Depends on:** none · **Effort:** moderate
- **Execution posture:** straight-through on the template/example content; test-first on the lint extension
- **Description:** Create the `INTENT.md` template (six locked sections: Problem, Users, What it does, Success, Non-goals, Maturity; `last_reviewed: YYYY-MM-DD` frontmatter; `<!-- Describe … -->` fill markers). Create `examples/example-intent.md`. Extend `scripts/lint/lint-examples.sh` to assert the schema. Resolve R1.
- **Approach:** Mirror `ARCHITECTURE.md` / `examples/example-scope.md`. Schema lands first as the contract for all downstream tasks. Lint extends `lint-examples.sh`'s `require_in_*` pattern — no new lint job.
- **Tests:** `lint-examples.sh` passes; fails on a removed section heading or `last_reviewed`. `run-all.sh` green.

### T2 — /spade-intent skill — `M-953`
- **Mode:** ai-delivered (dogfood verification human-in-the-loop) · **Depends on:** T1 · **Effort:** significant
- **Execution posture:** straight-through — new SKILL.md is Markdown prose, no executable surface; verified by `lint-skill-frontmatter.sh` + dogfood run
- **Description:** Author `.claude/skills/spade-intent/SKILL.md` (create + edit modes, human-composed/AI-structured conversation, hard "facilitate, never author" guarantee, `AskUserQuestion` for fixed-option decisions). Add the skill row to `fragments/CLAUDE-section.md` + `CLAUDE.md` skill table; bump fragment marker version. No HTML render closing step.
- **Approach:** Orthogonality (ANTI-PATTERNS "do not add skills casually"): not a mode of `/spade-scope` (per-unit-of-work Linear issue, flows then closes) nor `/spade-learn` (many small immutable retrospective entries). `INTENT.md` is one durable, in-place-edited project doc — different artefact, lifecycle, cardinality, storage. It maintains the why-doc the way `/spade-onboard` fills `ARCHITECTURE.md`, but intent is not inferable from code, so a dedicated human-facilitation skill is warranted.
- **Tests:** `lint-skill-frontmatter.sh` passes. Dogfood: skill run against this repo produces a complete `INTENT.md`, six sections filled, zero fill markers — human composes content (AC #2 evidence).

### T3 — /spade-onboard + /spade-update INTENT.md scaffolding — `M-954`
- **Mode:** ai-delivered · **Depends on:** T1, T2 · **Effort:** moderate
- **Execution posture:** test-first — extend the `onboard-idempotency` fixtures/assertions for `INTENT.md` first, then edit the skill prose
- **Description:** `/spade-onboard` scaffolds the `INTENT.md` template create-if-absent (never overwrites) and points the human at `/spade-intent`. `/spade-update`'s migration recipe does the same so pre-v1.7 consumers receive it on upgrade. Note the template-only exception to onboard's AI-authoring pattern.
- **Approach:** Architecture-template precedent (create-if-absent). Idempotency honoured *without* `spade-marker-replace` (see Prior Learnings). Extend `tests/fixtures/onboard-*` + `lint-onboard-idempotency.sh`.
- **Tests:** `lint-onboard-idempotency.sh` green; second run unchanged; existing filled `INTENT.md` never touched.

### T4 — /spade-plan INTENT.md staleness nudge — `M-955`
- **Mode:** ai-delivered · **Depends on:** T1 · **Effort:** moderate
- **Execution posture:** straight-through — skill-prose behaviour change, no runtime to unit-test; verified by documented scenario walk-throughs
- **Description:** `/spade-plan` reads `INTENT.md`, emits a non-blocking staleness nudge when `last_reviewed` >180 days old or unfilled. Once-per-session suppression (pandoc-hint cadence). Absent file → silent. Malformed/missing date → "stale", never error.
- **Approach:** Slot into `/spade-plan`'s existing pre-Plan reading step. 180 days documented as a deliberate named constant mirroring `/spade-learn --refresh`.
- **Tests:** Scenario walk-through: stale → one nudge; fresh → silent; unfilled → nudge; absent → silent; garbage date → "stale", no error.

### T5 — /spade-evaluate INTENT.md update suggestion — `M-956`
- **Mode:** ai-delivered · **Depends on:** T1 · **Effort:** moderate
- **Execution posture:** straight-through — skill-prose behaviour change; verified by scenario walk-through
- **Description:** `/spade-evaluate` suggests an `INTENT.md` update when delivered work touches or expands a stated non-goal. Non-blocking, human-gated. The single update suggestion — no plan-time capability nudge.
- **Approach:** Add to `/spade-evaluate`'s post-verdict step. Trigger is the concrete non-goal signal, not a free judgment.
- **Tests:** Scenario walk-through: work expands a non-goal → suggestion fires; ordinary work → silent.

### T6 — scope-guardian non-goal contradiction check — `M-957`
- **Mode:** ai-delivered · **Depends on:** T1 · **Effort:** moderate
- **Execution posture:** test-first — write the fixture Scope + expected finding first, then extend the persona
- **Description:** Extend `.claude/agents/spade-review-scope-guardian.md` to check Scopes/Plans against `INTENT.md`'s Non-goals section (distinct from the Scope's own Out of Scope) and raise an advisory finding on explicit, near-verbatim contradiction. Open decision: reuse `out-of-scope` category vs add one (Plan recommends reuse).
- **Approach:** Minimal single-file persona edit (never reshape all personas). Bound to near-verbatim contradiction to hold down false positives.
- **Tests:** Fixture Scope contradicting a sample non-goal → finding; non-contradicting Scope → none; `lint-agents.sh` green; merge logic still parses.

### T7 — Documentation and v1.7.0 release packaging — `M-958`
- **Mode:** ai-delivered · **Depends on:** T1–T6 · **Effort:** moderate
- **Execution posture:** straight-through — documentation and release-metadata edits
- **Description:** Document `INTENT.md`, `/spade-intent`, and loop integration in `README.md` + new `docs/FRAMEWORK.md` §Project Intent. Bump `VERSION` / `.spade/version` to 1.7.0; add `CHANGELOG.md` entry.
- **Approach:** FRAMEWORK.md section mirrors §Learnings / §HTML Rendering. Draw the INTENT.md ↔ ARCHITECTURE.md boundary and trim ARCHITECTURE.md's System Overview to cross-reference rather than duplicate.
- **Tests:** `run-all.sh` green; cross-references resolve; FRAMEWORK.md skill table includes `/spade-intent`.

## Delivery Sequence

1. **T1** (M-952) — no dependencies, start immediately.
2. **T2** (M-953) — after T1.
3. **T3** (M-954) — after T1, T2. *(Bundle A complete.)*
4. **T4, T5, T6** (M-955, M-956, M-957) — parallel; each depends only on T1.
5. **T7** (M-958) — after T4, T5, T6. *(Bundle B complete.)*

## Delivery Bundles

### Bundle A: `intent-core`
- **Branch:** `spade/M-951-intent-core`
- **PR title:** SPADE v1.7: INTENT.md, /spade-intent skill, onboarding scaffolding (M-951)
- **Tasks:** T1, T2, T3 (M-952, M-953, M-954)
- **Rationale:** A self-contained, independently shippable increment — once merged, consumers can create and maintain `INTENT.md`. No file overlap with Bundle B.

### Bundle B: `intent-loop`
- **Branch:** `spade/M-951-intent-loop`
- **PR title:** SPADE v1.7: INTENT.md loop integration + docs (M-951)
- **Tasks:** T4, T5, T6, T7 (M-955, M-956, M-957, M-958)
- **Rationale:** Purely additive loop-wiring on merged Bundle A. The dependency is strictly one-directional (B needs A; A delivers value without B), the two task sets share no files, and reviewers get two coherent stories — "the artefact and how you author it" vs "how the loop consumes it." Splitting lets Bundle A's value land even if B needs rework.
