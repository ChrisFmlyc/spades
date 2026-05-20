---
name: bad-enum-scope
title: A Scope with an out-of-vocabulary status value
id: sp-0xx0xx
status: shipped
type: feature
phase: scope
created: 2026-05-18
updated: 2026-05-18
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
---

# Scope: bad-enum fixture

This fixture carries every core field but sets `status: shipped` —
**not** a value in the canonical `status` enum (§ Local Layout:
scoped | planning | approval | delivering | evaluating | done).

The schema lint MUST hard-fail this file. `lint-local-frontmatter.sh`
exercises it on every run as a self-test, so the enum-enforcement logic
cannot rot silently.
