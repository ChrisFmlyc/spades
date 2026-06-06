---
name: close
description: The single conversational entry point for closing out a Plan, Scope, or Project in spades-anywhere. Asks the human what they're doing — finalise as shipped/done/archived (the happy path), reject (Plans only), or abandon (Scopes and Projects only). Always asks before acting; flags `--reject "reason"` and `--abandon "reason"` are optional power-user shortcuts that skip the menu but still capture a reason. Use whenever someone says "close this", "close P-…", "close S-…", "we're not doing this", "abandon this scope", "reject this plan". The skill figures out which flow applies. No SCM, no PR — all close flows are pure metadata writes.
version: 1.1.0
---

# /spades-anywhere:close

You are the close-out entry point. The human tells you what to
close; **you ask them what kind of close it is** — pass, reject,
or abandon — and you do the right thing based on the target type
and their answer.

Four close flows live in this skill:

1. **Pass** (happy path) — finalise the artefact's lifecycle.
   - Plan → `status: shipped` (requires `Shipped (artefact)` or
     `Shipped (action)` line in audit trail).
   - Scope → `status: done` (only when every child Plan is
     terminal; mixed-terminal rollup applies).
   - Project → `status: archived` (graceful sunset).
   - Quick item → `status: shipped` (the human confirms with
     evidence; the marker is updated with the actual action +
     evidence).
2. **Reject** — Plan rollback. Plan → `status: rejected`. Applies
   to Plans in any non-terminal status (`approved`, `delivering`,
   `evaluating`, `shipping`). A Plan in `draft` doesn't need
   rejection — the menu offers *"leave in draft (no-op)"* instead.
   Requires a reason.
3. **Abandon** — terminal walk-away on a container. Scope or
   Project → `status: abandoned`. Plans cannot be abandoned (they
   are attempts, not initiatives — see `docs/FRAMEWORK.md §
   Terminal States`). Requires a reason.
