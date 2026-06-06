---
name: ship
description: Ship the deliverable produced by an approved + done Plan. Branches on `deliverable_type:` — code gets PR + review + merge; artefact gets a recorded reference (URL, path, doc ID); action gets evidence of completion. Use after `/spades:evaluate` has issued a PASS, when someone says "ship this", "release this", "merge it", or when a Plan is in status `evaluating` with a PASS verdict.
version: 3.1.2
---

# /spades:ship

You are shipping the deliverable from an evaluated Plan. Ship is the
moment work becomes real to the outside world: a PR merges, an
artefact is published, an action's evidence is filed.

Read `docs/FRAMEWORK.md` § Hierarchy (`deliverable_type` semantics)
and § Target Resolution before running.

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. Anywhere this
skill would today summarise the Plan + parent Scope to the terminal
during ship, in HTML mode auto-open both `.html` files via the
OPEN_CMD prelude. The PR-opening, audit-trail markers, and SCM
driver dispatch all stay identical between modes.

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
5. **Open the artefacts (HTML mode only).** Read `review_format:`
   from `.spades/config`. When `review_format: html`, run the
   OPEN_CMD prelude (`docs/FRAMEWORK.md § OPEN_CMD detection
   prelude`) and open both the Plan's `.html` and the parent Scope's
   `.html`. **In HTML mode the open `.html` files ARE the review
   surface — do NOT also paste / summarise the Plan body, Scope
   content, or any "let me show you what we're about to ship"
   preview to the CLI; the human has the browser tabs.** Short
   conversational text (PR-open progress narration, SCM driver
   handshake messages, the final `✓ Plan shipped …` confirmation,
   error messages) stays CLI as today. In CLI mode, summarise
   inline as today. The PR-opening, audit-trail markers, and SCM
   driver dispatch all stay identical between modes. See
   `docs/FRAMEWORK.md § Output Format → What counts as review-form
   text` for the canonical line.

## Step 0 — Detect fresh run vs resume (code deliverables)

For `deliverable_type: code`, ship may be two-phase or single-phase
depending on the configured SCM driver:

- **Two-phase drivers** (e.g. `scm: github`, `scm: gitlab`) — Phase 1
  pushes and opens a PR/MR; Phase 2 resumes after merge to record
  the merge SHA and mark the Plan `shipped`.
- **Single-phase drivers** (e.g. `scm: local-git`) — push (if a
  remote is set), record the commit SHA, mark `shipped` immediately.
  No resume.

Resume detection is contract-level — the markers come from
`docs/EXTENDING-SCM.md` § 4 and don't depend on the driver loaded:

Read the audit trail before doing anything else.

- **No `PR opened:` / `MR opened:` line** → fresh run. Continue to
  Step 1.
- **`PR opened:` or `MR opened:` line present, no later `Shipped`
  line** → resume. Jump to Step 6 (Resume).
- **`Shipped` line present** → already complete. Ask via
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

**Branch A is routed by SCM** — the per-SCM ship flow lives in a
sibling driver file, not in this skill. SKILL.md's only job here is to
read the configured SCM and load the matching driver.

1. Read `scm:` from `.spades/config`. Expect one of: `github`,
   `local-git`.
2. **Read `${CLAUDE_PLUGIN_ROOT}/skills/ship/scm-<value>.md` and
   follow it.** That file owns Branch A from this point: branch
   verification, pre-push checks, push, PR-open (where applicable),
   and the audit-trail markers.
3. The driver returns control here after recording its shipment
   marker. Single-phase drivers (e.g. `local-git`) come back ready
   for Step 3. Two-phase drivers (e.g. `github`) come back from
   Phase 1 with an exit instruction — **honour it and stop**; the
   resume is a later invocation that re-enters at Step 0 → Step 6.

If `.spades/config`'s `scm:` value has no matching driver file in
`skills/ship/`, abort with:

> *No ship driver for `scm: <value>`. See `docs/EXTENDING-SCM.md` for
> the contract, or fall back to `scm: local-git` in `.spades/config`.*

This is the same failure mode that applied to the previous inline
dispatch — unsupported SCMs are a setup-time concern, not a ship-time
papering-over.

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
- YYYY-MM-DD: Shipped (artefact). Ref: <ref>.
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
- YYYY-MM-DD: Shipped (action). Description: <description>. Evidence:
  - <evidence 1>
  - <evidence 2>
```

## Step 6 — Resume (two-phase drivers, after merge)

You arrive here because Step 0 detected a two-phase resume marker
(`PR opened:`, `MR opened:`, etc.) in the audit trail with no later
`Shipped:` line. Single-phase drivers (e.g. `scm: local-git`) never
land here; they emit `Shipped` directly in Step 2 and continue to
Step 3.

Resume is per-SCM — the merge-state query, the parser, the credentials
all live in the driver:

1. Read `scm:` from `.spades/config`.
2. **Read `${CLAUDE_PLUGIN_ROOT}/skills/ship/scm-<value>.md` and
   follow its "Phase 2 — Resume after merge" section.** The driver
   verifies the merge, captures the merge SHA, and appends
   `Shipped. …` to the audit trail.
3. The driver returns here ready for Step 3 to finalise the Plan
   status. If the driver couldn't confirm a merge (PR still open,
   PR closed-without-merge), it has already exited or asked the
   human how to proceed — there is nothing further to do in Step 6.

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

SCM-specific edge cases (push failures, merge conflicts, missing CLI
auth) live in the driver files (`skills/ship/scm-<name>.md`). Edge
cases that apply across all deliverable types:

- **The deliverable lives in a system the human can't show you.**
  Accept a free-form evidence string. The audit trail records what
  the human attested to; SPADES doesn't enforce verifiability.
- **No matching driver for the configured `scm:`.** Branch A aborts
  with a pointer to `docs/EXTENDING-SCM.md`. The fix is upstream of
  ship — either add a driver or change `scm:` in `.spades/config`.
