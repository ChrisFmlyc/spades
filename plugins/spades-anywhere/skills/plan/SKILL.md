---
name: plan
description: Generate a structured SPADES Plan from a Scope. A Plan is a unit of executable work with an ID like `P-<description-slug>-<4-char-suffix>[-<dep-suffix>…]`. Plans can depend on prior plans within the same scope. Use when a Scope exists and the human wants to move to planning, when someone says "plan this", "break this down", "generate a plan", or when a scope is in status `scoped`/`planning`.
version: 0.3.0
---

# /spades-anywhere:plan

You are drafting a Plan for a Scope. A Plan is a first-class
artefact: written to `.spades-anywhere/plans/`, mirrored to the
backend, and gated at `/spades-anywhere:approve` before the human
starts the work. Plans can depend on earlier Plans in the same
Scope; the dependency chain is encoded in the filename and held in
`depends_on:`.

Read `docs/FRAMEWORK.md` § ID Format, § .spades-anywhere/ Local
Layout, § Target Resolution, § Execution Posture, and § Output
Format before running.

### Output format

- **Both modes** — `.spades-anywhere/plans/P-<…>.md`, the canonical
  record.
- **HTML mode** — additionally `.spades-anywhere/plans/P-<…>.html`
  from `${CLAUDE_PLUGIN_ROOT}/skills/plan/template.html`,
  auto-opened as the review surface; iteration is a targeted `.md`
  edit plus a re-render.
- **CLI mode** — Step 4 pastes the draft and iterates before Step 5
  writes it.

## Pre-Flight

1. **Confirm setup and active project.**
2. **Read `backend:` and `review_format:`.**
3. **Resolve the target Scope** per `docs/FRAMEWORK.md § Target
   Resolution` — status filter `scoped`, `planning`; zero candidates
   → `/spades-anywhere:scope <title>`.
4. **Verify ancestors active** per § Target Resolution →
   Parent-status precondition; hard abort on an `abandoned` Scope or
   an `abandoned` / `archived` Project.
5. **Verify Scope readiness** — a Scope missing required sections
   goes back to `/spades-anywhere:scope <slug>` (Edit mode).

## Step 1 — Read context

1. **The Scope** — intent, acceptance criteria, constraints,
   dependencies, risks.
2. **`INTENT.md`, `ARCHITECTURE.md`, `PATTERNS.md`,
   `ANTI-PATTERNS.md`** — the Plan conforms to them; a conflict is
   flagged in Risks & Assumptions for the human at Approve.
3. **Prior learnings.** Glob `.spades-anywhere/learnings/*.md`,
   skipping `private/` and `status: archived`. A learning matches
   on `scope_ref` equal to this Scope, or on `tags` appearing in the
   Scope's title or `ARCHITECTURE.md`. Under 20 active learnings one
   tag suffices; from 20 upward require two.
4. **Existing Plans under this Scope** via `list_plans(scope_id)`.

## Step 2 — Show your understanding

Summarise the Scope in three or four sentences; the human confirms
or corrects before any tasks are drafted.

## Step 3 — Identify the Plan

Ask for a short title. Derive the slug as for Scopes. Mint a random
4-character base62 suffix, re-minting on collision under this
Scope. Ask about dependencies via `AskUserQuestion`: **No
dependencies** / **Depends on `<P-…>`** / **Depends on multiple**
(free-form list). Compose
`P-<plan-slug>-<own-suffix>[-<dep-suffix>…].md` and confirm it.

## Step 4 — Draft the Plan

Sections:

- **Approach** — two or three sentences on how the work will be
  done.
- **Risks & Assumptions** — what might go wrong, what is assumed,
  any `ANTI-PATTERNS.md` conflict.
- **Prior Learnings Considered** — only when Step 1 matched
  something: title, filename, one line on how the Plan honours it,
  and `Match reason: …`.
- **Tasks (3–7)** — each with:
  - **Posture:** `specify-first` | `discover-first` | `iterate` |
    `spike` | `straight-through` per `docs/FRAMEWORK.md § Execution
    Posture`; `straight-through` carries its justification.
  - **Effort:** brief (<1h) | moderate (1–4h) | significant (4h+)
  - **Depends on:** task numbers, or none
  - **Routing:** `human` | `ai` — present only when the Plan will be
    `delivery: hybrid`. `ai` means the AI assists (a draft, a
    research summary, an outline); the human still acts. Draft it
    as a best guess; `/spades-anywhere:approve` confirms per task.
  - **Description**, **Approach**, **Evidence** (what shows this
    task is done).
- **Delivery Sequence** — order, noting what can run in parallel.
- **Testing & Verification** — the evidence that demonstrates
  completion overall; what "shipped" looks like.
- **`deliverable_type`** — `artefact` (a document, a booking record,
  a dataset) or `action` (a party hosted, a call made, an interview
  run). This drives `/spades-anywhere:ship`.

**CLI mode.** Paste the full draft with the proposed
`deliverable_type`; ask *"Does the breakdown feel right? Anything
I'm underestimating? Should the AI help with any task?"*; iterate;
confirm `deliverable_type` via `AskUserQuestion`; write in Step 5.

