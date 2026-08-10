---
name: close
description: The single conversational entry point for closing out a Plan, Scope, Project, or Objective in spades-anywhere. Asks the human what they're doing — finalise as shipped/done/archived/complete (the happy path), reject (Plans only), or abandon (Scopes, Projects, and Objectives). Always asks before acting; flags `--reject "reason"` and `--abandon "reason"` are optional power-user shortcuts that skip the menu but still capture a reason. Use whenever someone says "close this", "close P-…", "close S-…", "close O-…", "complete this objective", "we're not doing this", "abandon this scope", "reject this plan". The skill figures out which flow applies. No SCM, no PR — all close flows are pure metadata writes.
version: 1.3.0
---

# /spades-anywhere:close

You are the close-out entry point. The human tells you what to
close; **you ask them what kind of close it is** — pass, reject,
or abandon — and you do the right thing based on the target type
and their answer.

Five close flows live in this skill:

1. **Pass** (happy path) — finalise the artefact's lifecycle.
   - Plan → `status: shipped` (requires `Shipped (artefact)` or
     `Shipped (action)` line in audit trail).
   - Scope → `status: done` (only when every child Plan is
     terminal; mixed-terminal rollup applies).
   - Project → `status: archived` (graceful sunset).
   - Objective → `status: complete` (the team lead's **ungated**
     judgement; no rollup, no gating, no cascade to Project or
     Scopes — see `docs/FRAMEWORK.md § Hierarchy → Objectives`).
   - Quick item → `status: shipped` (the human confirms with
     evidence; the marker is updated with the actual action +
     evidence).
2. **Reject** — Plan rollback. Plan → `status: rejected`. Applies
   to Plans in any non-terminal status (`approved`, `delivering`,
   `evaluating`, `shipping`). A Plan in `draft` doesn't need
   rejection — the menu offers *"leave in draft (no-op)"* instead.
   Requires a reason.
3. **Abandon** — terminal walk-away on a container or objective.
   Scope, Project, or Objective → `status: abandoned`. Plans cannot
   be abandoned (they are attempts, not initiatives — see
   `docs/FRAMEWORK.md § Terminal States`). Requires a reason.
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

Objectives use `complete` (not `done`) and have no `rejected` state —
they are strategic statements, not attempts. Completing or abandoning
an Objective is independent of its Project and of any Scope.

Read `docs/FRAMEWORK.md` § Target Resolution, § Scope status
rollup, and § Terminal States before running.

## Conversational Entry

**Step 0 — Detect the target.**

- If the human passed an explicit ID, resolve it by prefix:
  `P-<slug>-<suffix>` → Plan; `O-<slug>` → Objective; `S-<slug>` →
  Scope; `Q-<slug>-<suffix>` → Quick item; bare slug that matches a
  `.spades-anywhere/projects/<slug>.<ext>` → Project. (Resolve `O-`
  before `S-`/`P-` to avoid mis-classifying an objective slug.)
- If no ID was passed, ask via `AskUserQuestion`:
  - *Plan* → run the Plan picker (status filter: `approved`,
    `delivering`, `evaluating`, `shipping`).
  - *Scope* → run the Scope picker (status filter: any
    non-terminal).
  - *Objective* → run the Objective picker (glob
    `.spades-anywhere/objectives/O-*.md`, status filter: `open`).
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

For **Objectives**:

| Objective status | Menu options |
|---|---|
| `open` | *Pass — mark complete (team-lead judgement; no gating)* / *Abandon* |
| `complete` / `abandoned` | abort: *"Objective `<id>` is already `<status>`."* |

Objectives are **ungated** on Pass — completion is the human's judgement,
not a rollup. Objectives have no `rejected` option.

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
- *Pass* on an Objective → continue to **Objective Complete Flow**
  (see below). Ungated.
- *Reject* on a Plan → continue to **Plan Reject Flow** (new; see
  below).
- *Abandon* on a Scope → continue to **Scope Abandonment Flow**
  (existing; below).
- *Abandon* on a Project → continue to **Project Abandonment Flow**
  (existing; below).
- *Abandon* on an Objective → continue to **Objective Abandonment
  Flow** (see below).
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
- `/spades-anywhere:close O-foo --abandon "reason"` — skip to
  Objective Abandonment Flow.

(Objective *completion* has no flag — it carries no reason; run
`/spades-anywhere:close O-foo` and pick *Pass* from the menu.)

Invalid flag/target combos abort:
- `--abandon` with a Plan ID → *"Plans use `rejected`. Use
  `--reject "reason"` instead."*
- `--reject` with a Scope, Project, or Objective → *"Scopes,
  Projects, and Objectives use `abandoned` (and complete/done
  gracefully), not `rejected`. Use `--abandon "reason"` instead."*
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

## Flow bodies

Each close action has its own flow file. Read the one Step 3 routes
you to and follow it:

| Route | Read |
|---|---|
| Any Quick-item close | [`reference/flow-quick.md`](reference/flow-quick.md) |
| Pass on a Plan | [`reference/flow-plan-pass.md`](reference/flow-plan-pass.md) |
| Reject, Abandon, Scope roll-up, Project archive, Objective complete | [`reference/flow-status-change.md`](reference/flow-status-change.md) |

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
