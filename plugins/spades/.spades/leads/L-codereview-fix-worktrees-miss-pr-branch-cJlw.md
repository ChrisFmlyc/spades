---
id: L-codereview-fix-worktrees-miss-pr-branch-cJlw
title: codereview:fix cuts per-finding worktrees from the default branch instead of the PR branch
project: spades-framework
type: bug
area: ChrisFmlyc/ai-skills plugins/codereview/skills/fix/SKILL.md:104,141 (external dependency; invoked by plugins/spades/skills/loop/SKILL.md:333, Stage 7 bot review)
effort: small
confidence: medium
status: open
created: 2026-10-27
discovered_while: P-narrow-skill-triggers-and-newproject-disclosure-8XWy
sightings: 1
promoted_to:
closed_reason:
github_issue: https://github.com/ChrisFmlyc/spades/issues/121
linear_issue_id:
---

## What
`/codereview:fix` (ai-skills codereview 1.2.1, plugins/codereview/skills/fix/SKILL.md:104,141) gives each finding a subagent with `isolation: "worktree"` and says subagent worktrees are cut from the repo you are standing in. Under Claude Code's default `worktree.baseRef` (`fresh`) those worktrees start from origin's default branch, which lacks an unmerged PR branch's commits. For PR #120 the per-finding worktrees were created by hand from the PR head under `.claude/worktrees/`, as in earlier loop runs (fix/review-101-*, -102-*, -103-*, -117-* branches).

## Why it matters
`/spades:loop` Stage 7 runs `/codereview:loop` on every ship PR, so each bot-review round depends on this manual step. A file the PR adds trips codereview:fix's `wrong-worktree` stop; a file the PR only modifies passes that check, and the fix is written against the default branch's copy (inferred, not observed).

## Suggested action
Fix upstream in ChrisFmlyc/ai-skills: cut each finding's worktree from the PR branch head (for example `git worktree add -b <name> .claude/worktrees/<name> HEAD`) or require `worktree.baseRef: head`, and correct the statement at SKILL.md:104. Close this Lead once a loop run's bot review works without the manual step.

## Sightings
- 2026-10-27 — while P-narrow-skill-triggers-and-newproject-disclosure-8XWy; context: learn:8XWy:subagent-worktree-base; evidence: PR #120 bot-review round, per-finding worktrees .claude/worktrees/review-120-f1..f4 cut by hand from PR head 29c8ee9 (not on origin/main); codereview:fix SKILL.md:104,141 at ai-skills 3f54271; Claude Code `worktree.baseRef` setting ("head" starts worktrees from the current HEAD); branch: fix/narrow-skill-triggers-newproject-disclosure; revision: 1c4c27e453dec0265dfda944ca98958aef381d17.

## History
- 2026-10-27 — GitHub mirror created: issue #121 (https://github.com/ChrisFmlyc/spades/issues/121), labels spades:lead + bug (both already in the repo); result verified by read-back of title, OPEN state, labels and body (Lead ID and context key present); worker-leads, Learn completion handoff, executed in-worker (caller asked for no further delegation).
