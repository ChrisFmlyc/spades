---
name: list
description: List active SPADES Scopes, optionally filtered by phase or project. Use when someone says "show my scopes", "list scopes", "what's active", "what needs planning", or wants to see what work is in progress across the SPADES pipeline. Accepts a `--project <slug>` filter; defaults to the active project from `.spades/config`.
version: 2.0.0
---

# /spades:list

You are showing the human their active SPADES work.

Read `docs/FRAMEWORK.md` § Hierarchy and § .spades/ Local Layout before
running.

## Pre-Flight

1. **Read `.spades/config`.** Note the `backend:` and the active
   `project:`.
2. **Apply `--project <slug>` if given.** Otherwise filter to the
   active project.
3. **Determine the filter.** Default is "active phases only"
   (`scoped`, `planning`, `approval`, `delivering`, `evaluating`,
   `shipping`). Accepted overrides:
   - `/spades:list scoped` — only scoped
   - `/spades:list delivering` — only delivering
   - `/spades:list all` — include `done` and `rejected`

## Step 1 — Fetch

### When `backend: local`

1. Glob `.spades/scopes/*.md`.
2. For each, parse the frontmatter. Skip any whose `project:` doesn't
   match the active project filter.
3. Read `status:`, `title:`, `priority:`, `type:`.
4. For each Scope, also glob `.spades/plans/P-<scope-slug>-*.md` to
   count plans and how many are `approved`/`delivering`/`shipped`.

### When `backend: linear`

1. Query the active Linear Project for parent issues.
2. Filter by status to match the chosen phase set.
3. For each parent, fetch its sub-issues to count plan progress.

## Step 2 — Render the Table

Group by SPADES phase. One row per Scope.

```
## Active Scopes — Project: closed-door-security-website

### Scoped (ready for planning)

| Scope | Title | Priority | Type |
|-------|-------|----------|------|
| S-add-ai-helper-bot | Add AI Helper Bot | high | feature |
| S-fix-broken-form | Fix Broken Contact Form | urgent | bug |

### Planning

| Scope | Title | Plans drafted |
|-------|-------|---------------|
| S-rework-landing-page | Rework Landing Page | 2 |

### Delivering

| Scope | Title | Plans (done / total) |
|-------|-------|----------------------|
| S-add-newsletter | Add Newsletter Signup | 2/4 |

### Evaluating

(none)

### Shipping

(none)
```

## Step 3 — Quality Flags

For Scopes in `scoped` status, do a quick body check — does the Scope
have all required sections (Intent, Acceptance Criteria, Constraints,
Dependencies, Out of Scope, Risk)? Flag missing fields:

```
⚠ S-add-ai-helper-bot is missing: Out of Scope, Risk
  Run /spades:scope S-add-ai-helper-bot to fill the gaps
```

For Plans:

- Plans in `delivering` status whose dependencies aren't yet `shipped`
  get a `⚠ blocked` flag.
- Plans with `delivery: undecided` (approved but no routing recorded)
  get a `⚠ routing not set` flag — recommend re-running
  `/spades:approve`.

## Step 4 — Empty State

If no Scopes match:

```
No active SPADES Scopes for project "<slug>".

  /spades:scope <title>    — create your first Scope
  /spades:list all         — include Done/rejected Scopes
  /spades:list --project <other-slug>  — try a different project
```

## Step 5 — Follow-up Suggestions

After the table, suggest next actions:

- Scopes in Scoped → `Run /spades:plan S-… to draft a plan`
- Scopes in Planning → `Run /spades:approve P-… when the plan is ready`
- Scopes in Delivering → `Run /spades:do P-… on the next plan`
- Scopes in Evaluating → `Run /spades:evaluate P-… to verify`
- Scopes in Shipping → `Run /spades:ship P-… to release`

Keep this section brief — one line per actionable suggestion.
