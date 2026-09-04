---
name: ship
description: Ship the deliverable produced by an approved + done Plan. Branches on `deliverable_type:` — code gets PR + review + merge; artefact gets a recorded reference (URL, path, doc ID); action gets evidence of completion. Use after `/spades:evaluate` has issued a PASS, when someone says "ship this", "release this", "merge it", or when a Plan is in status `evaluating` with a PASS verdict.
version: 3.5.0
---

# /spades:ship

You are shipping the deliverable of an evaluated Plan. Ship is the
moment work becomes real to the outside world: a PR is published, an
artefact is filed, an action's evidence is recorded.

Read `docs/FRAMEWORK.md` § Hierarchy (`deliverable_type`), § Target
Resolution, § Audit Trail (the `Shipped` marker), § Carry-Forward of
SPADES-Owned Artefacts, and § Output Format before running.

### Output format

The Plan and Scope are read from their `.md` files. HTML mode opens
both existing `.html` pages via the OPEN_CMD prelude at the start;
they are the human's view of what is being shipped, and the terminal
carries the progress lines, driver messages, prompts, and the final
confirmation. CLI mode summarises inline. After each audit-trail
write in HTML mode, re-dispatch `worker-html-plan` (and
`worker-html-scope` when the Scope changed).

## Pre-Flight

1. **Confirm setup and active project.** Abort otherwise.
2. **Read `backend:`, `scm:`, and `review_format:`** from
   `.spades/config`.
3. **Resolve the target Plan** per `docs/FRAMEWORK.md § Target
   Resolution` — artefact type Plan; status filter `evaluating` with
   a PASS verdict in the audit trail (PASS Plans listed first,
   PARTIAL below with an annotation, FAIL excluded); zero candidates
   → suggest `/spades:evaluate P-…`.
4. **Read the Plan and its parent Scope.**
5. **Verify ancestors active** per § Target Resolution →
   Parent-status precondition; hard abort on an `abandoned` Scope or
   an `abandoned` / `archived` Project.
6. **Verify the verdict.** `evaluating` + PASS → ship. `evaluating`
   + PARTIAL → ask whether to ship with the remaining gaps accepted
   (recorded in the audit trail) or return to `/spades:do`.
   `evaluating` + FAIL, or any other status → abort with a clear
   message.
7. **Open the review surface** per § Output format.

## Step 1 — Fresh run or resume (`deliverable_type: code`)

Read the audit trail:

- **No `PR opened:` / `MR opened:` line** → fresh run; continue.
- **`PR opened:` present, no later `Shipped` line** → the PR is
  published and finalisation belongs to `/spades:close`. Probe the
  PR state (`gh pr view <n> --json state`), report it, and print
  `Run /spades:close P-<id>` for a merged PR or `Merge the PR, then
  run /spades:close P-<id>` for an open one. Stop.
- **`Shipped` line present** → already shipped; say so and stop.

`artefact` and `action` deliverables are always single-phase;
continue.

## Step 2 — Mark shipping

Capture an optional one-line description via `AskUserQuestion`:
**Type a brief description** (free-form, ≤140 characters) / **Skip**.

Set the Plan to `status: shipping`, `updated: <today>`, and append:

```markdown
- YYYY-MM-DD: Ship phase started — deliverable_type: <code|artefact|action>[ — "<description>"].
```

With `backend: linear`, move the sub-issue to its `shipping`
workflow state.

## Step 3 — Ship by deliverable type

### A — `code`

`/spades:do` created the feature branch and committed onto it; this
branch publishes it. The flow is per SCM: read `scm:` and follow the
matching driver file, which owns branch verification, the pre-push
sweep, the push, PR opening where the SCM has one, and the audit
markers.

- `scm: github` → **read `${CLAUDE_PLUGIN_ROOT}/skills/ship/scm-github.md`
  and follow it.** Two-phase: this run pushes and opens the PR, then
  exits with the Plan at `shipping`; `/spades:close P-<id>` records
  the `Shipped` marker after the merge.
- `scm: local-git` → **read `${CLAUDE_PLUGIN_ROOT}/skills/ship/scm-local-git.md`
  and follow it.** Single-phase: push when a remote is configured,
  record the commit, return here for Step 4.
- Any other value → abort: *"No ship driver for `scm: <value>`. See
  `docs/EXTENDING-SCM.md` for the contract, or set `scm: local-git`
  in `.spades/config`."*

### B — `artefact`

The deliverable is a tangible thing outside the repo: a document, a
video, a dataset, a configuration landing somewhere else.

1. Ask via `AskUserQuestion` what kind of reference it is: **URL** /
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

Reached from the local-git driver and from Branches B and C. Set the
Plan to `status: shipped`, `updated: <today>`, then apply the Scope
rollup per `docs/FRAMEWORK.md § Scope status rollup`:

- **Every sibling `shipped`** → Scope `status: done`; append
  `- YYYY-MM-DD: All plans shipped. Scope done.`
- **All terminal, a mix of `shipped` and `rejected`, at least one
  `shipped`** → ask the human to acknowledge via `AskUserQuestion`,
  listing the rejected siblings. On acceptance the Scope is `done`
  with `- YYYY-MM-DD: All plans terminal. Shipped: <n>. Rejected:
  <m> (acknowledged: P-…). Scope done.`; on decline the Scope is
  unchanged and the Plan's audit trail records
  `- YYYY-MM-DD: Scope rollup deferred (mixed-terminal; human
  declined).`
- **Every sibling `rejected`** → no rollup; the Scope shipped
  nothing, so surface that and leave it at `shipping`.
- **A sibling still in flight** → no rollup.

With `backend: linear`, move the sub-issue to Done, and the parent
Issue to Done when every sub-issue is Done.

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
- **No driver for the configured `scm:`.** The fix is upstream of
  ship: add a driver per `docs/EXTENDING-SCM.md` or change
  `.spades/config`.
