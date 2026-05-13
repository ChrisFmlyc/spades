---
name: minimal-scope
title: Minimal-scope rendering fixture
status: scoped
type: feature
phase: scope
created: 2026-05-13
updated: 2026-05-13
linear_issue: M-000
linear_url: https://linear.app/example/issue/M-000
---

# Minimal Scope

Smoke fixture for the SPADE renderer. Exercises the status header
(status pill, type pill, dates, Linear link, title), the TOC, and a
mix of body elements.

## Acceptance Criteria

- [ ] Status pill renders the `scoped` colour.
- [ ] Linear link is clickable to `M-000`.
- [ ] TOC contains every `##` heading.

## Code block

```bash
echo "hello, world"
```

## Table

| Item | Value |
|------|-------|
| One  | 1     |
| Two  | 2     |

## Quote

> Markdown renders pleasantly under spade-render.
