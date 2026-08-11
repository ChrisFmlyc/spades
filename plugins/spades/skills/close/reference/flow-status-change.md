# Flow — status changes (reject, roll-up, archive, complete, abandon)

Reached from `SKILL.md` Step 3 for every close that is *"set a
terminal status on one artefact, record why, and land it via a
bookkeeping PR"*. Seven routes share one shape, so they share one
file; only the values in the table below differ.

All of them run SKILL.md's shared machinery — **B1** (preconditions),
**B2** (branch), **B3** (commit), **B4** (PR), **B5** (verify merge), **B6**
(cleanup), **B7** (Linear mirror). This file supplies the per-route
values and the handful of route-specific pre-checks.

## Contents

- The route table — status, branch, audit line, commit subject
- Route-specific pre-checks (reject, roll-up, archive, objective)
- Linear mirror per route
- The shared step sequence and confirmation shape
- No-cascade guarantees

## The route table

| Route | Target | `status:` → | Branch `chore/…` | Audit-trail line | Commit subject |
|---|---|---|---|---|---|
| **Plan reject** | `P-<slug>-<sfx>` | `rejected` | `reject-<plan-slug>` | `Plan rejected. Reason: <reason>.` | `reject <plan_id>` |
| **Scope roll-up** | `S-<slug>` | `done` | `rollup-<scope-slug>` | `All plans terminal. Shipped: <n>. Rejected: <m>[ (acknowledged: …)]. Scope done.` | `rollup <S-id>` |
| **Scope abandon** | `S-<slug>` | `abandoned` | `abandon-<scope-slug>` | `Scope abandoned. Reason: <reason>.` | `abandon <S-id>` |
| **Project archive** | `<project-slug>` | `archived` | `archive-project-<slug>` | `Archived. Project lifecycle complete.[ Active child Scopes at archive: <list>.]` | `archive <project-slug>` |
| **Project abandon** | `<project-slug>` | `abandoned` | `abandon-project-<slug>` | `Project abandoned. Reason: <reason>.` | `abandon <project-slug>` |
| **Objective complete** | `O-<slug>` | `complete` | `complete-<obj-slug>` | `Objective complete (team-lead judgement).` | `complete <O-id>` |
| **Objective abandon** | `O-<slug>` | `abandoned` | `abandon-<obj-slug>` | `Objective abandoned. Reason: <reason>.` | `abandon <O-id>` |

Slugs drop their `P-` / `S-` / `O-` prefix and are lower-cased;
truncate to 50 chars and validate against `/repo:branch`'s regex per
B2. Every route also sets `updated:` to today.

Files edited: `.spades/plans/<id>.md`, `.spades/scopes/<id>.md`,
`.spades/projects/<slug>.md`, `.spades/objectives/<id>.md`
respectively — plus the `.html` companion when present in HTML mode.

## Route-specific pre-checks

Run these **after B1**, before B2.

**All routes** — refuse if the target is already terminal: *"`<id>`
is already `<status>`. Terminal means terminal."*

**Plan reject.** Applies to `approved`, `delivering`, `evaluating`,
`shipping`. If the audit trail has a `PR opened:` line with no later
`Shipped`, query the PR state and surface it: *"PR `<URL>` is
currently `<state>`. Rejecting will mark the Plan rejected but won't
close the PR — close it on GitHub if you haven't already."*
Informational only; the rejection proceeds either way.

**Scope roll-up.** Read every child Plan and classify it `shipped`,
`rejected`, or in flight, then decide:

- **All `shipped`, criteria covered** → proceed; unambiguous.
- **All `shipped`, but acceptance criteria left uncovered** → do not
  roll up silently. *All Plans terminal* is not *the Scope is done*:
  if Plans were deferred and never written, this is true of a Scope
  whose criteria are mostly untouched. Surface the uncovered ones and
  ask — leave open (recommended), or roll up with them recorded.
- **Mix of `shipped` and `rejected`, ≥1 `shipped`** → prompt with
  the rejected siblings listed (mixed-terminal acknowledgement).
  Proceed on confirmation; include the acknowledged IDs in the audit
  line.
- **All `rejected`** → abort: *"Scope `<id>` has no shipped Plans.
  Roll-up to `done` doesn't apply. Use *Abandon* instead if you're
  walking away."*
