---
name: list
description: List active SPADES Scopes (and Objectives), optionally filtered by phase or project. Use when someone says "show my scopes", "list scopes", "list objectives", "what's active", "what needs planning", or wants to see what work is in progress across the SPADES pipeline. Accepts a `--project <slug>` filter; defaults to the active project from `.spades/config`.
version: 3.3.0
---

# /spades:list

You are showing the human their active SPADES work.

Read `docs/FRAMEWORK.md` § Hierarchy and § .spades/ Local Layout before
running.

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. In CLI mode,
print the scope list table to the terminal. In HTML mode, render
the transient view via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/list/template.html` to
`.spades/.tmp/list.html`, then auto-open via the OPEN_CMD prelude.
The filter logic, sort order, and visible columns are identical
between modes.

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
   - `/spades:list all` — include `done`, `rejected`, `abandoned`,
     and (for Objectives) `complete`
   - `/spades:list abandoned` — only abandoned Scopes and Projects

   For the Objectives subsection: the default view shows `open`
   objectives; `all` additionally includes `complete` and
   `abandoned`.

   **Default view excludes `abandoned` Scopes and their child Plans**
   (parent's terminal walk-away makes children irrelevant to active
   work). Same applies if the active Project itself is `abandoned`
   — abort with: *"Project `<slug>` is abandoned. Run `/spades:list
   --project <other>` or `/spades:list all` to override."*

## Step 1 — Fetch

### When `backend: local`

1. Glob `.spades/scopes/*.md`.
2. For each, parse the frontmatter. Skip any whose `project:` doesn't
   match the active project filter.
3. Read `status:`, `title:`, `priority:`, `type:`.
4. For each Scope, also glob `.spades/plans/P-<scope-slug>-*.md` and
   parse each Plan's `id_suffix`, `status`, `depends_on`. Classify
   each Plan into one of these buckets (mirrors `/spades:status`):
   - **shipped** — `status: shipped`
   - **in progress** — `status` ∈ `{delivering, evaluating, shipping}`
   - **ready** — `status: approved` AND every `depends_on` resolves
     to a sibling Plan with `status: shipped`
   - **blocked** — `status` ≠ `shipped`/`rejected` AND any `depends_on`
     resolves to a sibling that is not `shipped`
   - **draft** — `status: draft` (and not already "blocked")
   - **rejected** — `status: rejected`

   Hold the per-Scope counts (`shipped`, `in_progress`, `ready`,
   `blocked`, `draft`, `rejected`, `total`) plus the list of blocked
   Plan IDs (and what each is waiting on) for Step 2 and Step 3.
5. **Quick items.** Also glob `.spades/quick/Q-*.md`. Parse
   frontmatter; skip any whose `project:` doesn't match the active
   project filter. Read `status:`, `title:`, `type:`, `pr_url:`,
   `delivery:`. These render in their own subsection (Step 2 below).
6. **Objectives.** Also glob `.spades/objectives/O-*.md`. Parse
   frontmatter; skip any whose `project:` doesn't match the active
   project filter. Read `status:`, `title:`, `strategy_link:`. The
   default view shows `open`; `all` includes `complete`/`abandoned`.
   These render in their own subsection (Step 2 below). Objectives are
   independent of Scopes — never fold them into the Scope tables.

### When `backend: linear`

1. Query the active Linear Project for parent issues. For each
   parent and each sub-issue, capture the Linear `workflow state
   type` (`backlog` / `unstarted` / `started` / `completed` /
   `canceled`) alongside the team-specific status name.
2. Filter by status to match the chosen phase set.
3. For each parent, fetch its sub-issues to count plan progress. Then
   read the **local** `.spades/plans/` and `.spades/scopes/`
   mirrors for `depends_on:`, the Plan `status:` field, and the
   Scope `status:` field. Apply the same Plan-state classification
   as the local path (Step 4 above) — `shipped`, `in progress`,
   `ready`, `blocked`, `draft`, `rejected`. Hold per-Scope counts +
   blocked Plan list.
4. **Drift probe.** For every Scope and Plan fetched in steps 1–3,
   compare the local `status:` to the Linear workflow state type
   per `docs/FRAMEWORK.md § Drift detection`. Record any mismatch
   into a `drift:` list — each entry holds `(artefact_id,
   local_status, linear_workflow_type, linear_team_status_name)`.
   The probe is informational; it does not block rendering.
5. **Quick items.** Also glob `.spades/quick/Q-*.md` for the active
   project (the marker file is canonical even in Linear mode); the
   Linear label `spades:quick` is a secondary signal but not the
   primary source.
6. **Objectives.** Also glob `.spades/objectives/O-*.md` for the
   active project (the local file is canonical even in Linear mode).
   Read `status:`, `title:`, `strategy_link:`. Include each
   Objective's sister `O-` tracking issue in the drift probe (step 4):
   the expected mapping is `open`→issue not completed/canceled,
   `complete`→issue `completed`, `abandoned`→issue `canceled`
   (per `docs/FRAMEWORK.md § Drift detection → Status-type mapping`).
7. **Linear unreachable.** If any Linear query fails (timeout, auth,
   404), skip the drift probe and continue with the local view.
   Hold a `drift_probe_status: skipped` flag for Step 3 to surface
   below the table: *"Drift probe skipped — Linear unreachable.
   Showing local view only."*

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

| Scope | Title | Plans |
|-------|-------|-------|
| S-add-newsletter | Add Newsletter Signup | 2/4 shipped · 1 ready · 1 blocked |

The **Plans** column shows `<shipped>/<total> shipped` always, then
appends `· <n> ready`, `· <n> in progress`, `· <n> blocked`,
`· <n> draft`, `· <n> rejected` for any bucket with a non-zero count.
Suppress zero counts to keep the cell readable. Order of optional
suffixes (when present): `ready` → `in progress` → `blocked` →
`draft` → `rejected`. The "in progress" bucket combines `delivering`,
`evaluating`, and `shipping` Plans — `/spades:status` is where the
human goes for that level of detail.

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

The Quick items subsection renders only when at least one
`Q-*` marker file matches the active project filter. Quick items
are work being done outside the Scope/Plan loop but still under the
active project; they appear under the project's listing as their
own category, distinct from Scopes.

The **Objectives** subsection renders only when at least one
`O-*` record matches the active project filter. Objectives are an
independent strategic track under the project (see `docs/FRAMEWORK.md
§ Hierarchy → Objectives`) — they are not Scopes and have no plans,
phases, or dependency graph. The default view shows `open` objectives;
`/spades:list all` adds `complete` and `abandoned`. Render `—` for an
empty `strategy_link`.

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

For Scopes with any blocked Plan, render a per-Scope warning line
(below the table) so the blocking relationship is visible without
needing `/spades:status`:

```
⚠ S-add-newsletter has 1 blocked Plan:
    P-launch-announcement-7QkP — waiting on P-deploy-bot-9XaZ to ship
```

When a Scope has multiple blocked Plans, list each on its own
indented line. The blocked-plan list comes from the per-Scope count
gathered in Step 1; no extra parsing. The same data renders the
graph in `/spades:status`; `/list` flattens it to a warning so
quick-scan users can spot stuck work without dropping into the
deeper view.

### Drift warnings (Linear backend only)

If Step 1 populated a `drift:` list (any artefact whose local
`status:` doesn't match Linear's workflow state type per
`docs/FRAMEWORK.md § Drift detection`), render a subsection below
the Scope/Plan tables:

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

The probe is informational, never blocking. `/list` always renders
the main view first; drift warnings are advisory.

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

## Step 6 — Output (branch on `review_format`)

**Read `review_format:` from `.spades/config` and branch.**

### CLI mode (`review_format: cli`)

Print Steps 2–5 to the terminal as described above. Today's
behaviour.

### HTML mode (`review_format: html`)

**Dispatch `worker-html-list` per
`docs/FRAMEWORK.md § worker-html-* — parallel HTML rendering`.**
No inline render.

Worker inputs:

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/list/template.html`
- `output_path`: `.spades/.tmp/list.html`
- `frontmatter`: `{ project_slug, filter_label, rendered_at,
  plugin_version, in_flight_count, done_count }` —
  `in_flight_count` is the number of Scopes in delivering /
  shipping phases; `done_count` is the number of Scopes that are
  done. (These drive the deck.)
- `blocks`:
  - `objective-banner` — 0 or 1 item per
    `docs/FRAMEWORK.md § Objective banner`. Pass the project's sole
    `open` Objective `{ id, title }` when EXACTLY ONE exists in
    `.spades/objectives/`, else `[]`.
  - `status-filters` — one per status. Fields: `label, count,
    active` (boolean).
  - `scopes-rows` — one per Scope row (post-filter). Fields:
    `id, title, status, plans_breakdown` (string like
    `"2/4 shipped · 1 ready · 1 blocked"`, zero counts
    suppressed, ordered `ready → in progress → blocked → draft
    → rejected`), `blocked_warning_html` (empty string when no
    blocked Plans; otherwise a `<span class="blocked-warning">…
    </span>` containing the per-blocked-plan list — CSS in the
    template), `updated, flags`.

Required template markers:
`<!-- SPADES-BLOCK:objective-banner -->`,
`<!-- SPADES-BLOCK:status-filters -->`,
`<!-- SPADES-BLOCK:scopes-rows -->`.

After the worker returns, the main agent prints a one-line brief
(file path or fallback message). Never print the table to the
terminal in HTML mode.
