---
name: spade-review-signal-per-token
title: Redesign /spade-review for signal-per-token (4-persona panel, tiered report)
status: scoped
type: refactor
phase: scope
created: 2026-05-17
updated: 2026-05-17
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
linear_issue: M-994
linear_url: https://linear.app/m-kopa/issue/M-994/redesign-spade-review-for-signal-per-token-4-persona-panel-tiered
panel_review: 2026-05-17 (subagent-dispatch, 11 findings, 0 filtered)
---

## Scope: Redesign /spade-review for signal-per-token (4-persona panel, tiered report)

**Intent:** A human running `/spade-review` gets a report they can act on — convergence and `blocking`/`major` findings lead and fit on a screen, while the panel's full output is preserved as an audit artefact rather than dumped to the terminal. The panel also costs less: four personas instead of five, each capped to its strongest findings.

### Acceptance Criteria

1. The panel runs **four** personas — `spade-review-yagni-simplicity` is removed. Its remit is folded into two survivors as **literal, named rubric entries**: `scope-guardian`'s "What you look for" gains a named gold-plating / proportionality item, and `adversarial-reviewer`'s gains a named second-order / compounding-cost item — each checkable as concrete rubric text.
2. Each persona's output contract caps findings at **3 maximum on its primary remit, self-ranked strongest-first**. `scope-guardian` and `adversarial-reviewer` may additionally emit **up to 1** finding on their absorbed YAGNI remit — a reserved slot, so absorbed coverage cannot be crowded out by primary findings.
3. The `nit` severity tier is removed everywhere it appears — each persona file's severity rubric **and** its `category` enum / guidance text, the SKILL.md severity rubric, and the merge/sort logic. No dangling `nit` reference remains; severity is `blocking | major | minor`.
4. `confidence` is demoted to a **display-only `high | low` annotation — not a sort key**. The merge sorts by severity, then convergence (`also_flagged_by` count); no `severity × confidence` arithmetic remains. The report-envelope `schema_version` is bumped to **`2.0.0`** (breaking finding-shape change: `nit` removed, `confidence` recast, `personas_spawned` 5→4). No `/spade-update` data-migration entry is added — the envelope has no persistent consumer.
5. The report is **tiered**. Inline output shows convergence findings + every `blocking` finding in full; `major` findings fill an inline budget of ~5–7 findings total and any beyond it spill to a count line; `minor` findings collapse to a single count line pointing at the full report. The full merged report — every finding, every persona prose summary, the envelope — is persisted on every panel run.
6. The persisted report is written to **`.spade/reviews/<slug>-<date>.md`**; the directory is **gitignored by default**; a filename-collision rule handles repeat runs of the same slug on the same date (numeric suffix). `.spade/reviews/` is added to the documented `.spade/` layout in `PATTERNS.md` and `ARCHITECTURE.md`.
7. The roster and schema changes are propagated coherently across the framework surface: `docs/FRAMEWORK.md` (persona table, `severity` enum, "panel of five" prose), this repo's `CLAUDE.md` skills table, `examples/`, and `SKILL.md`'s "five personas or none" invariant prose. The `agents` and `examples` CI jobs pass.
8. Report presentation survives intact: the dispatch-mode banner stays the first line and the envelope stays a JSON block; a `degraded`-mode run remains distinguishable from a real multi-context panel, verified by a stated check. Cross-model synthesis shows only disagreements and tension points — "where I agree" collapses to one line.

### Architectural Constraints

- All changes are skill prose + persona markdown — `.claude/skills/spade-review/SKILL.md` and `.claude/agents/spade-review-*.md` (one file deleted). No `bin/` script, no `jq`, no compiled merge step — honours `PATTERNS.md` "Prose over code", the constraint M-968 was reviewed down to.
- Convergence detection stays coordinator-side semantic judgement at merge time — no merge script, no `concern_tag` shared vocabulary (reaffirms the M-968 outcome).
- `schema_version` `2.0.0` versions the **report envelope** — it is distinct from the framework's skill-file fragment-marker / `/spade-update` distribution mechanism. Planning confirms `docs/FRAMEWORK.md` does not couple the two; if it does, planning reconciles.
- `.spade/reviews/` is a new gitignored artefact directory; it must be added to the `.spade/` layout documented in `PATTERNS.md` and `ARCHITECTURE.md` so the new state location is documented, not drift.
- The dispatch-mode banner and envelope's `degraded`-run honesty signal must survive the redesign.

### Dependencies

