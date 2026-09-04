---
name: list
description: List active SPADES Scopes (and Objectives), optionally filtered by phase or project. Use when someone says "show my scopes", "list scopes", "list objectives", "what's active", "what needs planning", or wants to see what work is in progress across the SPADES pipeline. Accepts a `--project <slug>` filter; defaults to the active project from `.spades/config`.
version: 3.5.0
---

# /spades:list

You are showing the human their active SPADES work: Scopes grouped
by phase, with Plan progress, plus Quick items and Objectives in
their own subsections.

Read `docs/FRAMEWORK.md` § Hierarchy, § .spades/ Local Layout,
§ Freshness, § Drift detection, and § Output Format before running.

### Output format

This is a transient view. CLI mode prints it to the terminal. HTML
mode renders it from `${CLAUDE_PLUGIN_ROOT}/skills/list/template.html`
to `.spades/.tmp/list.html` via `worker-html-list`, auto-opens it,
and prints a one-line brief with the path.

## Pre-Flight

1. **Read `.spades/config`** — `backend:`, `project:`,
   `review_format:`.
2. **Apply `--project <slug>`** when given; otherwise the active
   project. An `abandoned` active Project aborts with *"Project
   `<slug>` is abandoned. Run `/spades:list --project <other>` or
   `/spades:list all`."*
3. **Determine the filter.** Default: active phases (`scoped`,
   `planning`, `delivering`, `evaluating`, `shipping`), excluding
   `abandoned` Scopes and their Plans. Overrides:
   - `/spades:list scoped`, `/spades:list delivering`, … — one phase
   - `/spades:list all` — adds `done`, `abandoned`, and for
     Objectives `complete` and `abandoned`
   - `/spades:list abandoned` — abandoned Scopes and Projects only

   Objectives default to `open`.

## Step 1 — Fetch

### `backend: local`

1. Glob `.spades/scopes/*.md`; keep those whose `project:` matches.
   Read `status`, `title`, `priority`, `type`.
2. For each Scope glob `.spades/plans/P-*.md` with `scope:` set to
   it; read `id_suffix`, `status`, `depends_on`. Classify each Plan:
   - **shipped** — `status: shipped`
   - **in progress** — `delivering`, `evaluating`, `shipping`
   - **ready** — `approved` and every `depends_on` sibling `shipped`
   - **blocked** — not `shipped` / `rejected`, and a `depends_on`
     sibling not `shipped`
   - **draft** — `draft` and not blocked
   - **rejected** — `rejected`

   Hold the per-Scope counts and the blocked list (each with what
   it waits on).
3. **Quick items** — glob `.spades/quick/Q-*.md` for the project;
   read `status`, `title`, `type`, `pr_url`, `delivery`.
4. **Objectives** — glob `.spades/objectives/O-*.md` for the
   project; read `status`, `title`, `strategy_link`; apply the
   Objective filter.

### `backend: linear`

1. Query the active Linear Project for parent Issues and their
   sub-issues, capturing each workflow state **type** (`backlog`,
   `unstarted`, `started`, `completed`, `canceled`) alongside the
   team-specific name.
2. Filter by the chosen phase set.
3. Read the local `.spades/scopes/` and `.spades/plans/` files for
   `depends_on:` and `status:` and classify Plans as above.
4. **Drift probe** — compare each local `status:` with Linear's
   state type per `docs/FRAMEWORK.md § Drift detection`; collect
   mismatches as `(artefact_id, local_status, linear_type,
   linear_name)`. Include each Objective's sister `O-` issue.
5. **Quick items and Objectives** from the local files, as above;
   the local file is canonical in both backends.
6. **Linear unreachable** → skip the probe, note
   `drift_probe_status: skipped`, and render the local view.

## Step 2 — The table

Group by phase, one row per Scope:

