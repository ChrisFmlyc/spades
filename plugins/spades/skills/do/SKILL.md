---
name: do
description: Execute an approved SPADES Plan. Routes to AI-autonomous run, human handoff, or hybrid based on the `delivery:` field set at Approve time. Use after `/spades:approve` has run, when someone says "do this", "execute this plan", "start delivery", or when a Plan is in status `approved`.
version: 3.1.2
---

# /spades:do

You are executing an approved Plan. The Plan's `delivery:` field
(written by `/spades:approve`) tells you who does the work:

- **`ai`** — you run the work autonomously, committing as you go.
- **`human`** — you record the assignment and stand down.
- **`hybrid`** — some tasks AI, some human; per the Plan's per-task
  routing.

You do NOT make the routing decision here. That happened at Approve.

Read `docs/FRAMEWORK.md` § Target Resolution and § Execution Posture
before running — every task declares a posture (`specify-first`,
`discover-first`, `iterate`, `spike`, `straight-through`) and the
posture drives how you build.

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. At the start of
Do, in HTML mode auto-open the Plan's existing `.html` file via the
OPEN_CMD prelude so the human can see what's being executed. In CLI
mode, summarise the Plan in the terminal as today. The
delivery-routing (ai / human / hybrid) and all subsequent task
execution are identical between modes.

## Pre-Flight

1. **Confirm setup + active project.** Abort otherwise.
2. **Resolve the target Plan** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill's parameters:
   - **Artefact type:** Plan (no type-question needed).
   - **Status filter:** `approved`, `delivering` (so resume works).
   - **Zero-candidate suggestion:** `/spades:approve P-…` on a draft
     plan.

   If the human passed a Plan ID, resolve directly; otherwise run the
   interactive picker.
3. **Read the Plan and the parent Scope.**
4. **Verify status.** The Plan must be `status: approved`. If it's
   `draft`, abort and suggest `/spades:approve` first. If it's
   `delivering` already, resume rather than restart.
5. **Verify dependencies.** Read every plan listed in the Plan's
   `depends_on:` field.

   - If any dependency has `status: rejected`, **abort** with a
     pointer to `/spades:plan` for the rejected ancestor.
     Rejections do not cascade silently — the human must explicitly
     replan the rejected ancestor (or mark its dependants
     rejected too) before Do can proceed. See `docs/FRAMEWORK.md §
     Plan Rejection` for the contract.
   - If any dependency is not yet `status: shipped` (still
     `delivering`, `evaluating`, etc.), warn the human:

     > Plan `P-foo-3HyD` depends on `P-bar-28sD`, which is still
     > `delivering`. Do you want to proceed anyway, or wait?

     Offer (via `AskUserQuestion`):
     - **Wait** — abort, suggest finishing the dependency first
     - **Proceed anyway** — record the override in the audit trail
6. **Open the artefact (HTML mode only).** Read `review_format:` from
   `.spades/config`. When `review_format: html`, run the OPEN_CMD
   prelude (`docs/FRAMEWORK.md § OPEN_CMD detection prelude`) and
   open the Plan's `.html` so the human can see what's being executed.
   **In HTML mode the open `.html` IS the review surface — do NOT
   also paste / summarise / restate the Plan body, task list, or
   parent Scope content to the CLI; the human has the browser tab.**
   Short conversational text (delivery-routing acknowledgement,
   "Plan marked delivering" status, error messages, the final
   "Run /spades:evaluate when ready" pointer) stays CLI as today.
   In CLI mode, summarise the Plan inline as today.
   Delivery-routing (ai / human / hybrid) is identical between
   modes. See `docs/FRAMEWORK.md § Output Format → What counts as
   review-form text` for the canonical line.

## Step 1 — Ensure a feature branch (code deliverables)

For `deliverable_type: code` plans, Do-phase commits land on a
feature branch named for this Plan. `/spades:ship` later pushes
that branch and opens the PR. This step creates or confirms the
branch **before** any code work begins.

For `deliverable_type: artefact` or `action`: skip this step
entirely — there's no branch lifecycle.

### Pre-check git state

Run:

```bash
git rev-parse --abbrev-ref HEAD       # current branch
git status --porcelain                # working-tree state
```

Then decide:

