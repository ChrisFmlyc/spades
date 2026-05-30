---
name: plan
description: Generate a structured SPADES Plan from a Scope. A Plan is a unit of executable work with an ID like `P-<description-slug>-<4-char-suffix>[-<dep-suffix>…]`. Plans can depend on prior plans within the same scope. Use when a Scope exists and the human wants to move to planning, when someone says "plan this", "break this down", "generate a plan", or when a scope is in status `scoped`/`planning`.
version: 2.1.0
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
4. **Verify Scope readiness.** If the Scope is missing required fields,
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

Propose the full draft Plan, then ask: *"Does the task breakdown feel
right? Anything I'm underestimating? Should any tasks be human-delivered
instead?"* Iterate until the human is satisfied; do NOT write the file
yet.

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
- **Posture**: `test-first` | `characterization-first` | `refactor-first`
  | `spike` | `straight-through`. See `docs/FRAMEWORK.md` § Execution
  Posture. No silent defaults — if you pick `straight-through`,
  justify it on the task line.
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

### Deliverable Type

Ask the human (via `AskUserQuestion`):
- **`code`** — produces code merged via a PR (default for software work)
- **`artefact`** — produces a tangible thing (document, dataset, config)
- **`action`** — a one-off human action (server install, vendor call)

This drives what `/spades:ship` does later.

## Step 5 — Write the Plan File

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
- **Posture:** test-first
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

## Step 6 — Update Scope Status

Update the parent Scope's frontmatter:
- `status: planning` (if it was `scoped`)
- `updated: <today>`

Append to the Scope's `## Audit Trail`:

```markdown
- YYYY-MM-DD: Plan drafted — P-<slug>-<suffix>
```

## Step 7 — Backend Mirror

### When `backend: linear`

After the local file is written:

1. Create a sub-issue under the parent Scope Issue with title and
   description matching the Plan.
2. Apply labels: `ai-planned`, plus the `deliverable_type:<value>` label.
3. Capture the new sub-issue ID and write it back to the local file's
   `linear_issue_id:` frontmatter.

If the Linear write fails, the local file is canonical; surface the
failure to the human and offer a retry.

### When `backend: local`

The local file IS canonical. Nothing else to mirror.

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
