---
name: ship
description: Ship the deliverable produced by an approved + done Plan. Branches on `deliverable_type:` — code gets PR + review + merge; artefact gets a recorded reference (URL, path, doc ID); action gets evidence of completion. Use after `/spades:evaluate` has issued a PASS, when someone says "ship this", "release this", "merge it", or when a Plan is in status `evaluating` with a PASS verdict.
version: 2.2.0
---

# /spades:ship

You are shipping the deliverable from an evaluated Plan. Ship is the
moment work becomes real to the outside world: a PR merges, an
artefact is published, an action's evidence is filed.

Read `docs/FRAMEWORK.md` § Hierarchy (`deliverable_type` semantics)
and § Target Resolution before running.

## Pre-Flight

1. **Confirm setup + active project.** Abort otherwise.
2. **Resolve the target Plan** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill's parameters:
   - **Artefact type:** Plan (no type-question needed).
   - **Status filter:** `evaluating` with a PASS verdict in the audit
     trail. When listing candidates, parse the audit trail to surface
     only PASS-verdict plans first; PARTIAL plans appear below with
     an annotation; FAIL plans are excluded.
   - **Zero-candidate suggestion:** `/spades:evaluate P-…` to verify a
     delivered plan.

   If the human passed a Plan ID, resolve directly; otherwise run the
   interactive picker.
3. **Read the Plan and parent Scope.**
4. **Verify status.** The Plan must be `status: evaluating` with a
   PASS verdict recorded in the audit trail. Acceptable variations:
   - `evaluating` + PASS → ship
   - `evaluating` + PARTIAL → ask the human if they want to ship
     anyway (PARTIAL with explicit acceptance of remaining gaps) or
     route back to `/spades:do`
   - `evaluating` + FAIL → abort; not shippable
   - any other status → abort with a clear message

## Step 0 — Detect fresh run vs resume (code deliverables)

For `deliverable_type: code`, this skill is two-phase:

- **Phase 1 (fresh)** — Push the branch, open the PR, exit. Plan
  goes to `status: shipping`.
- **Phase 2 (resume)** — After CodeRabbit feedback is addressed and
  the PR is squash-merged, re-invoke `/spades:ship`. The skill
  detects the resume via audit-trail markers, verifies the merge,
  records the merge SHA, marks the Plan `shipped`.

Read the audit trail before doing anything else.

- **No `PR opened:` line** → fresh run. Continue to Step 1.
- **`PR opened: <URL>` present but no `Shipped:` line** → resume.
  Jump to Step 6 (Resume).
- **`Shipped:` present** → already complete. Ask via
  `AskUserQuestion` whether to re-record or exit.

For `deliverable_type: artefact` or `action`: always single-phase.
Continue to Step 1.

## Step 1 — Update Status

Move the Plan to `status: shipping` and `updated: <today>`.

Append to the audit trail:

```markdown
- YYYY-MM-DD: Ship phase started — deliverable_type: <code|artefact|action>.
```

## Step 2 — Branch on Deliverable Type

### Branch A: `deliverable_type: code`

You're publishing code. `/spades:do` already created a feature
branch and committed work onto it; this branch publishes that work.

**Branch A is routed by SCM** (read `scm:` from `.spades/config`):

- **`scm: github`** — two-phase: Phase 1 pushes and opens a PR via
  `gh pr create`; Phase 2 (resume after squash-merge) records the
  merge SHA. See A.github below.
- **`scm: local-git`** — single-phase: push to the configured remote
  if one exists, record the commit SHA, mark the Plan shipped. No
  PR, no CodeRabbit loop. See A.local-git below.
- **(other SCMs)** — see `docs/EXTENDING-SCM.md` for the contract.
  If `.spades/config` has an `scm:` value this skill doesn't know
  about, abort and tell the human to install the corresponding
  driver or fall back to `scm: local-git`.

### Branch A.github — `scm: github` (two-phase)

This is the original flow. `/spades:do` created the branch and
committed; this phase publishes via PR. No auto-merge —
squash-merge happens in GitHub after CodeRabbit review.

#### A.1 — Verify on the right branch

- `git rev-parse --abbrev-ref HEAD` — current branch
- If on `main` / `master`: error. `/spades:do` should have created a
  feature branch. Abort and suggest the human verifies what
  happened.