```
## Active Scopes — Project: closed-door-security-website

### Scoped (ready for planning)

| Scope | Title | Priority | Type |
|-------|-------|----------|------|
| S-add-ai-helper-bot | Add AI Helper Bot | high | feature |

### Planning

| Scope | Title | Plans drafted |
|-------|-------|---------------|
| S-rework-landing-page | Rework Landing Page | 2 |

### Delivering

| Scope | Title | Plans |
|-------|-------|-------|
| S-add-newsletter | Add Newsletter Signup | 2/4 shipped · 1 ready · 1 blocked |

### Evaluating

(none)

### Shipping

(none)

### Quick items

| ID | Title | Type | Delivery | PR |
|----|-------|------|----------|----|
| Q-fix-broken-form-4nKr | Fix Broken Contact Form | bug | ai | merged |

### Objectives

| Objective | Title | Status | Strategy link |
|-----------|-------|--------|---------------|
| O-q3-trust-launch | Q3 Trust Launch | open | — |
```

The **Plans** cell is always `<shipped>/<total> shipped`, then any
non-zero bucket in the order `ready` → `in progress` → `blocked` →
`draft` → `rejected`. The Quick items and Objectives subsections
render only when they have rows; `strategy_link` renders `—` when
empty.

## Step 3 — Flags

- A `scoped` Scope missing a required section (Intent, Acceptance
  Criteria, Constraints, Dependencies, Out of Scope, Risk):

  ```
  ⚠ S-add-ai-helper-bot is missing: Out of Scope, Risk
    Run /spades:scope S-add-ai-helper-bot to fill the gaps
  ```

- A `delivering` Plan with unshipped dependencies → `⚠ blocked`.
- An `approved` Plan with `delivery: undecided` → `⚠ routing not
  set`; re-run `/spades:approve`.
- A Scope with blocked Plans gets one warning line per blocked Plan:

  ```
  ⚠ S-add-newsletter has 1 blocked Plan:
      P-launch-announcement-7QkP — waiting on P-deploy-bot-9XaZ to ship
  ```

### Drift (`backend: linear`)

When the probe found mismatches, a subsection after the tables:

```
### Linear drift (N)

⚠ S-add-newsletter — local `delivering`, Linear `completed` (Done).
    Re-run /spades:close S-add-newsletter (Pass) to push local → Linear,
    or edit the local Scope if Linear is correct.
```

Omitted when empty; replaced by *"⚠ Drift probe skipped — Linear
unreachable. Showing local view only."* when skipped. The probe is
advisory.

## Step 4 — Empty state

```
No active SPADES Scopes for project "<slug>".

  /spades:scope <title>    — create your first Scope
  /spades:list all         — include done and abandoned Scopes
  /spades:list --project <other-slug>  — try a different project
```

## Step 5 — Next actions

One line per actionable phase: Scoped → `/spades:plan S-…`;
Planning → `/spades:approve P-…`; Delivering → `/spades:do P-…`;
Evaluating → `/spades:evaluate P-…`; Shipping → `/spades:ship P-…`
or `/spades:close P-…`.

## Step 6 — Output

**CLI mode** — print Steps 2–5.

**HTML mode** — dispatch `worker-html-list` per
`docs/FRAMEWORK.md § worker-html-*`, using the wave to run the
drift probe in parallel:

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/list/template.html`
- `output_path`: `.spades/.tmp/list.html`
- `frontmatter`: `{ project_slug, filter_label, rendered_at,
  plugin_version, in_flight_count, done_count }` — Scopes in
  delivering / evaluating / shipping, and Scopes done
- `blocks`:
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`
  - `status-filters` — one per status. Fields: `label, count,
    active` (boolean).
  - `scopes-rows` — one per Scope row. Fields: `id, title, status,
    plans_breakdown` (the Step 2 string), `blocked_warning_html`
    (empty, or a `<span class="blocked-warning">…</span>` with the
    per-Plan list), `updated, flags`.

Required markers: `objective-banner`, `status-filters`,
`scopes-rows`. Then print the one-line brief with the path (and the
`file://` fallback when the open failed).
