---
name: status
description: Show the current SPADES phase, progress, and dependency graph for active work. Use when someone asks "where are we", "what's the status", "show progress", or any question about current state. Renders the Plan dependency graph so the human can see which plans are unblocked vs waiting.
---

# /spades:status

You are giving the human a status overview of active SPADES work — at
the Scope level *and* at the Plan level, with dependency relationships
visible.

Read `docs/FRAMEWORK.md` § Hierarchy before running.

## Pre-Flight

1. **Read `.spades/config`.** Identify backend and active project.
2. **Apply `--project <slug>` if given.** Otherwise active project.

## Step 1 — Fetch

### When `backend: local`

1. Glob `.spades/scopes/*.md` for active scopes (not `done`,
   `rejected`). Filter by `project:` field.
2. For each Scope, glob `.spades/plans/P-<scope-slug>-*.md`. Parse
   each plan's frontmatter for `id_suffix`, `depends_on`, `status`,
   `title`, `delivery`, `deliverable_type`.

### When `backend: linear`

1. Query the active Linear Project for active parent issues + their
   sub-issues. Translate each Linear status to its SPADES phase.
2. For dependency information, fall back to the local `.spades/plans/`
   mirror (the `depends_on:` field; Linear doesn't natively express
   the SPADES dependency graph).

## Step 2 — Render the Per-Scope Detail

For each active Scope, render:

```
### S-add-ai-helper-bot — Add AI Helper Bot

Phase: Delivering (2/4 plans shipped)
Project: closed-door-security-website
Priority: high

Plans (dependency order):

  ✓ P-create-initial-mastra-bot-28sD    [shipped]   code   ai
  ✓ P-rag-pipeline-lookup-3HyD-28sD     [shipped]   code   ai
  ⏵ P-deploy-bot-9XaZ-3HyD-28sD         [delivering] code   ai
  ⊘ P-launch-announcement-7QkP-9XaZ     [draft]     artefact human
         └─ blocked: waiting for P-deploy-bot-9XaZ to ship
```

Symbols:
- `✓` shipped
- `⏵` in progress (delivering/evaluating/shipping)
- `▷` ready to start (approved, deps satisfied)
- `◐` partial (PARTIAL verdict from /spades:evaluate)
- `⊘` blocked (dependencies not shipped yet)
- `⌧` rejected

Columns after the ID: status, `deliverable_type`, `delivery` routing.

### Dependency graph

Resolve from the `depends_on:` field of each Plan. A Plan is blocked
if any plan in its `depends_on:` is not `shipped`. Show the blocked
edge inline (see example above).

If a Plan is approved, has all dependencies shipped, but hasn't been
started, mark it `▷ ready` — this is the next thing the human should
do.

## Step 3 — Summary Header

Above the per-Scope detail, render a one-line-per-Scope summary:

```
## SPADES Status — Project: closed-door-security-website

| Scope | Phase | Plans |
|-------|-------|-------|
| S-add-ai-helper-bot | Delivering | 2/4 shipped, 1 ready |
| S-rework-landing-page | Planning | 2 draft |
| S-add-newsletter | Scoped | — |

Fast-track items (no plans):

| Scope | Type | PR state |
|-------|------|----------|
| S-fix-broken-form-quick | bug | merged (awaiting Done) |
```

Quick items appear in their own subsection only when present. They
have no Plan records.

## Step 4 — Recommendations

Suggest the single most useful next action:

- A Plan in `▷ ready` state → `Run /spades:do P-… to start it`
- A Plan with PARTIAL verdict → `Run /spades:do P-… to apply fixes`
- A Plan in `evaluating` with PASS in audit trail → `Run /spades:ship P-…`
- A Scope with no plans → `Run /spades:plan S-… to draft the first plan`
- A Plan with `delivery: undecided` → `Re-run /spades:approve P-… (routing not set)`

Surface only the most impactful one or two suggestions. Don't list
every possible next step.

## Step 5 — Empty State

If no active work for the project:

```
No active SPADES work for project "<slug>".

  /spades:scope <title>    — start a new Scope
  /spades:list all         — see Done/rejected work
```

## Performance

This skill reads many files in `local` mode. For projects with 50+
scopes, render the summary table first and stream the per-Scope
detail. The human is usually scanning for one specific thing.
