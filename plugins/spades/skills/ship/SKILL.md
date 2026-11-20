---
name: ship
description: Ships the deliverable produced by an approved Plan after evaluation. Branches on `deliverable_type:` — code gets a GitHub PR or GitLab MR + review + merge; artefact gets a recorded reference (URL, path, doc ID); action gets evidence of completion. Use after `/spades:evaluate` has issued a PASS, when someone says "ship this", "release this", "merge it", or when a Plan is in status `evaluating` with a PASS verdict or in status `shipping`.
version: 3.8.1
---

# /spades:ship

Ship the evaluated Plan's deliverable: publish its PR, record its artefact
reference, or record evidence of the completed action.

Read `docs/FRAMEWORK.md` § Hierarchy (`deliverable_type`), § Target
Resolution, § Audit Trail (the `Shipped` marker), § Carry-Forward of
SPADES-Owned Artefacts, and § Output Format before running.

### Output format

The Plan and Scope are read from their `.md` files. HTML mode opens the
target Plan's existing `.html` as the review page for shipping. The
Scope is background context. The terminal carries progress, driver
messages, prompts and the final confirmation; CLI mode presents the Plan
in the CLI review pane (`docs/FRAMEWORK.md § CLI review pane`) on the
ship confirmation question. After each audit-trail write in HTML mode,
re-dispatch `worker-html-plan` and, when needed, `worker-html-scope`,
both with `open_path: null`. These refreshes keep the files current
while the Plan remains the active review page.

## Pre-Flight

1. **Confirm setup and active project.** Abort otherwise.
2. **Read `backend:`, `scm:`, and `review_format:`** from
   `.spades/config`.
3. **Resolve the target Plan** per `docs/FRAMEWORK.md § Target
   Resolution` — artefact type Plan; status filter `evaluating` with
   a PASS verdict in the audit trail, or `shipping`; zero candidates →
   suggest `/spades:evaluate P-…`.
4. **Read the Plan and its parent Scope** in the resolved Scope worktree
   per § Scope Worktrees. Reuse that context for all drivers.
5. **Verify ancestors active** per § Target Resolution →
   Parent-status precondition; hard abort on an `abandoned` Scope or
   an `abandoned` / `archived` Project.
6. **Verify the status and verdict.** `evaluating` + PASS, or
   `shipping` → continue to Step 1. PARTIAL → stop and direct the
   caller to `/spades:deliver P-…` for the remaining gaps. Any other
   status or verdict → abort with a clear message.
7. **Scope PR readiness (`code`, two-phase SCM).** With `scm: github` or
   `scm: gitlab`, before marking any Plan `shipping`, check the Scope is
   ready for its PR per `docs/FRAMEWORK.md § Scope Worktrees → Plans share
   the Scope branch`. If siblings are pending, keep this Plan `evaluating`
   and continue their delivery/evaluation first.
8. **Verify Leads completion and carry-forward** for every participating
   Plan per `docs/FRAMEWORK.md § Leads handoff → Evaluation and
   publication`, before publishing.
9. **Open the review surface** per § Output format.

## Step 1 — Fresh run or resume

An `evaluating` Plan is a fresh run; continue to Step 2. A `shipping`
Plan resumes from its audit trail:

- **`PR opened:` or `MR opened:` line, no later `Shipped` line** →
  the PR is published and finalisation belongs to `/spades:close`.
  Probe its state with `review_state` (`docs/FRAMEWORK.md § SCM
  Drivers`), report it, and print `Run /spades:close P-<id>` for a
  merged PR or `Merge the PR, then run /spades:close P-<id>` for an
  open one, naming it MR on GitLab. Stop.
- **`Shipped` line** → the single-phase shipment is recorded; continue
  at Step 4 to finalise it.
- **Neither** → the earlier run stopped before recording a shipment: a
  rejected push, a PR or MR that failed to open, or an artefact or
  action not yet recorded. Continue at Step 3, which repeats it. With
  `scm: local-git` there is no PR line, so a `shipping` code Plan
  resumes here, or at Step 4 once its `Shipped (local-git)` line is
  written.

## Step 2 — Mark shipping

Record a one-line description (≤140 characters) when the human's
request carries one; otherwise omit the clause.

Set the Plan to `status: shipping`, `updated: <today>`, and append:

```markdown
- YYYY-MM-DD: Ship phase started — deliverable_type: <code|artefact|action>[ — "<description>"].
```

