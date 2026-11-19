---
id: L-codereview-loop-waits-on-one-review-bot-nV0T
title: codereview:loop waits for one bot's review, so a PR with two review bots can proceed before both finish
project: spades-framework
type: bug
area: ChrisFmlyc/ai-skills plugins/codereview/skills/loop/SKILL.md:50-66 (external dependency, codereview 1.2.1 / loop 0.7.1; relied on by plugins/spades/skills/loop/reference/bot-review.md:7-8, Stage 7 bot review)
effort: small
confidence: medium
status: closed
created: 2026-11-19
discovered_while: research-2026-11-19-cr-article
sightings: 1
promoted_to:
closed_reason: "done — fixed upstream in ai-skills PR #29 (f8e43b4, codereview 1.3.1); step 1 waits for every bot that has reviewed the PR, matched by user.type and commit_id, with one 30-minute deadline per commit"
github_issue:
linear_issue_id:
---

## What
Step 1 of codereview:loop (SKILL.md:52-66) compares HEAD's commit time with the latest review from one login, `coderabbitai[bot]` (:57-58), and says to swap in "whichever agent reviews this PR" (:61). With two review bots on a PR, the wait tracks only one. SPADES states that /codereview:loop "handles every review bot" (plugins/spades/skills/loop/reference/bot-review.md:7-8).

## Why it matters
When the tracked bot finishes first, the cycle collects findings before the other bot has posted. Those findings surface only through SPADES' final sweep or Stage 8, at the cost of extra cycles. This is inferred from the text; no two-bot PR has been observed.

## Suggested action
Fix upstream in ChrisFmlyc/ai-skills: before step 2, wait until the latest review from every review bot present on the PR (or a configured list) postdates HEAD.

## Sightings
- 2026-11-19 — while research-2026-11-19-cr-article (/spades:research on Claude Code's code-review practice); context: research-2026-11-19-cr-article:G8; evidence: installed codereview 1.2.1 skills/loop/SKILL.md:52-66 (login filter :57-58, swap note :61); plugins/spades/skills/loop/reference/bot-review.md:7-8; branch: main; revision: a21fef5439b0e10e63634620a72160d4f6e6c02a.

## History
- 2026-11-19 — GitHub mirror create pending at its first step (authentication for the search-before-create in ChrisFmlyc/spades): `gh auth token --user ChrisFmlyc` timed out after 30 s on both attempts (exit 124) while api.github.com answered HTTP 200; no issue was searched or created; local capture is complete; complete with `/spades:leads --sync L-codereview-loop-waits-on-one-review-bot-nV0T`. worker-leads, Research completion handoff (research-2026-11-19-cr-article), executed in-worker.
- 2026-11-19 — Closed as done by ai-skills PR #29 (merge f8e43b4, codereview 1.3.1): step 1 waits for every review bot by account type and reviewed commit, with one deadline per commit. Takes effect once the installed codereview plugin is updated. No GitHub issue exists yet (create pending), so the mirror needs a create then a close: `/spades:leads --sync L-codereview-loop-waits-on-one-review-bot-nV0T`. Coordinator of PR #124, executed in-session.
