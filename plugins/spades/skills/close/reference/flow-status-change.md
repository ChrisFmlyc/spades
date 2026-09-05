# Flow — status changes (reject, roll-up, archive, complete, abandon)

Reached from `SKILL.md` Step 3 for every close that sets a terminal
status on one artefact, records why, and lands it via a bookkeeping
PR. Seven routes share one shape; the table supplies the values and
the pre-checks below supply the route-specific judgement.

All routes run SKILL.md's **B1** (preconditions), **B2** (branch),
**B3** (commit), **B4** (PR), **B5** (verify merge), **B6** (retain worktree),
**B7** (Linear mirror).

## Contents

- The route table
- Route-specific pre-checks
- Linear mirror per route
- Step sequence and confirmation
- No cascade

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

Slugs drop the `P-` / `S-` / `O-` prefix, lower-case, truncate to 50
characters, and validate per B2. Every route sets `updated:` to
today. Files edited: `.spades/plans/<id>.md`,
`.spades/scopes/<id>.md`, `.spades/projects/<slug>.md`,
`.spades/objectives/<id>.md`.

## Route-specific pre-checks (after B1, before B2)

**All routes** — a target already terminal aborts: *"`<id>` is
already `<status>`. Terminal means terminal."*

**Plan reject** — applies to `approved`, `delivering`, `evaluating`,
`shipping`. With a `PR opened:` line and no `Shipped`, query the PR
and inform: *"PR `<URL>` is currently `<state>`. Rejecting marks the
Plan rejected; close the PR on GitHub if you haven't."* The
rejection proceeds either way.

**Scope roll-up** — classify every child Plan:

- **All `shipped`, criteria covered** → proceed.
- **All `shipped`, criteria left uncovered** → surface the uncovered
  ones and ask: leave open (recommended) or roll up with them
  recorded in the audit line.
- **Mix of `shipped` and `rejected`, ≥1 `shipped`** → prompt with
  the rejected siblings; include the acknowledged IDs in the line.
- **All `rejected`** → abort: *"Scope `<id>` has no shipped Plans.
  Roll-up to `done` doesn't apply; use *Abandon* if you're walking
  away."*
- **Any in flight** → abort with the list.

**Project archive** — with child Scopes in flight, list them and ask
via `AskUserQuestion`: *Proceed — archive; in-flight Scopes keep
their status* / *Abort — close them first*. Archive needs no reason;
graceful sunset is its own explanation.

**Objectives (both routes)** — resolve
`.spades/objectives/O-<slug>.md` (abort if missing). The
parent-status precondition does not apply: Objectives are
independent of the Project's lifecycle. With `backend: linear`,
probe the sister `O-` issue first; if it is already Done, this run
is a reconcile of the local record.

## Linear mirror (B7) per route

| Route | Mirror |
|---|---|
| Plan reject | Sub-issue → Cancelled; label `spades:rejected`; comment *"Rejected. Reason: `<reason>`. Bookkeeping PR: `<URL>`."* |
| Scope roll-up | Parent Issue → Done |
| Scope abandon | Parent Issue → Cancelled; label `spades:abandoned`; comment *"Abandoned. Reason: `<reason>`. Bookkeeping PR: `<URL>`. No cascade — child sub-issues unchanged."* |
| Project archive | Linear Project → Completed |
| Project abandon | Linear Project → Canceled; without a project-level cancelled state, label `spades:abandoned` and tell the human |
| Objective complete | Sister `O-` issue → Done (the act that marks the milestone complete); comment *"Objective complete (team-lead judgement). Bookkeeping PR: `<URL>`."* Project and Scopes untouched. |
| Objective abandon | Sister `O-` issue → Cancelled; label `spades:abandoned`; comment *"Objective abandoned. Reason: `<reason>`. Bookkeeping PR: `<URL>`."* |

With `backend: local` the file on `main` is the record.

## Step sequence

1. **B1** — Reject and Abandon skip the parent-status precondition.
2. Route-specific pre-check.
3. **B2** — branch from the table.
4. Edit the target: `status:`, `updated:`, audit line.
5. **B3** — subject from the table; the body states the reason
   where one applies and the no-cascade guarantee, citing
   `docs/FRAMEWORK.md § Terminal States` (or `§ Hierarchy →
   Objectives`).
6. **B4** → **B5** → **B6**.
7. **B7** per the table.
8. Confirm:

```
✓ <Verb>:                 <id>
✓ Reason:                 <reason>                    # reject / abandon
✓ Bookkeeping PR merged:  <bookkeeping-pr-url>
✓ Linear mirror:          <per the table>             # backend: linear
✓ <Children>:             unchanged (no cascade)
✓ Status:                 <new status>

Next:
  <two route-appropriate suggestions>
```

Next steps: Plan reject → `/spades:plan S-<scope>` and
`/spades:list`; Scope or Project abandon → `/spades:list all` and
`/spades:status`; Objective complete → `/spades:objective` and
`/spades:status`.

## No cascade

Every route changes exactly one artefact. Rejecting a Plan leaves
siblings and the Scope alone; abandoning a Scope leaves its Plans at
their status; archiving or abandoning a Project leaves its Scopes;
completing or abandoning an Objective changes nothing else. The
producing skills' parent-status refusal is the other half of this
design: nothing auto-rejects, and no new work starts under a dead
ancestor.
