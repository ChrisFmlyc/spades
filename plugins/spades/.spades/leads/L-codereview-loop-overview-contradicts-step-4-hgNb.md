---
id: L-codereview-loop-overview-contradicts-step-4-hgNb
title: codereview:loop's overview says to pass the review's prompt block alone, contradicting step 4's build-the-list rule
project: spades-framework
type: bug
area: ChrisFmlyc/ai-skills plugins/codereview/skills/loop/SKILL.md:19 vs :129-141 (external dependency, codereview 1.2.1 / loop 0.7.1; invoked by plugins/spades/skills/loop/SKILL.md:333, Stage 7 bot review)
effort: trivial
confidence: high
status: closed
created: 2026-11-19
discovered_while: research-2026-11-19-cr-article
sightings: 1
promoted_to:
closed_reason: done — fixed upstream in ai-skills PR #29 (f8e43b4, codereview 1.3.1); the loop overview now says the open threads are the findings and the loop builds the block itself
github_issue:
linear_issue_id:
---

## What
The overview's step 4 in codereview:loop (SKILL.md:19) says to collect the "Prompt for all review comments with AI agents" block from the latest review: "That block is what you pass on — you do not assemble a list yourself." Section 4 (:129-141) says the open threads are the source of truth, calls the block "routinely incomplete", and says "So build the block yourself" from every open thread.

## Why it matters
An agent that follows the overview passes the block alone, which § 4 says fixes one finding per cycle until the cycle cap. /spades:loop Stage 7 relies on /codereview:loop for every ship and bookkeeping PR (plugins/spades/skills/loop/reference/bot-review.md § 1).

## Suggested action
Fix upstream in ChrisFmlyc/ai-skills: reword the overview's step 4 to match § 4 (start from the open threads, enrich each from the review block). Close this Lead once a released codereview version carries the fix.

## Sightings
- 2026-11-19 — while research-2026-11-19-cr-article (/spades:research on Claude Code's code-review practice); context: research-2026-11-19-cr-article:G7; evidence: installed codereview 1.2.1 skills/loop/SKILL.md:19 and :129-141; plugins/spades/skills/loop/SKILL.md:333; plugins/spades/skills/loop/reference/bot-review.md:7-8,21; branch: main; revision: a21fef5439b0e10e63634620a72160d4f6e6c02a.

## History
- 2026-11-19 — GitHub mirror create pending at its first step (authentication for the search-before-create in ChrisFmlyc/spades): `gh auth token --user ChrisFmlyc` timed out after 30 s on both attempts (exit 124) while api.github.com answered HTTP 200; no issue was searched or created; local capture is complete; complete with `/spades:leads --sync L-codereview-loop-overview-contradicts-step-4-hgNb`. worker-leads, Research completion handoff (research-2026-11-19-cr-article), executed in-worker.
- 2026-11-19 — Closed as done by ai-skills PR #29 (merge f8e43b4, codereview 1.3.1): the loop overview step 4 now matches section 4. Takes effect once the installed codereview plugin is updated. No GitHub issue exists yet (create pending), so the mirror needs a create then a close: `/spades:leads --sync L-codereview-loop-overview-contradicts-step-4-hgNb`. Coordinator of PR #124, executed in-session.
