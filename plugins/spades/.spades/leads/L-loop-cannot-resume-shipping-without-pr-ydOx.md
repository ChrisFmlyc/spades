---
id: L-loop-cannot-resume-shipping-without-pr-ydOx
title: Loop and Ship have no resume path for a Plan left at shipping when its PR failed to open
project: spades-framework
type: bug
area: plugins/spades/skills/loop/SKILL.md:169-184 (Loop state table); plugins/spades/skills/ship/SKILL.md:42-44,67,83; plugins/spades/skills/ship/scm-github.md:79-81
effort: small
confidence: high
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
Ship sets `status: shipping` (skills/ship/SKILL.md:83) before its GitHub driver pushes and opens the PR, and a failed open leaves the Plan at `shipping` with no `PR opened:` line (skills/ship/scm-github.md:79-81). The loop's state table (skills/loop/SKILL.md:169-184) has no row for that state: every `shipping` row needs `PR opened:`, a clean review or a merged PR. Re-running `/spades:ship` does not recover it, because prerequisite 6 (skills/ship/SKILL.md:42-44) aborts on any status other than `evaluating`, so Step 1's "no `PR opened:` line → fresh run" (:67) cannot be reached from `shipping`.

## Why it matters
A transient push or `gh` failure at Stage 6 strands the Plan. Resume derives no stage and falls back to asking the human (skills/loop/SKILL.md:536), and Ship's own gate refuses the re-run. This follows from the text; it has not been observed in a run.

## Suggested action
Add a loop state row for `shipping` with no `PR opened:` line that resumes Stage 6, and let Ship's prerequisite 6 accept that state as a resumed shipment that re-runs the driver from the push.

## Sightings
- 2026-11-19 — while research-2026-11-19-cr-article (/spades:research on Claude Code's code-review practice); context: research-2026-11-19-cr-article:G2; evidence: plugins/spades/skills/loop/SKILL.md:169-184,536; plugins/spades/skills/ship/SKILL.md:42-44,67,83; plugins/spades/skills/ship/scm-github.md:79-81; branch: main; revision: a21fef5439b0e10e63634620a72160d4f6e6c02a.

## History
- 2026-11-19 — GitHub mirror create pending at its first step (authentication for the search-before-create in ChrisFmlyc/spades): `gh auth token --user ChrisFmlyc` timed out after 30 s on both attempts (exit 124) while api.github.com answered HTTP 200; no issue was searched or created; local capture is complete; complete with `/spades:leads --sync L-loop-cannot-resume-shipping-without-pr-ydOx`. worker-leads, Research completion handoff (research-2026-11-19-cr-article), executed in-worker.
