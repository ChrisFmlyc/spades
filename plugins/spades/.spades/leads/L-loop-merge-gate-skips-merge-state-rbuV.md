---
id: L-loop-merge-gate-skips-merge-state-rbuV
title: Loop Stage 8 fetches mergeStateStatus but never asserts it, so a PR behind its base can merge on stale checks
project: spades-framework
type: bug
area: plugins/spades/skills/loop/SKILL.md:342-364 (Stage 8 pre-merge assertions)
effort: small
confidence: medium
status: closed
created: 2026-11-19
discovered_while: research-2026-11-19-cr-article
sightings: 1
promoted_to:
closed_reason: done — fixed on branch fix/loop-merge-gate-checks; loop Stage 8 step 1 forward-merges a moved base and step 3 asserts mergeStateStatus, pausing on BLOCKED, DIRTY and DRAFT
github_issue:
linear_issue_id:
---

## What
Stage 8 runs `gh pr view <n> --json state,mergeable,mergeStateStatus,statusCheckRollup` (skills/loop/SKILL.md:342), but none of the assertions at :345-362 reads `mergeStateStatus`, and no other file in plugins/spades uses it. A `BEHIND` PR (head out of date with its base) passes every pre-merge check; a `BLOCKED` one is caught only when `gh pr merge` fails (:364).

## Why it matters
Where branch protection does not require up-to-date branches, the loop can squash-merge a PR whose CI ran against an older base. docs/FRAMEWORK.md § Freshness (:1289-1291) says a PR that needs integration with its updated base gets a deliberate branch update and rerun checks. The impact depends on each repo's protection settings (inferred, not observed).

## Suggested action
Assert `mergeStateStatus` in Stage 8 under Pause 9: `CLEAN` or `HAS_HOOKS` proceeds; `BEHIND` takes a forward-only update of the PR branch from its base (no rebase, per § Boundaries) and reruns checks, or pauses; `BLOCKED`, `DIRTY` and `DRAFT` pause naming the state; `UNKNOWN` re-polls.

## Sightings
- 2026-11-19 — while research-2026-11-19-cr-article (/spades:research on Claude Code's code-review practice); context: research-2026-11-19-cr-article:G1; evidence: plugins/spades/skills/loop/SKILL.md:342 (field fetched) against :345-362 (assertions) and :364 (merge-failure pause); docs/FRAMEWORK.md:1289-1291; grep of plugins/spades finds no other mergeStateStatus use; branch: main; revision: a21fef5439b0e10e63634620a72160d4f6e6c02a.

## History
- 2026-11-19 — GitHub mirror create pending at its first step (authentication for the search-before-create in ChrisFmlyc/spades): `gh auth token --user ChrisFmlyc` timed out after 30 s on both attempts (exit 124) while api.github.com answered HTTP 200; no issue was searched or created; local capture is complete; complete with `/spades:leads --sync L-loop-merge-gate-skips-merge-state-rbuV`. worker-leads, Research completion handoff (research-2026-11-19-cr-article), executed in-worker.
- 2026-11-19 — Closed as done by the fix on branch fix/loop-merge-gate-checks (plugin 6.8.3, loop 1.14.3): skills/loop/SKILL.md Stage 8 step 1 checks that the PR head contains the current base and forward-merges it, and step 3 asserts every mergeStateStatus value. Evidence: that branch's diff of skills/loop/SKILL.md § Stage 8. No GitHub issue exists (the create is still pending), so the mirror needs a create then a close as completed: `/spades:leads --sync L-loop-merge-gate-skips-merge-state-rbuV` once gh authenticates (`gh auth token --user ChrisFmlyc` timed out again on 2026-11-19). Coordinator of the Stage 8 fix, executed in-worker.
