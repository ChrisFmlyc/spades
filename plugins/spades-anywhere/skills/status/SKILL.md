---
name: status
description: Show the current SPADES phase, progress, and dependency graph for active work. Use when someone asks "where are we", "what's the status", "show progress", or any question about current state. Renders the Plan dependency graph so the human can see which plans are unblocked vs waiting.
version: 0.4.0
---

# /spades-anywhere:status

You are giving the human a status overview at the Scope level and
the Plan level, with the dependency graph visible and the next
useful action named.

Read `docs/FRAMEWORK.md` § Hierarchy, § Drift detection, and
§ Output Format before running.

### Output format

A transient view. CLI mode prints it. HTML mode renders from
`${CLAUDE_PLUGIN_ROOT}/skills/status/template.html` to
`.spades-anywhere/.tmp/status.html`, auto-opens it, and prints a
one-line brief with the path.

## Pre-Flight

1. **Read `.spades-anywhere/config`** — `backend:`, `project:`,
   `review_format:`.
2. **Apply `--project <slug>`** when given. An `abandoned` active
   Project aborts with *"Project `<slug>` is abandoned. Run
   `/spades-anywhere:status --project <other>`."*

## Step 1 — Fetch

### `backend: local`

1. Active Scopes (not `done` or `abandoned`) for the project.
2. Each Scope's Plans: `id_suffix`, `depends_on`, `status`,
   `title`, `delivery`, `deliverable_type`.
3. **Quick items** — `.spades-anywhere/quick/Q-*.md`: `title`,
   `type`, `status`, `evidence_ref`, `delivery`, `created`.
4. **Objectives** — `open` ones: `title`, `strategy_link`.

### `backend: linear`

1. Query the active Linear Project for active parent Issues and
   sub-issues with their workflow state types; translate to the
   SPADES phase.
2. Read the local files for `depends_on:` (Linear has no dependency
   graph) and `status:`.
3. **Quick items and Objectives** from the local files.
4. **Drift probe** — compare local `status:` (Scopes, Plans, each
   Objective's sister issue) with Linear's state type per
   `docs/FRAMEWORK.md § Drift detection`. A failed query sets
   `drift_probe_status: skipped`.

## Step 2 — Summary header

```
## SPADES Status — Project: family-events

| Scope | Phase | Plans |
|-------|-------|-------|
| S-hiring-round-q3 | Delivering | 2/4 shipped, 1 ready |
| S-summer-trip | Planning | 2 draft |
| S-plan-birthday-party | Scoped | — |

Fast-track items (no plans):

| ID | Title | Type | Delivery | Evidence | Age |
|----|-------|------|----------|----------|-----|
| Q-book-venue-deposit-7Mqz | Book venue deposit | errand | human | receipt photo | 3 days |
| Q-send-thankyou-cards-4nKr | Send thank-you cards | errand | human | — | ⚠ 22 days |

Objectives (independent strategic track):

| Objective | Title | Status | Strategy link |
|-----------|-------|--------|---------------|
| O-q3-trust-launch | Q3 Trust Launch | open | roadmap-42 |
```

Quick items and Objectives appear only when present. Objectives are
a flat, independent track; completion is `/spades-anywhere:close
O-<id>`.

**Age** is the day count from the marker's `created:`, rendered `<n>
days` or `<1 day` and prefixed `⚠ ` at 14 days or more. With no
external state to back-stop a forgotten marker, the age is the
signal that work was opened and never closed.

## Step 3 — Per-Scope detail

```
### S-hiring-round-q3 — Q3 hiring round

Phase: Delivering (2/4 plans shipped)
Project: family-events
Priority: high

Plans (dependency order):

  ✓ P-write-the-brief-28sD               [shipped]    artefact human
  ✓ P-source-candidates-3HyD-28sD        [shipped]    action   human
  ⏵ P-run-interviews-9XaZ-3HyD           [delivering] action   hybrid
  ⊘ P-make-the-offer-7QkP-9XaZ           [draft]      action   human
         └─ blocked: waiting for P-run-interviews-9XaZ to ship
```

Symbols: `✓` shipped · `⏵` in progress · `▷` ready (approved,
dependencies shipped) · `◐` partial · `⊘` blocked · `⌧` rejected.
Columns after the ID: status, `deliverable_type`, `delivery`.

## Step 4 — Recommendation

The one or two most useful next actions:

- `▷ ready` Plan → `/spades-anywhere:do P-…`
- PARTIAL verdict → `/spades-anywhere:do P-…` to keep going
- `evaluating` with PASS → `/spades-anywhere:ship P-…`
- `shipping` with a `Shipped` line → `/spades-anywhere:close P-…`
- Scope with no Plans → `/spades-anywhere:plan S-…`
- `delivery: undecided` → re-run `/spades-anywhere:approve P-…`
- Quick item at `shipping` for 14+ days → `/spades-anywhere:close
  Q-<id>`

### Drift (`backend: linear`)

After the recommendation, when the probe found mismatches, the
same subsection as `/spades-anywhere:list`; omitted when empty,
replaced by the skipped note when Linear was unreachable. Advisory.

## Step 5 — Empty state

```
No active SPADES work for project "<slug>".

  /spades-anywhere:scope <title>    — start a new Scope
  /spades-anywhere:list all         — see done and abandoned work
```

## Step 6 — Output

**CLI mode** — print Steps 2–5. For 50+ Scopes, print the summary
first and stream the detail.

**HTML mode** — render from the template per `docs/FRAMEWORK.md §
Output Format → HTML rendering`, running the drift probe alongside:

- `output_path`: `.spades-anywhere/.tmp/status.html`
- `frontmatter`: `{ project_slug, rendered_at, plugin_version }`
- `blocks`:
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`
  - `ready-items` — `▷` Plans. Fields: `id, title, status, href`.
  - `in-flight-items` — `⏵` Plans. Same fields.
  - `blocked-items` — `⊘` Plans; adds `blocked_by`.
  - `plan-nodes` — every Plan in topological order. Fields:
    `indent, id, title, status, depends_on`.

Required markers: `objective-banner`, `ready-items`,
`in-flight-items`, `blocked-items`, `plan-nodes`. Then print the
one-line brief with the path (and the `file://` fallback when the
open failed).
