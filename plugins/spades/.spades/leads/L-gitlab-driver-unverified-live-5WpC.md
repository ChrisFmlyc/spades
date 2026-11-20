---
id: L-gitlab-driver-unverified-live-5WpC
title: GitLab bot-review signals, reviewer states and closes_issues are verified against GitLab docs only, not a live instance
project: spades-framework
type: testing
area: ChrisFmlyc/ai-skills plugins/codereview/skills/loop/reference/gitlab-bots.md:57-58,103 (branch feat/codereview-gitlab-merge-requests, external dependency); plugins/spades/skills/loop/reference/finish-checks.md:111-112,328-329; plugins/spades/tests/fixtures/scm/
effort: medium
confidence: medium
status: open
created: 2026-11-20
discovered_while: research-gitlab-2026-11-20
sightings: 1
promoted_to:
closed_reason:
github_issue: https://github.com/ChrisFmlyc/spades/issues/128
linear_issue_id:
---

## What
The research checked these GitLab behaviours against documentation only: which notes and commit statuses CodeRabbit and Greptile post on an MR, and so the completion and clean-review signals in codereview's gitlab-bots.md:57-58 and the target of Greptile's reactions (:103); the REST reviewer `state` values the merge-readiness probe filters on (skills/loop/reference/finish-checks.md:111-112); and whether `merge_requests/<iid>/closes_issues` still lists issues after the MR merges (FINISHED probe, finish-checks.md:328-329). The offline snippet tests replay fixture JSON (tests/fixtures/scm/) and share those assumptions.

## Why it matters
If a bot's signal or an API response differs from the docs, the GitLab loop can wait out its 15-minute fallbacks, misread a finished review, or pass FINISHED's linked-issue check on an empty list. The offline tests would not catch it.

## Suggested action
In a sandbox GitLab project the human names (no live test before then), run one MR through CodeRabbit and Greptile, capture the notes, statuses, reviewers and closes_issues responses as fixtures under tests/fixtures/scm/, and correct any adapter or probe that disagrees.

## Sightings
- 2026-11-20 — while research-gitlab-2026-11-20 (/spades:research on GitLab SCM driver parity, standalone); context: research-gitlab-2026-11-20/gitlab-live-verification; evidence: research report's docs-only verification notes; ai-skills feat/codereview-gitlab-merge-requests plugins/codereview/skills/loop/reference/gitlab-bots.md:57-58,103 (untracked working tree); plugins/spades/skills/loop/reference/finish-checks.md:111-112,328-329; plugins/spades/scripts/test/scm-snippets.sh with tests/fixtures/scm/; branch: feat/gitlab-scm-driver; revision: fe327fcac0b4b2fa32e5e29187a327750b26acf7 plus uncommitted edits.

## History
- 2026-11-20 — GitHub mirror created: issue #128 (https://github.com/ChrisFmlyc/spades/issues/128), labels spades:lead + testing (both already in the repo); result verified by read-back of title, OPEN state, labels and body (Lead ID and context key present); find_issue and keyword searches found no earlier issue; worker-leads, Research completion handoff (research-gitlab-2026-11-20), dispatch mode degraded (mirror operations run in-worker).
