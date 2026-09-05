---
name: do
description: Execute an approved SPADES Plan. Routes to AI-autonomous run, human handoff, or hybrid based on the `delivery:` field set at Approve time. Use after `/spades:approve` has run, when someone says "do this", "execute this plan", "start delivery", or when a Plan is in status `approved`.
version: 3.8.0
---

# /spades:do

You are executing an approved Plan. The routing decision was made at
Approve and lives in the Plan's `delivery:` field:

- **`ai`** — you run the work autonomously, committing as you go.
- **`human`** — you record the assignment and stand down.
- **`hybrid`** — tasks are split by their per-task `Routing:` bullet.

Read `docs/FRAMEWORK.md` § Target Resolution, § Execution Posture,
§ Carry-Forward of SPADES-Owned Artefacts, and § Output Format
before running.

### Output format

The Plan and Scope are read from their `.md` files. HTML mode opens
the Plan's existing `.html` via the OPEN_CMD prelude at the start,
and that page is the human's view of what is being executed; the
terminal carries routing acknowledgements, status lines, errors, and
the hand-off pointer. CLI mode summarises the Plan inline. After
each audit-trail write in HTML mode, re-dispatch `worker-html-plan`
so the page stays current.

## Pre-Flight

1. **Confirm setup and active project.** Abort otherwise.
2. **Read `backend:`, `scm:`, and `review_format:`** from
   `.spades/config`.
3. **Resolve the target Plan** per `docs/FRAMEWORK.md § Target
   Resolution` — artefact type Plan; status filter `approved`,
   `delivering` (so resume works); zero candidates → suggest
   `/spades:approve P-…`.
4. **Read the Plan and its parent Scope.**
5. **Verify ancestors active** per § Target Resolution →
   Parent-status precondition; hard abort on an `abandoned` Scope or
   an `abandoned` / `archived` Project.
6. **Verify status.** `approved` → fresh run. `delivering` → resume
   (Step 4). `draft` → point at `/spades:approve` and stop.
7. **Verify dependencies.** Read every Plan in `depends_on:`.
   - A `rejected` dependency is a hard abort with a pointer to
     `/spades:plan` for that ancestor — rejections do not cascade,
     so the human replans it (or rejects the dependants) first. See
     `docs/FRAMEWORK.md § Plan rejection — no cascade`.
   - A dependency neither `shipped` nor ready on the same Scope branch
     per § Scope Worktrees → ask via `AskUserQuestion`:
     **Wait** (abort, finish the dependency first) / **Proceed
     anyway** (record the override in the audit trail).
8. **Open the review surface** per § Output format.

## Step 1 — Scope worktree

Resolve the parent Scope's branch and enter its worktree per
`docs/FRAMEWORK.md § Scope Worktrees`, using `/repo:newbranch --resume
<branch>`. Scope already created the branch; Do uses it for every Plan,
including artefact/action records. Carry the returned path through every
command and worker dispatch, and record the branch in Step 2's audit line.

Existing commits belong to this branch's PR. Resolve pre-existing
uncommitted changes per § Carry-Forward before editing or committing;
reuse decisions already recorded for this run.

## Step 2 — Mark delivering

Capture an optional one-line description via `AskUserQuestion`:
**Type a brief description** (free-form follow-up, ≤140 characters)
/ **Skip**. For `delivery: ai` the commit messages already carry the
detail, so Skip is typical; for `human` and `hybrid` a description
helps the person picking it up.

Set the Plan to `status: delivering`, `updated: <today>`, and
append one line:

```markdown
- YYYY-MM-DD: Do phase started — routing: <ai|human|hybrid>[, branch: <prefix>/<slug>][ — "<description>"].
```

The branch clause appears for `code` deliverables; the description
clause when one was given. Set the parent Scope to `delivering` if
it is not already. With `backend: linear`, move the sub-issue and
parent Issue to their `delivering` workflow states.

## Step 3 — Route

### A — `delivery: ai`

