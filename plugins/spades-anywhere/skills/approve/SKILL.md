---
name: approve
description: Present a SPADES Plan for human review against the approval checklist, then record the routing decision (AI / human / hybrid) on the Plan. Use when a Plan has been drafted and needs approval, when someone says "approve this", "review the plan", "approve P-…", or when a Plan is in status `draft`. The biggest risk in SPADES is a weak Approval gate.
version: 0.1.0
---

# /spades-anywhere:approve

You are running the Approve gate on a drafted Plan. Approval is a gate,
not a rubber stamp. You walk the human through a fixed checklist, ask
for the routing decision (who does the work — AI, human, or hybrid),
and write the result back to the Plan record.

Read `docs/FRAMEWORK.md` § .spades-anywhere/ Local Layout, § Target
Resolution, and § Asking the Human before running.

### Output format

This skill honours `review_format:` from `.spades-anywhere/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. Anywhere this
skill would today paste the Plan body (and optionally the parent
Scope) to the terminal for the human's approval review, in HTML
mode it auto-opens the Plan's existing `.html` file (already written
by `/spades-anywhere:plan`) via the OPEN_CMD prelude instead. The approval
prompts and audit-trail writes stay identical between modes.

## Pre-Flight

1. **Confirm setup + active project.** Abort otherwise.
2. **Resolve the target Plan** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill's parameters:
   - **Artefact type:** Plan (no type-question needed).
   - **Status filter:** `draft`.
   - **Zero-candidate suggestion:** `/spades-anywhere:plan S-…` to draft a
     plan on a Scope.

   If the human passed a Plan ID, resolve directly; otherwise run the
   interactive picker.
3. **Read the Plan file.** Locate `.spades-anywhere/plans/<filename>.<ext>`
   where `<ext>` is `md` in CLI mode and `html` in HTML mode (read
   `review_format:` from `.spades-anywhere/config` first). Same for the parent
   Scope at `.spades-anywhere/scopes/S-<scope-slug>.<ext>`.
4. **Read `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`** so you
   can assess alignment.
5. **Open the artefact (HTML mode only).** When `review_format: html`,
   run the OPEN_CMD prelude from
   `docs/FRAMEWORK.md § OPEN_CMD detection prelude` and open
   `.spades-anywhere/plans/<filename>.html` so the human can review it in the
   browser. Do NOT also paste the plan body to the CLI in this mode —
   the browser view is the review surface. In CLI mode, present the
   Plan body in the terminal as the existing checklist describes.

## The Approval Checklist

Present each check with your own assessment, then ask for the human's
decision. Scale review depth to the risk — architecture-touching work
gets a deep review; granular low-risk tasks get a light one.

### 1. Architecture Alignment

- Does the Plan conform to `ARCHITECTURE.md`?
- Does it use approved patterns from `PATTERNS.md`?
- Does it avoid everything in `ANTI-PATTERNS.md`?
- Any new dependencies, frameworks, or major patterns being introduced?

**Your assessment:** <state alignment, flag concerns>

### 2. Completeness

- Are there obvious gaps or missing edge cases?
- Does the Plan cover the Scope's acceptance criteria?
- Is error handling addressed?
- Is the testing approach sufficient for the risk level?

**Your assessment:** <state any gaps>

### 3. Feasibility

- Can this actually be built this way?
- Are effort estimates realistic?
- Are task dependencies correctly identified?
- Are external dependencies (APIs, services, access) accounted for?

**Your assessment:** <state feasibility>

### 4. Risk

- Are the AI's assumptions valid?
- Are identified risks genuine? Anything missing?
- What is the worst case if the Plan is wrong?
- Is there a fallback approach?

**Your assessment:** <state risk picture>

### 5. Scope and Granularity

- Is the task breakdown at the right size?
- Tasks too big? Too small? Should some merge or split?
- Is the dependency graph between this Plan and other Plans in the same
  Scope correct?

**Your assessment:** <state granularity>

### 6. Deliverable Fit

- Does the Plan's `deliverable_type:` match reality? (`code` vs
  `artefact` vs `action`)
- For `code`: is the work PR-able as a single coherent change?
- For `artefact`: is the artefact form clear (where it'll live, how
  it'll be referenced)?
- For `action`: is the evidence-of-completion criterion specific?

**Your assessment:** <state deliverable fit>

## Optional Second Opinion

Before the decision step, offer (via `AskUserQuestion`):

- **Yes, run `/spades-anywhere:review`** on this Scope + Plan
- **No, skip**

If yes, invoke `/spades-anywhere:review` in Full Review mode (Scope + Plan
together). After the review, resume here.

This is always optional and never replaces the checklist.

## Decision

Ask the human (via `AskUserQuestion`):

1. **Approve** — Plan is good. Proceed.
2. **Approve with notes** — Plan is acceptable; note concerns to watch.
3. **Revise** — Plan needs changes. Specify what.
4. **Reject** — Fundamental approach is wrong. Back to scoping.

When "Approve with notes" or "Revise" is chosen, follow up with a
free-form prompt for the notes.

## Routing Decision (Only When Approved)

If the decision was Approve or Approve-with-notes, ask via
`AskUserQuestion`. The three options use the same wording as
`/spades-anywhere:evaluate`'s evaluation-routing question, so the human gets
a consistent vocabulary across the loop:

1. **AI** — `/spades-anywhere:do` will execute autonomously, committing as it
   goes.
2. **Human** — `/spades-anywhere:do` records the assignment in the backend;
   a human picks this up and does the work.
3. **Hybrid** — split per task. AI does its tasks, then hands off to
   a human for theirs. Per-task routing is recorded as a
   `- **Routing:** ai | human` bullet under each task in the Plan
   body (the Plan template already provisions this field; see
   `/spades-anywhere:plan` § Tasks).

   When the human picks Hybrid, walk each task and ask:

   > *Task <N> — "<title>". Who does this one — ai or human?*

   Update the Plan body's Routing field for each task accordingly.
   If the Plan was drafted with Routing guesses by `/spades-anywhere:plan`,
   show those guesses as the recommended option in the per-task
   AskUserQuestion; the human can accept or revise.

   Plans MUST have a Routing field on every task before approval
   completes when `delivery: hybrid`. If any task is missing it,
   refuse to save the approval and re-prompt.

Notes:
- For `deliverable_type: action` (server install, vendor call),
  Human is the typical choice.
- For `deliverable_type: code` on standard feature work, AI is the
  typical choice.

## Write the Decision (fan-out dispatch)

Apply the fan-out pattern from
`docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`. Spawn the
following sub-agents **in parallel in a single assistant message
with multiple `Agent` tool calls** (`subagent_type:
general-purpose`):

| Sub-agent | Resource owned | Returns |
|-----------|---------------|---------|
| `worker-file-plan-approve` | `.spades-anywhere/plans/P-<…>.<ext>` — update frontmatter (`status: approved` \| `rejected` \| keep `draft`; `delivery: ai \| human \| hybrid \| undecided`; `updated: <today>`) and append to audit trail: `- YYYY-MM-DD: Approved by <human> — routing: <routing>. Notes: <any notes>.` For `delivery: hybrid` also write the per-task Routing fields under each task. | `{ status: ok }` |
| `worker-file-scope-approve` | `.spades-anywhere/scopes/S-<scope-slug>.<ext>` — update Scope frontmatter (`updated: <today>` only; status stays at `planning` — the Plan's own `status: approved` carries the approval gate decision; the Scope advances when the first child Plan transitions into `delivering`) and append a short audit-trail entry referencing the plan ID. | `{ status: ok }` |
| `worker-linear-approve` *(only when `backend: linear`)* | Linear — call `record_approval(plan_id, decision, routing, notes)`: (1) post a comment on the Plan's sub-issue with decision + routing, (2) update sub-issue status to "Approval" (or "Delivering" for immediate AI hand-off), (3) apply routing label (`ai-delivered`, `human-delivery`, `hybrid-delivery`). Includes the Layer-2 freshness probe. | `{ status: ok }` |

No back-write — `linear_issue_id` is already in the Plan file from
`/spades-anywhere:plan`. After sub-agents return, the coordinator collects
results per the failure semantics in
`FRAMEWORK.md § Sub-agent Dispatch`:

- **All ok** → record dispatch mode and proceed to Confirm.
- **`worker-file-plan-approve` failed** → abort with the error;
  surface partial state to the human.
- **`worker-file-scope-approve` failed** → surface the failure;
  the plan file is correct, scope rollup needs manual patch.
- **`worker-linear-approve` failed** → keep local files
  (canonical), surface the Linear failure, offer retry. Do NOT
  block.

### When `backend: local`

Only the two file sub-agents are dispatched (no Linear). Local
files are canonical.

## Confirm and Hand Off

```
✓ Plan approved: P-rag-pipeline-lookup-3HyD
✓ Routing:       ai (auto-delivery)
✓ Status:        approved
✓ Notes:         "watch for rate limits on the embedding API"

Next:
  /spades-anywhere:do P-rag-pipeline-lookup-3HyD   — begin delivery
```

## If Revise

- Apply a `plan-rejected` label (Linear) or note (local).
- Hand back to `/spades-anywhere:plan` to apply the human's feedback.
- Do NOT begin Do-phase work.

## If Reject

- Apply `plan-rejected`.
- Discuss with the human whether the Scope itself needs revision or a
  different approach is needed.
- Do NOT attempt to salvage the Plan after a hard reject.
