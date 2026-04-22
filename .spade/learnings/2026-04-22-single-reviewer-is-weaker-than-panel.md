---
title: For review and evaluation gates, a panel of persona-specific reviewers beats one generalist
area: review
tags: review, personas, panel, confidence, gating, spade-review, spade-evaluate
created: 2026-04-22
status: active
public_safe: true
scope_ref: M-323
---

## What we learned

The M-323 recon compared `/spade-review` (one generalist "fresh agent")
with compound-engineering's `/ce-code-review` (~50 persona agents,
structured JSON findings, confidence-gated merge). Two differences
mattered:

1. **Coverage.** A generalist asked to review a Plan tends to collapse
   the review into one dominant concern — usually whichever is most
   obvious — and under-explores the others. Persona agents (each pinned
   to one concern: scope completeness, architecture alignment, security,
   YAGNI, adversarial) each return their own findings; the merge pass
   gets a broader surface.
2. **Calibration.** Structured output
   (`{persona, severity, confidence, category, message}`) is cheap to
   produce and lets the human defer low-confidence findings without
   losing them. A generalist's prose review is all-or-nothing: the
   reviewer has to re-read everything to tell what's load-bearing.

Bundle E operationalises this for `/spade-review`: at least five
personas (scope-guardian, architecture-strategist, security-lens,
yagni-simplicity, adversarial-reviewer) spawned in parallel where the
runtime supports it, findings merged and deduped by
`(category, first 100 chars of message)`, sorted by severity × confidence.

## Why it matters for future work

Apply the same pattern whenever a skill is a **gate** rather than a
generator. Specifically:

- `/spade-evaluate` has the same shape — it's a review gate at the end
  of the loop. A future iteration should use the same persona + panel
  approach on acceptance criteria.
- Any future "second opinion" skill (e.g. a dedicated architecture
  reviewer before a major change) should reuse the persona contract
  established in `.claude/agents/spade-review-*.md` rather than
  spawning a new generalist.
- Personas live in `.claude/agents/`. Each is one file with YAML
  frontmatter declaring focus + output schema + prose priming. Adding
  a persona is a small, isolated change. Reshaping them all is not —
  avoid it.
- Do not add persona-specific slash-commands (no `/spade-security-review`
  etc.). One gate, one command. Personas are subagents, not commands —
  this prevents skill-count sprawl.

Two anti-patterns to watch out for:

1. **Panel without confidence.** If every finding has the same
   implicit confidence, the merge collapses back to a generalist
   review. The JSON schema is load-bearing.
2. **Personas that overlap.** scope-guardian and architecture-
   strategist should not both own "does this fit PATTERNS.md".
   Assign each concern to exactly one persona; overlap produces
   duplicated findings and dilutes the merge.

Related: `.claude/skills/spade-review/SKILL.md`,
`.claude/agents/spade-review-*.md` (Bundle E),
`docs/FRAMEWORK.md#multi-persona-review`.
