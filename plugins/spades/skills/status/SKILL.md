---
name: status
description: Show the current SPADES phase, progress, and dependency graph for active work. Use when someone asks "where are we", "what's the status", "show progress", or any question about current state. Renders the Plan dependency graph so the human can see which plans are unblocked vs waiting.
version: 3.4.0
---

# /spades:status

You are giving the human a status overview of active SPADES work — at
the Scope level *and* at the Plan level, with dependency relationships
visible.

Read `docs/FRAMEWORK.md` § Hierarchy before running.

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. In CLI mode,
print the status overview + dependency graph to the terminal
(today's behaviour). In HTML mode, render the transient view via
the sibling `${CLAUDE_PLUGIN_ROOT}/skills/status/template.html` to
`.spades/.tmp/status.html`, then auto-open via the OPEN_CMD
prelude. The graph data and roll-up counts are identical between
modes — only the presentation changes.

## Pre-Flight

1. **Read `.spades/config`.** Identify backend and active project.
2. **Apply `--project <slug>` if given.** Otherwise active project.

## Step 1 — Fetch

### When `backend: local`

1. Glob `.spades/scopes/*.md` for active scopes (not `done`,
   `rejected`, or `abandoned`). Filter by `project:` field. Skip the
   whole render and abort with a hint if the active Project itself
   has `status: abandoned` — *"Project `<slug>` is abandoned. Run
   `/spades:status --project <other>` to look at a live project."*
2. For each Scope, glob `.spades/plans/P-<scope-slug>-*.md`. Parse
   each plan's frontmatter for `id_suffix`, `depends_on`, `status`,
   `title`, `delivery`, `deliverable_type`.
3. **Quick items.** Glob `.spades/quick/Q-*.md`. Parse frontmatter
   for `title`, `type`, `status`, `pr_url`, `delivery`. Filter to the
   active project.
4. **Objectives.** Glob `.spades/objectives/O-*.md` for `open`
   objectives in the active project. Parse `title`, `status`,
   `strategy_link`. Objectives are a flat, independent track — they
   have no plans, phases, or dependency graph; do not fold them into
   the Scope detail.

### When `backend: linear`

1. Query the active Linear Project for active parent issues + their
   sub-issues. Capture each artefact's Linear `workflow state type`
   (`backlog` / `unstarted` / `started` / `completed` / `canceled`)
   alongside the team-specific status name. Translate to its SPADES
   phase for the main render.
2. For dependency information, fall back to the local `.spades/plans/`
   mirror (the `depends_on:` field; Linear doesn't natively express
   the SPADES dependency graph). Also read the local
   `.spades/scopes/` and `.spades/plans/` `status:` fields for the
   drift probe in step 4.
3. **Quick items.** Glob `.spades/quick/Q-*.md` for the active
   project — the marker file is canonical for both backends.
4. **Objectives.** Glob `.spades/objectives/O-*.md` for `open`
   objectives in the active project (the local file is canonical for
   both backends).
5. **Drift probe.** For every Scope, Plan, and Objective, compare the
   local `status:` to the Linear workflow state type per
   `docs/FRAMEWORK.md § Drift detection` (for an Objective, the
   compared artefact is its sister `O-` tracking issue). Record any
   mismatch into a `drift:` list. If any Linear query failed, set
   `drift_probe_status: skipped` instead. The probe is informational;
   it does not block rendering.

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

| ID | Title | Type | Delivery | PR state | Age |
|----|-------|------|----------|----------|-----|
| Q-fix-broken-form-4nKr | Fix Broken Contact Form | bug | ai | merged (awaiting Done) | 2 days |
| Q-tweak-footer-9XaZ | Tweak Footer Copy | tweak | human | closed (no merge) | ⚠ 18 days |

Objectives (independent strategic track):

| Objective | Title | Status | Strategy link |
|-----------|-------|--------|---------------|
| O-q3-trust-launch | Q3 Trust Launch | open | — |
```

The Objectives subsection appears only when at least one `open`
Objective matches the active project. Objectives are independent of
Scopes (see `docs/FRAMEWORK.md § Hierarchy → Objectives`) — they have
no plans, phases, or dependency graph. Mark complete via
`/spades:close O-<id>`.

Quick items appear in their own subsection only when present. They
have no Plan records. The marker file at
`.spades/quick/Q-<slug>-<suffix>.md` is the canonical source; the
Linear `spades:quick` label (when `backend: linear`) is a mirror.

**Age column.** Compute `Age` as the integer day-count between today
and the marker's `created:` frontmatter field. `/spades:quick` writes
the marker directly at `status: shipping`, so `created:` is the
"time-at-shipping started" anchor — note that re-writes by the
Update PR sub-flow advance `updated:` but never reset `created:`,
so the aging clock is stable across replacements. Render as
`<n> days` (or `<1 day` when same-day). Prefix the cell with `⚠ `
when `Age ≥ 14 days` — at that point the marker is overdue for a
`/spades:close Q-<id>` run, regardless of the PR state column.

## Step 4 — Recommendations

Suggest the single most useful next action:

- A Plan in `▷ ready` state → `Run /spades:do P-… to start it`
- A Plan with PARTIAL verdict → `Run /spades:do P-… to apply fixes`
- A Plan in `evaluating` with PASS in audit trail → `Run /spades:ship P-…`
- A Scope with no plans → `Run /spades:plan S-… to draft the first plan`
- A Plan with `delivery: undecided` → `Re-run /spades:approve P-… (routing not set)`
- A Quick item at `status: shipping` with `Age ≥ 14 days` → `Run /spades:close Q-<id> — marker has been at status: shipping for <n> days.`

Surface only the most impactful one or two suggestions. Don't list
every possible next step.

## Step 4.5 — Drift warnings (Linear backend only)

If Step 1's drift probe (step 4) populated a `drift:` list, render
a subsection below the Recommendations:

```
### Linear drift (N)

⚠ S-add-newsletter — local `delivering`, Linear `completed` (Done).
    Re-run /spades:close S-add-newsletter (Pass) to push local → Linear,
    or edit the local Scope if Linear is correct.

⚠ P-deploy-bot-9XaZ-3HyD — local `shipped`, Linear `started` (In Progress).
    Re-run /spades:close P-deploy-bot-9XaZ-3HyD (Pass) to push local → Linear.
```

Suppress the section when `drift:` is empty. If
`drift_probe_status: skipped`, replace the section with a single
line: *"⚠ Drift probe skipped — Linear unreachable. Showing local
view only."*

The probe is informational, never blocking — `/status` always
renders the dependency graph first; drift warnings are advisory.

## Step 5 — Empty State

If no active work for the project:

```
No active SPADES work for project "<slug>".

  /spades:scope <title>    — start a new Scope
  /spades:list all         — see Done/rejected work
```

## Step 6 — Output (branch on `review_format`)

**Read `review_format:` from `.spades/config` and branch.**

### CLI mode (`review_format: cli`)

Print everything from Steps 2–5 to the terminal as described above.
This is today's behaviour.

### HTML mode (`review_format: html`)

**Dispatch `worker-html-status` per
`docs/FRAMEWORK.md § worker-html-* — parallel HTML rendering`.**
No inline render. The main agent uses the dispatch wave to run
the Linear drift probe in parallel.

Worker inputs:

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/status/template.html`
- `output_path`: `.spades/.tmp/status.html` (worker creates
  `.spades/.tmp/` if missing — auto-gitignored by setup Step 5.5)
- `frontmatter`: `{ project_slug, rendered_at, plugin_version }`
- `blocks`:
  - `objective-banner` — 0 or 1 item per
    `docs/FRAMEWORK.md § Objective banner`. Pass the project's sole
    `open` Objective `{ id, title }` when EXACTLY ONE exists in
    `.spades/objectives/`, else `[]`.
  - `ready-items` — Plans in `Ready (unblocked)`. Fields:
    `id, title, status, href`.
  - `in-flight-items` — Plans currently `delivering` /
    `evaluating` / `shipping`. Same fields.
  - `blocked-items` — Plans blocked by unshipped deps. Adds
    `blocked_by`.
  - `plan-nodes` — Plans in topological order. Fields:
    `indent` (tree-prefix string like `└─ `), `id, title,
    status, depends_on`.

Required template markers (worker validates and aborts on
mismatch): `<!-- SPADES-BLOCK:objective-banner -->`,
`<!-- SPADES-BLOCK:ready-items -->`,
`<!-- SPADES-BLOCK:in-flight-items -->`,
`<!-- SPADES-BLOCK:blocked-items -->`,
`<!-- SPADES-BLOCK:plan-nodes -->`.

After the worker returns, the main agent prints the brief (file
path, link to open if OPEN_CMD was empty). Never print the
markdown view in HTML mode — the browser is the review surface.

## Performance

This skill reads many files in `local` mode. For projects with 50+
scopes, render the summary table first and stream the per-Scope
detail. The human is usually scanning for one specific thing.
