---
name: plan
description: Generate a structured SPADES Plan from a Scope. A Plan is a unit of executable work with an ID like `P-<description-slug>-<4-char-suffix>[-<dep-suffix>…]`. Plans can depend on prior plans within the same scope. Use when a Scope exists and the human wants to move to planning, when someone says "plan this", "break this down", "generate a plan", or when a scope is in status `scoped`/`planning`.
version: 3.4.0
---

# /spades:plan

You are generating a Plan for an approved Scope. A Plan is a first-class
artefact: it gets written to `.spades/plans/`, mirrored to the backend,
and reviewed at the Approve gate. Plans can depend on prior plans
within the same scope, and the dependency chain is encoded in the
filename.

Read `docs/FRAMEWORK.md` § ID Format, § .spades/ Local Layout,
§ Target Resolution, and § Execution Posture before running. Schemas
below mirror those contracts.

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML) → Universal
rule`. In **both** modes, write `.spades/plans/P-<…>.md` — this
is the AI-readable source of truth. In HTML mode,
**additionally** render via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/plan/template.html` (includes the
expandable task-card pattern) and write `.spades/plans/P-<…>.html`
for the human's view, then auto-open. HTML mode is additive —
the `.md` always exists; the `.html` is added in HTML mode.

**HTML mode is review-via-file, not review-via-CLI.** Do NOT paste
the Plan body (tasks, technical approach, risks, etc.) to the CLI
for the human's approval before Step 5 writes the file. The file IS
the review surface. Step 5 writes a working draft and auto-opens it;
the human reviews in the browser. To iterate, apply targeted edits
to the file (the human reloads to see changes) — never re-paste a
new full draft to the CLI. In CLI mode the existing draft-then-paste
workflow is fine.

## Pre-Flight

1. **Confirm setup + active project.** Abort otherwise.
2. **Read the backend** from `.spades/config`.
3. **Resolve the target Scope** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill's parameters:
   - **Artefact type:** Scope (no type-question needed).
   - **Status filter:** `scoped`, `planning`.
   - **Zero-candidate suggestion:** `/spades:scope <title>` to create
     one.

   If the human passed an ID (`S-<slug>`), a slug, or a title in the
   invocation, fuzzy-resolve directly via `find_scope_fuzzy` and
   confirm if ambiguous. Otherwise run the interactive picker.
4. **Verify ancestors active** per `docs/FRAMEWORK.md § Target
   Resolution → Parent-status precondition`. If the parent Scope is
   `abandoned`, or its parent Project is `abandoned` / `archived`,
   abort hard with the canonical error shape. No override.
5. **Verify Scope readiness.** If the Scope is missing required fields,
   abort and suggest `/spades:scope <slug>` (Edit mode) first.

## Step 1 — Read Context

Before drafting the Plan:

1. **Read the Scope.** Understand intent, acceptance criteria,
   constraints, dependencies, risks.
2. **Read `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`** at the
   repo root. The Plan must conform to these.
3. **Surface prior learnings.** Glob `.spades/learnings/*.md` (skip
   `private/` and `status: archived`). For each, check whether its
   `scope_ref` matches the current Scope ID, OR whether any of its
   `tags` (case-insensitive) appear in the Scope's title or in the
   tech stack section of `ARCHITECTURE.md`.

   Cold-start threshold: if there are fewer than 20 active learnings,
   one matching tag is enough; once there are 20+, require two. The
   `scope_ref` path is unaffected by the threshold.

4. **List existing plans under this scope.** Call the backend's
   `list_plans(scope_id)`. The human will pick which of them (if any)
   the new Plan depends on.

## Step 2 — Show Your Understanding

Before producing tasks, summarise what you understand from the Scope in
3–4 sentences. Ask the human to confirm or correct. This catches
misunderstandings early.

## Step 3 — Identify the Plan

Ask the human for the plan's title — a short description like
*"RAG Pipeline Lookup"* or *"Create Initial Mastra Bot"*. Derive the
slug exactly as for scopes (lowercase, hyphens, ≤64 chars).

### Mint the own-suffix

Generate a random 4-character base62 ID (`[A-Za-z0-9]{4}`). Before
using it, check the existing plans under this scope: if any plan has
the same `id_suffix`, mint a fresh one. Collisions in a 4-char base62
space are rare (~14M combinations) but cheap to detect.