1. Read the whole Plan: every task, posture, and intra-Plan
   dependency.
2. Read `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`; the
   work conforms to them.
3. Execute tasks in Delivery Sequence order, honouring each posture:
   - **`specify-first`** — write failing tests, then satisfy them.
   - **`discover-first`** — pin current behaviour in tests, or read
     the existing code and data carefully, before changing it.
   - **`iterate`** — small steps, each leaving the tree green.
   - **`spike`** — produce a decision record or follow-up tasks;
     spike code is not merged.
   - **`straight-through`** — a mechanical change covered by
     existing tests.
4. Commit as you go, one commit per task by default, with conventional
   messages. Include the task's changes and approved pending artefacts
   using `docs/FRAMEWORK.md § Carry-Forward → Commit contents`. Verify the
   whole proposed commit, including any pre-existing index entries, and
   preserve excluded staged and unstaged work.
5. When the Plan turns out to be wrong mid-task, stop and surface
   the discrepancy: revise via `/spades:plan` and `/spades:approve`,
   or push through with a documented deviation in the audit trail —
   the human decides.
6. Pushing, opening PRs, and merging belong to `/spades:ship`.

On completion append:

```markdown
- YYYY-MM-DD: Do phase complete — routing: ai. Tasks completed: <n>. Commits: <SHAs>.
```

Continue to Step 5.

### B — `delivery: human`

1. Ask via `AskUserQuestion` who takes the work: **The current
   human** / **Someone else** (free-form name and email).
2. With `backend: linear`, assign the sub-issue.
3. Append `- YYYY-MM-DD: Do phase complete — routing: human.
   Assigned to: <name>.`
4. Print and stop:

   ```
   ✓ Plan handed off: P-rag-pipeline-lookup-3HyD
   ✓ Assigned to:     <name>
   ✓ Status:          delivering (human)

   When the work is done, run /spades:evaluate P-… (or re-run
   /spades:do to confirm completion first).
   ```

### C — `delivery: hybrid`

Every task carries a `- **Routing:** ai | human` bullet (written by
`/spades:approve`); a hybrid Plan missing one goes back to
`/spades:approve`.

1. Walk `Routing: ai` tasks as in A, in Delivery Sequence order.
2. Record `Routing: human` tasks as in B.
3. When an AI task depends on a human task, stop at the boundary
   and stand down; the human re-runs `/spades:do` after their
   portion, and Step 4 resumes the remaining AI tasks.

## Step 4 — Resume

On a Plan already `delivering`:

1. Read the audit trail to see what is done.
2. Identify the remaining tasks or human assignments.
3. AI tasks continue from where the trail left off.
4. Human tasks: ask whether they are complete (continue) or still in
   progress (stand down again).

The audit trail is the source of truth; a resumed Plan picks up, it
does not restart.

## Step 5 — Move to Evaluate

When every task is complete (AI portion done, human portion
confirmed):

1. Plan `status: evaluating`.
2. Parent Scope `status: evaluating` when every Plan under it has
   reached Evaluate.
3. For hybrid Plans append `- YYYY-MM-DD: Do phase complete —
   routing: hybrid.` first. Then, for AI and hybrid Plans, append
   `- YYYY-MM-DD: Plan ready for evaluation — routing: <ai|hybrid>.`

```
✓ Plan delivered: P-rag-pipeline-lookup-3HyD
✓ Routing:        ai
✓ Tasks done:     4
✓ Status:         evaluating

Next:
  /spades:evaluate P-rag-pipeline-lookup-3HyD   — verify against criteria
```

## Edge cases

- **No tasks declared** → back to `/spades:plan`; a Plan carries 3–7
  tasks before Do.
- **A task fails** (tests, unavailable dependency) → stop, surface
  it, leave the partial state recorded in the audit trail.
- **Approval revoked mid-delivery** → Plan `status: rejected`, a
  rejection note in the audit trail, surface the partial state, and
  ask the human how to clean up.