4. **Drop** — quick-item bail. Quick item whose action was
   abandoned or didn't happen → delete the marker file. Quick
   items have no `rejected` / `abandoned` terminal status (per
   the framework's deliberate non-goal); the marker file is just
   removed. No reason required.

The sister `spades` plugin's `/spades:close` opens bookkeeping PRs
because spades publishes code through git. `spades-anywhere` has
no SCM; all flows are pure metadata writes (file edits + Linear
mirror when applicable). The conversational shape is identical for
process symmetry.

Read `docs/FRAMEWORK.md` § Target Resolution, § Scope status
rollup, and § Terminal States before running.

## Conversational Entry

**Step 0 — Detect the target.**

- If the human passed an explicit ID, resolve it by prefix:
  `P-<slug>-<suffix>` → Plan; `S-<slug>` → Scope; `Q-<slug>-<suffix>`
  → Quick item; bare slug that matches a
  `.spades-anywhere/projects/<slug>.<ext>` → Project.
- If no ID was passed, ask via `AskUserQuestion`:
  - *Plan* → run the Plan picker (status filter: `approved`,
    `delivering`, `evaluating`, `shipping`).
  - *Scope* → run the Scope picker (status filter: any
    non-terminal).
  - *Quick item* → run the Quick-item picker (glob
    `.spades-anywhere/quick/Q-*.md`, status filter: `shipping`).
  - *Project* → run the Project picker (status filter: `active`).
- If the human gave an ambiguous reference, surface 1–3 best
  candidates and ask which one. Don't guess silently.
- **If the resolved target is a Quick item, skip Step 1 and go
  directly to the Quick Close Flow** — quick items have no
  multi-option menu (the action is to flip to shipped with evidence,
  or drop the marker if the human didn't end up doing it).

**Step 1 — Ask what kind of close.**

Read the target's current `status:` first; the menu options are
conditional on that.

For **Plans**:

| Plan status | Menu options |
|---|---|
| `draft` | *Leave in draft (no-op)* / *Reject* |
| `approved` | *Reject* (no pass — Plan hasn't been delivered yet) |
| `delivering` | *Reject* (no pass — Plan hasn't been evaluated) |
| `evaluating` | *Reject* (no pass — Plan hasn't shipped) |
| `shipping` (with `Shipped (artefact)`/`Shipped (action)` line and no `Closed` line) | *Pass — finalise as shipped (proceed to roll-up + Linear mirror)* / *Reject* |
| `shipped` / `rejected` | abort: *"Plan `<id>` is already `<status>`. Terminal means terminal."* |

For **Scopes**:

| Scope status | Menu options |
|---|---|
| `scoped` / `planning` (no Plans started) | *Abandon* (no pass — nothing to roll up) |
| `delivering` / `evaluating` / `shipping` | *Pass — roll up to done (requires every Plan terminal; mixed-terminal aware)* / *Abandon* |
| `done` / `abandoned` | abort: *"Scope `<id>` is already `<status>`."* |

For **Projects**:

| Project status | Menu options |
|---|---|
| `active` | *Pass — archive (graceful sunset)* / *Abandon* |
| `archived` / `abandoned` | abort: *"Project `<slug>` is already `<status>`."* |

**Step 2 — Capture a reason (Reject / Abandon only).**

If the human picked *Reject* or *Abandon*, follow up with a
free-form prompt: *"Brief reason (one line) — why are you
[rejecting / abandoning]?"* The reason is **required**; pressing
through with an empty string re-prompts with: *"Rejecting /
abandoning needs a reason. The audit trail loses meaning without
one."*

**Step 3 — Route to the matching flow.**

- *Leave in draft (no-op)* → exit cleanly. Print *"Plan `<id>` left
  at `draft`. Run `/spades-anywhere:approve` when ready."*
- *Pass* on a Plan → continue to **Plan Pass Flow** (the existing
  Pre-Flight + Steps 1–5 below).
- *Pass* on a Scope → continue to **Scope Roll-Up Flow** (new; see
  below). Mixed-terminal aware.
- *Pass* on a Project → continue to **Project Archive Flow** (new;
  see below).
- *Reject* on a Plan → continue to **Plan Reject Flow** (new; see
  below).
- *Abandon* on a Scope → continue to **Scope Abandonment Flow**
  (existing; below).
- *Abandon* on a Project → continue to **Project Abandonment Flow**
  (existing; below).
- Quick item (resolved at Step 0) → continue to **Quick Close
  Flow** (no Step 1 menu).

## Power-user Shortcuts

For automation, two flags skip Step 1's menu but still capture the
reason inline:

- `/spades-anywhere:close P-foo --reject "reason"` — skip to Plan
  Reject Flow.
- `/spades-anywhere:close S-foo --abandon "reason"` — skip to Scope
  Abandonment Flow.
- `/spades-anywhere:close <project-slug> --abandon "reason"` — skip
  to Project Abandonment Flow.

Invalid flag/target combos abort:
- `--abandon` with a Plan ID → *"Plans use `rejected`. Use
  `--reject "reason"` instead."*
- `--reject` with a Scope or Project → *"Scopes and Projects use
  `abandoned`. Use `--abandon "reason"` instead."*
- Either flag with no reason text → *"<flag> needs a reason. Re-run
  with `<flag> "reason text here"`."*

### Output format

This skill honours `review_format:` from `.spades-anywhere/config`
per `docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. In HTML mode,
auto-open the Plan's existing `.html` file via the OPEN_CMD prelude.
**In HTML mode the open `.html` IS the review surface — do NOT also
paste / summarise the Plan body or audit trail to the CLI; the
human has the browser tab.** Short conversational text (rollup
acknowledgement, the final `✓ Plan closed …` confirmation, error
messages) stays CLI as today. In CLI mode, summarise inline. See
`docs/FRAMEWORK.md § Output Format → What counts as review-form text`
for the canonical line.

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

## Plan Pass Flow — Pre-Flight + Steps 1–5

Reached when target is a Plan in `status: shipping` and the human
picked *Pass* (or invoked bare `/close P-foo` with a Shipped marker
in the audit trail).

### Pre-Flight

1. **Confirm setup + active project.** Read `.spades-anywhere/config`.
   Abort otherwise.

2. **Resolve the target Plan** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill's parameters:
   - **Artefact type:** Plan (no type-question needed).
   - **Status filter:** `status: shipping` AND audit trail contains a
     `Shipped (artefact)` or `Shipped (action)` line AND no later
     `Closed` line.
   - **Zero-candidate suggestion:** `/spades-anywhere:ship P-…` to
     capture shipment evidence first.

   If exactly one candidate matches and the human passed no Plan ID,
   pick it silently and announce. Otherwise, run the interactive
   picker.

3. **Read the Plan and parent Scope.** Capture:
   - `plan_id`, `scope_id`, `project_slug`.
   - The shipment marker line from the Plan's audit trail (artefact
     reference or action evidence summary).

4. **Open the artefact (HTML mode only).** Read `review_format:` from
   `.spades-anywhere/config`. When `review_format: html`, run the
   OPEN_CMD prelude (`docs/FRAMEWORK.md § OPEN_CMD detection prelude`)
   and open the Plan's `.html`. In CLI mode, summarise inline as today.

## Step 1 — Update the Plan

- Frontmatter `status:` → `shipped`.
- Frontmatter `updated:` → today's date.
- Append to the `## Audit Trail` section:

  ```markdown
  - YYYY-MM-DD: Closed. Plan finalised; status: shipped.
  ```

## Step 2 — Roll up the parent Scope (mixed-terminal aware)

Read every sibling Plan under `scope_id`. Classify each:

- `shipped` — terminal, success.
- `rejected` — terminal, abandoned (rejection was a prior explicit
  decision; the rejected Plan is a leaf state on its own track).
- Anything else (`draft`, `approved`, `delivering`, `evaluating`,
  `shipping`) — still in flight.

Rules:

- **Every sibling is `shipped`** → roll up silently. Update
  `.spades-anywhere/scopes/<scope_id>.md` frontmatter `status:` →
  `done`, `updated:` → today. Append to the Scope's `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: All plans shipped. Scope done.
  ```

- **Every sibling is terminal (mix of `shipped` and `rejected`) and at
  least one is `shipped`** → ask the human to acknowledge the rollup
  via `AskUserQuestion`, listing the rejected siblings so the
  acknowledgement is informed:

  > *Rolling up Scope `<scope_id>` to `done`. The following Plans were
  > rejected and will be acknowledged in the audit trail:*
  > - *`P-<rejected-id-1>` — "<title>"*
  > - *`P-<rejected-id-2>` — "<title>"*
  >
  > - **Roll up — mark Scope `done`** *(recommended)*
  > - **Leave Scope at `shipping` — I'll come back to this**

  If **Roll up**: update Scope frontmatter and append:

  ```markdown
  - YYYY-MM-DD: All plans terminal. Shipped: <n>. Rejected: <m>
    (acknowledged: P-<id-1>, P-<id-2>). Scope done.
  ```

  If **Leave**: skip the Scope edit; record the deferred ack:

  ```markdown
  - YYYY-MM-DD: Close run on P-<…>; Scope rollup deferred (rejected
    siblings present, human chose to revisit).
  ```

- **Every sibling is `rejected` (no `shipped`)** → do not roll up to
  `done`. A Scope where every Plan was abandoned is not "done" — it
  is closed in failure. Surface this and stop short of rolling up:

  > *Every Plan under Scope `<scope_id>` is rejected. The Scope
  > didn't ship anything. Leaving it at `shipping`; consider
  > re-scoping or abandoning the Scope explicitly via a follow-up
  > Plan.*

  No Scope edit. The Plan close-out itself still proceeds.

- **At least one sibling still in flight** → no rollup. Surface
  briefly which siblings remain (one-line list).

## Step 3 — Linear mirror (when `backend: linear`)

When `backend: linear`:

- Update the Plan's sub-issue → status `Done`.
- If the Scope was rolled up to `done`, also update the parent Issue
  → `Done`.
- Post a comment on the sub-issue summarising the close-out:

  > *Closed. Shipment recorded: `<artefact-ref-or-action-summary>`.*
  > *Scope rolled up: yes / no (deferred / blocked).*

When `backend: local`: nothing to mirror. Local files are the source
of truth.

Follow the fan-out pattern from `docs/FRAMEWORK.md § Sub-agent
Dispatch (Fan-Out)`. Spawn the file writes and Linear mirror in
parallel (single assistant message, multiple `Agent` tool calls,
`subagent_type: general-purpose`):

| Sub-agent | Resource owned | Returns |
|-----------|---------------|---------|
| `worker-file-plan-close` | `.spades-anywhere/plans/P-<…>.<ext>` — update frontmatter (`status: shipped`, `updated: <today>`) and append the audit-trail line. | `{ status: ok }` |
| `worker-file-scope-rollup` *(only when rollup applies)* | `.spades-anywhere/scopes/S-<…>.<ext>` — update frontmatter (`status: done`, `updated: <today>`) and append the rollup audit-trail line. | `{ status: ok }` |
| `worker-linear-close` *(only when `backend: linear`)* | Linear — update Plan sub-issue → Done; update parent Issue → Done if rollup applied; post the close-out comment. Includes the Layer-2 freshness probe. | `{ status: ok }` |

Failure semantics per `FRAMEWORK.md § Sub-agent Dispatch`:

- **All ok** → proceed to Step 4.
- **`worker-file-plan-close` failed** → abort; the Plan stays at
  `status: shipping`. Surface the error.
- **`worker-file-scope-rollup` failed** → surface partial state; the
  Plan is closed but the Scope rollup needs manual patch.
- **`worker-linear-close` failed** → keep local files canonical;
  surface the Linear failure with a retry hint.

## Step 4 — Suggest a Learning

Most close-outs produce something worth remembering. Ask via
`AskUserQuestion`:

- **Capture a learning** *(recommended)* — invokes
  `/spades-anywhere:learn`
- **Skip** — no learning this time

If yes, hand off to `/spades-anywhere:learn` with the plan ID as
context. The learning will be tagged and stored under
`.spades-anywhere/learnings/`.

## Step 5 — Confirm

```
✓ Plan closed:    P-host-birthday-party-3HyD
✓ Plan status:    shipped
✓ Scope:          S-plan-birthday-party (done — all plans terminal)   # adapt rollup line
✓ Linear mirror:  sub-issue Done, parent Issue Done                   # omit when backend: local
✓ Status:         shipped

Next:
  /spades-anywhere:learn                       — capture a learning
  /spades-anywhere:status                      — see what's still open
```

Rollup line variants:
- `(done — all plans shipped)` — clean rollup, no rejections
- `(done — N shipped, M rejected acknowledged)` — mixed-terminal rollup
- `(shipping — rollup deferred, human will revisit)` — human chose to leave
- `(shipping — N still in flight)` — siblings remain
- `(shipping — every Plan rejected, Scope didn't ship)` — failure case

## Plan Reject Flow

Reached when target is a Plan in `approved`, `delivering`,
`evaluating`, or `shipping`, and the human picked *Reject* (or
invoked `/close P-foo --reject "reason"`). Plans in `draft` use
*"leave in draft (no-op)"* — no skill action.

A reject is a Plan rollback. Pure metadata write — no SCM, no PR.
Sibling Plans and the parent Scope are unchanged.

### R1. Pre-Flight
1. **Confirm setup + active project.** Read
   `.spades-anywhere/config`.
2. **Resolve the Plan** and read current `status:`. Refuse if
   already `shipped` or `rejected`.
3. **HTML mode** — auto-open the Plan's existing `.html`. Don't
   paste the Plan body to CLI.

### R2. Edit the Plan file
- Frontmatter `status:` → `rejected`.
- Frontmatter `updated:` → today's date.
- Append to `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: Rejected. Reason: <reason>.
  ```

### R3. Linear mirror (when `backend: linear`)
- Update sub-issue → `Cancelled` (or team equivalent).
- Apply label `spades:rejected`.
- Comment: *"Rejected. Reason: `<reason>`. Parent Scope and sibling
  Plans unchanged."*

Fan-out pattern (per `docs/FRAMEWORK.md § Sub-agent Dispatch`):
local-file edit + Linear mirror run in parallel. Local file is
canonical; Linear failure is surfaced and retryable.

### R4. Confirm
```
✓ Plan rejected:    <plan_id>
✓ Reason:           <reason>
✓ Linear mirror:    sub-issue Cancelled                # omit when backend: local
✓ Sibling Plans:    unchanged (no cascade)
✓ Parent Scope:     unchanged

Next:
  /spades-anywhere:plan S-<scope>   — draft a replacement Plan toward the same goal
  /spades-anywhere:list             — see what else is active
```

## Scope Roll-Up Flow

Reached when target is a Scope in `delivering`/`evaluating`/
`shipping` and the human picked *Pass*. Standalone roll-up — the
human explicitly chooses to roll up (e.g. after a deferred ack, or
when child Plans terminated out of order).

### U1. Pre-Flight
1. **Confirm setup + active project.**
2. **Resolve the Scope.** Refuse if already `done` or `abandoned`.
3. **Read every sibling Plan.** Classify as `shipped`, `rejected`,
   or still in flight.
4. **Decide the rollup:**
   - **Every Plan `shipped`** → proceed.
   - **Mix of `shipped` and `rejected`, ≥1 `shipped`** → prompt with
     the rejected siblings list (mixed-terminal ack). Proceed on
     confirmation.
   - **Every Plan `rejected`** → abort: *"Scope `<id>` has no
     shipped Plans. Roll-up to `done` doesn't apply. Use *Abandon*
     if you're walking away."*
   - **Any Plan still in flight** → abort with the list.

### U2. Edit the Scope file
- Frontmatter `status:` → `done`.
- Frontmatter `updated:` → today's date.
- Append to `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: All plans terminal. Shipped: <n>. Rejected: <m>[ (acknowledged: P-<id-1>, P-<id-2>)]. Scope done.
  ```

### U3. Linear mirror
- Parent Issue → `Done`.
- If every sub-issue is now `Done`, that's already the case from
  prior Plan closes; no additional action.

### U4. Confirm
```
✓ Scope rolled up:  <S-id> → done
✓ Plans terminal:   <n> shipped, <m> rejected
✓ Linear mirror:    parent Issue Done                  # omit when backend: local

Next:
  /spades-anywhere:list           — see what else is active
```

## Project Archive Flow

Reached when target is a Project in `active` and the human picked
*Pass*. Archived is the graceful-sunset terminal state — distinct
from `abandoned` (see `docs/FRAMEWORK.md § Terminal States`). No
reason required.

### V1. Pre-Flight
1. **Confirm setup.**
2. **Resolve the Project** by slug. Refuse if already `archived`
   or `abandoned`.
3. **Check active child work.** If any Scope under this Project is
   still in flight, surface the list and ask via `AskUserQuestion`:
   - *Proceed anyway — archive the Project; in-flight Scopes stay
     at their current status (no cascade).*
   - *Abort — close the in-flight Scopes first.*

### V2. Edit the Project file
- Frontmatter `status:` → `archived`.
- Frontmatter `updated:` → today's date.
- Append to `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: Archived. Project lifecycle complete.[ Active child Scopes at archive: <list>.]
  ```

### V3. Linear mirror
- Update the Linear Project to `Completed` (or equivalent
  graceful-terminal state).

### V4. Confirm
```
✓ Project archived: <project-slug>
✓ Linear mirror:    Project Completed                  # omit when backend: local
✓ Child Scopes:     unchanged (no cascade)

Next:
  /spades-anywhere:list --project <other>  — switch to a different project
```

## Scope Abandonment Flow

Reached when target is `S-<slug>` and `--abandon "reason"` is set.
See `docs/FRAMEWORK.md § Terminal States` for the contract. No PR,
no SCM — pure metadata write.

### A1. Pre-Flight
1. **Confirm setup + active project.** Read `.spades-anywhere/config`.
2. **Resolve the Scope.** Read
   `.spades-anywhere/scopes/<S-id>.<ext>`. Abort if missing.
3. **Refuse if already terminal.** If `status:` is already
   `abandoned` or `done`, abort with: *"Scope `<S-id>` is already
   `<status>`. Terminal means terminal."*
4. **HTML mode** — auto-open the Scope's existing `.html` via the
   OPEN_CMD prelude. Don't paste the Scope body to CLI.

### A2. Edit the Scope file
- Frontmatter `status:` → `abandoned`.
- Frontmatter `updated:` → today's date.
- Append to `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: Abandoned. Reason: <reason>.
  ```

### A3. Linear mirror (when `backend: linear`)
- Update parent Issue → status `Cancelled` (or the team's equivalent
  for "abandoned" — fall back to `Canceled`).
- Apply label `spades:abandoned` to the parent Issue.
- Post a comment: *"Abandoned. Reason: `<reason>`. No cascade —
  child sub-issues unchanged; see `docs/FRAMEWORK.md § Terminal
  States`."*

Apply the fan-out pattern from `docs/FRAMEWORK.md § Sub-agent
Dispatch (Fan-Out)` if both local-file edit and Linear mirror need
to happen. Failure semantics: local file is canonical; Linear
failure is surfaced and retryable.

### A4. Confirm
```
✓ Scope abandoned:   <S-id>
✓ Reason:            <reason>
✓ Linear mirror:     parent Issue Cancelled              # omit when backend: local
✓ Child Plans:       unchanged (no cascade)
✓ Status:            abandoned

Next:
  /spades-anywhere:list all     — see abandoned Scopes alongside active
  /spades-anywhere:status       — review remaining active work
```

## Project Abandonment Flow

Reached when target is `<project-slug>` and `--abandon "reason"` is
set. Identical shape to Scope abandonment, with two differences:

1. Target file is `.spades-anywhere/projects/<project-slug>.<ext>`,
   not a Scope.
2. Linear mirror updates the Linear *Project* (not an Issue) to
   `Canceled`/`Cancelled`. If the team doesn't have a project-level
   "cancelled" status, apply a `spades:abandoned` label on the
   project and surface the limitation to the human.

Pre-Flight, edit, Linear mirror, confirm — all follow the Scope
abandonment shape. The audit-trail line is identical:

```markdown
- YYYY-MM-DD: Abandoned. Reason: <reason>.
```

No cascade to child Scopes (which keep their own statuses). The
project's `abandoned` is the authoritative signal.

## Edge Cases

- **Plan is already `status: shipped`.** Surface: *"Plan `<id>` is
  already shipped. Nothing to close out. Re-run
  `/spades-anywhere:ship` if you need to amend the shipment record."*
  Exit cleanly.

- **No `Shipped (artefact)` or `Shipped (action)` line in the audit
  trail.** Surface and abort: *"Plan `<id>` is in `status: shipping`
  but has no shipment marker. Run `/spades-anywhere:ship P-<id>`
  first to capture the evidence."*

- **Mixed-terminal Scope where human chose "Leave".** The deferred
  ack stays in the Plan's audit trail; re-running `/spades-anywhere:close`
  on another sibling later (or `/spades-anywhere:status`) will offer
  the rollup again.

- **`backend: linear` and Linear is unreachable.** The local files
  are canonical. Surface the Linear failure; the human can re-run to
  retry the mirror once Linear is reachable, or accept the drift and
  reconcile manually.

- **Abandon target is already terminal.** Pre-Flight Step A3 catches
  this; abort without touching files.

- **`--abandon` passed with a Plan ID.** Target-Type Routing catches
  this; explains that Plans use `rejected` (via Approve/Evaluate
  gates), not `abandoned`.