- **On main / master, clean tree** → derive branch name (below),
  validate against `/repo:branch`'s regex, then run
  `git switch -c <name>`. Continue to Step 2.
- **On main / master, dirty tree** → abort. Tell the human to
  commit, stash, or discard those unrelated changes first. SPADES
  does NOT silently carry unrelated work onto a new feature branch.
- **On a feature branch named for this Plan** — already in place.
  Record this as a resume in the audit trail; continue to Step 2.
- **On a feature branch named for a different Plan** — warn the
  human via `AskUserQuestion`:
  - *Switch to a new branch off main for this Plan*
  - *Keep working on the current branch (bundling related work)*
  - *Abort*

### Branch name derivation

Source is the Plan's `title:` field. Apply the slug rules from
`/repo:newbranch` § Slug generation:

1. Lowercase.
2. Replace anything outside `[a-z0-9]` with `-`.
3. Collapse `-` runs.
4. Trim leading and trailing `-`.
5. Truncate at the last `-` ≤ 48 chars so the slug fits the
   `/repo:branch` length cap.

Prefix the result with the work type:

- `feat/` for additive code (new feature, new endpoint, new behaviour)
- `fix/` for bug-fix Plans
- `refactor/` for behaviour-preserving restructuring
- Default to `feat/` if unclear, surfacing the assumption to the
  human.

Final branch name must satisfy `/repo:branch`'s regex:
`^(feat|fix|chore|docs|refactor|rnd|hotfix)/[a-z0-9]([a-z0-9-]{0,48}[a-z0-9])?$`

If validation fails (slug ends up empty or invalid), abort and ask
the human to rename the Plan.

Worked example:
- Plan title: `"RAG Pipeline Lookup"` → branch `feat/rag-pipeline-lookup`

### Why `git switch -c`, not `/repo:newbranch`

`/repo:newbranch` creates a *worktree* (separate directory) off a
clean main. For Do-phase use, in-place branch creation is what we
want — Do, Evaluate, and Ship all operate against the same Plan
file's `## Audit Trail` heading and need to share a working tree.

The name-validation rule from `/repo:branch` still applies — same
prefix regex, same slug rules. Only the git primitive differs.

### Hold the branch name for Step 2

After `git switch -c <name>` succeeds, hold `<prefix>/<slug>` in
memory for Step 2's single combined audit-trail entry — Step 1
does NOT write its own line. `/spades:ship` reads the Step-2
combined line later to verify it's pushing the right branch.

## Step 2 — Update Status

Move the Plan to `status: delivering` and `updated: <today>`.

Append a single combined start-line to the Plan's
`## Audit Trail` (mirrors Approve / Evaluate's one-line-per-phase
pattern):

```markdown
- YYYY-MM-DD: Do phase started — routing: <ai|human|hybrid>[, branch: <prefix>/<slug>].
```

The `, branch: …` clause is included when `deliverable_type: code`
(Step 1 created or confirmed the branch) and omitted for
`artefact` / `action` deliverables.

Also update the parent Scope's status to `delivering` if it isn't
already.

When `backend: linear`, mirror the status changes (sub-issue → "Delivering",
parent Issue → "Delivering").

## Step 3 — Route

### Branch A: `delivery: ai`

You execute the Plan autonomously. The order:

1. **Read the full Plan** — every task, every posture, every
   dependency between tasks.
2. **Read `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`.** Your
   work must conform.
3. **Execute tasks in the Plan's Delivery Sequence order.** For each
   task, honour its execution posture (the shared 5-verb set from
   `docs/FRAMEWORK.md` § Execution Posture):
   - **`specify-first`** — write failing tests, then satisfy them.
   - **`discover-first`** — pin current behaviour in tests first,
     then change; or read the existing code/data carefully before
     reshaping.
   - **`iterate`** — reshape or build the area in small steps, each
     leaving the tree green; covers what used to be `refactor-first`.
   - **`spike`** — produce a decision record or follow-up tasks; do
     NOT merge code from a spike.
   - **`straight-through`** — mechanical change; existing tests cover.
4. **Commit as you go.** One commit per task is a reasonable default
   for AI delivery. Use clear, conventional messages.
