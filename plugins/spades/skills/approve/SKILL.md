---
name: approve
description: Present a SPADES Plan for human review against the approval checklist, then record the routing decision (AI / human / hybrid) on the Plan. Use when a Plan has been drafted and needs approval, when someone says "approve this", "review the plan", "approve P-…", or when a Plan is in status `draft`. The biggest risk in SPADES is a weak Approval gate.
version: 3.0.0
---

# /spades:approve

You are running the Approve gate on a drafted Plan. Approval is a gate,
not a rubber stamp. You walk the human through a fixed checklist, ask
for the routing decision (who does the work — AI, human, or hybrid),
and write the result back to the Plan record.

Read `docs/FRAMEWORK.md` § .spades/ Local Layout, § Target
Resolution, and § Asking the Human before running.

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. Anywhere this
skill would today paste the Plan body (and optionally the parent
Scope) to the terminal for the human's approval review, in HTML
mode it auto-opens the Plan's existing `.html` file (already written
by `/spades:plan`) via the OPEN_CMD prelude instead. The approval
prompts and audit-trail writes stay identical between modes.

## Pre-Flight

1. **Confirm setup + active project.** Abort otherwise.
2. **Resolve the target Plan** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill's parameters:
   - **Artefact type:** Plan (no type-question needed).
   - **Status filter:** `draft`.
   - **Zero-candidate suggestion:** `/spades:plan S-…` to draft a
     plan on a Scope.

   If the human passed a Plan ID, resolve directly; otherwise run the
   interactive picker.
3. **Read the Plan file** at `.spades/plans/<filename>.md` plus its
   parent Scope at `.spades/scopes/S-<scope-slug>.md`.
4. **Read `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`** so you
   can assess alignment.

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

- **Yes, run `/spades:review`** on this Scope + Plan
- **No, skip**

If yes, invoke `/spades:review` in Full Review mode (Scope + Plan
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
`/spades:evaluate`'s evaluation-routing question, so the human gets
a consistent vocabulary across the loop:

1. **AI** — `/spades:do` will execute autonomously, committing as it
   goes.
2. **Human** — `/spades:do` records the assignment in the backend;
   a human picks this up and does the work.
3. **Hybrid** — split per task. AI does its tasks, then hands off to
   a human for theirs. Per-task routing is recorded as a
   `- **Routing:** ai | human` bullet under each task in the Plan
   body (the Plan template already provisions this field; see
   `/spades:plan` § Tasks).

   When the human picks Hybrid, walk each task and ask:

   > *Task <N> — "<title>". Who does this one — ai or human?*

   Update the Plan body's Routing field for each task accordingly.
   If the Plan was drafted with Routing guesses by `/spades:plan`,
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

## Write the Decision

Update the Plan file's frontmatter:

- `status: approved` (or `rejected` / keep `draft` for revise)
- `delivery: ai | human | hybrid | undecided`
- `updated: <today>`

Append to the Plan's `## Audit Trail`:

```markdown
- YYYY-MM-DD: Approved by <human> — routing: ai. Notes: <any notes>.
```

Update the parent Scope:
- `status: approval` (if it was `planning`)
- `updated: <today>`

## Backend Mirror

### When `backend: linear`

Call the backend's `record_approval(plan_id, decision, routing, notes)`.
The Linear driver:

1. Posts a comment on the Plan's sub-issue with the approval decision
   and routing.
2. Updates the sub-issue status to "Approval" (or "Delivering" if
   immediately handing off to AI).
3. Applies labels for the routing (`ai-delivered`, `human-delivery`,
   `hybrid-delivery`).

If the Linear write fails, the local file is canonical; surface and
offer retry.

### When `backend: local`

The local file IS canonical. Nothing else.

## Confirm and Hand Off

```
✓ Plan approved: P-rag-pipeline-lookup-3HyD
✓ Routing:       ai (auto-delivery)
✓ Status:        approved
✓ Notes:         "watch for rate limits on the embedding API"

Next:
  /spades:do P-rag-pipeline-lookup-3HyD   — begin delivery
```

## If Revise

- Apply a `plan-rejected` label (Linear) or note (local).
- Hand back to `/spades:plan` to apply the human's feedback.
- Do NOT begin Do-phase work.

## If Reject

- Apply `plan-rejected`.
- Discuss with the human whether the Scope itself needs revision or a
  different approach is needed.
- Do NOT attempt to salvage the Plan after a hard reject.
