---
name: status
description: Show the current SPADES phase, progress, and dependency graph for active work. Use when someone asks "where are we", "what's the status", "show progress", or any question about current state. Renders the Plan dependency graph so the human can see which plans are unblocked vs waiting.
version: 3.5.0
---

# /spades:status

You are giving the human a status overview at the Scope level and
the Plan level, with the dependency graph visible and the next
useful action named.

Read `docs/FRAMEWORK.md` § Hierarchy, § Freshness, § Drift
detection, and § Output Format before running.

### Output format

A transient view. CLI mode prints the overview and graph. HTML mode
renders from `${CLAUDE_PLUGIN_ROOT}/skills/status/template.html` to
`.spades/.tmp/status.html` via `worker-html-status`, auto-opens it,
and prints a one-line brief with the path.

## Pre-Flight

1. **Read `.spades/config`** — `backend:`, `project:`,
   `review_format:`.
2. **Apply `--project <slug>`** when given; otherwise the active
   project. An `abandoned` active Project aborts with *"Project
   `<slug>` is abandoned. Run `/spades:status --project <other>`."*

## Step 1 — Fetch

### `backend: local`

1. Glob `.spades/scopes/*.md` for the project's active Scopes (not
   `done` or `abandoned`).
2. For each, glob the Plans with `scope:` set to it; read
   `id_suffix`, `depends_on`, `status`, `title`, `delivery`,
   `deliverable_type`.
3. **Quick items** — `.spades/quick/Q-*.md` for the project: `title`,
   `type`, `status`, `pr_url`, `delivery`, `created`.
4. **Objectives** — `.spades/objectives/O-*.md` with `status: open`
   for the project: `title`, `strategy_link`.

### `backend: linear`

1. Query the active Linear Project for active parent Issues and
   sub-issues, capturing each workflow state type alongside the
   team-specific name, and translate to the SPADES phase.
2. Read the local `.spades/plans/` and `.spades/scopes/` files for
   `depends_on:` (Linear has no dependency graph) and `status:`.
3. **Quick items and Objectives** from the local files, canonical in
   both backends.
4. **Drift probe** — compare each local `status:` (Scopes, Plans,
   and each Objective's sister `O-` issue) with Linear's state type
   per `docs/FRAMEWORK.md § Drift detection`; collect mismatches. A
   failed Linear query sets `drift_probe_status: skipped`.

## Step 2 — Summary header

```
## SPADES Status — Project: closed-door-security-website

| Scope | Phase | Plans |
|-------|-------|-------|
| S-add-ai-helper-bot | Delivering | 2/4 shipped, 1 ready |
| S-rework-landing-page | Planning | 2 draft |
| S-add-newsletter | Scoped | — |

Fast-track items (no plans):

| ID | Title | Type | Delivery | PR state | Age |
|----|-------|------|----------|----------|-----|
| Q-fix-broken-form-4nKr | Fix Broken Contact Form | bug | ai | merged (awaiting close) | 2 days |
| Q-tweak-footer-9XaZ | Tweak Footer Copy | tweak | human | closed (no merge) | ⚠ 18 days |

Objectives (independent strategic track):

| Objective | Title | Status | Strategy link |
|-----------|-------|--------|---------------|
| O-q3-trust-launch | Q3 Trust Launch | open | — |
```

Quick items and Objectives appear only when present. Objectives are
a flat, independent track with no Plans or graph; completion is
`/spades:close O-<id>`.

**Age** is the day count from the marker's `created:` (the moment
`/spades:quick` opened it at `shipping`; replacement-PR rewrites
advance `updated:` and leave `created:` alone). Render `<n> days`
or `<1 day`, prefixed `⚠ ` at 14 days or more — the marker is
overdue for `/spades:close Q-<id>` whatever the PR column says.

## Step 3 — Per-Scope detail

```
### S-add-ai-helper-bot — Add AI Helper Bot

Phase: Delivering (2/4 plans shipped)
Project: closed-door-security-website
Priority: high

Plans (dependency order):

  ✓ P-create-initial-mastra-bot-28sD    [shipped]    code   ai
  ✓ P-rag-pipeline-lookup-3HyD-28sD     [shipped]    code   ai
  ⏵ P-deploy-bot-9XaZ-3HyD-28sD         [delivering] code   ai
  ⊘ P-launch-announcement-7QkP-9XaZ     [draft]      artefact human
         └─ blocked: waiting for P-deploy-bot-9XaZ to ship
```

Symbols: `✓` shipped · `⏵` in progress (delivering / evaluating /
shipping) · `▷` ready (approved, dependencies shipped) · `◐` partial
(a PARTIAL verdict) · `⊘` blocked · `⌧` rejected. Columns after the
ID: status, `deliverable_type`, `delivery`.

A Plan is blocked when any `depends_on` sibling is not `shipped`;
show the blocking edge inline. A `▷ ready` Plan is the next thing to
do.

## Step 4 — Recommendation

The one or two most useful next actions:

- `▷ ready` Plan → `/spades:do P-…`
- PARTIAL verdict → `/spades:do P-…` to apply the fixes
- `evaluating` with PASS → `/spades:ship P-…`
- `shipping` with `PR opened:` → `/spades:close P-…`
- Scope with no Plans → `/spades:plan S-…`
- `delivery: undecided` → re-run `/spades:approve P-…`
- Quick item at `shipping` for 14+ days → `/spades:close Q-<id>`

### Drift (`backend: linear`)

After the recommendation, when the probe found mismatches:

```
### Linear drift (N)

⚠ S-add-newsletter — local `delivering`, Linear `completed` (Done).
    Re-run /spades:close S-add-newsletter (Pass) to push local → Linear,
    or edit the local Scope if Linear is correct.
```

Omitted when empty; *"⚠ Drift probe skipped — Linear unreachable.
Showing local view only."* when skipped. Advisory.

## Step 5 — Empty state

```
No active SPADES work for project "<slug>".

  /spades:scope <title>    — start a new Scope
  /spades:list all         — see done and abandoned work
```

## Step 6 — Output

**CLI mode** — print Steps 2–5. For 50+ Scopes, print the summary
first and stream the detail.

**HTML mode** — dispatch `worker-html-status` per
`docs/FRAMEWORK.md § worker-html-*`, running the drift probe in
parallel with the render:

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/status/template.html`
- `output_path`: `.spades/.tmp/status.html`
- `frontmatter`: `{ project_slug, rendered_at, plugin_version }`
- `blocks`:
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`
  - `ready-items` — `▷` Plans. Fields: `id, title, status, href`.
  - `in-flight-items` — `⏵` Plans. Same fields.
  - `blocked-items` — `⊘` Plans; adds `blocked_by`.
  - `plan-nodes` — every Plan in topological order. Fields:
    `indent` (tree prefix such as `└─ `), `id, title, status,
    depends_on`.

Required markers: `objective-banner`, `ready-items`,
`in-flight-items`, `blocked-items`, `plan-nodes`. Then print the
one-line brief with the path (and the `file://` fallback when the
open failed).