5. **If you discover the Plan is wrong, STOP.** Do not silently change
   direction. Surface the discrepancy and ask whether to revise the
   Plan (back to `/spades:plan` / `/spades:approve`) or push through
   with a documented deviation noted in the Plan's audit trail.
6. **Do not push, open PRs, or merge.** That is `/spades:ship`'s job.

When all tasks complete, record completion in the audit trail —
**do not transition the Plan status here**. Step 5 owns the single
canonical transition to `evaluating`. Append:

```markdown
- YYYY-MM-DD: Do phase complete — routing: ai. Tasks completed: 4. Commits: <list of SHAs>.
```

Then fall through to Step 5.

### Branch B: `delivery: human`

You record the assignment and stand down. You do NOT start building.

1. Ask the human (via `AskUserQuestion`) who is taking the work:
   - The current human
   - Someone else (free-form name + email)
2. When `backend: linear`, assign the sub-issue to that person.
3. Append to the Plan's audit trail:
   ```markdown
   - YYYY-MM-DD: Do phase complete — routing: human. Assigned to: <name>.
   ```
4. Print a short summary and exit:

   ```
   ✓ Plan handed off: P-rag-pipeline-lookup-3HyD
   ✓ Assigned to:     <name>
   ✓ Status:          delivering (human)

   When complete, re-run /spades:do to mark the Plan ready for
   /spades:evaluate, OR run /spades:evaluate directly once the human
   reports done.
   ```

### Branch C: `delivery: hybrid`

Some tasks are AI; some are human. The Plan's body records per-task
routing as a `- **Routing:** ai | human` bullet under each task (the
canonical format — set by `/spades:plan`'s task template and
confirmed by `/spades:approve` when Hybrid is picked).

1. **Parse each task's Routing field** from the Plan body. If any
   task is missing its Routing field on a `delivery: hybrid` Plan,
   abort and route back to `/spades:approve` — Hybrid Plans MUST
   have a Routing field per task.
2. **Walk each `Routing: ai` task** as in Branch A. Honour the
   Delivery Sequence order and per-task dependencies.
3. **Record each `Routing: human` task** as in Branch B (ask the
   assignee, write the audit trail line, do not start building).
4. **Wait between phases** — if Task 2 (`human`) depends on Task 1
   (`ai`), do Task 1, then stand down. The human must run
   `/spades:do` again when their portion is complete to resume any
   remaining AI tasks.

## Step 4 — Resume Path

If `/spades:do` is re-invoked on a plan already `status: delivering`:

1. Read the audit trail to see what's done.
2. Identify remaining tasks (or remaining human assignments).
3. For AI tasks: continue from where the audit trail left off.
4. For human tasks: ask whether they're complete (move on) or still
   in progress (stand down again).

Never restart a Plan from scratch. The audit trail is the source of
truth for what's already happened.

## Step 5 — Move to Evaluate

When every task is complete (AI portion done, human portion confirmed
done):

1. Plan status → `evaluating`.
2. Parent Scope status → `evaluating` (if all plans under it are done).
3. Append the audit-trail lines. **For Hybrid Plans only**, write
   the canonical complete-line first (Branch C does not write one
   of its own — Branch A wrote one for AI, Branch B wrote one for
   Human, but Hybrid waits until everything is done):
   ```markdown
   - YYYY-MM-DD: Do phase complete — routing: hybrid.
   ```
   Then in both AI and Hybrid cases, write the transition line:
   ```markdown
   - YYYY-MM-DD: Plan ready for evaluation — routing: <ai|hybrid>.
   ```

Print the summary:

```
✓ Plan delivered: P-rag-pipeline-lookup-3HyD
✓ Routing:        ai
✓ Tasks done:     4
✓ Status:         evaluating

Next:
  /spades:evaluate P-rag-pipeline-lookup-3HyD   — verify against criteria
```

## Edge Cases

- **The Plan has no tasks declared.** Abort and route back to
  `/spades:plan` — every Plan must have 3–7 tasks before Do.
- **A task fails (tests don't pass, dependency unavailable).** Stop,
  surface the failure, do not skip and continue. The audit trail
  records the partial state.
- **The human revokes approval mid-delivery.** Update the Plan to
  `status: rejected`, append a rejection note to the audit trail,
  surface the partial state, and ask the human how to clean up.
