---
name: approve
description: Present a SPADES Plan for human review against the approval checklist, then record the routing decision (human / hybrid) on the Plan. Use when a Plan has been drafted and needs approval, when someone says "approve this", "review the plan", "approve P-…", or when a Plan is in status `draft`. The biggest risk in SPADES is a weak Approval gate.
version: 0.2.0
---

# /spades-anywhere:approve

You are running the Approve gate on a drafted Plan. Approval is a
gate, not a rubber stamp: you walk a fixed checklist with your own
assessment of each point, ask the human for the decision, record
the routing (`human` or `hybrid` — the human does the work in
`spades-anywhere`; the AI at most assists), and write the result to
the Plan.

Read `docs/FRAMEWORK.md` § .spades-anywhere/ Local Layout, § Target
Resolution, § Asking the Human, and § Output Format before running.

### Output format

The Plan and Scope are read from their `.md` files. CLI mode pastes
the Plan body alongside the checklist. HTML mode opens the Plan's
existing `.html` via the OPEN_CMD prelude as the review surface;
the terminal carries the assessments, prompts, and confirmation.
After the decision is written in HTML mode, re-render the `.html`.

## Pre-Flight

1. **Confirm setup and active project.**
2. **Read `backend:` and `review_format:`.**
3. **Resolve the target Plan** per `docs/FRAMEWORK.md § Target
   Resolution` — status filter `draft`; zero candidates →
   `/spades-anywhere:plan S-…`.
4. **Read the Plan `.md` and its parent Scope `.md`.**
5. **Verify ancestors active**; hard abort on an `abandoned` Scope or
   an `abandoned` / `archived` Project.
6. **Read `INTENT.md`, `ARCHITECTURE.md`, `PATTERNS.md`,
   `ANTI-PATTERNS.md`.**
7. **Read any panel report** at
   `.spades-anywhere/reviews/<plan-id-lower>-*.md`.
8. **Open the review surface** per § Output format.

Before the checklist, offer the second opinion in one line: *"Want
an independent review first? Run `/spades-anywhere:review P-<id>`,
then re-run `/spades-anywhere:approve`."*

## The checklist

Present each check with your own assessment, scaled to the risk.

### 1. Alignment
Serves `INTENT.md`; fits the operating model in `ARCHITECTURE.md`;
follows `PATTERNS.md`; avoids everything in `ANTI-PATTERNS.md`;
names any new tool, vendor, or commitment it introduces.

### 2. Completeness
Covers the Scope's acceptance criteria; handles the obvious
contingencies; the evidence per task is specific.

### 3. Feasibility
Doable as described; realistic effort; task dependencies and
external dependencies (people, bookings, access) accounted for.

### 4. Risk
Assumptions valid; risks genuine and none missing; the worst case
understood; a fallback exists.

### 5. Scope and granularity
Tasks the right size; the dependency graph to sibling Plans correct.

### 6. Deliverable fit
`deliverable_type` matches reality: `artefact` has a clear home and
reference; `action` has a specific evidence-of-completion criterion.

## Decision — `AskUserQuestion`

1. **Approve.**
2. **Approve with notes** — capture the concerns (free-form).
3. **Revise** — capture what changes (free-form).
4. **Reject** — the approach is wrong; back to scoping.

## Routing — `AskUserQuestion` (Approve outcomes only)

1. **Human** — the human does every task; `/spades-anywhere:do`
   marks the start and restates the acceptance criteria.
2. **Hybrid** — per task. Walk every task: *"Task <N> — '<title>'.
   Who does this one — human, or ai (the AI drafts, researches, or
   structures; you act)?"*, offering the planner's draft as the
   recommended option. Every task carries a `- **Routing:** human |
   ai` bullet before the approval is saved.

## Write the decision (fan-out)

One wave per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-plan-approve` | `.spades-anywhere/plans/P-<…>.md` — `status: approved` (or `rejected`, or `draft` on Revise), `delivery: human \| hybrid`, `updated: <today>`, per-task `Routing:` for hybrid, audit line `- YYYY-MM-DD: Approved by <human> — routing: <routing>. Notes: <notes>.` (or `Revise requested: …` / `Rejected at approve: …`) | `{ status: ok }` |
| `worker-file-scope-approve` | `.spades-anywhere/scopes/S-<…>.md` — `updated: <today>` and a one-line audit entry; the Scope stays `planning` | `{ status: ok }` |
| `worker-linear-approve` *(`backend: linear`)* | Linear — `record_approval(plan_id, decision, routing, notes)`: a comment on the sub-issue, the `approved` workflow state (or `plan-rejected` label), routing label `human-delivery` / `hybrid-delivery` | `{ status: ok }` |

In HTML mode, re-render the Plan's `.html` after the write. After
the wave: all ok → record the dispatch mode; plan file failed →
abort; scope file failed → surface for a manual patch; Linear
failed → keep local files, offer a retry.

## Confirm and hand off

```
✓ Plan approved: P-book-the-venue-3HyD
✓ Routing:       human
✓ Status:        approved
✓ Notes:         "confirm the deposit is refundable before paying"

Next:
  /spades-anywhere:do P-book-the-venue-3HyD   — start the work
```

**Revise** → the Plan stays `draft`; back to `/spades-anywhere:plan`
with the notes. **Reject** → `rejected`; discuss whether the Scope
needs revision, and start a fresh Plan.
