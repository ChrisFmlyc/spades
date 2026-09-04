---
name: close
description: The single conversational entry point for closing out a Plan, Scope, Project, or Objective in spades-anywhere. Asks the human what they're doing — finalise as shipped/done/archived/complete (the happy path), reject (Plans only), or abandon (Scopes, Projects, and Objectives). Always asks before acting; flags `--reject "reason"` and `--abandon "reason"` are optional power-user shortcuts that skip the menu but still capture a reason. Use whenever someone says "close this", "close P-…", "close S-…", "close O-…", "complete this objective", "we're not doing this", "abandon this scope", "reject this plan". The skill figures out which flow applies. No SCM, no PR — all close flows are pure metadata writes.
version: 1.4.0
---

# /spades-anywhere:close

You are the close-out entry point. The human names what to close;
you ask what kind of close it is and run the matching flow. Every
close is a metadata write — the file, and the Linear mirror when
`backend: linear`.

Four close actions:

1. **Pass** — finalise the lifecycle. Plan → `shipped` (a recorded
   `Shipped` line). Scope → `done` (every child Plan terminal).
   Project → `archived`. Objective → `complete` (the team lead's
   ungated judgement). Quick item → `shipped` (the human brings the
   evidence).
2. **Reject** — a non-terminal Plan → `rejected`, with a reason.
3. **Abandon** — a Scope, Project, or Objective → `abandoned`, with
   a reason.
4. **Drop** — a Quick item whose action didn't happen: delete the
   marker.

Read `docs/FRAMEWORK.md` § Target Resolution, § Scope status
rollup, § Terminal States, and § Output Format before running.

**Flow bodies live in `reference/`.** This file owns the entry
menus and the routing; read the flow file Step 3 routes you to:

| Route | Read |
|---|---|
| Pass on a Plan | [`reference/flow-plan-pass.md`](reference/flow-plan-pass.md) |
| Any Quick-item close | [`reference/flow-quick.md`](reference/flow-quick.md) |
| Reject, Abandon, Scope roll-up, Project archive, Objective complete | [`reference/flow-status-change.md`](reference/flow-status-change.md) |

### Output format

The target is read from its `.md`. HTML mode opens the target's
existing `.html` as the human's view; the terminal carries the
prompts and confirmation. CLI mode summarises inline. After the
close-out edit in HTML mode, re-render the `.html`.

## Conversational entry

**Step 0 — Resolve the target.**

- **Explicit ID** — by prefix: `P-<slug>-<suffix>` → Plan;
  `O-<slug>` → Objective; `S-<slug>` → Scope; `Q-<slug>-<suffix>` →
  Quick item; a bare slug matching
  `.spades-anywhere/projects/<slug>.md` → Project. Test `O-` before
  `S-` and `P-`.
- **No ID** — `AskUserQuestion`, then the matching picker: *Plan*
  (`approved`, `delivering`, `evaluating`, `shipping`) / *Scope*
  (any non-terminal) / *Objective* (`open`) / *Quick item*
  (`shipping`) / *Project* (`active`).
- **Ambiguous phrase** — offer the best one to three candidates.
- A Quick item skips Step 1.

**Step 1 — Ask what kind of close.**

| Plan status | Menu |
|---|---|
| `draft` | *Leave in draft (no-op)* / *Reject* |
| `approved`, `delivering`, `evaluating` | *Reject* |
| `shipping` (has a `Shipped` line) | *Pass — finalise as shipped* / *Reject* |
| `shipped`, `rejected` | abort: *"Plan `<id>` is already `<status>`. Terminal means terminal."* |

| Scope status | Menu |
|---|---|
| `scoped`, `planning` | *Abandon* |
| `delivering`, `evaluating`, `shipping` | *Pass — roll up to done* / *Abandon* |
| `done`, `abandoned` | abort: already terminal |

| Project status | Menu |
|---|---|
| `active` | *Pass — archive* / *Abandon* |
| `archived`, `abandoned` | abort: already terminal |

| Objective status | Menu |
|---|---|
| `open` | *Pass — mark complete* / *Abandon* |
| `complete`, `abandoned` | abort: already terminal |

**Step 2 — Capture the reason (Reject and Abandon).** Free-form,
one line; an empty answer re-prompts.

**Step 3 — Route.** *Leave in draft* exits with *"Plan `<id>` left at
`draft`. Run `/spades-anywhere:approve` when ready."* Pass on a Plan
→ `flow-plan-pass.md`. Everything else → `flow-status-change.md`. A
Quick item → `flow-quick.md`.

## Shortcuts

- `/spades-anywhere:close P-foo --reject "reason"`
- `/spades-anywhere:close S-foo --abandon "reason"`
- `/spades-anywhere:close <project-slug> --abandon "reason"`
- `/spades-anywhere:close O-foo --abandon "reason"`

Objective completion carries no reason and so no flag. A flag on
the wrong target type, or without a reason, aborts with the correct
form.

## Edge cases

- **A `shipping` Plan with no `Shipped` line** — abort: *"Plan
  `<id>` has no shipment record. Run `/spades-anywhere:ship P-<id>`
  first."*
- **A mixed-terminal Scope where the human chose to leave it** — the
  deferred acknowledgement stays in the Plan's audit trail; the
  next close on a sibling offers the rollup again.
- **Linear unreachable** — the local files are canonical; surface
  the failure and re-run later for the mirror.
