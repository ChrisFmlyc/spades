---
id: L-gitlab-path-prefix-unsupported-fR2Y
title: GitLab instances served under a URL path prefix are unsupported by the GitLab driver and /codereview:loop
project: spades-framework
type: feature
area: plugins/spades/docs/EXTENDING-SCM.md:202-203; plugins/spades/skills/setup/reference/gitlab.md:70-71; plugins/spades/docs/FRAMEWORK.md:771-776 (`<repo-url>` and `glab api` addressing); ChrisFmlyc/ai-skills plugins/codereview/skills/loop/SKILL.md:48 (branch feat/codereview-gitlab-merge-requests, external dependency)
effort: medium
confidence: medium
status: open
created: 2026-11-20
discovered_while: research-gitlab-2026-11-20
sightings: 1
promoted_to:
closed_reason:
github_issue: https://github.com/ChrisFmlyc/spades/issues/127
linear_issue_id:
---

## What
The GitLab driver builds `<repo-url>` as `https://<gitlab.host>/<gitlab.project>` and calls `glab api --hostname <host>` (docs/FRAMEWORK.md:771-776), so it needs GitLab at the root of its host. docs/EXTENDING-SCM.md:202-203 states that an instance under a path prefix (`https://host/gitlab/…`) is not supported, setup's project probe meets one as a 404 (skills/setup/reference/gitlab.md:70-71), and /codereview:loop's GitLab branch says the same (codereview loop SKILL.md:48). GitLab documents relative-URL installs as Beta (docs.gitlab.com/install/relative_url/); the research reports that glab reaches them through its `subfolder` setting (not checked locally: glab is not installed here).

## Why it matters
A self-managed team whose GitLab is served under a path prefix cannot use the GitLab driver or the GitLab bot-review loop; setup stops at the project probe. Such installs are a minority and Beta upstream.

## Suggested action
Record an optional path prefix in setup's `gitlab:` block and derive `<repo-url>`, API addressing and the remote-URL check from it (through glab's `subfolder` setting if it holds up), with a matching change in /codereview:loop; or keep the limit and have setup recognise a prefixed remote and name it.

## Sightings
- 2026-11-20 — while research-gitlab-2026-11-20 (/spades:research on GitLab SCM driver parity, standalone); context: research-gitlab-2026-11-20/gitlab-path-prefix; evidence: plugins/spades/docs/EXTENDING-SCM.md:202-203; plugins/spades/skills/setup/reference/gitlab.md:70-71; plugins/spades/docs/FRAMEWORK.md:771-776; ai-skills feat/codereview-gitlab-merge-requests plugins/codereview/skills/loop/SKILL.md:48 (working tree); docs.gitlab.com/install/relative_url/; research report on glab's `subfolder` setting; branch: feat/gitlab-scm-driver; revision: fe327fcac0b4b2fa32e5e29187a327750b26acf7 plus uncommitted edits.

## History
- 2026-11-20 — GitHub mirror created: issue #127 (https://github.com/ChrisFmlyc/spades/issues/127), labels spades:lead + feature (label feature created in the repo); result verified by read-back of title, OPEN state, labels and body (Lead ID and context key present); find_issue and keyword searches found no earlier issue; worker-leads, Research completion handoff (research-gitlab-2026-11-20), dispatch mode degraded (mirror operations run in-worker).
