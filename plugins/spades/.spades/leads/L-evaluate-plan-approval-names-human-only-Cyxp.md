---
id: L-evaluate-plan-approval-names-human-only-Cyxp
title: Evaluate's verification-plan approval line hardcodes "by human" instead of naming the approver
project: spades-framework
type: enhancement
area: plugins/spades/skills/evaluate/SKILL.md:203
effort: trivial
confidence: medium
status: open
created: 2026-11-19
discovered_while: research-2026-11-19-cr-article
sightings: 1
promoted_to:
closed_reason:
github_issue:
linear_issue_id:
---

## What
Evaluate Step 4 writes `- YYYY-MM-DD: Verification plan APPROVED by human.` (skills/evaluate/SKILL.md:203). Under `/spades:loop` the AI approves and records its answers as `AI (/spades:loop)` (skills/loop/SKILL.md:68-69; docs/FRAMEWORK.md:640-643). Loop runs have rewritten the literal correctly (.spades/plans/P-narrow-skill-triggers-and-newproject-disclosure-8XWy.md:136; P-projectlead-assignment-hX8p.md:90). Approve's audit line already uses an approver slot (`Approved by <human>`, skills/approve/SKILL.md:114).

## Why it matters
Correct attribution depends on the loop overriding literal template text. An agent that copies the line verbatim would record an AI approval as a human's in the audit trail. No misattributed record has been observed.

## Suggested action
Replace the literal with an approver slot, for example `Verification plan APPROVED by <approver>.`, consistent with approve's `<human>` slot.

## Sightings
- 2026-11-19 — while research-2026-11-19-cr-article (/spades:research on Claude Code's code-review practice); context: research-2026-11-19-cr-article:G3; evidence: plugins/spades/skills/evaluate/SKILL.md:203; plugins/spades/skills/loop/SKILL.md:68-69; docs/FRAMEWORK.md:640-643; skills/approve/SKILL.md:114; .spades/plans/P-narrow-skill-triggers-and-newproject-disclosure-8XWy.md:136; branch: main; revision: a21fef5439b0e10e63634620a72160d4f6e6c02a.

## History
- 2026-11-19 — GitHub mirror create pending at its first step (authentication for the search-before-create in ChrisFmlyc/spades): `gh auth token --user ChrisFmlyc` timed out after 30 s on both attempts (exit 124) while api.github.com answered HTTP 200; no issue was searched or created; local capture is complete; complete with `/spades:leads --sync L-evaluate-plan-approval-names-human-only-Cyxp`. worker-leads, Research completion handoff (research-2026-11-19-cr-article), executed in-worker.
