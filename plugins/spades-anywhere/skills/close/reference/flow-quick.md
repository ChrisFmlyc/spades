# Flow — Quick item close

Reached from `SKILL.md` Step 0 when the target is a Quick item
(`Q-<slug>-<suffix>`). There is no Step 1 menu — the action is
unambiguous. Quick items are deliberately lightweight
(`FRAMEWORK.md § Fast-Track Path`) and are leaf nodes: no Scope
rollup, no parent bookkeeping.

## Contents

- Pre-flight and marker read
- Confirming completion with the human
- Flipping the marker to shipped, or dropping it
- Linear mirror and confirmation

---

## Quick Close Flow

Reached when target is a Quick item (`Q-<slug>-<suffix>`). The
action is to capture the evidence the human brings back from doing
the thing, fill in the placeholder body sections, and flip the
marker to `status: shipped`. Mirrors the sister `spades` plugin's
Quick Close Flow shape — different trigger (human confirmation,
not PR merge), same audit-trail grammar.

### Pre-Flight

1. **Confirm setup + active project.** Read
   `.spades-anywhere/config`. Abort otherwise.
2. **Read the marker file** at `.spades-anywhere/quick/<Q-id>.md`.
   Capture:
   - `id`, `linear_issue_id`, `status`, `type`.
   - The **Action to take** body section (so you can echo it back
     to the human at Step 1).
   - Reject if `status: shipped` — already terminal. Print:
     *"Quick item `<Q-id>` is already `shipped`. Terminal means
     terminal."*
3. **Open the marker (HTML mode only).** When `review_format: html`,
   run the OPEN_CMD prelude and open
   `.spades-anywhere/quick/<Q-id>.html` if it exists.

### Step 1 — Confirm the action

Echo the **Action to take** back to the human (one line) and ask
via `AskUserQuestion`:

- *Done — capture evidence and finalise* (recommended)
- *Drop — the action didn't happen* (delete the marker)
- *Cancel* — exit without changes

On *Done* → continue to Step 2 (capture evidence + flip).
On *Drop* → continue to Step 3 (drop).
On *Cancel* → exit cleanly.

### Step 2 — Capture evidence and flip to shipped

Prompt the human for the evidence reference. Free-form:

> *Evidence reference (one line) — URL, file path, message ID,
> photo path, or attestation. Light is fine; the standard is
> "future-me can tell what happened from this evidence alone".*

The reference is **required** — pressing through with an empty
string re-prompts: *"Evidence is required to finalise a quick
item. The marker without evidence loses meaning."* (If the human
genuinely has no evidence, *Drop* in Step 1 is the right choice;
the action shouldn't be marked shipped.)

Optionally prompt for a one-line **Action taken** summary if
what actually happened differs from the planned action — useful
when the human improvised. The skill keeps the planned **Action
to take** for the audit trail and adds **Action taken** alongside,
so reviewers can see intent vs reality.

Update `.spades-anywhere/quick/<Q-id>.md`:

- Frontmatter: `status: shipping` → `status: shipped`;
  `evidence_ref: <ref>`; `updated: <today>`.
- Body:
  - **Action taken** section: replace `<filled in at close>` with
    the human's summary (or copy the planned **Action to take**
    if they didn't provide a new one).
  - **Evidence** section: replace `<filled in at close>` with the
    captured `evidence_ref`.
  - **Gate Check** heading: `(prospective)` → `(retrospective)`.
    The 10 checkboxes already ticked at `/quick` time are now
    revalidated *retrospectively* — if the human reports any
    criterion failed in flight (the "single email" became a
    thread; the "≤ 30 min" stretched to two hours), uncheck it
    and follow up via `AskUserQuestion`:
    - *Drop — gate violated; this should have been a Scope*
    - *Keep as quick anyway — note the deviation in the audit trail*
- Append to the `## Audit Trail` section:

  ```markdown
  - YYYY-MM-DD: Shipped (action). Evidence: <evidence_ref>.
  ```

  If the marker's `type` is `docs` or `tweak` (an artefact-shaped
  type), use `Shipped (artefact). Ref: <evidence_ref>.` instead —
  matches the canonical Ship grammar for artefact vs action.

If HTML mode and `.spades-anywhere/quick/<Q-id>.html` exists,
re-render via the bundled template (or append the audit-trail
line to the existing HTML).

### Step 3 — Drop (action didn't happen)

Delete the marker file at `.spades-anywhere/quick/<Q-id>.md`
(and the `.html` companion if present). Git history records the
delete; no other audit-trail entry is needed.

Print a single confirmation line:

> *`Q-<id>` dropped. Action didn't happen; marker deleted.*

### Step 4 — Linear mirror (when `backend: linear`)

If `linear_issue_id` is present in the marker (capture it before
Step 3 deletes the file):

- On Step 2 flip: move the Linear issue from In Progress → Done.
  Post a comment: *"Closed via `/spades-anywhere:close Q-<id>`.
  Evidence: `<evidence_ref>`."*
- On Step 3 drop: move the Linear issue from In Progress →
  Cancelled (or Backlog, if your team uses that for
  not-done-not-failed). Post a comment: *"Quick item dropped —
  action did not happen."*

### Step 5 — Confirm

Print one line in CLI mode (HTML mode: the marker's `.html` is
already updated):

- On flip: *`✓ Q-<id> shipped. Evidence: <evidence_ref>.`*
- On drop: *`✓ Q-<id> dropped.`*

No Scope rollup. Quick items are leaf nodes — they don't have
parents in the audit-trail sense.
