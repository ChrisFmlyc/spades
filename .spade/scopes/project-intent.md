---
name: project-intent
title: SPADE v1.7 — Project Intent (INTENT.md) and /spade-intent skill
status: scoped
type: feature
phase: scope
created: 2026-05-16
updated: 2026-05-16
origin: milestone
priority: high
delivery: mixed
linear_issue: M-951
linear_url: https://linear.app/m-kopa/issue/M-951/spade-v17-project-intent-intentmd-and-spade-intent-skill
panel_review: 2026-05-16 (subagent-dispatch, 20 findings, 0 filtered)
---

## Scope: Project Intent — INTENT.md document and /spade-intent skill

**Intent:** Every SPADE project has a single, human-owned `INTENT.md` capturing why the project exists — the problem it solves, who it serves, and what it deliberately will not do — and the SPADE loop actively keeps Scopes and Plans aligned to it. Individual units of work can no longer drift the product away from its purpose unnoticed.

---

### Acceptance Criteria

1. **INTENT.md template** — a new root document, peer to `ARCHITECTURE.md`, with six sections (Problem, Users, What it does, Success, Non-goals, Maturity) and a `last_reviewed: YYYY-MM-DD` frontmatter field. The six section headings and the `last_reviewed` key are a **locked conformance schema** that CI and downstream skills depend on.
2. **/spade-intent skill** (create + edit modes) runs an interactive, human-composed / AI-structured conversation that produces or refines `INTENT.md` and never silently authors or rewrites it. Correctness is demonstrated by the skill producing this framework repo's own filled-in `INTENT.md` (dogfooding).
3. **Scaffolding via both onboarding paths** — `/spade-onboard` and `/spade-update` both scaffold the `INTENT.md` template idempotently (an existing `INTENT.md` is never overwritten) and point the human at `/spade-intent` to fill it, so repos adopting v1.7 via either path receive the template.
4. **/spade-plan staleness nudge** — `/spade-plan` reads `INTENT.md` and surfaces a non-blocking staleness nudge when `last_reviewed` is >180 days old or the doc is unfilled. The nudge is suppressed to once per session (mirroring the pandoc-hint cadence); an absent `INTENT.md` is treated as "feature inactive" (no nudge); a malformed or missing date degrades to "stale" rather than erroring.
5. **/spade-evaluate update suggestion** — `/spade-evaluate` suggests an `INTENT.md` update when delivered work touches or expands a stated `INTENT.md` non-goal. Non-blocking and human-gated. This is the single update suggestion in the loop — there is no plan-time capability nudge.
6. **scope-guardian non-goal check** — `/spade-review`'s `scope-guardian` persona checks Scopes and Plans against `INTENT.md`'s Non-goals section (a distinct, project-level input from the Scope's own Out of Scope) and raises an advisory finding on an explicit, near-verbatim contradiction. Verified by a fixture Scope that contradicts a sample non-goal producing a finding, with panel-merge logic and the agents lint still passing.
7. **Documentation + CI** — `README.md` and `docs/FRAMEWORK.md` document the new document, the skill, and the loop integration; the 180-day threshold is recorded as a deliberate named constant mirroring the `/spade-learn --refresh` cadence; the `INTENT.md` template and example are validated by extending an existing CI lint, not by adding a new lint job.

---

### Architectural Constraints

- Skill is Markdown + YAML frontmatter at `.claude/skills/spade-intent/SKILL.md` (ARCHITECTURE.md Tech Stack). `INTENT.md` is a root reference doc — no runtime, no new dependency, no Python/Node (ANTI-PATTERNS dependency rules).
- **Hard constraint:** human-owned / AI-facilitated. Per AGENTS.md ("humans own the edges — intent and verification"), the skill facilitates and structures but never silently authors or rewrites `INTENT.md`.
- `INTENT.md` scaffolding is **template-only**: neither `/spade-onboard` nor `/spade-update` may AI-author its content. This is a deliberate exception to `/spade-onboard`'s codebase-analysis fill pattern and must be called out in the relevant Plan task.
- Onboarding and update writes must be idempotent (`.spade/learnings/2026-04-22-onboarding-must-be-idempotent.md`).
- Fixed-option decisions use `AskUserQuestion` (FRAMEWORK.md "Asking the Human").
- No new `/spade-review` persona — panel capped at 5; extend `scope-guardian`'s remit instead. The agent file's finding-`category` set is closed — the Plan must state whether the non-goal check reuses an existing category or adds one, and confirm the agents lint and `/spade-review` merge logic tolerate it.
- CI lint stays shell/stdlib-only (External Toolchain Policy). Staleness detection is prose-in-skills, not a consumer-facing CI lint.

---

### Dependencies

None — entirely internal to the framework repo. `INTENT.md` is not HTML-rendered, so no pandoc dependency.

### Context

- **Upstream:** `/spade-onboard` and `/spade-update` scaffold it; the human composes it via `/spade-intent`.
- **Downstream:** `/spade-plan`, `/spade-evaluate`, and `/spade-review`/`scope-guardian` read or check against it.
- **Related:** peer to the `ARCHITECTURE.md` / `PATTERNS.md` / `ANTI-PATTERNS.md` reference docs; parallel to `/spade-learn` — `/spade-learn` captures process knowledge, `/spade-intent` captures product evolution.

### Out of Scope

- `INTENT.md` does not define or replace OKRs, Milestones, or strategy — it is the durable backdrop, not a strategy-planning tool.
- No new SPADE phase or acronym letter; not a delivery gate.
- No HTML rendering for `INTENT.md` (root docs are not rendered).
- No new `/spade-review` persona; no AI auto-rewrite or autonomous maintenance of `INTENT.md`.
- No consumer-side CI enforcement of staleness (prose nudge only).
- `/spade-quick` (fast-track) and `/spade-status` are deliberately untouched — no staleness nudge on the quick path, no INTENT health surfaced in `/spade-status`. Both are v1.8+ candidates if demand surfaces.

### Origin

SPADE v1.7 milestone — the v1.7 headline feature (v1.6.0 shipped 2026-05-15). No Linear milestone object exists in the SPADE project yet; origin recorded here in text.

### Risk / Unknowns

- The central tension is keeping AI from owning a human artefact — the skill prose must enforce "facilitate, never author." Getting this wrong undermines AGENTS.md's core thesis.
- **Adoption risk:** a filled-in `INTENT.md` produces no immediate delivery value the way `ARCHITECTURE.md` improves Plan quality, so consumer repos may carry permanently-unfilled templates and every downstream feature silently no-ops. Mitigated by dogfooding (AC #2) as the honest acceptance test; broader adoption is a v1.7-evaluation question, not a delivery criterion.
- The non-goal contradiction check is the one feature with teeth and depends on the human writing precise non-goals; bounded to explicit/near-verbatim contradiction to keep the false-positive rate low (false positives erode trust across the whole panel).
- The Plan must justify why `/spade-intent` is genuinely orthogonal to `/spade-scope` and `/spade-learn` rather than a mode of either (ANTI-PATTERNS "do not add skills casually") — absent that argument this is a review-time rejection.
- Overlap with `ARCHITECTURE.md`'s System Overview — the Plan should draw an explicit boundary (INTENT.md owns durable why/who/non-goals; ARCHITECTURE.md owns how it is built) and trim or cross-reference the overview.
- Sizeable Scope (~7 tasks across multiple skills) — likely two delivery bundles. If Plan generation exceeds 7 tasks, split (core doc + skill + scaffolding as one Scope, loop-integration wiring as a follow-up).

### Delivery Preference

Mixed, mostly AI-delivered. AI delivers the template, skill, loop integration, lint extension, and docs. The framework repo's own `INTENT.md` content is human-composed via `/spade-intent` (intent is human-owned by definition).

### Priority

High — v1.7 headline feature.

---

### Panel Review (2026-05-16)

A 5-persona `/spade-review` panel ran on the draft Scope: **subagent-dispatch, 20 findings (0 blocking, 6 major, 11 minor, 3 nit), 0 filtered.** Three personas independently rated the Scope "unusually disciplined / architecture-aware." Findings actioned into the Scope above:

| Finding (persona) | Disposition |
|---|---|
| Plan-time "new capability/audience" nudge is speculative (yagni, scope-guardian, adversarial — major ×3) | **Cut.** No plan-time capability nudge; the single update suggestion moved to `/spade-evaluate`, tied to the concrete non-goal signal. |
| Staleness nudge fires on every `/spade-plan` run (adversarial, major) | **Actioned.** AC #4 specifies once-per-session suppression; absent file = "feature inactive". |
| Scope assumes humans fill INTENT.md; no adoption measure (adversarial, major) | **Actioned.** Dogfooding promoted to AC #2 as the acceptance test. |
| AC #6 partly restates scope-guardian's existing remit (scope-guardian, adversarial, major) | **Actioned.** AC #6 reworded — distinct project-level Non-goals input; bounded to explicit/near-verbatim contradiction; fixture-verified. |
| `/spade-update` path unaddressed for existing consumers (adversarial, minor) | **Actioned.** AC #3 covers `/spade-onboard` and `/spade-update`. |
| Dedicated CI lint job is marginal (yagni, minor) | **Actioned.** AC #7 extends an existing lint instead of adding a job. |
| Section set / 180-day constant under-specified (scope-guardian, minor/nit) | **Actioned.** AC #1 locks the schema; AC #7 documents 180 days as a named constant. |
| `onboard` scaffolding diverges from its AI-author pattern; justify skill orthogonality (architecture-strategist, minor ×2) | **Actioned.** Captured as Architectural Constraints / Risk for the Plan to honour. |
| Malformed `last_reviewed` date handling (security-lens, minor) | **Actioned.** AC #4 degrades gracefully. |
| Drop two-mode skill structure (yagni, minor) | **Rejected** — `/spade-scope`, the closest analogue, has explicit Create/Edit modes; formal modes are an established framework pattern. |
| Defer the Maturity section (yagni, nit) | **Rejected** — six-section set confirmed with the scoper; Maturity is cheap human context. |

Carried to the Plan: exact `scope-guardian` category decision, the suppression-cadence mechanism shared with the pandoc hint, the INTENT.md ↔ ARCHITECTURE.md boundary, and the `/spade-intent` orthogonality argument.
