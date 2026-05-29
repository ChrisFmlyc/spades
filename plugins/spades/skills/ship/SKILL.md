---
name: ship
description: Ship the deliverable produced by an approved + done Plan. Branches on `deliverable_type:` — code gets PR + review + merge; artefact gets a recorded reference (URL, path, doc ID); action gets evidence of completion. Use after `/spades:evaluate` has issued a PASS, when someone says "ship this", "release this", "merge it", or when a Plan is in status `evaluating` with a PASS verdict.
version: 2.0.0
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

## Step 1 — Update Status

Move the Plan to `status: shipping` and `updated: <today>`.

Append to the audit trail:

```markdown
- YYYY-MM-DD: Ship phase started — deliverable_type: <code|artefact|action>.
```

## Step 2 — Branch on Deliverable Type

### Branch A: `deliverable_type: code`

You're shipping code via a PR. Inline checklist (no dependency on
external review tooling — if the human has `coderabbit` or similar
installed, that's their own augmentation):

#### A.1 — Verify Local State

- Has every task's code been committed?
- Are there uncommitted changes that shouldn't go in the PR? Surface
  them; ask before discarding.
- Is the branch you're shipping from named sensibly? Suggest
  `spades/<plan-id>` (e.g. `spades/P-rag-pipeline-lookup-3HyD`).
- Does the branch include any commits that don't belong to this Plan?
  If so, ask the human whether to rebase or split.

#### A.2 — Push

Push the branch to the remote. Show the push output.

#### A.3 — Open the PR

Open a PR via `gh pr create` (or whatever the project's convention is —
inspect `.github/` or recent PRs to match local style). The title and
body should be:

**Title** — short and descriptive. Suggested form:
`<verb> <thing>: <plan-id>`. e.g. `Add RAG pipeline lookup (P-rag-pipeline-lookup-3HyD)`.

**Body** — generate from the Plan:

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

#### A.4 — Review

Walk the human through the review checklist:

- [ ] CI is green on the latest commit
- [ ] All acceptance criteria visible to the reviewer
- [ ] No unexpected files in the diff
- [ ] No secrets, tokens, or .env files in the diff
- [ ] The PR description tells the reviewer everything they need

If the project has automated review tooling (CodeRabbit, etc.)
installed, the human will invoke it themselves. SPADES doesn't depend
on any specific reviewer.

#### A.5 — Address Findings

If review surfaces findings:

1. Push fixes as new commits to the same branch.
2. Re-request review.
3. Iterate until clean.

#### A.6 — Merge

Once approved and CI green, ask the human (via `AskUserQuestion`):

- **Merge now** (recommended) — runs `gh pr merge` with the project's
  default strategy (squash / merge / rebase — pick from the project's
  recent merge history)
- **Hold** — leave the PR open; the human will merge later

If merging now, do the merge and capture the merge commit SHA.

#### A.7 — Record Shipment

Call the backend's `record_shipment(plan_id, artefact_ref)` with the PR
URL and merge commit SHA. Append to the audit trail:

```markdown
- YYYY-MM-DD: Shipped. PR: <url>. Merge commit: <sha>.
```

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
