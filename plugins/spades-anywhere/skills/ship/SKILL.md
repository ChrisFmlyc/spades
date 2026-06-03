---
name: ship
description: Ship a delivered Plan in spades-anywhere — a confirmation walk through the project's INTENT.md success criteria, capturing evidence per criterion. Branches on `deliverable_type:` — `artefact` records a reference (URL, file, doc); `action` records evidence of a real-world action completed. Use after `/spades-anywhere:evaluate` has issued a PASS, when someone says "ship this", "release this", "mark it done", or when a Plan is in status `evaluating` with a PASS verdict.
version: 0.1.1
---

# /spades-anywhere:ship

You are shipping the deliverable from an evaluated Plan. Ship is
the moment the work becomes real to the project — the artefact is
filed, the action is evidenced, the success criteria are confirmed
against the project's `INTENT.md`.

Unlike the sister `spades` plugin, this skill has **no SCM**, **no
PR**, **no merge SHA**. There is no `deliverable_type: code`
branch. Ship in `spades-anywhere` is a confirmation walk against
the project's stated success criteria.

Read `docs/FRAMEWORK.md` § Hierarchy (`deliverable_type` semantics),
§ Target Resolution, and § Audit Trail (the `Shipped` marker)
before running.

### Output format

This skill honours `review_format:` from `.spades-anywhere/config`
per `docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. In HTML
mode, auto-open both the Plan's and parent Scope's `.html` files
via the OPEN_CMD prelude at the start of the confirmation walk so
the human can see what's being shipped. In CLI mode, summarise
inline as today. The confirmation walk and audit-trail writes are
identical between modes.

## Pre-Flight

1. **Confirm setup + active project.** Abort otherwise.
2. **Resolve the target Plan** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill's parameters:
   - **Artefact type:** Plan (no type-question needed).
   - **Status filter:** `evaluating` with a PASS verdict in the
     audit trail. Parse the audit trail to surface only
     PASS-verdict plans first; PARTIAL plans appear below with an
     annotation; FAIL plans are excluded.
   - **Zero-candidate suggestion:** `/spades-anywhere:evaluate
     P-…` to verify a delivered plan.

   If the human passed a Plan ID, resolve directly; otherwise run
   the interactive picker.
3. **Read the Plan, parent Scope, and the project's INTENT.md.**
   The Scope's acceptance criteria are about *this slice of work*;
   `INTENT.md`'s success criteria are about *the project's broader
   purpose*. Ship confirms the work moved the project-level
   criteria forward.
4. **Verify status.** The Plan must be `status: evaluating` with a
   PASS verdict recorded in the audit trail. Acceptable variations:
   - `evaluating` + PASS → ship
   - `evaluating` + PARTIAL → ask the human if they want to ship
     anyway (PARTIAL with explicit acceptance of remaining gaps) or
     route back to `/spades-anywhere:do`
   - `evaluating` + FAIL → abort; not shippable
   - any other status → abort with a clear message
5. **Open the artefacts (HTML mode only).** When `review_format:
   html`, run the OPEN_CMD prelude and open both the Plan's `.html`
   and the parent Scope's `.html`. **In HTML mode the open `.html`
   files ARE the review surface — do NOT also paste / summarise
   the Plan body, Scope content, or the cumulative INTENT-criteria
   evidence table to the CLI; the human has the browser tabs.**
   Short conversational text (the per-INTENT-criterion
   `AskUserQuestion` polls, evidence-capture follow-ups, the final
   `✓ Plan shipped …` confirmation, error messages) stays CLI as
   today. In CLI mode, summarise inline as today. See
   `docs/FRAMEWORK.md § Output Format → What counts as review-form
   text` for the canonical line.

## Step 1 — Update Status

Move the Plan to `status: shipping` and `updated: <today>`.

Append to the audit trail:

```markdown
- YYYY-MM-DD: Ship phase started — deliverable_type: <artefact|action>.
```

## Step 2 — INTENT success-criteria confirmation walk

This is the heart of `/spades-anywhere:ship`. Read each success
criterion from `INTENT.md` (the `## Success` section, per
`/spades-anywhere:intent`'s template) and walk the human through
them one at a time. For each criterion:

1. **Surface the criterion** verbatim back to the human via
   `AskUserQuestion`:
   - *Yes — this Plan moved it forward, and I have evidence*
   - *Partially — it moved forward but not all the way*
   - *No — this Plan didn't move this criterion forward*
   - *Not applicable to this Plan*

2. For *Yes* or *Partially*, ask via a free-form follow-up:
   "What evidence? URL / file path / photo / note / record ID."
   Capture whatever the human supplies.

3. For *No* or *Not applicable*, capture a brief justification
   (optional but recommended).

