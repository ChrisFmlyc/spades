# Flow — Plan Pass (finalise as shipped)

Reached from `SKILL.md` Step 3 when the target is a Plan the human
confirmed is delivered and evidenced, and they picked *Pass*.

## Contents

- Pre-flight
- Step 1 — Update the Plan
- Step 2 — Roll up the parent Scope (mixed-terminal aware)
- Step 3 — Linear mirror
- Step 4 — Suggest a learning
- Step 5 — Confirm

---

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

4. **Verify ancestors active** per `docs/FRAMEWORK.md § Target
   Resolution → Parent-status precondition`. If the parent Scope is
   `abandoned`, or its parent Project is `abandoned` / `archived`,
   abort hard with the canonical error shape. No override. (The
   Reject and Abandon flows below are exempt — they *create*
   terminal status; only the Pass route is gated.)

5. **Open the artefact (HTML mode only).** Read `review_format:` from
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
