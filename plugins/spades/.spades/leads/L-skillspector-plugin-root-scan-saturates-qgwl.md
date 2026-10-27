---
id: L-skillspector-plugin-root-scan-saturates-qgwl
title: A whole-plugin skillspector scan saturates at CRITICAL from non-skill files
project: spades-framework
type: maintenance
area: plugins/spades/ (skillspector scan of the plugin root; CHANGELOG.md, .spades/, docs/, agents/)
effort: small
confidence: high
status: open
created: 2026-10-27
discovered_while: P-narrow-skill-triggers-and-newproject-disclosure-8XWy
sightings: 1
promoted_to:
closed_reason:
github_issue: https://github.com/ChrisFmlyc/spades/issues/119
linear_issue_id:
---

## What
`skillspector scan ./plugins/spades/` treats the plugin root, which has no SKILL.md, as one skill ("Skill: unknown"). It scans CHANGELOG.md (45 findings), the .spades/ dogfood records (14), docs/, root project documents and agents/. The score saturates at 100/CRITICAL and the CLI exits 1. 74 of 98 findings were marked `disagreed` by skillspector's own LLM review but still count. Scans of `plugins/spades/skills/<name>/` are clean or near-clean.

## Why it matters
Each whole-plugin scan reports maximum risk whatever the skills contain, so new genuine skill findings are hard to see and the exit code cannot gate anything.

## Suggested action
Settle on a scan procedure: per-skill scans of plugins/spades/skills/*/, or a baseline or exclusion for non-skill paths. Document it, then decide whether to add a CI job. This Scope deferred that work.

## Sightings
- 2026-10-27 — while P-narrow-skill-triggers-and-newproject-disclosure-8XWy; context: eval:8XWy:skillspector-plugin-root-noise; evidence: evaluation re-scan `skillspector scan ./plugins/spades/` (Skill: unknown, 98 findings, 74 disagreed, risk 100/CRITICAL, exit 1) compared with per-skill scans of plugins/spades/skills/<name>/; Scope S-narrow-skill-triggers-and-disclose-newproject-actions § Out of Scope; branch: fix/narrow-skill-triggers-newproject-disclosure; revision: 1b3716eba9629ffc8d7ed4a7f1df892697c63095.

## History
- 2026-10-27 — GitHub mirror created: issue #119 (https://github.com/ChrisFmlyc/spades/issues/119), labels spades:lead + maintenance (label maintenance created in the repo); result verified by read-back of title, OPEN state, labels and body; worker-leads, dispatch mode degraded (caller asked for no further delegation).
