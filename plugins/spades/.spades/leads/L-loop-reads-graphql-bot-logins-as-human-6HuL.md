---
id: L-loop-reads-graphql-bot-logins-as-human-6HuL
title: Loop identifies review bots by a [bot] login suffix that GraphQL and gh pr view do not return
project: spades-framework
type: bug
area: plugins/spades/skills/loop/SKILL.md:353-356 (Stage 8 human-review query); plugins/spades/skills/loop/reference/finish-checks.md:28,32-33; plugins/spades/skills/loop/reference/bot-review.md:52,56-61
effort: small
confidence: high
status: closed
created: 2026-11-19
discovered_while: research-2026-11-19-cr-article
sightings: 1
promoted_to:
closed_reason: done — fixed on branch fix/loop-merge-gate-checks; thread sweeps classify authors by GraphQL author.__typename and Stage 8 classifies reviewers by REST user.type
github_issue:
linear_issue_id:
---

## What
Stage 8 counts human CHANGES_REQUESTED reviews with `select(.author.login | endswith("[bot]") | not)` on `gh pr view <n> --json reviews` (skills/loop/SKILL.md:353-356). The thread sweep sends "a `[bot]` author" to /codereview:loop (reference/finish-checks.md:32-33); bot-review.md:56-61 classifies by author with the same `author { login }` query. Both read GraphQL logins. Observed `gh` output in earlier local sessions returned the bare login `coderabbitai`, without `[bot]`, from `gh pr view <n> --json reviews` and from the `gh api graphql` reviewThreads query. Only the REST API returns `coderabbitai[bot]`.

## Why it matters
Bot reviews and threads are classed as human. A bot's latest CHANGES_REQUESTED review trips Pause 9 at Stage 8, and an unresolved bot thread pauses as a human thread (Pause 8) instead of returning to /codereview:loop. The result is a spurious pause, not an unsafe merge (inferred from the queries).

## Suggested action
Classify authors by GraphQL type: add `__typename` to `author { … }` in both thread queries and treat `Bot` as a bot; run the Stage 8 review check through `gh api graphql` with the same field.

## Sightings
- 2026-11-19 — while research-2026-11-19-cr-article (/spades:research on Claude Code's code-review practice); context: research-2026-11-19-cr-article:G5; evidence: plugins/spades/skills/loop/SKILL.md:353-356; reference/finish-checks.md:28,32-33; reference/bot-review.md:52,56-61; bare `coderabbitai` author logins in recorded output of `gh pr view <n> --json reviews` and `gh api graphql` reviewThreads from two earlier local sessions on other repositories (checked by worker-leads on 2026-11-19; a live PR #120 query timed out); branch: main; revision: a21fef5439b0e10e63634620a72160d4f6e6c02a.

## History
- 2026-11-19 — GitHub mirror create pending at its first step (authentication for the search-before-create in ChrisFmlyc/spades): `gh auth token --user ChrisFmlyc` timed out after 30 s on both attempts (exit 124) while api.github.com answered HTTP 200; no issue was searched or created; local capture is complete; complete with `/spades:leads --sync L-loop-reads-graphql-bot-logins-as-human-6HuL`. worker-leads, Research completion handoff (research-2026-11-19-cr-article), executed in-worker.
- 2026-11-19 — Closed as done by the fix on branch fix/loop-merge-gate-checks (plugin 6.8.3, loop 1.14.3): reference/bot-review.md § 3 and reference/finish-checks.md § Thread sweep query `author { __typename login }` and route `Bot` to /codereview:loop; Stage 8's human-review check reads `repos/{owner}/{repo}/pulls/<n>/reviews` and filters on `user.type`. Evidence: that branch's diff of those three files. No GitHub issue exists (the create is still pending), so the mirror needs a create then a close as completed: `/spades:leads --sync L-loop-reads-graphql-bot-logins-as-human-6HuL` once gh authenticates (`gh auth token --user ChrisFmlyc` timed out again on 2026-11-19). Coordinator of the Stage 8 fix, executed in-worker.
