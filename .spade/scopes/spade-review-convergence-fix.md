---
name: spade-review-convergence-fix
title: Make /spade-review surface reviewer convergence (prose-only merge fix)
status: scoped
type: bug
phase: scope
created: 2026-05-17
updated: 2026-05-17
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
linear_issue: M-968
linear_url: https://linear.app/m-kopa/issue/M-968/make-spade-review-surface-reviewer-convergence-prose-only-merge-fix
panel_review: 2026-05-17 (subagent-dispatch, 24 findings, 0 filtered)
---

## Scope: Make /spade-review surface reviewer convergence (prose-only merge fix)

**Intent:** When independent reviewers on a `/spade-review` panel converge on the same concern, the human reading the report should see it. Today they don't — the merge's dedupe key can never match across personas, so the convergence signal is silently dropped. Make the merge surface convergence, specify the envelope counts plainly, and keep Scope-mode personas from emitting Plan-only findings — entirely in skill prose.

---

### Acceptance Criteria

1. SKILL.md's "Merging" section, when followed, merges two personas' findings on the **same underlying concern** into a single finding carrying `also_flagged_by`, and keeps findings on **unrelated** concerns separate — demonstrated by a worked example a reader can verify by hand.
2. The `(category, first-100-chars)` dedupe key is removed from SKILL.md; the section specifies convergence detection as coordinator-side semantic clustering at merge time, and names the disjoint-category-enum reason the old key could never fire.
3. `findings_total`, `findings_filtered_low_confidence`, and `personas_completed` are specified in SKILL.md as plain counts of the merged list / completed-persona set — no estimation language.
4. A mode-conditional line in SKILL.md's spawn-prompt template instructs personas, in Scope Review mode, to emit no `Task N` / bundle-count / task-count findings; the five persona files themselves are not edited.
5. `docs/FRAMEWORK.md` and `examples/` are updated only where they restate merge behaviour; the `agents` and `examples` CI jobs pass; the finding schema, the report-envelope schema, and `schema_version` are all unchanged.

---

### Architectural Constraints

- All changes are skill prose in `.claude/skills/spade-review/SKILL.md`. No new files, no `bin/` script, no `jq`/dependency, no compiled step. This deliberately honours `PATTERNS.md` "Prose over code" — the earlier `bin/`-utility approach was reviewed out by a `/spade-review` panel.
- No change to the finding JSON schema, the report-envelope schema, or `schema_version`. The envelope contract (1.1.1) is unchanged → no consumer migration, no `/spade-update` entry.
- The five persona files are **not** edited — the "five personas or none" invariant and the deliberate disjoint-category-enum design (which enforces "staying in lane") are preserved. The Scope-mode fix lives in the coordinator's spawn prompt, not the personas.
- Convergence detection is coordinator-side semantic judgement at merge time — accepted as non-deterministic (see Risk).

### Dependencies

None.

### Context

- **Upstream:** `.claude/skills/spade-review/SKILL.md` — its "Merging", "Report envelope", "Presenting the Report", and spawn-prompt sections.
- **Downstream:** humans reading panel reports. `/spade-approve` and `/spade-scope` invoke the panel but consume the human's decision, not the envelope — neither is affected.
- **Related:** the five `.claude/agents/spade-review-*.md` files (read, not modified); `docs/FRAMEWORK.md` if it restates merge behaviour.

### Out of Scope

- A `bin/` merge utility / scripted determinism — reviewed out by the panel.
- A `concern_tag` field or any shared cross-persona vocabulary — reviewed out (couples persona files, erodes independence).
- Any `schema_version` bump or `/spade-update` migration.
- Editing persona rubrics, severity calibration, or the roster.
- security-lens severity-inflation calibration, and feeding `.spade/learnings/` to personas — separate Scopes.
- Whether the panel should gate — stays non-blocking.

### Origin

Ad-hoc — a review of `/spade-review` this session found the convergence/dedupe mechanism is dead code. A first Scope draft was itself put through a `/spade-review` panel (Scope Review mode, 5 personas), which cut the original `bin/`-utility + `concern_tag` approach down to this prose-only fix.

### Risk / Unknowns

- Convergence detection becomes coordinator-side semantic judgement — not deterministic, not unit-testable. Accepted: the report's consumer is a human who already reads five verbatim prose summaries; a convergence signal in the merged list is an improvement, not a guarantee.
- "Same underlying concern" is a judgement call — the prose must calibrate the coordinator well enough that unrelated findings don't falsely merge. The worked example carries that weight.
- `docs/FRAMEWORK.md` may restate merge behaviour; check and keep in sync.

### Delivery Preference

Mostly AI-delivered — skill prose only.

### Priority

This cycle — small, in-flight, no dependencies.

---

### Panel Review (2026-05-17)

A 5-persona `/spade-review` panel ran in Scope Review mode on the **first draft** of this Scope (which proposed a `bin/spade-review-merge` utility, a `concern_tag` shared vocabulary, a `schema_version` bump, and a `/spade-update` migration). `subagent-dispatch`, 24 findings, 0 filtered. The panel confirmed all three defects are real but reviewed the fix shape down to this prose-only Scope.

| Panel finding | Disposition |
|---|---|
| adversarial: "unreliable audit trail" framing assumes a downstream envelope consumer that does not exist | **Reframed** — Intent is now human-facing; audit-trail claim dropped |
| yagni + adversarial + architecture + security: the `bin/` merge utility is over-build / an anti-pattern deviation | **Cut** — merge stays prose; counts are plain list lengths |
| yagni + adversarial: `concern_tag` shared vocabulary couples the five persona files and erodes "staying in lane" independence | **Cut** — convergence is coordinator-side semantic clustering; no schema change |
| yagni: five forked persona rubrics for Scope mode is over-build | **Reduced** — one mode-conditional line in the spawn prompt; persona files untouched |
| scope-guardian: criterion #5 smuggled an unannounced docs/migration workstream | **Moot** — no schema bump, no migration; docs sync only |
| scope-guardian: two unresolved forks made the Scope unplannable | **Resolved** — both forks closed (no script, no Scope Review removal) |

Findings carried forward to the Plan:

- The worked example proving convergence merges (AC#1) and the calibration that keeps unrelated findings separate — the panel flagged "same underlying concern" as the crux judgement call.
- Whether `docs/FRAMEWORK.md` restates the merge behaviour and therefore needs syncing (AC#5).
