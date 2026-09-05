---
name: plan
description: Generate a structured SPADES Plan from a Scope. A Plan is a unit of executable work with an ID like `P-<description-slug>-<4-char-suffix>[-<dep-suffix>…]`. Plans can depend on prior plans within the same scope. Use when a Scope exists and the human wants to move to planning, when someone says "plan this", "break this down", "generate a plan", or when a scope is in status `scoped`/`planning`.
version: 3.7.1
---

# /spades:plan

You are drafting a Plan for a Scope. A Plan is a first-class
artefact: written to `.spades/plans/`, mirrored to the backend, and
gated at `/spades:approve` before any Deliver-phase work starts. Plans
can depend on earlier Plans in the same Scope; the dependency chain
is encoded in the filename and held authoritatively in `depends_on:`.

Read `docs/FRAMEWORK.md` § ID Format, § .spades/ Local Layout,
§ Target Resolution, § Execution Posture, and § Output Format before
running.

### Output format

- **Both modes** — `.spades/plans/P-<…>.md`, the canonical record.
- **HTML mode** — additionally `.spades/plans/P-<…>.html`, rendered
  from `${CLAUDE_PLUGIN_ROOT}/skills/plan/template.html` by
  `worker-html-plan` and auto-opened. The page is the review surface:
  Step 5 writes the working draft, the human reviews in the browser,
  and iteration is a targeted `.md` edit plus a re-render.
- **CLI mode** — Step 4 pastes the draft to the terminal and iterates
  there before Step 5 writes it.

## Pre-Flight

Use the parent Scope's documentation checkout before delivery, or its
established delivery worktree afterwards, per `docs/FRAMEWORK.md § Scope
Worktrees`. Drafting another Plan reuses that context. Deliver creates the
separate implementation branch; all Plans in the Scope share it. Readiness
for dependent delivery is a confirmed PASS on that branch or shipment.

1. **Confirm setup and active project.** Abort otherwise.
2. **Read `backend:` and `review_format:`** from `.spades/config`.
3. **Resolve the target Scope** per `docs/FRAMEWORK.md § Target
   Resolution` — artefact type Scope; status filter `scoped`,
   `planning`; zero candidates → suggest `/spades:scope <title>`. A
   passed ID, slug, or title resolves via `find_scope_fuzzy` with a
   confirmation when ambiguous.
4. **Verify ancestors active** per § Target Resolution →
   Parent-status precondition: an `abandoned` Scope, or an
   `abandoned` / `archived` Project, is a hard abort.
5. **Verify Scope readiness.** A Scope missing required sections is
   sent back to `/spades:scope <slug>` (Edit mode).

## Step 1 — Read context

1. **The Scope** — intent, acceptance criteria, constraints,
   dependencies, risks.
2. **`ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`** — the
   Plan conforms to these; a conflict is flagged in Risks &
   Assumptions for the human to rule on at Approve.
3. **Prior learnings.** Glob `.spades/learnings/*.md`, skipping
   `private/` and `status: archived`. A learning matches when its
   `scope_ref` equals this Scope's ID, or when its `tags`
   (case-insensitive) appear in the Scope's title or the tech-stack
   section of `ARCHITECTURE.md`. With fewer than 20 active learnings
   one matching tag is enough; from 20 upward require two. The
   `scope_ref` match is unaffected by the threshold.
4. **Existing Plans under this Scope** via `list_plans(scope_id)` —
   the candidates for `depends_on:`.

## Step 2 — Show your understanding

Summarise the Scope in three or four sentences and ask the human to
confirm or correct before any tasks are drafted.

## Step 3 — Identify the Plan

Ask for a short title (*"RAG Pipeline Lookup"*). Derive the slug as
for Scopes (lowercase, hyphens, ≤64 characters).

**Mint the suffix.** Generate a random 4-character base62 ID
(`[A-Za-z0-9]{4}`) and re-mint on collision with any `id_suffix`
under this Scope.

**Dependencies.** Show the existing Plans and ask via
`AskUserQuestion`: **No dependencies** / **Depends on
`<P-foo-28sD>`** / **Depends on multiple** (free-form list follows).
`depends_on:` holds the prior Plans' `id_suffix` values, most recent
first.