- Read the Plan's audit trail. Find the `Do phase started — branch:`
  line. If the current branch doesn't match, warn via
  `AskUserQuestion`:
  - *Push the current branch anyway (overrides the audit-trail
    branch)*
  - *Switch to the recorded branch and continue*
  - *Abort*

#### A.2 — Pre-push checks

- Are there uncommitted changes? Surface them; ask via
  `AskUserQuestion` whether to commit (with a follow-up free-form
  message), stash, or discard before pushing.
- Does the branch include commits that don't belong to this Plan?
  If so, surface them; ask whether to rebase / split or proceed.

#### A.3 — Push

Push the branch to origin:

```bash
git push -u origin <branch>
```

Capture the output.

#### A.4 — Open the PR

Open a PR via `gh pr create`. Title and body derived from the Plan:

**Title** — short, descriptive. Suggested form:
`<verb> <thing> (<plan-id>)`. e.g.
`Add RAG pipeline lookup (P-rag-pipeline-lookup-3HyD)`.

**Body** — generated from the Plan:

```markdown
## Summary

<2-3 sentences from the Plan's Technical Approach>

## SPADES audit trail

- Project: `<project-slug>`
- Scope:   `S-<scope-slug>`
- Plan:    `P-<plan-slug>-<suffix>`
- Approved: <YYYY-MM-DD> — routing: ai|human|hybrid
- Evaluation verdict: PASS

## Tasks completed

- [x] Task 1: <title>
- [x] Task 2: <title>
- [x] Task 3: <title>

## Test plan

<from the Plan's Testing & Verification section>
```

Capture the PR URL from `gh pr create`'s output.

#### A.5 — Record Phase 1 completion and exit

Append to the Plan's audit trail:

```markdown
- YYYY-MM-DD: PR opened: <URL>.
```

Plan stays in `status: shipping`. Print the hand-off:

```
✓ PR opened: <URL>
○ CodeRabbit will run automatically (if installed on the repo).
○ Address review feedback by committing to this branch.

Once the PR is squash-merged:
  /repo:sync                — clean up main + the local branch
  /spades:ship P-<plan-id>  — record the merge SHA, mark shipped

Plan stays in `shipping` until the resume runs.
```

**Exit here.** Do NOT proceed to Step 3+ on a Phase 1 run.

### Branch A.local-git — `scm: local-git` (single-phase)

There's no PR system in front of `local-git`. Ship's job is just to
push (if a remote exists) and record the latest commit on the
branch as the shipment reference.

#### A.local-git.1 — Verify on the right branch

Same as A.github (above) — `git rev-parse --abbrev-ref HEAD`, check
against the audit trail's `Do phase started — branch:` line, warn
on mismatch via `AskUserQuestion`.

#### A.local-git.2 — Pre-push checks

Same as A.github — surface uncommitted changes, offer commit / stash
/ discard. Make sure the branch only carries this Plan's work.

#### A.local-git.3 — Push (if a remote is configured)

```bash
git remote -v
```

