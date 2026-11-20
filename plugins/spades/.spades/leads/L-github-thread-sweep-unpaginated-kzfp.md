---
id: L-github-thread-sweep-unpaginated-kzfp
title: GitHub review-thread sweeps read only the first 100 threads and the first 10 comments of each
project: spades-framework
type: bug
area: plugins/spades/skills/loop/reference/finish-checks.md:42,44 (§ Thread sweep, GitHub); ChrisFmlyc/ai-skills plugins/codereview/skills/loop/SKILL.md:92-93 (external dependency, codereview 1.3.1; invoked by loop Stage 7)
effort: small
confidence: high
status: open
created: 2026-11-20
discovered_while: research-gitlab-2026-11-20
sightings: 1
promoted_to:
closed_reason:
github_issue: https://github.com/ChrisFmlyc/spades/issues/126
linear_issue_id:
---

## What
The GitHub thread sweep queries `reviewThreads(first: 100)` and `comments(first: 10)` with no `pageInfo` or cursor (skills/loop/reference/finish-checks.md:42,44 on this branch; finish-checks.md:26,28 and reference/bot-review.md:50,52 on origin/main 93c70bd). `/codereview:loop` runs the same unpaginated query (codereview 1.3.1 skills/loop/SKILL.md:92-93). The GitLab sweep reads every page with `glab api --paginate` (finish-checks.md:63).

## Why it matters
Stage 7's final sweep, Stage 8's pre-merge check and FINISHED assertion 2 rely on this query, so a PR with more than 100 review threads could pass "zero unresolved threads" with unresolved threads unread, and replies after a thread's tenth comment are never seen. PRs that large are uncommon; not observed.

## Suggested action
Page through `reviewThreads` (and a thread's comments past 10) with `pageInfo { hasNextPage endCursor }` and `gh api graphql --paginate`, in SPADES' sweep and upstream in ChrisFmlyc/ai-skills' /codereview:loop.

## Sightings
- 2026-11-20 — while research-gitlab-2026-11-20 (/spades:research on GitLab SCM driver parity, standalone); context: research-gitlab-2026-11-20/github-thread-sweep-pagination; evidence: plugins/spades/skills/loop/reference/finish-checks.md:42,44 (GitHub) against :63 (GitLab `--paginate`); origin/main 93c70bd finish-checks.md:26,28 and bot-review.md:50,52; installed codereview 1.3.1 skills/loop/SKILL.md:92-93; branch: feat/gitlab-scm-driver; revision: fe327fcac0b4b2fa32e5e29187a327750b26acf7 plus uncommitted edits.

## History
- 2026-11-20 — GitHub mirror created: issue #126 (https://github.com/ChrisFmlyc/spades/issues/126), labels spades:lead + bug (both already in the repo); result verified by read-back of title, OPEN state, labels and body (Lead ID and context key present); find_issue and keyword searches found no earlier issue; worker-leads, Research completion handoff (research-gitlab-2026-11-20), dispatch mode degraded (mirror operations run in-worker).
