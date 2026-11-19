---
id: L-quick-pr-bypasses-repo-pr-9h0N
title: Quick opens its PR without /repo:pr, and the operating rules omit /repo:pr from the repo-plugin table
project: spades-framework
type: bug
area: plugins/spades/skills/quick/SKILL.md:103-153 (§ 4 Publish, PR description); plugins/spades/AGENTS.md:336-341; plugins/spades/skills/setup/reference/agents-md-block.md:305-310
effort: small
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
Ship and Close pass their PR title and body through `/repo:pr` before `gh pr create` (skills/ship/scm-github.md:42-50; skills/close/SKILL.md:169). Quick § 4 opens its PR from its own body template with no `/repo:pr` step and no title rule (skills/quick/SKILL.md:105,118-153). The repo-plugin table in plugins/spades/AGENTS.md:336-341, and its consumer copy in skills/setup/reference/agents-md-block.md:305-310, lists /repo:init, /repo:newbranch, /repo:sync and /repo:branch but not /repo:pr, which (ai-skills repo 0.9.0) runs before every PR and writes the title that becomes the squash-merge subject.

## Why it matters
Quick PRs skip the title and body pass that Scope and bookkeeping PRs get, so their squash-merge subjects follow no rule, and agents reading the operating rules have no pointer to /repo:pr. The two PR-text paths can drift further apart.

## Suggested action
Add a /repo:pr row to the repo-plugin table in AGENTS.md and agents-md-block.md (bumping agents_version and setup), and route Quick's drafted title and template body through /repo:pr before `gh pr create`, keeping the template's required fields and gate checklist.

## Sightings
- 2026-11-19 — while research-2026-11-19-cr-article (/spades:research on Claude Code's code-review practice); context: research-2026-11-19-cr-article:G4; evidence: plugins/spades/AGENTS.md:336-341; plugins/spades/skills/setup/reference/agents-md-block.md:305-310; plugins/spades/skills/ship/scm-github.md:42-50; plugins/spades/skills/close/SKILL.md:169; plugins/spades/skills/quick/SKILL.md:105,118-153; repo plugin 0.9.0 skills/pr/SKILL.md description; branch: main; revision: a21fef5439b0e10e63634620a72160d4f6e6c02a.

## History
- 2026-11-19 — GitHub mirror create pending at its first step (authentication for the search-before-create in ChrisFmlyc/spades): `gh auth token --user ChrisFmlyc` timed out after 30 s on both attempts (exit 124) while api.github.com answered HTTP 200; no issue was searched or created; local capture is complete; complete with `/spades:leads --sync L-quick-pr-bypasses-repo-pr-9h0N`. worker-leads, Research completion handoff (research-2026-11-19-cr-article), executed in-worker.
