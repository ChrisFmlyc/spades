---
name: list
description: List active SPADES Scopes, optionally filtered by phase or project. Use when someone says "show my scopes", "list scopes", "what's active", "what needs planning", or wants to see what work is in progress across the SPADES pipeline. Accepts a `--project <slug>` filter; defaults to the active project from `.spades-anywhere/config`.
version: 0.1.0
---

# /spades-anywhere:list

You are showing the human their active SPADES work.

Read `docs/FRAMEWORK.md` § Hierarchy and § .spades-anywhere/ Local Layout before
running.

### Output format

This skill honours `review_format:` from `.spades-anywhere/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. In CLI mode,
print the scope list table to the terminal. In HTML mode, render
the transient view via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/list/template.html` to
`.spades-anywhere/.tmp/list.html`, then auto-open via the OPEN_CMD prelude.
The filter logic, sort order, and visible columns are identical
between modes.

## Pre-Flight

1. **Read `.spades-anywhere/config`.** Note the `backend:` and the active
   `project:`.
2. **Apply `--project <slug>` if given.** Otherwise filter to the
   active project.
3. **Determine the filter.** Default is "active phases only"
   (`scoped`, `planning`, `approval`, `delivering`, `evaluating`,
   `shipping`). Accepted overrides:
   - `/spades-anywhere:list scoped` — only scoped
   - `/spades-anywhere:list delivering` — only delivering
   - `/spades-anywhere:list all` — include `done` and `rejected`

## Step 1 — Fetch

### When `backend: local`

1. Glob `.spades-anywhere/scopes/*.md`.
2. For each, parse the frontmatter. Skip any whose `project:` doesn't
   match the active project filter.
3. Read `status:`, `title:`, `priority:`, `type:`.
4. For each Scope, also glob `.spades-anywhere/plans/P-<scope-slug>-*.md` to
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
  Run /spades-anywhere:scope S-add-ai-helper-bot to fill the gaps
```

For Plans:

- Plans in `delivering` status whose dependencies aren't yet `shipped`
  get a `⚠ blocked` flag.
- Plans with `delivery: undecided` (approved but no routing recorded)
  get a `⚠ routing not set` flag — recommend re-running
  `/spades-anywhere:approve`.

## Step 4 — Empty State

If no Scopes match:

```
No active SPADES Scopes for project "<slug>".

  /spades-anywhere:scope <title>    — create your first Scope
  /spades-anywhere:list all         — include Done/rejected Scopes
  /spades-anywhere:list --project <other-slug>  — try a different project
```

## Step 5 — Follow-up Suggestions

After the table, suggest next actions:

- Scopes in Scoped → `Run /spades-anywhere:plan S-… to draft a plan`
- Scopes in Planning → `Run /spades-anywhere:approve P-… when the plan is ready`
- Scopes in Delivering → `Run /spades-anywhere:do P-… on the next plan`
- Scopes in Evaluating → `Run /spades-anywhere:evaluate P-… to verify`
- Scopes in Shipping → `Run /spades-anywhere:ship P-… to release`

Keep this section brief — one line per actionable suggestion.

## Step 6 — Output (branch on `review_format`)

**Read `review_format:` from `.spades-anywhere/config` and branch.**

### CLI mode (`review_format: cli`)

Print Steps 2–5 to the terminal as described above. Today's
behaviour.

### HTML mode (`review_format: html`)

1. Read the template at
   `${CLAUDE_PLUGIN_ROOT}/skills/list/template.html`.
2. Substitute placeholders per
   `docs/FRAMEWORK.md § Output Format`:
   - `{{spades.project}}`, `{{spades.filter}}`, generated_at.
   - `<!-- SPADES-BLOCK:rows -->` — one row per Scope from Step 2
     (with the Step 3 quality flags applied inline).
   - `<!-- SPADES-BLOCK:empty -->` — Step 4 output when no rows.
   - `<!-- SPADES-BLOCK:suggestions -->` — Step 5 output.
3. Write to `.spades-anywhere/.tmp/list.html` (creating `.spades-anywhere/.tmp/` if
   missing — already auto-gitignored by `/spades-anywhere:setup` Step 5.5).
4. Auto-open via the OPEN_CMD prelude
   (`docs/FRAMEWORK.md § OPEN_CMD detection prelude`). Print the
   file path with "open this in your browser" if `OPEN_CMD` is
   empty. Do NOT also print the table to the terminal in HTML mode.