- **Any still in flight** → abort: *"Scope `<id>` has Plans still in
  flight (`<list>`). Wait for them to terminate, or abandon the
  Scope."*

**Project archive.** If any child Scope is still in flight
(`scoped` / `planning` / `delivering` / `evaluating` / `shipping`),
list them and ask via `AskUserQuestion`: *Proceed anyway — archive
the Project; in-flight Scopes stay at their current status (no
cascade)* / *Abort — close the in-flight Scopes first*.

A reason is **not required** for archive — the action is graceful
sunset, and the absence of a reason is itself the signal. A human
who wants one can edit the audit line on the bookkeeping branch.

**Objectives (both routes).** Resolve
`.spades/objectives/O-<slug>.md`; abort if missing. **Do not apply
the parent-status precondition** — Objectives are exempt on close,
being independent of Project lifecycle. When `backend: linear`,
probe the sister `O-` tracking issue first: if it is already `Done`,
note that this run is a **reconcile** — the local `.md` is being
brought into line with an already-recorded completion signal.

## Linear mirror (B7) per route

| Route | Mirror |
|---|---|
| Plan reject | Sub-issue → `Cancelled`; label `spades:rejected`; comment *"Rejected. Reason: `<reason>`. Bookkeeping PR: `<URL>`."* |
| Scope roll-up | Parent Issue → `Done` |
| Scope abandon | Parent Issue → `Cancelled`; label `spades:abandoned`; comment *"Abandoned. Reason: `<reason>`. Bookkeeping PR: `<URL>`. No cascade — child sub-issues unchanged."* |
| Project archive | Linear Project → `Completed` (or equivalent) |
| Project abandon | Linear **Project** (not an Issue) → `Canceled`. If the team has no project-level cancelled status, apply a `spades:abandoned` label and **surface the limitation to the human.** |
| Objective complete | Sister `O-` issue → `Done` — *this is the act that marks the milestone complete; that's how Linear knows.* If the O1 probe found it already `Done`, leave it and just post the comment: *"Objective complete (team-lead judgement). Bookkeeping PR: `<URL>`."* **Do not touch the Project or any Scope.** |
| Objective abandon | Sister `O-` issue → `Cancelled`; label `spades:abandoned`; comment *"Objective abandoned. Reason: `<reason>`. Bookkeeping PR: `<URL>`."* |

When `backend: local` there is nothing to mirror — the file on
`main` is the record.

## The step sequence

1. **B1** — preconditions. (Reject and Abandon skip the
   parent-status precondition; they *create* terminal status.)
2. Route-specific pre-check above.
3. **B2** — branch, named from the table.
4. Edit the target file: `status:` and `updated:` from the table,
   plus the audit-trail line.
5. **B3** — commit. Subject from the table; body states the reason
   (where one applies) and the no-cascade guarantee, citing
   `docs/FRAMEWORK.md § Terminal States` (or
   `§ Hierarchy → Objectives` for Objectives).
6. **B4** → **B5** → **B6** — PR, verify the merge, cleanup.
7. **B7** — mirror per the table above.
8. Confirm.

## Confirmation shape

```
✓ <Verb>:                 <id>
✓ Reason:                 <reason>                    # omit for archive / objective complete
✓ Bookkeeping PR merged:  <bookkeeping-pr-url>
✓ Linear mirror:          <per the table>             # omit when backend: local
✓ <Children>:             unchanged (no cascade)
✓ Status:                 <new status>

Next:
  <two route-appropriate suggestions>
```

Route-appropriate next steps: Plan reject → `/spades:plan S-<scope>`
(draft a replacement toward the same goal) and `/spades:list`. Scope
or Project abandon → `/spades:list all` and `/spades:status`.
Objective complete → `/spades:objective` (set the next one) and
`/spades:status`.

## No-cascade guarantees

Every route on this page is **non-cascading**, and the confirmation
says so explicitly:

- Rejecting a Plan leaves sibling Plans and the parent Scope
  untouched.
- Abandoning a Scope leaves its child Plans at their current status.
- Archiving or abandoning a Project leaves child Scopes at theirs.
- Completing or abandoning an Objective changes nothing else at all
  — not the Project, not any Scope.

This is deliberate and is paired with the hard parent-status refusal
in producing skills (`FRAMEWORK.md § Target Resolution →
Parent-status precondition`): nothing auto-rejects, but no new work
may start under a dead ancestor.