Record each (criterion, verdict, evidence) tuple. The collected
list is the **shipment record**.

If `INTENT.md` is missing or unfilled, surface that — recommend
`/spades-anywhere:intent` to capture project intent first, then
re-run ship. Do not silently substitute the Scope's acceptance
criteria for INTENT's success criteria; the two levels are
distinct (see `docs/FRAMEWORK.md § Hierarchy → Two layers of
"intent"`).

## Step 3 — Branch on deliverable_type and record the shipment

### Branch A: `deliverable_type: artefact`

The deliverable is a tangible thing — a document, a video, a
filed record. Beyond the per-criterion evidence captured in Step
2, ask via `AskUserQuestion` for the *primary* artefact reference:

- **URL** (doc link, video link, photo album link)
- **File path** (within the user's filesystem or cloud drive)
- **Record in a system** (Notion page ID, Google Doc ID,
  Confluence page ID)

Capture the reference. Where reasonable, verify reachability — for
URLs, attempt a quick fetch; for file paths, stat them. If the
artefact isn't reachable, surface it and ask whether to proceed
anyway.

Call `record_shipment(plan_id, artefact_ref, intent_criteria_evidence)`.
Append to the audit trail:

```markdown
- YYYY-MM-DD: Shipped. Artefact: <ref>. Type: artefact.
  INTENT success criteria evidence:
  - <criterion 1> — <yes|partial|no|n/a> — <evidence>
  - <criterion 2> — …
```

### Branch B: `deliverable_type: action`

The deliverable is a one-off human action — a party hosted, a
trip taken, an interview round run, a difficult conversation had.
The thing itself isn't a file; the evidence of completion is.

Ask the human (free-form) what was done — a one-line summary.

Then ask for evidence (multiple items fine):

- Photos (file paths or album links)
- Confirmation emails (forwarded thread reference, message ID)
- Receipts / order numbers / booking refs
- Signed documents (path or URL)
- A note in a system of record (URL or record ID)
- Witness signatures (free-form note: "confirmed by <name>")

Call `record_shipment(plan_id, evidence_list,
intent_criteria_evidence)`. Append to the audit trail:

```markdown
- YYYY-MM-DD: Shipped. Action: <description>. Type: action.
  Evidence:
  - <evidence 1>
  - <evidence 2>
  INTENT success criteria evidence:
  - <criterion 1> — <yes|partial|no|n/a> — <evidence>
  - <criterion 2> — …
```

## Step 4 — Update status

Plan status → `shipped`. `updated: <today>`.

If every Plan under the parent Scope is now `shipped`:
- Scope status → `done`
- Append to Scope audit trail:
  ```markdown
  - YYYY-MM-DD: All plans shipped. Scope done.
  ```

When `backend: linear`, mirror: sub-issue → "Done", parent Issue →
"Done" (only if every sub-issue is Done).

## Step 5 — Suggest a Learning

Most ships produce something worth remembering. Ask via
`AskUserQuestion`:

- **Capture a learning** (recommended) — invokes
  `/spades-anywhere:learn`
- **Skip** — no learning this time

If yes, hand off to `/spades-anywhere:learn` with the plan ID as
context. The learning will be tagged and stored under
`.spades-anywhere/learnings/`.

## Step 6 — Confirm

```
✓ Plan shipped:   P-host-birthday-party-3HyD
✓ Scope:          S-plan-birthday-party (done — all plans shipped)
✓ Deliverable:    action — "Birthday party hosted at venue"
✓ Evidence:       4 items (photos, thank-you notes, vendor receipts)
✓ INTENT criteria: 3/3 met, 0/3 partial
✓ Status:         shipped

Next:
  /spades-anywhere:learn                       — capture a learning
  /spades-anywhere:status                      — see what's still open
```

## Edge cases

- **`INTENT.md` is missing.** Abort with: *"Ship walks the
  project's success criteria from `INTENT.md`. Run
  `/spades-anywhere:intent` to capture them, then re-run
  `/spades-anywhere:ship`."*
- **Every INTENT criterion came back `Not applicable`.** Surface
  this as a confirmation question — "this Plan didn't move any of
  the project's success criteria. Are you sure it should ship?" —
  and allow ship to continue if the human confirms, or route back
  to scope-revision if not. The audit trail captures the human's
  override.
- **Partial PASS that the human is shipping anyway.** Recorded
  in the audit trail; the PARTIAL is preserved as the verdict,
  and a follow-up Plan may be needed.
- **The deliverable lives in a system the human can't show you.**
  Accept a free-form evidence string. The audit trail records what
  the human attested to; `spades-anywhere` doesn't enforce
  verifiability.
