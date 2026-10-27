---
title: Skill trigger phrases name a SPADES noun, or the skill loads for unrelated requests
area: plan
tags: [description, triggers, trigger-phrases, skillspector]
created: 2026-10-27
status: active
public_safe: true
scope_ref: S-narrow-skill-triggers-and-disclose-newproject-actions
plan_ref: P-narrow-skill-triggers-and-newproject-disclosure-8XWy
---

## What we learned

A harness decides whether to load a skill from its `description:` alone, so
each trigger phrase is matched against every request, not only SPADES work.
Bare verbs such as "review this", "evaluate this", "approve this", "new
project" and "where are we", or a catch-all like "any question about current
state", match ordinary requests such as a code review or scaffolding an
unrelated app, and skillspector confirms them as SQP-1. Tying each phrase to a
Scope, a Plan, a `P-…` ID or a SPADES Project ("review this Scope", "evaluate
P-…", "new SPADES project") cleared SQP-1 on all five affected skills in
per-skill re-scans. The README skill table repeats the triggers under "Use
when you say", and CodeRabbit caught one row left generic in #120.

## Why it matters for future work

A Plan that adds a skill or edits a description writes every trigger phrase
with a SPADES noun in it and updates the matching README row in the same task.
A deliberately broad trigger, such as scope's "add X" / "we need a Y" that
routes work requests into a Scope, is a routing decision; the Plan says so
rather than leaving it to read as an oversight. Check changed skills one
directory at a time (`skillspector scan plugins/spades/skills/<name>/`); a
whole-plugin scan saturates (L-skillspector-plugin-root-scan-saturates-qgwl).

## Audit Trail

- 2026-10-27: Captured by AI (/spades:loop) at Stage 10 of P-narrow-skill-triggers-and-newproject-disclosure-8XWy; public-safe. Leads handoff receipt (worker-leads, revision 1c4c27e): learn:8XWy:skill-trigger-phrases and learn:8XWy:bot-review-round on-scope; learn:8XWy:subagent-worktree-base captured as L-codereview-fix-worktrees-miss-pr-branch-cJlw (GitHub #121 verified).
