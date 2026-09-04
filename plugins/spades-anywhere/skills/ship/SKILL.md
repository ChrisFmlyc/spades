---
name: ship
description: Ship a delivered Plan in spades-anywhere — a confirmation walk through the project's INTENT.md success criteria, capturing evidence per criterion. Branches on `deliverable_type:` — `artefact` records a reference (URL, file, doc); `action` records evidence of a real-world action completed. Use after `/spades-anywhere:evaluate` has issued a PASS, when someone says "ship this", "release this", "mark it done", or when a Plan is in status `evaluating` with a PASS verdict.
version: 0.2.0
---

# /spades-anywhere:ship

You are shipping the deliverable of an evaluated Plan. Ship is the
moment the work becomes real to the project: the artefact is filed
or the action is evidenced, and the human confirms, criterion by
criterion, how it moved the project's `INTENT.md` success criteria
forward. The Plan reaches `shipping` here; `/spades-anywhere:close`
flips it to `shipped` and rolls the Scope up.

Read `docs/FRAMEWORK.md` § Hierarchy (`deliverable_type` and the two
layers of intent), § Target Resolution, § Audit Trail (the
`Shipped` marker), and § Output Format before running.

### Output format

The Plan, Scope, and `INTENT.md` are read from their `.md` files.
HTML mode opens the Plan's and Scope's existing `.html` via the
OPEN_CMD prelude as the human's view; the terminal carries the
per-criterion prompts, evidence capture, and confirmation. CLI mode
summarises inline. After the audit-trail writes in HTML mode,
re-render the Plan's `.html`.

## Pre-Flight

1. **Confirm setup and active project.**
2. **Read `backend:` and `review_format:`.**
3. **Resolve the target Plan** per `docs/FRAMEWORK.md § Target
   Resolution` — status filter `evaluating` with a PASS verdict
   (PASS first, PARTIAL annotated below, FAIL excluded); zero
   candidates → `/spades-anywhere:evaluate P-…`.
4. **Read the Plan, its parent Scope, and `INTENT.md`.** The Scope's
   criteria are about this slice of work; INTENT's success criteria
   are about the project. Ship confirms the slice moved the project.
   A missing or unfilled `INTENT.md` aborts: *"Ship walks the
   project's success criteria from `INTENT.md`. Run
   `/spades-anywhere:intent`, then re-run ship."*
5. **Verify ancestors active**; hard abort on an `abandoned` Scope or
   an `abandoned` / `archived` Project.
6. **Verify the verdict.** `evaluating` + PASS → ship. `evaluating`
   + PARTIAL → ask whether to ship with the gaps accepted (recorded)
   or return to `/spades-anywhere:do`. FAIL or any other status →
   abort.
7. **Open the review surface** per § Output format.

## Step 1 — Mark shipping

Capture an optional one-line description via `AskUserQuestion`:
**Type a brief description** (free-form, ≤140 characters, the
human's own words) / **Skip**.

Set `status: shipping`, `updated: <today>`, and append:

```markdown
- YYYY-MM-DD: Ship phase started — deliverable_type: <artefact|action>[ — "<description>"].
```

With `backend: linear`, move the sub-issue to its `shipping` state.

## Step 2 — INTENT confirmation walk

For each criterion under `INTENT.md § Success`, in turn:

1. Surface it verbatim via `AskUserQuestion`: **Yes — this Plan
   moved it forward, and I have evidence** / **Partially** / **No**
   / **Not applicable to this Plan**.
2. Yes or Partially → free-form: *"What evidence? URL, file path,
   photo, note, record ID."*
3. No or Not applicable → an optional one-line justification.

The collected `(criterion, verdict, evidence)` list is the
shipment record. When every criterion comes back Not applicable,
ask once whether the Plan should ship at all; a confirmed yes is
recorded as the human's override.

## Step 3 — Record the shipment

### `artefact`

Ask via `AskUserQuestion` for the primary reference: **URL** /
**File path** / **Record in a system** (Notion page, Google Doc,
Confluence ID). Verify reachability where possible; an unreachable
artefact is surfaced and the human decides. Then
`record_shipment(plan_id, artefact_ref, intent_criteria_evidence)`
and append:

```markdown
- YYYY-MM-DD: Shipped (artefact). Ref: <ref>.
  INTENT success criteria evidence:
  - <criterion 1> — <yes|partial|no|n/a> — <evidence>
  - <criterion 2> — …
```

### `action`

Ask free-form what was done (one line), then for evidence — photos,
confirmation emails or message IDs, receipts or booking references,
signed documents, a note in a system of record, a witness note
("confirmed by <name>"). Several items are fine. Then
`record_shipment(plan_id, evidence_list, intent_criteria_evidence)`
and append:

```markdown
- YYYY-MM-DD: Shipped (action). Description: <description>. Evidence:
  - <evidence 1>
  - <evidence 2>
  INTENT success criteria evidence:
  - <criterion 1> — <yes|partial|no|n/a> — <evidence>
```

## Step 4 — Confirm

The Plan stays at `shipping` until `/spades-anywhere:close` finalises
it — the same two-step shape as the `spades` plugin, so the audit
trail reads identically.

```
✓ Ship recorded:    P-host-birthday-party-3HyD
✓ Plan status:      shipping
✓ Deliverable:      action — "Birthday party hosted at venue"
✓ Evidence:         4 items (photos, thank-you notes, vendor receipts)
✓ INTENT criteria:  3/3 moved forward

Next:
  /spades-anywhere:close P-host-birthday-party-3HyD   — finalise (Plan → shipped, Scope rollup, Linear mirror)
  /spades-anywhere:learn                              — capture a learning
```

`/spades-anywhere:learn` is a suggestion the human runs separately.

## Edge cases

- **A PARTIAL the human ships anyway** — the PARTIAL stays the
  recorded verdict; a follow-up Plan may be needed.
- **The deliverable lives somewhere you can't see** — accept a
  free-form evidence string; the audit trail records what the human
  attested to.