**Filename.** `P-<plan-slug>-<own-suffix>[-<dep-suffix>…].md`:

- `P-create-initial-mastra-bot-28sD.md` — standalone
- `P-rag-pipeline-lookup-3HyD-28sD.md` — depends on `28sD`
- `P-deploy-bot-9XaZ-3HyD-28sD.md` — depends on `3HyD` and `28sD`

Confirm the filename before continuing.

## Step 4 — Draft the Plan

The Plan has these sections:

- **Technical Approach** — two or three sentences on how the work
  will be done.
- **Risks & Assumptions** — what might go wrong, what is assumed,
  any `ANTI-PATTERNS.md` conflict to flag.
- **Prior Learnings Considered** — only when Step 1 matched
  something. Per learning: title verbatim, filename in parentheses,
  one line on how the Plan honours it, and `Match reason:
  scope_ref=S-…` or `Match reason: tags matched [tag1, tag2]`.
- **Tasks (3–7)** — each with:
  - **Posture:** `specify-first` | `discover-first` | `iterate` |
    `spike` | `straight-through` per `docs/FRAMEWORK.md § Execution
    Posture`. `straight-through` carries its justification on the
    task line.
  - **Effort:** brief (<1h) | moderate (1–4h) | significant (4h+)
  - **Depends on:** task numbers within this Plan, or none
  - **Routing:** `ai` | `human` — present only when the Plan will
    be `delivery: hybrid`; single-routing Plans inherit the Plan
    level. Draft it as the planner's best guess; `/spades:approve`
    confirms per task.
  - **Description**, **Approach**, **Tests**.
- **Delivery Sequence** — execution order, noting what can run in
  parallel.
- **Testing & Verification** — what passes for code, what evidence
  demonstrates completion otherwise.
- **`deliverable_type`** — `code` (lands via a PR; the default for
  software work), `artefact` (a document, dataset, config), or
  `action` (a one-off human act). This drives `/spades:ship`.

**CLI mode.** Paste the full draft, including the proposed
`deliverable_type`, and ask: *"Does the task breakdown feel right?
Anything I'm underestimating? Should any tasks be human-delivered?"*
Iterate by re-pasting revised sections; confirm `deliverable_type`
via `AskUserQuestion`; then write in Step 5.

**HTML mode.** Confirm only the shape verbally — task count,
headline approach — and go straight to Step 5. The
`deliverable_type` question comes after the page is open (Step 6).

## Step 5 — Write the Plan

### The canonical `.md` (both modes)

```yaml
---
id: P-<plan-slug>-<own-suffix>
id_suffix: <own-suffix>
scope: S-<scope-slug>
title: "<title>"
depends_on: [<dep-suffix-1>, <dep-suffix-2>]    # [] when none
status: draft
delivery: undecided                              # set by /spades:approve
evaluation: undecided                            # set by /spades:evaluate
deliverable_type: code | artefact | action
created: YYYY-MM-DD
updated: YYYY-MM-DD
linear_issue_id: <id>                            # backend: linear, injected in Step 7
---
```

```markdown
# <title>

## Technical Approach

<2–3 sentence summary>

## Risks & Assumptions

- <risk 1>
- <assumption 1>

## Prior Learnings Considered

- *<learning title>* (`<filename>`) — <one-line note>
  Match reason: tags matched [<tag1>, <tag2>]

## Tasks

### Task 1: <title>
- **Posture:** specify-first
- **Effort:** moderate
- **Depends on:** none
- **Routing:** ai                 # hybrid Plans only
- **Description:** <what needs doing>
- **Approach:** <how it will be done>
- **Tests:** <what covers this>

### Task 2: <title>
…

## Delivery Sequence

1. Task 1 (no deps, start immediately)
2. Task 2 (depends on Task 1)
3. Tasks 3 and 4 (parallel, both depend on Task 2)

## Testing & Verification

<overall strategy and what "shipped" looks like>

## Audit Trail

<!-- Appended by /spades:approve, /spades:deliver, /spades:evaluate,
     /spades:ship, /spades:close. -->
```

Omit the Prior Learnings section when nothing matched.

### `worker-html-plan` (HTML mode)

Dispatched in Step 7's wave per `docs/FRAMEWORK.md § worker-html-*`:

