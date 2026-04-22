---
title: A persona panel surfaces blocking review findings a generalist reviewer would miss
area: review
tags: review, panel, personas, adversarial-reviewer, dogfood, blocking-findings, spade-review, gates
created: 2026-04-22
status: active
public_safe: true
scope_ref: M-343
---

## What we learned

During v1.1 delivery we ran `/spade-review` as a 5-persona panel
against M-323 (the Scope that delivered the panel itself). The merge
pass received 22 findings from 5 personas; the `(category, first 100
chars)` dedupe fired on **zero** findings — every persona stayed in
lane as designed. That was the first real evidence the panel shape
produces distinct signal rather than five restatements.

The decisive moment was the adversarial-reviewer finding:

> "Bundle E's value depends on Claude Code dispatching `.claude/agents/*.md`
> as independent subagent contexts. Plan names this as an assumption but
> ships no runtime probe, no fallback spec, and no visible-to-user
> degradation signal. If dispatch silently falls back to in-context
> re-prompting, `/spade-review` emits JSON that looks multi-persona but
> isn't — and the user can't tell."

That was **blocking × 0.82 confidence** from a single persona. It drove
the entire M-343 v1.1.1 Scope — a 7-acceptance-criteria Scope with
two delivery bundles (F and G) that shipped end-to-end in under a day,
plus two pre-requisite fast-tracks (M-341 + M-342). The adversarial
persona alone also produced the 2 `major` findings (0.68 and 0.60
confidence) that became ACs 4–5 of the same v1.1.1 Scope.

The finding would have been invisible to a generalist reviewer. A
generalist collapses a review into the single most obvious concern —
on M-323 that would have been architectural fit or scope completeness,
neither of which was blocking. The dispatch-honesty blocker required
an adversarial angle: *"how does a consumer verify at runtime that the
panel actually ran as a panel?"* That question is structurally unlikely
to surface from a scope-guardian or architecture-strategist prompt.
Only a persona explicitly told to argue the Plan will fail was shaped
to reach for it.

## Why it matters for future work

1. **When scoping review, evaluation, or approval gates, don't default
   to a single-reviewer v1.** The marginal cost of a persona panel is
   small — five subagent files, one coordinator skill, one dedupe/sort
   pass, one lint for persona frontmatter. The marginal value is a
   measurable increase in blocking-severity catch rate for concerns
   that are structurally hard to surface from a generalist.

2. **A review gate that has never produced a blocking finding in N
   invocations is probably miscalibrated.** Not because every gate
   should block every time, but because a gate that *structurally
   cannot* block — because its reviewer has no persona tuned to the
   most load-bearing failure mode — is a rubber stamp. The
   adversarial-reviewer persona is the kind of persona a gate
   typically lacks by default; add it explicitly.

3. **Pair the panel with structured findings and explicit confidence.**
   Severity × confidence sort is what makes a 22-finding report
   actionable. Without that calibration the signal collapses back to
   "lots of reviewer opinions"; with it, the one blocking finding
   floats to the top.

4. **Direct application to `/spade-evaluate`.** Today it is single-agent
   against the acceptance criteria. The same persona-panel pattern
   would apply — a scope-guardian checking AC testability, a
   security-lens sanity-checking no security ACs were quietly dropped
   during delivery, an adversarial-reviewer asking "what would make
   the human sign off on something that doesn't actually meet the
   Scope?" Future Scope worth filing.

## Evidence

- M-323 panel review output (end of the v1.1 delivery session): 22
  findings, 0 dedupes, 1 blocking / 3 major / 18 minor-nit. The
  blocking came from adversarial-reviewer.
- M-343 Scope ([Linear](https://linear.app/m-kopa/issue/M-343)):
  acceptance criteria 1–5 all trace back to adversarial-reviewer
  findings. Provenance table in the Scope is verbatim from the panel
  review.
- `/spade-review` panel contract is documented in
  `.claude/skills/spade-review/SKILL.md`; persona files under
  `.claude/agents/spade-review-*.md`.
- Dispatch-mode banner + schema versioning (v1.1.1) make the
  "did the panel actually run as a panel?" question answerable — see
  `docs/FRAMEWORK.md#multi-persona-review`.
