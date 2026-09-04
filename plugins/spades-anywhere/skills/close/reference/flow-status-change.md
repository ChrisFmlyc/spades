# Flow — status changes (reject, roll-up, archive, complete, abandon)

Reached from `SKILL.md` Step 3 for every close that sets a terminal
status on one artefact and records why. Seven routes share one
shape: pre-check, edit the file, mirror to Linear, confirm.

## Contents

- The route table
- Route-specific pre-checks
- Linear mirror per route
- Step sequence and confirmation
- No cascade

## The route table

| Route | Target | `status:` → | Audit-trail line |
|---|---|---|---|
| **Plan reject** | `P-<slug>-<sfx>` | `rejected` | `Rejected. Reason: <reason>.` |
| **Scope roll-up** | `S-<slug>` | `done` | `All plans terminal. Shipped: <n>. Rejected: <m>[ (acknowledged: …)]. Scope done.` |
| **Scope abandon** | `S-<slug>` | `abandoned` | `Abandoned. Reason: <reason>.` |
| **Project archive** | `<project-slug>` | `archived` | `Archived. Project lifecycle complete.[ Active child Scopes at archive: <list>.]` |
| **Project abandon** | `<project-slug>` | `abandoned` | `Abandoned. Reason: <reason>.` |
| **Objective complete** | `O-<slug>` | `complete` | `Objective complete (team-lead judgement).` |
| **Objective abandon** | `O-<slug>` | `abandoned` | `Objective abandoned. Reason: <reason>.` |

Every route sets `updated:` to today. Files edited:
`.spades-anywhere/plans/<id>.md`, `.spades-anywhere/scopes/<id>.md`,
`.spades-anywhere/projects/<slug>.md`,
`.spades-anywhere/objectives/<id>.md`.

## Route-specific pre-checks

**All routes** — a target already terminal aborts: *"`<id>` is
already `<status>`. Terminal means terminal."* HTML mode opens the
target's `.html`.

**Plan reject** — applies to `approved`, `delivering`, `evaluating`,
`shipping`.

**Scope roll-up** — classify every child Plan: all `shipped` →
proceed; a mix of `shipped` and `rejected` with at least one
`shipped` → prompt with the rejected siblings and include the
acknowledged IDs in the line; all `rejected` → abort (*"Scope `<id>`
has no shipped Plans. Use *Abandon* if you're walking away."*); any
in flight → abort with the list.

**Project archive** — with child Scopes in flight, list them and
ask via `AskUserQuestion`: *Proceed — archive; in-flight Scopes keep
their status* / *Abort — close them first*. Archive needs no reason.

**Objectives (both routes)** — resolve
`.spades-anywhere/objectives/O-<slug>.md` (abort if missing). The
parent-status precondition does not apply; Objectives are
independent of the Project's lifecycle. With `backend: linear`,
probe the sister `O-` issue first; already Done means this run
reconciles the local record.

## Linear mirror per route (`backend: linear`)

| Route | Mirror |
|---|---|
| Plan reject | Sub-issue → Cancelled; label `spades:rejected`; comment *"Rejected. Reason: `<reason>`. Parent Scope and sibling Plans unchanged."* |
| Scope roll-up | Parent Issue → Done |
| Scope abandon | Parent Issue → Cancelled; label `spades:abandoned`; comment *"Abandoned. Reason: `<reason>`. No cascade — child sub-issues unchanged."* |
| Project archive | Linear Project → Completed |
| Project abandon | Linear Project → Canceled; without a project-level cancelled state, label `spades:abandoned` and tell the human |
| Objective complete | Sister `O-` issue → Done (the act that marks the milestone complete; left alone when already Done); comment *"Objective complete (team-lead judgement)."* |
| Objective abandon | Sister `O-` issue → Cancelled; label `spades:abandoned`; comment *"Objective abandoned. Reason: `<reason>`."* |

With `backend: local` the file is the record.

## Step sequence

1. Setup and active project.
2. Resolve the target; the route-specific pre-check.
3. Edit the target: `status:`, `updated:`, the audit line.
4. Mirror per the table, in one fan-out wave with the file edit per
   `docs/FRAMEWORK.md § Sub-agent Dispatch`; the local file is
   canonical and a Linear failure is surfaced and retryable.
5. Confirm:

```
✓ <Verb>:           <id>
✓ Reason:           <reason>                    # reject / abandon
✓ Linear mirror:    <per the table>             # backend: linear
✓ <Children>:       unchanged (no cascade)
✓ Status:           <new status>

Next:
  <two route-appropriate suggestions>
```

Next steps: Plan reject → `/spades-anywhere:plan S-<scope>` and
`/spades-anywhere:list`; Scope or Project abandon →
`/spades-anywhere:list all` and `/spades-anywhere:status`; Objective
complete → `/spades-anywhere:objective` and
`/spades-anywhere:status`.

## No cascade

Every route changes exactly one artefact. Rejecting a Plan leaves
siblings and the Scope alone; abandoning a Scope leaves its Plans at
their status; archiving or abandoning a Project leaves its Scopes;
completing or abandoning an Objective changes nothing else. The
producing skills' parent-status refusal is the other half: no new
work starts under a dead ancestor.