- `open_path`: the absolute `output_path` for this skill’s initial review
  presentation; `null` for refreshes or background use, per
  `docs/FRAMEWORK.md § Review-page ownership`.
- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/plan/template.html`
- `output_path`: `.spades/plans/<filename>.html`
- `frontmatter`: `{ id, title, status, scope, deliverable_type,
  delivery, depends_on, created, updated }`, also embedded verbatim
  in `<script id="spades-frontmatter">`
- `routing_ai`, `routing_hybrid`, `routing_human` *(scalars)*: task
  counts by `routing`
- `panel_blockers`, `panel_findings` *(scalars)*: from the Plan's
  `panel_blocking` / `panel_major` / `panel_minor` frontmatter keys
  when a `/spades:review` has stamped them (`panel_findings` is
  `"<major> / <minor>"`); the literal string `not run` when absent
- `blocks`:
  - `tasks` — one card per task. Fields: `num, title_html, posture,
    posture_short, effort, routing, depends_on, description_html,
    approach_html, tests_html`.
  - `objective-banner` — 0 or 1 item `{ id, title }` per
    `docs/FRAMEWORK.md § Objective banner`, inherited from the parent
    Scope's `strategy_link`; else `[]`.
  - `risks-items` — one per Risks & Assumptions bullet. Field: `html`.
  - `delivery-sequence` — one per sequence step. Field: `html`.
  - `audit-events` — one per audit entry. Fields: `date, desc`.
- `prose_sections`: `{ technical_approach_html,
  testing_verification_html }`

Required markers: `tasks`, `risks-items`, `delivery-sequence`,
`audit-events`.

## Step 6 — Confirm `deliverable_type` (HTML mode)

With the page open, ask via `AskUserQuestion`: **`code`** (default)
/ **`artefact`** / **`action`**. A change is a targeted edit to the
`.md` frontmatter followed by a re-dispatch of `worker-html-plan` with
`open_path: null` to refresh the already-presented page.

## Step 7 — Write and mirror (fan-out)

One wave per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`,
every sub-agent in a single assistant message, `subagent_type:
general-purpose`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-plan` | `.spades/plans/P-<…>.md`, written without `linear_issue_id:` | `{ status: ok }` |
| `worker-html-plan` *(HTML mode)* | `.spades/plans/P-<…>.html` per Step 5 | `{ status: ok, path, opened }` |
| `worker-file-scope-audit` | `.spades/scopes/S-<scope-slug>.md` — `status: planning` when it was `scoped`, `updated: <today>`, and `- YYYY-MM-DD: Plan drafted — P-<slug>-<suffix>.` appended. In HTML mode the Scope's `.html` is re-rendered afterwards by `worker-html-scope` with `open_path: null`. | `{ status: ok }` |
| `worker-linear-plan` *(`backend: linear`)* | Linear — a sub-issue under the Scope's parent Issue with the Plan's title and body, labels `ai-planned` and `deliverable_type:<value>`. Carries the resolved worktree context per § Freshness. | `{ status: ok, linear_issue_id }` |

After the wave:

- **All ok** → with `backend: linear`, inject `linear_issue_id` into
  the Plan `.md` (and the `.html` frontmatter block). Record the
  dispatch mode.
- **`worker-file-plan` failed** → abort; a Linear sub-issue may be
  orphaned, so say so.
- **`worker-file-scope-audit` failed** → abort; the Plan exists but
  the Scope's audit trail lacks its entry — surface for a manual
  patch or re-run.
- **`worker-html-plan` failed** → keep the `.md`, surface, continue.
- **`worker-linear-plan` failed** → keep both files, surface, offer
  a retry.

## Step 8 — Confirm and hand off

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

The Plan stays `draft` until `/spades:approve` runs; Deliver-phase work
starts after approval.

## Revision (Edit mode)

1. Read the Plan by ID.
2. Show the current content and the parts the human wants changed.
3. Iterate conversationally (CLI) or via targeted edits and
   re-render (HTML).
4. Write back, preserving `id`, `id_suffix`, `scope`, `created`,
   `depends_on`, `linear_issue_id`; set `updated`.
5. When the Plan was `approved`, ask whether the revision goes back
   through `/spades:approve` (recommended) or stays approved.