### Identify dependencies

Show the human the existing plans for this scope and ask via
`AskUserQuestion`:

- **No dependencies** — this plan stands alone
- **Depends on <P-foo-28sD>** — prior plan
- **Depends on multiple** — opens a follow-up free-form prompt for the
  list

The `depends_on:` list contains the prior plans' `id_suffix` values,
in order (most recent dependency first if multiple).

### Build the filename

Compose: `P-<plan-slug>-<own-suffix>[-<dep-suffix>...].md`

Worked examples:

- No deps: `P-create-initial-mastra-bot-28sD.md`
- One dep: `P-rag-pipeline-lookup-3HyD-28sD.md`
- Two deps (`3HyD` and `28sD`): `P-deploy-bot-9XaZ-3HyD-28sD.md`

Show the computed filename to the human; confirm before proceeding.

## Step 4 — Draft the Plan

**Read `review_format:` from `.spades/config` and branch.** Both modes
iterate on the same draft conceptually; only the iteration surface
differs.

### CLI mode

Propose the full draft Plan inline in the terminal, then ask: *"Does
the task breakdown feel right? Anything I'm underestimating? Should
any tasks be human-delivered instead?"* Iterate by re-pasting revised
sections until the human is satisfied; do NOT write the file yet.

### HTML mode

Do NOT paste the Plan body to the CLI. Confirm the high-level shape
verbally (number of tasks, headline approach, deliverable type), then
proceed straight to Step 5 — that step writes the working `.md` and
auto-opens the rendered `.html`. The human reviews the rendered file
and tells you what to change; iterate via targeted file edits (they
reload to see changes). Never re-paste a new full draft to the CLI.

The Plan structure:

### Technical Approach Summary
2–3 sentence overview of how the work will be done.

### Risks & Assumptions
- What might go wrong?
- What am I assuming?
- Any ANTI-PATTERNS.md conflicts to flag?

### Prior Learnings Considered (if any matched)
For each matched learning, list:
- The title (verbatim from frontmatter).
- The filename in parentheses.
- A one-line note on how the Plan honours it.
- A match-reason log line: `Match reason: scope_ref=S-…` OR
  `Match reason: tags matched [tag1, tag2]`.

Skip this section entirely if nothing matched. Silence is cheaper than
"no matches found" padding.

### Tasks (3–7)
For each task, declare:
- **Title**: short, descriptive
- **Description**: what needs to be built
- **Posture**: `specify-first` | `discover-first` | `iterate` | `spike`
  | `straight-through`. See `docs/FRAMEWORK.md` § Execution Posture.
  No silent defaults — if you pick `straight-through`, justify it on
  the task line.
- **Effort**: brief (<1h) | moderate (1–4h) | significant (4+h)
- **Depends on**: task numbers within this Plan, or "none"
- **Routing**: `ai` | `human`. **Required when the Plan's
  `delivery:` field will be `hybrid`; omit otherwise** — single-mode
  Plans (`ai`-only or `human`-only) inherit Plan-level routing. At
  Plan-draft time the routing decision usually isn't fixed yet, so
  draft the field with the planner's best guess and let
  `/spades:approve` confirm or revise per task before approval.

### Testing & Verification
- What tests pass to consider this complete? (for code)
- What evidence demonstrates completion? (for non-code)

### Delivery Sequence
Tasks in recommended execution order, noting which can run in
parallel.

### Deliverable Type — handled mode-specifically

`deliverable_type:` drives what `/spades:ship` does later.

- **CLI mode**: the full draft body was pasted to the terminal in
  Step 4 with the AI's `deliverable_type:` choice visible. Ask the
  human now via `AskUserQuestion` to confirm or change:
  - **`code`** — produces code merged via a PR (default for software work)
  - **`artefact`** — produces a tangible thing (document, dataset, config)
  - **`action`** — a one-off human action (server install, vendor call)
- **HTML mode**: the human has not seen the rendered artefact yet.
  Default to `code` for the initial draft and **defer** the confirm
  question to Step 5.x (after the worker dispatch opens the
  `.html`). Do NOT ask `AskUserQuestion` here.

## Step 5 — Write the Plan File