- If a remote is configured (read the configured one from
  `.spades/config`'s `local_git.remote:` field, default `origin`):

  ```bash
  git push -u <remote> <branch>
  ```

  Record the push in the audit trail (with remote name + branch).
- If no remote is configured: skip the push, surface
  *"No remote configured — recording the local commit as the
  shipment reference."* in the report.

#### A.local-git.4 — Capture the shipment reference

```bash
git rev-parse HEAD          # current commit SHA on the branch
git log -1 --format='%h %s' # short SHA + subject for the audit trail
```

#### A.local-git.5 — Record and exit (single-phase)

Append to the Plan's audit trail:

```markdown
- YYYY-MM-DD: Shipped (local-git). Branch: <branch>. Commit: <sha>.
  Pushed to: <remote>/<branch>.    # omit this line if no remote
```

Plan → `status: shipped` directly (no second phase needed).

Continue to Step 3.

### Branch B: `deliverable_type: artefact`

The deliverable is a tangible thing that isn't merged code — a
document, a video, a dataset, a configuration file landing somewhere
outside the repo.

#### B.1 — Identify the artefact

Ask the human (via `AskUserQuestion`):

- **Artefact is at a URL** (doc link, video link, dataset URL)
- **Artefact is a file path** (within this repo or elsewhere)
- **Artefact is a record in a system** (Confluence page ID, Notion
  page ID, S3 key, etc.)

#### B.2 — Capture the reference

Get the exact reference from the human in free-form text. Validate
shape: URLs are well-formed, file paths exist, system records are
identifiable.

#### B.3 — Verify reachability

When you can — for URLs, attempt a quick fetch. For file paths, stat
them. If the artefact isn't reachable, surface that and ask whether to
proceed anyway.

#### B.4 — Record Shipment

Call `record_shipment(plan_id, artefact_ref)`. Append to audit trail:

```markdown
- YYYY-MM-DD: Shipped. Artefact: <ref>. Type: artefact.
```

### Branch C: `deliverable_type: action`

The deliverable is a one-off human action — a server install, a
vendor call, an email, a meeting. The thing itself isn't a file or a
PR; the evidence of completion is.

#### C.1 — Identify the action

Ask the human (free-form) what was done.

#### C.2 — Capture evidence

Ask for the evidence:

- A photo (file path)
- A confirmation email (forwarded thread reference, message ID)
- A receipt or order number
- A signed document (path or URL)
- A note in a system of record (URL or record ID)

Multiple evidence items are fine; record all.

#### C.3 — Record Shipment

Call `record_shipment(plan_id, artefact_ref)` with the evidence list.
Append to audit trail:

```markdown
- YYYY-MM-DD: Shipped. Action: <description>. Evidence:
  - <evidence 1>
  - <evidence 2>
```

## Step 6 — Resume (code deliverables on `scm: github`, after squash-merge)

You arrive here because Step 0 detected a `PR opened:` line in the
audit trail with no `Shipped:` line. This step only runs for
`scm: github`; `scm: local-git` is single-phase and skips
straight to Step 3.

1. **Parse the PR URL** from the most recent `PR opened:` line.
   Extract the PR number (last segment of `/pull/<n>`).
2. **Verify merge state:**

   ```bash
   gh pr view <number> --json state,mergeCommit,mergedAt,mergedBy
   ```

   - `state == "MERGED"` → capture `mergeCommit.oid` and
     `mergedAt`. Continue.
   - `state == "OPEN"` → tell the human the PR is still open; show
     a one-line summary (CI status, reviews). Ask via
     `AskUserQuestion`:
     - *Wait — re-run later*
     - *Abort — record nothing, exit*
   - `state == "CLOSED"` (not merged) → ask the human how to
     handle: re-open the PR (manual), mark the Plan rejected, or
     abort.

3. **Record the shipment.** Append to the audit trail:

   ```markdown
   - YYYY-MM-DD: Shipped. PR: <URL>. Merge: <sha>. Merged by: <login>.
   ```

4. **Continue to Step 3** to finalise the Plan status.

## Step 3 — Update Status

Plan status → `shipped`. `updated: <today>`.

If every Plan under the parent Scope is now `shipped`:
- Scope status → `done`
- Append to Scope audit trail:
  ```markdown
  - YYYY-MM-DD: All plans shipped. Scope done.
  ```

When `backend: linear`, mirror: sub-issue → "Done", parent Issue →
"Done" (only if every sub-issue is Done).

## Step 4 — Suggest a Learning

Most ships produce something worth remembering. Ask the human (via
`AskUserQuestion`):

- **Capture a learning** (recommended) — invokes `/spades:learn`
- **Skip** — no learning this time

If yes, hand off to `/spades:learn` with the plan ID as context. The
learning will be tagged and stored under `.spades/learnings/`.

## Step 5 — Confirm

```
✓ Plan shipped:   P-rag-pipeline-lookup-3HyD
✓ Scope:          S-add-ai-helper-bot (done — all plans shipped)
✓ Artefact:       https://github.com/.../pull/123  (or other ref)
✓ Status:         shipped

Next:
  /spades:learn                            — capture a learning
  /spades:status                           — see what's still open
```

## Edge Cases

- **The PR fails to open.** Common causes: branch not pushed, no remote
  set, `gh` not authenticated. Surface the exact error and offer
  remediation. Do NOT mark the Plan shipped.
- **Merge conflicts.** The Plan author resolves these as fix commits.
  `/spades:ship` resumes when the branch is clean again.
- **The deliverable lives in a system the human can't show you.** Accept
  a free-form evidence string. The audit trail records what the human
  attested to; SPADES doesn't enforce verifiability.
- **No PR convention in the project.** If `gh` isn't installed or no
  remote is set, show the human exactly what command they'd run to
  open the PR manually, then capture the resulting URL.