None.

### Context

- **Upstream:** `.claude/skills/spade-review/SKILL.md`; the five `.claude/agents/spade-review-*.md` persona files.
- **Downstream:** humans reading panel reports; `.spade/reviews/` as a new persisted-artefact directory; `/spade-approve` and `/spade-scope` invoke the panel but consume the human's decision, not the envelope — unaffected.
- **Related:** M-968 (convergence surfacing, just shipped) — this builds on it; `docs/FRAMEWORK.md`, `CLAUDE.md`, and `examples/` restate the roster and schema and must stay in sync; the `.spade/learnings/` review learnings.

### Out of Scope

- A `bin/` merge utility or scripted determinism — stays prose (M-968 outcome).
- A `concern_tag` / shared cross-persona vocabulary — stays out (couples persona files).
- Going below 4 personas — 5→3 was considered and rejected.
- Per-persona context tailoring (trimmed context per persona).
- Making the panel scale with plan size (fewer personas for small plans).
- Whether the panel should gate — stays non-blocking.
- Re-running past reviews to *prove* the 4-persona cut loses no findings — the reserved-slot mitigation (AC #2) is accepted in lieu of empirical evidence.

### Origin

Ad-hoc — a review of `/spade-review` this session found its report too verbose and token-hungry to be actionable. This Scope is the redesign. The Scope was itself put through a 5-persona `/spade-review` panel (Scope Review mode); see Panel Review below.

### Risk / Unknowns

- The reserved-slot mechanism (AC #2) is a *mitigation* for the yagni-fold coverage risk, not a proof. If a future review misses a YAGNI concern neither survivor's rubric caught, the loss is unobservable because the panel is non-blocking. Accepted: empirical evidence was deliberately descoped.
- `schema_version` `2.0.0` is pinned, but planning must confirm `docs/FRAMEWORK.md` does not tie the envelope version to the skill-file fragment-marker policy.
- The inline budget (~5–7) plus the AC #2 caps (4 personas × up to 3+1) can still produce more `blocking`/`major` findings than the budget — AC #5's spill-to-count-line rule is the defined overflow behaviour; planning verifies it reads cleanly.
- `docs/FRAMEWORK.md` / `examples/` / `CLAUDE.md` all restate roster/schema; the `agents` and `examples` CI jobs guard consistency and must pass.

### Delivery Preference

Mostly AI-delivered — skill prose + persona markdown only.

### Priority

This cycle.

### Panel Review (2026-05-17)

A 5-persona `/spade-review` panel ran in Scope Review mode on the first draft of this Scope. `subagent-dispatch`, 11 findings (6 major), 0 filtered. Two genuine multi-persona convergences. All findings 1–8 were folded into this revision.

| Panel finding | Disposition |
|---|---|
| 4 personas converged: `.spade/reviews/` artefact under-specified (layout, gitignore, collision, whether to persist) | **Folded** — AC #6 pins path, gitignore default, collision rule, doc-layout; persistence kept (load-bearing for Intent) |
| scope-guardian + adversarial + yagni: AC #2/#5 caps uncoordinated, overflow undefined | **Folded** — AC #5 defines the spill-to-count-line overflow rule |
| scope-guardian: `nit` removal misses the `category` enum / guidance in each persona file | **Folded** — AC #3 names both the rubric and category/guidance text |
| adversarial: folding yagni makes scope-guardian a two-concern reviewer the 3-cap forces to drop one | **Mitigated** — AC #2 reserved slot; AC #1 named rubric entries |
| architecture + scope-guardian: `schema_version` not pinned, may engage fragment-marker policy | **Folded** — AC #4 pins `2.0.0`; constraint notes the envelope-vs-distribution distinction |
| scope-guardian: AC #1 "verifiable in rubrics" not testable | **Folded** — AC #1 now requires literal named rubric entries |
| architecture + scope-guardian: doc/cross-ref surface broader than ACs covered | **Folded** — AC #7 names FRAMEWORK.md, CLAUDE.md, examples/, the invariant prose |
| security-lens: no AC verifies `degraded`-mode detection survives | **Folded** — AC #8 adds the verifying check |
| yagni: "expansion affordance" is gold-plating | **Applied** — AC #5 says "count line", no affordance |
| yagni: `confidence` as a sort key earns little | **Applied** — AC #4 makes confidence display-only, not a sort key |
| yagni (nit): `/spade-update` migration entry may be YAGNI | **Applied** — AC #4 states no migration entry |
