---
name: approve
description: Present a SPADES Plan for human review against the approval checklist, then record the routing decision (AI / human / hybrid) on the Plan. Use when a Plan has been drafted and needs approval, when someone says "approve this", "review the plan", "approve P-…", or when a Plan is in status `draft`. The biggest risk in SPADES is a weak Approval gate.
version: 3.3.0
---

# /spades:approve

You are running the Approve gate on a drafted Plan. Approval is a
gate, not a rubber stamp: you walk a fixed checklist with your own
assessment of each point, ask the human for the decision, record the
routing (who does the work), and write the result to the Plan.

Read `docs/FRAMEWORK.md` § .spades/ Local Layout, § Target
Resolution, § Asking the Human, and § Output Format before running.

### Output format

The Plan and its Scope are read from their `.md` files in both
modes. In CLI mode the Plan body is pasted to the terminal alongside
the checklist. In HTML mode the Plan's existing `.html` (written by
`/spades:plan`) is auto-opened via the OPEN_CMD prelude and is the
review surface; the terminal carries the checklist assessments, the
prompts, and the confirmation. After the decision is written, the
`.html` is re-rendered so it shows the new status and audit line.

## Pre-Flight

1. **Confirm setup and active project.** Abort otherwise.
2. **Read `backend:` and `review_format:`** from `.spades/config`.
3. **Resolve the target Plan** per `docs/FRAMEWORK.md § Target
   Resolution` — artefact type Plan; status filter `draft`; zero
   candidates → suggest `/spades:plan S-…`.
4. **Read the Plan `.md` and its parent Scope `.md`.**
5. **Verify ancestors active** per § Target Resolution →
   Parent-status precondition; an `abandoned` Scope or an
   `abandoned` / `archived` Project is a hard abort.
6. **Read `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`.**
7. **Read any panel report** at `.spades/reviews/<plan-id-lower>-*.md`
   for this Plan; its findings feed the checklist.
8. **Open the review surface.** HTML mode: OPEN_CMD the Plan's
   `.html`. CLI mode: paste the Plan body.

Before the checklist, offer the second opinion in one line: *"Want
an independent review first? Run `/spades:review P-<id>`, then
re-run `/spades:approve`."* Continue when the human declines.

## The checklist

Present each check with your own assessment, scaled to the risk:
architecture-touching work gets a deep review, granular low-risk
work a light one.

### 1. Architecture alignment
Conforms to `ARCHITECTURE.md`; uses `PATTERNS.md`; avoids everything
in `ANTI-PATTERNS.md`; names any new dependency, framework, or
pattern it introduces.

### 2. Completeness
Covers the Scope's acceptance criteria; handles the obvious edge
cases and errors; tests match the risk level.

### 3. Feasibility
Buildable as described; realistic effort; task dependencies and
external dependencies (APIs, services, access) accounted for.

### 4. Risk
Assumptions are valid; identified risks are genuine and none are
missing; the worst case is understood; a fallback exists.

### 5. Scope and granularity
Tasks are the right size; the dependency graph to sibling Plans is
correct.

### 6. Deliverable fit
`deliverable_type` matches reality. `code` is PR-able as one
coherent change; `artefact` has a clear home and reference;
`action` has a specific evidence-of-completion criterion.

## Decision — `AskUserQuestion`

1. **Approve** — proceed.
2. **Approve with notes** — acceptable; capture the concerns to
   watch (free-form follow-up).
3. **Revise** — needs changes; capture what (free-form follow-up).
4. **Reject** — the approach is wrong; back to scoping.

## Routing — `AskUserQuestion` (Approve outcomes only)

Same wording as `/spades:evaluate`'s routing question, so the
vocabulary is consistent across the loop:

1. **AI** — `/spades:do` executes autonomously, committing as it
   goes. The typical choice for `code` feature work.
2. **Human** — `/spades:do` records the assignment and stands down.
   The typical choice for `action` deliverables.
3. **Hybrid** — per task. Walk every task: *"Task <N> — '<title>'.
   Who does this one — ai or human?"*, offering the planner's draft
   `Routing:` as the recommended option. Every task carries a
   `- **Routing:** ai | human` bullet before the approval is saved.

## Write the decision (fan-out)

One wave per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`,
`subagent_type: general-purpose`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-plan-approve` | `.spades/plans/P-<…>.md` — frontmatter `status: approved` (or `rejected`, or `draft` on Revise), `delivery: ai \| human \| hybrid`, `updated: <today>`; per-task `Routing:` bullets for hybrid; audit line `- YYYY-MM-DD: Approved by <human> — routing: <routing>. Notes: <notes>.` (or `Revise requested: <notes>.` / `Rejected at approve: <reason>.`) | `{ status: ok }` |
| `worker-file-scope-approve` | `.spades/scopes/S-<…>.md` — `updated: <today>` and a one-line audit entry naming the Plan and decision. The Scope's `status:` stays `planning`; the Plan's own status carries the gate. | `{ status: ok }` |
| `worker-linear-approve` *(`backend: linear`)* | Linear — `record_approval(plan_id, decision, routing, notes)`: comment on the sub-issue, workflow state for `approved` (or `plan-rejected` label on Revise / Reject), routing label `ai-delivered` / `human-delivery` / `hybrid-delivery`. Carries the freshness probe. | `{ status: ok }` |

In HTML mode, re-dispatch `worker-html-plan` after the file write so
the page shows the decision.

After the wave: all ok → record the dispatch mode and confirm; plan
file failed → abort with the error; scope file failed → surface, the
Plan is correct and the Scope needs a manual patch; Linear failed →
keep local files, surface, offer a retry.

## Confirm and hand off

```
✓ Plan approved: P-rag-pipeline-lookup-3HyD
✓ Routing:       ai
✓ Status:        approved
✓ Notes:         "watch for rate limits on the embedding API"

Next:
  /spades:do P-rag-pipeline-lookup-3HyD   — begin delivery
```

**Revise** → the Plan stays `draft`; hand back to `/spades:plan`
with the human's notes. **Reject** → the Plan is `rejected`; discuss
whether the Scope needs revision or a different approach, and start
a fresh Plan rather than patching this one.
