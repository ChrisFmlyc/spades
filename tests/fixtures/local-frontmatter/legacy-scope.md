---
name: legacy-scope
title: A pre-v1.8 Scope with no stable id field
status: scoped
type: feature
phase: scope
created: 2026-04-21
updated: 2026-04-21
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
linear_issue: M-000
---

# Scope: legacy fixture

This fixture stands in for a Scope file authored before the v1.8 `id`
field existed. It carries every **core required** field and only valid
enum values, but it deliberately has **no `id`**.

The schema lint MUST pass this file: a missing `id` is grandfathered
(§ Local Layout) and surfaces only as a warning, never a hard failure.
`lint-local-frontmatter.sh` exercises this fixture on every run as a
self-test so the grandfathering rule cannot rot silently.