With `backend: linear`, move the sub-issue to its `shipping`
workflow state. For a Scope delivery PR on a two-phase SCM, apply this
transition to every participating code Plan; one PR publishes their
shared branch.

## Step 3 — Ship by deliverable type

### A — `code`

`/spades:deliver` created the Scope delivery branch and worktree and committed onto
that branch. Ship publishes it. The flow is per SCM: read `scm:` and follow the
matching driver file, which owns branch verification, the pre-push
sweep, the push, PR opening where the SCM has one, and the audit
markers.

- `scm: github` → **read `${CLAUDE_PLUGIN_ROOT}/skills/ship/scm-github.md`**;
  `scm: gitlab` → **read `${CLAUDE_PLUGIN_ROOT}/skills/ship/scm-gitlab.md`**;
  **follow it.** Two-phase: this run pushes and opens the PR (a merge
  request, MR, on GitLab), then exits with the Plan at `shipping`;
  `/spades:close P-<id>` records the `Shipped` marker after the merge.
- `scm: local-git` → **read `${CLAUDE_PLUGIN_ROOT}/skills/ship/scm-local-git.md`
  and follow it.** Single-phase: push when a remote is configured,
  record the commit, return here for Step 4.
- Any other value → abort: *"No ship driver for `scm: <value>`. See
  `docs/EXTENDING-SCM.md` for the contract, or set `scm: local-git`
  in `.spades/config`."*

### B — `artefact`

The deliverable is a tangible thing outside the repo: a document, a
video, a dataset, a configuration landing somewhere else.

1. Ask what kind of reference it is: **URL** /
   **File path** / **Record in a system** (Confluence or Notion page
   ID, S3 key, …).
2. Capture the exact reference free-form. Check its shape: a
   well-formed URL, an existing path, an identifiable record.
3. Verify reachability where possible — fetch a URL, stat a path.
   An unreachable artefact is surfaced, and the human decides whether
   to proceed.
4. `record_shipment(plan_id, artefact_ref)` and append:

   ```markdown
   - YYYY-MM-DD: Shipped (artefact). Ref: <ref>.
   ```

Continue to Step 4.

### C — `action`

The deliverable is a one-off human act: a server install, a vendor
call, an email, a meeting. The evidence of completion is what gets
recorded.

1. Ask free-form what was done.
2. Ask for evidence — a photo path, a confirmation email reference
   or message ID, a receipt or order number, a signed document, a
   note in a system of record. Several items are fine.
3. `record_shipment(plan_id, evidence_list)` and append:

   ```markdown
   - YYYY-MM-DD: Shipped (action). Description: <description>. Evidence:
     - <evidence 1>
     - <evidence 2>
   ```

Continue to Step 4.

## Step 4 — Finalise (single-phase paths)

Reached from the local-git driver, from Branches B and C, and from a
Step 1 resume whose shipment is already recorded. Set the
Plan to `status: shipped`, `updated: <today>`, then apply the Scope
rollup per `docs/FRAMEWORK.md § Scope status rollup`:

- **Every sibling `shipped`** → Scope `status: done`; append
  `- YYYY-MM-DD: All plans shipped. Scope done.`
- **All terminal, a mix of `shipped` and `rejected`, at least one
  `shipped`** → ask the human to acknowledge it,
  listing the rejected siblings. On acceptance the Scope is `done`
  with `- YYYY-MM-DD: All plans terminal. Shipped: <n>. Rejected:
  <m> (acknowledged: P-…). Scope done.`; on decline the Scope is
  unchanged and the Plan's audit trail records
  `- YYYY-MM-DD: Scope rollup deferred (mixed-terminal; human
  declined).`
- **A sibling still in flight** → no rollup.

With `backend: linear`, move the sub-issue to Done, and the parent
Issue to Done when the Scope rolls up to `done`.

## Step 5 — Confirm

Two-phase drivers print their own hand-off and exit inside Step 3.
Single-phase paths print:

```
✓ Plan shipped:   P-rag-pipeline-lookup-3HyD
✓ Scope:          S-add-ai-helper-bot (done — all plans shipped)
✓ Artefact:       https://docs.example.com/…  (or commit / evidence)
✓ Status:         shipped

Next:
  /spades:learn                            — capture a learning
  /spades:status                           — see what's still open
```

`/spades:learn` is a suggestion the human runs separately.

## Edge cases

SCM-specific cases — push failures, merge conflicts, missing CLI
auth — live in the driver files. Across all deliverable types:

- **The deliverable lives somewhere the human can't show you.**
  Accept a free-form evidence string; the audit trail records what
  the human attested to.
