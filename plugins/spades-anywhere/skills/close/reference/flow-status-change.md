# Flow — status changes (reject, roll-up, archive, complete, abandon)

Reached from `SKILL.md` Step 3 for every close that sets a terminal
status on one artefact and records why. Seven routes share one
shape; each section below gives its specifics.

Every route on this page is **non-cascading** — rejecting a Plan
leaves siblings and the parent Scope untouched; abandoning a Scope
leaves its Plans at their current status; completing or abandoning
an Objective changes nothing else at all.

## Contents

- Plan Reject Flow
- Scope Roll-Up Flow
- Project Archive Flow
- Objective Complete Flow
- Objective Abandonment Flow
- Scope Abandonment Flow
- Project Abandonment Flow

---

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

## Objective Complete Flow

Reached when target is an Objective (`O-<slug>`) in `status: open` and the
human picked *Pass*. This is the team lead's **ungated** judgement that the
objective is reached. There is **no rollup, no gating on Scopes, and no
cascade** — completing an Objective never changes the Project's status and
never touches any Scope (see `docs/FRAMEWORK.md § Hierarchy → Objectives`).
Pure metadata write — no SCM, no PR.

### O1. Pre-Flight
1. **Confirm setup + active project.** Read `.spades-anywhere/config`.
   Abort otherwise.
2. **Resolve the Objective.** Read
   `.spades-anywhere/objectives/O-<slug>.<ext>`. Abort if missing. Refuse
   if `status:` is already `complete` or `abandoned` (*"Objective `<id>` is
   already `<status>`. Terminal means terminal."*). **Do NOT apply the
   parent-status precondition** — Objectives are exempt on close
   (independent of Project lifecycle).
3. **Linear reconcile probe (when `backend: linear`).** If the sister `O-`
   tracking issue is already `Done` in Linear (the team lead closed it
   directly), note that this run is a reconcile — the local `.md` is being
   brought into line with the already-recorded completion signal.
4. **HTML mode** — auto-open the Objective's existing `.html` via the
   OPEN_CMD prelude. Don't paste the Objective body to CLI.

### O2. Edit the Objective file
- Frontmatter `status:` → `complete`.
- Frontmatter `updated:` → today's date.
- Append to `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: Objective complete (team-lead judgement).
  ```

### O3. Linear (completion signal — when `backend: linear`)
- Move the **sister `O-` tracking issue** → `Done`. This is the act that
  marks the Objective/milestone complete — *that's how Linear knows*. (If
  it was already `Done` per the O1 reconcile probe, leave it and just record
  the comment.)
- Post a comment on the sister issue: *"Objective complete (team-lead
  judgement)."*
- Do **not** touch the Project or any Scope.

Apply the fan-out pattern from `docs/FRAMEWORK.md § Sub-agent Dispatch
(Fan-Out)` if both local-file edit and Linear mirror need to happen.
Failure semantics: local file is canonical; Linear failure is surfaced and
retryable. When `backend: local`: nothing to mirror — the `.md` is the
completion signal.

### O4. Confirm
```
✓ Objective complete:  <O-id>
✓ Linear:              sister O- issue Done; milestone complete   # omit when backend: local
✓ Project:             unchanged (no cascade)
✓ Scopes:              unchanged (independent)
✓ Status:              complete

Next:
  /spades-anywhere:objective    — set the next objective for this project
  /spades-anywhere:status       — review remaining active work
```

## Objective Abandonment Flow

Reached when target is `O-<slug>` and the human picked *Abandon* (or
invoked `/spades-anywhere:close O-foo --abandon "reason"`). Identical shape
to the Objective Complete Flow with three differences:

1. A **reason is required** (Step 2 of the conversational entry captures it,
   or the `--abandon` flag carries it).
2. Frontmatter `status:` → `abandoned`; audit line:
   ```markdown
   - YYYY-MM-DD: Objective abandoned. Reason: <reason>.
   ```
3. Linear mirror (when `backend: linear`): move the sister `O-` tracking
   issue → `Cancelled` (team equivalent), apply label `spades:abandoned`,
   and comment *"Objective abandoned. Reason: `<reason>`."* No cascade —
   Project and Scopes unchanged.

Refuse if already terminal (`complete`/`abandoned`). The parent-status
precondition does not apply (Objectives are exempt on close).

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