**HTML mode.** Confirm the shape verbally and go to Step 5; the
`deliverable_type` question comes once the page is open (Step 6).

## Step 5 — Write the Plan

### The canonical `.md` (both modes)

```yaml
---
id: P-<plan-slug>-<own-suffix>
id_suffix: <own-suffix>
scope: S-<scope-slug>
title: "<title>"
depends_on: [<dep-suffix-1>]           # [] when none
status: draft
delivery: undecided                    # set by /spades-anywhere:approve (human | hybrid)
evaluation: human
deliverable_type: artefact | action
created: YYYY-MM-DD
updated: YYYY-MM-DD
linear_issue_id: <id>                  # backend: linear, injected in Step 7
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
- **Posture:** discover-first
- **Effort:** moderate
- **Depends on:** none
- **Routing:** human               # hybrid Plans only
- **Description:** <what needs doing>
- **Approach:** <how it will be done>
- **Evidence:** <what shows it is done>

### Task 2: <title>
…

## Delivery Sequence

1. Task 1 (no deps, start immediately)
2. Task 2 (depends on Task 1)

## Testing & Verification

<the evidence that demonstrates completion; what "shipped" looks like>

## Audit Trail

<!-- Appended by /spades-anywhere:approve, do, evaluate, ship, close. -->
```

Omit Prior Learnings when nothing matched. The `## Technical
Approach` heading is the schema's name for the approach section.

### The `.html` (HTML mode)

Rendered from `${CLAUDE_PLUGIN_ROOT}/skills/plan/template.html` to
`.spades-anywhere/plans/<filename>.html` per `docs/FRAMEWORK.md §
Output Format → HTML rendering`:

- `frontmatter`: `{ id, title, status, scope, deliverable_type,
  delivery, depends_on, created, updated }`, embedded verbatim in
  `<script id="spades-frontmatter">`
- `routing_ai`, `routing_hybrid`, `routing_human` *(scalars)*: task
  counts by `routing`
- `panel_blockers`, `panel_findings` *(scalars)*: from
  `panel_blocking` / `panel_major` / `panel_minor` frontmatter keys
  when a review stamped them (`"<major> / <minor>"`); the literal
  `not run` when absent
- `blocks`:
  - `tasks` — one card per task. Fields: `num, title_html, posture,
    posture_short, effort, routing, depends_on, description_html,
    approach_html, tests_html` (the Evidence bullet).
  - `objective-banner` — 0 or 1 item `{ id, title }`, inherited from
    the parent Scope's `strategy_link`; else `[]`.
  - `risks-items` — one per Risks & Assumptions bullet. Field: `html`.
  - `delivery-sequence` — one per step. Field: `html`.
  - `audit-events` — one per audit entry. Fields: `date, desc`.
- `prose_sections`: `{ technical_approach_html,
  testing_verification_html }`

Required markers: `tasks`, `risks-items`, `delivery-sequence`,
`audit-events`.

## Step 6 — Confirm `deliverable_type` (HTML mode)

With the page open, ask via `AskUserQuestion`: **`artefact`** /
**`action`**. A change is a targeted `.md` edit plus a re-render.

## Step 7 — Write and mirror (fan-out)

One wave per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-plan` | `.spades-anywhere/plans/P-<…>.md`, without `linear_issue_id:` | `{ status: ok }` |
| `worker-html-plan` *(HTML mode)* | `.spades-anywhere/plans/P-<…>.html` | `{ status: ok, path, opened }` |
| `worker-file-scope-audit` | `.spades-anywhere/scopes/S-<…>.md` — `status: planning` when it was `scoped`, `updated: <today>`, `- YYYY-MM-DD: Plan drafted — P-<slug>-<suffix>.` appended; re-render the Scope's `.html` afterwards in HTML mode | `{ status: ok }` |
| `worker-linear-plan` *(`backend: linear`)* | Linear — a sub-issue under the Scope's parent Issue with the Plan's title and body, labels `ai-planned` and `deliverable_type:<value>` | `{ status: ok, linear_issue_id }` |

After the wave: all ok → with Linear, inject `linear_issue_id` into
the Plan `.md` (and `.html`), record the dispatch mode; plan file
failed → abort, noting a possible orphaned sub-issue; scope audit
failed → abort, surface for a manual patch; HTML failed → keep the
`.md`, continue; Linear failed → keep both files, offer a retry.

## Step 8 — Confirm and hand off

```
✓ Plan drafted: P-book-the-venue-3HyD
✓ Scope:        S-plan-the-birthday-party
✓ Depends on:   []
✓ Tasks:        4
✓ Deliverable:  action
✓ Status:       draft

Next:
  /spades-anywhere:approve P-book-the-venue-3HyD    — review and approve
```

The Plan stays `draft` until approved; the work starts after
`/spades-anywhere:do`.

## Revision (Edit mode)

Read the Plan by ID, show the parts to change, iterate (CLI) or
edit and re-render (HTML), write back preserving `id`, `id_suffix`,
`scope`, `created`, `depends_on`, `linear_issue_id`, and set
`updated`. An `approved` Plan is offered a trip back through
`/spades-anywhere:approve`.
