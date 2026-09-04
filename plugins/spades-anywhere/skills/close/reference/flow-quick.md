# Flow — Quick item close

Reached from `SKILL.md` Step 0 for a `Q-<slug>-<suffix>` target.
There is no menu: the human brings the evidence for the action they
took, the marker's placeholders are filled, and it flips to
`shipped` — or the action didn't happen and the marker is dropped.
Quick items are leaf nodes: no Scope rollup.

## Contents

- Q1 — Pre-flight
- Q2 — Confirm the action
- Q3 — Capture evidence and flip to shipped
- Q4 — Drop
- Q5 — Linear mirror and confirm

## Q1 — Pre-flight

1. **Setup and active project** from `.spades-anywhere/config`.
2. **Read the marker** `.spades-anywhere/quick/<Q-id>.md`: `id`,
   `linear_issue_id`, `status`, `type`, and the **Action to take**
   section. A marker already at `shipped` is terminal: *"Quick item
   `<Q-id>` is already `shipped`."*
3. Print the marker's title and planned action.

## Q2 — Confirm the action — `AskUserQuestion`

Echo the planned action in one line, then:

- **Done — capture evidence and finalise** *(recommended)* → Q3.
- **Drop — the action didn't happen** → Q4.
- **Cancel** → exit without changes.

## Q3 — Capture evidence and flip to shipped

Prompt free-form: *"Evidence reference (one line) — URL, file path,
message ID, photo path, or attestation. Light is fine; the standard
is that future-you can tell what happened from this alone."* The
reference is required; with none to give, *Drop* is the right
answer.

Optionally prompt for a one-line **Action taken** when what happened
differs from the plan; both the planned and actual lines are kept
so a reader sees intent against reality.

Update the marker:

- Frontmatter: `status: shipped`, `evidence_ref: <ref>`, `updated:`
  today.
- **Action taken**: the human's summary, or the planned action.
- **Evidence**: the reference.
- **Gate Check** heading: `(prospective)` → `(retrospective)`. A
  criterion that failed in flight (the one email became a thread;
  the 30 minutes became two hours) is unticked, and
  `AskUserQuestion`: **Drop — this should have been a Scope** /
  **Keep as quick — note the deviation in the audit trail**.
- Append `- YYYY-MM-DD: Shipped (action). Evidence: <evidence_ref>.`,
  or for `type: docs` / `type: tweak` (artefact-shaped)
  `- YYYY-MM-DD: Shipped (artefact). Ref: <evidence_ref>.` — the
  same grammar as `/spades-anywhere:ship`.

## Q4 — Drop

Capture `linear_issue_id` first, then delete
`.spades-anywhere/quick/<Q-id>.md`. Where the marker is under
version control, history keeps the trace.

> *`Q-<id>` dropped. Action didn't happen; marker deleted.*

## Q5 — Linear mirror and confirm

With `backend: linear` and a `linear_issue_id`:

- **After Q3** — issue In Progress → Done; comment *"Closed via
  `/spades-anywhere:close Q-<id>`. Evidence: `<evidence_ref>`."*
- **After Q4** — issue → Cancelled (or Backlog per team
  convention); comment *"Quick item dropped — action did not
  happen."*

Confirm in one line: `✓ Q-<id> shipped. Evidence: <evidence_ref>.`
or `✓ Q-<id> dropped.`
