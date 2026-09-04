---
name: list
description: List active SPADES Scopes (and Objectives), optionally filtered by phase or project. Use when someone says "show my scopes", "list scopes", "list objectives", "what's active", "what needs planning", or wants to see what work is in progress across the SPADES pipeline. Accepts a `--project <slug>` filter; defaults to the active project from `.spades-anywhere/config`.
version: 0.4.0
---

# /spades-anywhere:list

You are showing the human their active SPADES work: Scopes grouped
by phase with Plan progress, plus Quick items and Objectives in
their own subsections.

Read `docs/FRAMEWORK.md` § Hierarchy, § .spades-anywhere/ Local
Layout, § Drift detection, and § Output Format before running.

### Output format

A transient view. CLI mode prints it. HTML mode renders it from
`${CLAUDE_PLUGIN_ROOT}/skills/list/template.html` to
`.spades-anywhere/.tmp/list.html`, auto-opens it, and prints a
one-line brief with the path.

## Pre-Flight

1. **Read `.spades-anywhere/config`** — `backend:`, `project:`,
   `review_format:`.
2. **Apply `--project <slug>`** when given. An `abandoned` active
   Project aborts with *"Project `<slug>` is abandoned. Run
   `/spades-anywhere:list --project <other>` or
   `/spades-anywhere:list all`."*
3. **Determine the filter.** Default: active phases (`scoped`,
   `planning`, `delivering`, `evaluating`, `shipping`), excluding
   `abandoned` Scopes and their Plans. Overrides: a single phase
   name; `all` (adds `done`, `abandoned`, and for Objectives
   `complete` and `abandoned`); `abandoned`. Objectives default to
   `open`.

## Step 1 — Fetch

### `backend: local`

1. Glob `.spades-anywhere/scopes/*.md` for the project; read
   `status`, `title`, `priority`, `type`.
2. For each Scope, its Plans (`scope:` set to it); read `id_suffix`,
   `status`, `depends_on`. Classify: **shipped**; **in progress**
   (`delivering`, `evaluating`, `shipping`); **ready** (`approved`
   with every `depends_on` sibling `shipped`); **blocked** (not
   terminal, a `depends_on` sibling not `shipped`); **draft**;
   **rejected**. Hold the counts and the blocked list.
3. **Quick items** — `.spades-anywhere/quick/Q-*.md` for the
   project: `status`, `title`, `type`, `evidence_ref`, `delivery`.
4. **Objectives** — `.spades-anywhere/objectives/O-*.md` for the
   project: `status`, `title`, `strategy_link`, filtered.

### `backend: linear`

1. Query the active Linear Project for parent Issues and
   sub-issues, capturing each workflow state type alongside the
   team-specific name; filter by phase.
2. Read the local files for `depends_on:` and `status:`; classify
   Plans as above.
3. **Drift probe** — compare each local `status:` (Scopes, Plans,
   each Objective's sister `O-` issue) with Linear's state type per
   `docs/FRAMEWORK.md § Drift detection`; collect mismatches.
4. **Quick items and Objectives** from the local files, canonical
   in both backends.
5. **Linear unreachable** → skip the probe, note
   `drift_probe_status: skipped`, render the local view.

## Step 2 — The table

```
## Active Scopes — Project: family-events

### Scoped (ready for planning)

| Scope | Title | Priority | Type |
|-------|-------|----------|------|
| S-plan-birthday-party | Plan the birthday party | high | feature |

### Planning

| Scope | Title | Plans drafted |
|-------|-------|---------------|
| S-summer-trip | Summer trip | 2 |

### Delivering

| Scope | Title | Plans |
|-------|-------|-------|
| S-hiring-round-q3 | Q3 hiring round | 2/4 shipped · 1 ready · 1 blocked |

### Evaluating

(none)

### Shipping

(none)

### Quick items

| ID | Title | Type | Evidence |
|----|-------|------|----------|
| Q-book-venue-deposit-7Mqz | Book venue deposit | errand | receipt photo |

### Objectives

| Objective | Title | Status | Strategy link |
|-----------|-------|--------|---------------|
| O-q3-trust-launch | Q3 Trust Launch | open | roadmap-42 |
```

The **Plans** cell is always `<shipped>/<total> shipped`, then any
non-zero bucket in the order `ready` → `in progress` → `blocked` →
`draft` → `rejected`. Quick items and Objectives render only when
they have rows; an empty `strategy_link` renders `—`.

## Step 3 — Flags

- A `scoped` Scope missing a required section (Intent, Acceptance
  Criteria, Constraints, Dependencies, Out of Scope, Risk) → `⚠
  S-… is missing: <sections>` with a pointer to
  `/spades-anywhere:scope S-…`.
- A `delivering` Plan with unshipped dependencies → `⚠ blocked`.
- An `approved` Plan with `delivery: undecided` → `⚠ routing not
  set`; re-run `/spades-anywhere:approve`.
- A Scope with blocked Plans gets one warning line per blocked Plan
  naming what it waits on.

### Drift (`backend: linear`)

When the probe found mismatches, a subsection after the tables:

```
### Linear drift (N)

⚠ S-plan-birthday-party — local `delivering`, Linear `completed` (Done).
    Re-run /spades-anywhere:close S-plan-birthday-party (Pass) to push local → Linear,
    or edit the local Scope if Linear is correct.
```

Omitted when empty; *"⚠ Drift probe skipped — Linear unreachable.
Showing local view only."* when skipped. Advisory.

## Step 4 — Empty state

```
No active SPADES Scopes for project "<slug>".

  /spades-anywhere:scope <title>    — create your first Scope
  /spades-anywhere:list all         — include done and abandoned Scopes
  /spades-anywhere:list --project <other-slug>  — try a different project
```

## Step 5 — Next actions

One line per actionable phase: Scoped → `/spades-anywhere:plan
S-…`; Planning → `/spades-anywhere:approve P-…`; Delivering →
`/spades-anywhere:do P-…`; Evaluating → `/spades-anywhere:evaluate
P-…`; Shipping → `/spades-anywhere:ship P-…`, then
`/spades-anywhere:close P-…`.

## Step 6 — Output

**CLI mode** — print Steps 2–5.

**HTML mode** — render from the template per `docs/FRAMEWORK.md §
Output Format → HTML rendering`, running the drift probe alongside:

- `output_path`: `.spades-anywhere/.tmp/list.html`
- `frontmatter`: `{ project_slug, filter_label, rendered_at,
  plugin_version, in_flight_count, done_count }`
- `blocks`:
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`
  - `status-filters` — one per status. Fields: `label, count,
    active`.
  - `scopes-rows` — one per Scope row. Fields: `id, title, status,
    plans_breakdown, blocked_warning_html` (empty, or a
    `<span class="blocked-warning">…</span>`), `updated, flags`.

Required markers: `objective-banner`, `status-filters`,
`scopes-rows`. Then print the one-line brief with the path (and the
`file://` fallback when the open failed).