**Read `review_format:` from `.spades/config` and branch.** This step
MUST write a file — never exit Step 5 with the Plan content only
pasted to the CLI, **and never paste the Plan body (tasks, approach,
risks, etc.) to the CLI for human approval before this step writes
the file in HTML mode**. The file IS the review surface in HTML mode
(see § Output format above).

### Step 5.A — Write the canonical `.md` (both modes)

Write `.spades/plans/<filename>.md` with this exact frontmatter:

```yaml
---
id: P-<plan-slug>-<own-suffix>
id_suffix: <own-suffix>
scope: S-<scope-slug>
title: "<title>"
depends_on: [<dep-suffix-1>, <dep-suffix-2>]    # or [] if none
status: draft
delivery: undecided                              # /spades:approve sets this
evaluation: undecided                            # /spades:evaluate sets this
deliverable_type: code | artefact | action
created: YYYY-MM-DD
updated: YYYY-MM-DD
linear_issue_id: <id>                            # only when backend: linear
---
```

### Body template

```markdown
# <title>

## Technical Approach

<2-3 sentence summary>

## Risks & Assumptions

- <risk 1>
- <assumption 1>

## Prior Learnings Considered

<this section omitted if no learnings matched>

- *<learning title>* (`<filename>`) — <one-line note>
  Match reason: tags matched [<tag1>, <tag2>]

## Tasks

### Task 1: <title>
- **Posture:** specify-first
- **Effort:** moderate
- **Depends on:** none
- **Routing:** ai            # only required when Plan `delivery: hybrid` (see below). For Plans with a single Plan-level routing (`ai` or `human`), omit this field — every task inherits.
- **Description:** <what needs doing>
- **Approach:** <how it'll be done>
- **Tests:** <what tests cover this>

### Task 2: <title>
...

## Delivery Sequence

1. Task 1 (no deps, start immediately)
2. Task 2 (depends on Task 1)
3. Task 3 and Task 4 (parallel, both depend on Task 2)

## Testing & Verification

<overall test strategy and what "shipped" looks like>

## Audit Trail

<!-- Auto-appended by /spades:approve, /spades:do, /spades:evaluate,
     /spades:ship. Do not edit by hand. -->
```

### Step 5.B — HTML render is a parallel worker (HTML mode only)

When `review_format: html`, the `.html` companion is rendered by
`worker-html-plan` dispatched in the same fan-out wave as
`worker-file-plan` (see Step 6 below). The skill body never
renders HTML inline.

Worker inputs:

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/plan/template.html`
- `output_path`: `.spades/plans/<filename>.html` (same slug as the `.md`)
- `frontmatter`: `{ id, title, status, scope, deliverable_type,
  delivery, depends_on, created, updated, … }` (also embedded
  verbatim in `<script id="spades-frontmatter">`)
- `routing_ai`, `routing_hybrid`, `routing_human` *(scalars)*:
  counts of the Plan's tasks by their `routing` field.
- `panel_blockers`, `panel_findings` *(review-echo scalars)*: both
  default to the literal string `not run`. Fill these ONLY from a
  prior `/spades:review` of this Plan that stamped its panel counts
  onto the Plan (frontmatter keys, e.g. `panel_blocking` /
  `panel_major` / `panel_minor`). When those keys are absent, emit
  `not run` (NEVER `0`). `panel_blockers` = the blocking count;
  `panel_findings` = `"<major> / <minor>"`.
- `blocks`:
  - `tasks` — one card per task. Fields: `num, title_html,
    posture, posture_short, effort, routing, depends_on,
    description_html, approach_html, tests_html`.
  - `objective-banner` — 0 or 1 item, fields `{ id, title }`, per
    `docs/FRAMEWORK.md § Objective banner`. Inherit from this
    Plan's Scope's `strategy_link` resolution (only when it matches
    an existing `O-<slug>` objective file); else pass `[]`.
  - `risks-items` — one per `## Risks & Assumptions` bullet.
    Field: `html`.
  - `delivery-sequence` — one per step in `## Delivery Sequence`.
    Field: `html`.
  - `audit-events` — one per audit entry. Fields: `date, desc`.
- `prose_sections`: `{ technical_approach_html,
  testing_verification_html }`

