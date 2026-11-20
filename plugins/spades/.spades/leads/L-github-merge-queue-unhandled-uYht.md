---
id: L-github-merge-queue-unhandled-uYht
title: GitHub merge_review expects an immediate squash-merge, so a branch that requires a merge queue leaves the loop paused on a queued PR
project: spades-framework
type: bug
area: plugins/spades/docs/FRAMEWORK.md:846,909 (§ SCM Drivers → merge_review, GitHub column); plugins/spades/skills/loop/SKILL.md:371-374 (Stage 8); plugins/spades/docs/EXTENDING-SCM.md:192
effort: medium
confidence: medium
status: open
created: 2026-11-20
discovered_while: research-gitlab-2026-11-20
sightings: 1
promoted_to:
closed_reason:
github_issue: https://github.com/ChrisFmlyc/spades/issues/125
linear_issue_id:
---

## What
On GitHub, `merge_review` is `gh pr merge <n> --squash` (docs/FRAMEWORK.md:846), and docs/FRAMEWORK.md:909 says it squash-merges immediately. On a base branch that requires a merge queue, `gh pr merge` adds the PR to the queue, or enables auto-merge while required checks are pending, and returns without merging (gh 2.100.0 `gh pr merge --help`). Loop Stage 8 then expects `review_state` to read `MERGED` (skills/loop/SKILL.md:371-374) and has no queued state or polling. The GitLab driver on this branch joins a merge train with auto-merge and polls (docs/FRAMEWORK.md:918-922).

## Why it matters
In a repository that uses a merge queue, a loop run would stop at Stage 8 after a successful queue entry and report it as a blocked merge, and the queue's own merge method, not `--squash`, decides how the PR lands. Inferred from gh's documented behaviour; not observed in a run.

## Suggested action
Detect a required merge queue on the base branch (branch rules or GraphQL), join the queue, poll `review_state` every 60–90 seconds as the GitLab merge-train path does, and pause with the reason if the PR leaves the queue unmerged. Update docs/FRAMEWORK.md § SCM Drivers, loop Stage 8 with reference/finish-checks.md, and docs/EXTENDING-SCM.md together.

## Sightings
- 2026-11-20 — while research-gitlab-2026-11-20 (/spades:research on GitLab SCM driver parity, standalone); context: research-gitlab-2026-11-20/github-merge-queue; evidence: plugins/spades/docs/FRAMEWORK.md:846,909,918-922; plugins/spades/skills/loop/SKILL.md:371-374; plugins/spades/docs/EXTENDING-SCM.md:192; `gh pr merge --help` (gh 2.100.0) on merge-queue branches; research part A on GitLab merge trains (docs.gitlab.com/ci/pipelines/merge_trains/); branch: feat/gitlab-scm-driver; revision: fe327fcac0b4b2fa32e5e29187a327750b26acf7 plus uncommitted edits.

## History
- 2026-11-20 — GitHub mirror created: issue #125 (https://github.com/ChrisFmlyc/spades/issues/125), labels spades:lead + bug (both already in the repo); result verified by read-back of title, OPEN state, labels and body (Lead ID and context key present); find_issue and keyword searches found no earlier issue; worker-leads, Research completion handoff (research-gitlab-2026-11-20), dispatch mode degraded (mirror operations run in-worker).
