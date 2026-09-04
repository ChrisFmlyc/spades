# Flow — Plan Pass (finalise as shipped)

Reached from `SKILL.md` Step 3 for a Plan at `status: shipping`
whose human picked *Pass*.

## Contents

- P1 — Pre-flight
- P2 — Update the Plan
- P3 — Roll up the parent Scope
- P4 — Write and mirror (fan-out)
- P5 — Confirm

## P1 — Pre-flight

1. **Setup and active project** from `.spades-anywhere/config`.
2. **Resolve the Plan** per `docs/FRAMEWORK.md § Target Resolution`
   — status filter `shipping` with a `Shipped (artefact)` or
   `Shipped (action)` line and no later `Closed` line; zero
   candidates → `/spades-anywhere:ship P-…`. A single candidate with
   no ID passed is picked and announced.
3. **Read the Plan and parent Scope.** Capture `plan_id`,
   `scope_id`, `project_slug`, and the shipment line.
4. **Verify ancestors active** per § Target Resolution →
   Parent-status precondition; hard abort on an `abandoned` Scope or
   an `abandoned` / `archived` Project.
5. **Open the review surface** per SKILL.md § Output format.

## P2 — Update the Plan

`status: shipped`, `updated:` today, and append:

```markdown
- YYYY-MM-DD: Closed. Plan finalised; status: shipped.
```

## P3 — Roll up the parent Scope

Read every sibling Plan, counting this one as `shipped`, and
classify each as `shipped`, `rejected`, or in flight.

- **Every sibling `shipped`** → Scope `status: done`, `updated:`
  today, append `- YYYY-MM-DD: All plans shipped. Scope done.`
- **All terminal, a mix of `shipped` and `rejected`, ≥1 `shipped`**
  → `AskUserQuestion` listing the rejected siblings: **Roll up —
  mark Scope `done`** *(recommended)* / **Leave the Scope at
  `shipping` — I'll come back to this**. Roll up appends to the
  Scope `- YYYY-MM-DD: All plans terminal. Shipped: <n>. Rejected:
  <m> (acknowledged: P-…). Scope done.`; Leave appends to the Plan
  `- YYYY-MM-DD: Scope rollup deferred (mixed-terminal; human
  declined).`
- **Every sibling `rejected`** → no rollup; the Scope shipped
  nothing. Say so; the Plan's close-out proceeds.
- **A sibling in flight** → no rollup; name the siblings.

## P4 — Write and mirror (fan-out)

One wave per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-plan-close` | `.spades-anywhere/plans/P-<…>.md` — P2's edit | `{ status: ok }` |
| `worker-file-scope-rollup` *(when the rollup applies)* | `.spades-anywhere/scopes/S-<…>.md` — P3's edit | `{ status: ok }` |
| `worker-linear-close` *(`backend: linear`)* | Linear — sub-issue → Done; parent Issue → Done when the Scope rolled up; comment *"Closed. Shipment recorded: `<ref or summary>`. Scope rolled up: yes / no."* | `{ status: ok }` |

In HTML mode, re-render the Plan's (and the Scope's) `.html` after
the writes. After the wave: plan file failed → abort, the Plan stays
`shipping`; scope file failed → surface for a manual patch; Linear
failed → keep local files, offer a retry.

## P5 — Confirm

```
✓ Plan closed:    P-host-birthday-party-3HyD
✓ Plan status:    shipped
✓ Scope:          S-plan-birthday-party (done — all plans shipped)
✓ Linear mirror:  sub-issue Done, parent Issue Done          # backend: linear
✓ Status:         shipped

Next:
  /spades-anywhere:learn      — capture a learning
  /spades-anywhere:status     — see what's still open
```

Scope line variants: `(done — all plans shipped)`, `(done — N
shipped, M rejected acknowledged)`, `(shipping — rollup deferred)`,
`(shipping — N still in flight)`, `(shipping — every Plan
rejected)`.