Required template markers: `<!-- SPADES-BLOCK:tasks -->`,
`<!-- SPADES-BLOCK:risks-items -->`,
`<!-- SPADES-BLOCK:delivery-sequence -->`,
`<!-- SPADES-BLOCK:audit-events -->`.

### Step 5.C — Post-render deliverable_type confirm (HTML mode only)

Now that the worker dispatch has rendered `.html` and the human
has the browser tab open, ask via `AskUserQuestion`:

- **`code`** *(default)* — produces code merged via a PR
- **`artefact`** — produces a tangible thing (document, dataset, config)
- **`action`** — a one-off human action (server install, vendor call)

If the human picks something other than `code`, apply a targeted
edit to the `.md` frontmatter (`deliverable_type:` field) and
re-dispatch `worker-html-plan` so the `.html` re-renders with the
corrected value.

CLI mode already asked this in Step 4.

## Step 6 — Fan-out: scope-audit update + backend mirror

Apply the fan-out pattern from
`docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`. **Step 5's plan
file write joins this step's scope-audit append and Linear sub-issue
create as a single fan-out wave.** Three sub-agents, each owning a
distinct resource, dispatched in parallel in a single assistant
message with multiple `Agent` tool calls
(`subagent_type: general-purpose`):

| Sub-agent | Resource owned | Returns |
|-----------|---------------|---------|
| `worker-file-plan` | `.spades/plans/P-<…>.md` — the canonical plan `.md`. Written **without** `linear_issue_id:` — coordinator injects post-dispatch. | `{ status: ok }` |
| `worker-html-plan` *(only when `review_format: html`)* | `.spades/plans/P-<…>.html` — see Step 5.B for inputs. | `{ status: ok, path, opened }` |
| `worker-file-scope-audit` | `.spades/scopes/S-<scope-slug>.<ext>` — update parent Scope frontmatter (`status: planning` if was `scoped`, `updated: <today>`) and append to the audit trail: `- YYYY-MM-DD: Plan drafted — P-<slug>-<suffix>`. | `{ status: ok }` |
| `worker-linear-plan` *(only when `backend: linear`)* | Linear — create a sub-issue under the parent Scope Issue with title + description matching the Plan; apply labels `ai-planned` + `deliverable_type:<value>`. Includes the Layer-2 freshness probe. | `{ status: ok, linear_issue_id: "<id>" }` |

After all sub-agents return, the coordinator:

- **All ok** *(Linear backend)* → targeted edit on the plan file
  to inject `linear_issue_id: <id>` into the frontmatter (and the
  embedded `<script type="application/yaml" id="spades-frontmatter">`
  block in HTML mode). Record dispatch mode.
- **All ok** *(local backend, only two sub-agents)* → no
  back-write needed.
- **`worker-file-plan` failed** → abort. The Linear sub-issue may
  exist but the plan file doesn't; surface clearly so the human can
  delete the orphan or re-run.
- **`worker-file-scope-audit` failed** → abort. The plan file
  exists but the parent scope's audit trail is missing the entry;
  surface so the human can patch manually or re-run.
- **`worker-linear-plan` failed** → keep both local files
  (canonical), surface the Linear failure, offer a retry. Do NOT
  block on Linear failure.

### When `backend: local`

Only the two file sub-agents are dispatched (no Linear). Local files
are canonical. Nothing else to mirror.

## Step 8 — Confirm and Hand Off

```
✓ Plan drafted: P-rag-pipeline-lookup-3HyD
✓ Scope:        S-add-ai-helper-bot
✓ Depends on:   [28sD]
✓ Tasks:        4
✓ Deliverable:  code
✓ Status:       draft

Next:
  /spades:approve P-rag-pipeline-lookup-3HyD    — review and approve
```

The Plan is `draft` until `/spades:approve` runs. Do NOT begin Do-phase
work yet.

## Revision (Edit Mode)

If the human wants to revise an existing Plan:

1. Read the file by its ID.
2. Show the current content and the parts the human wants to change.
3. Iterate conversationally.
4. Write the file back, preserving `id`, `id_suffix`, `scope`, `created`,
   `depends_on`, `linear_issue_id`. Update `updated`.
5. If the Plan was previously `approved`, ask whether the revision
   should re-route through `/spades:approve` (recommended) or stay
   approved.
