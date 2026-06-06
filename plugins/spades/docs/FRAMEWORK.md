# SPADES Framework v2.11.0

SPADES is a human–AI operating model for engineering teams. It is
backend-agnostic: artefacts can live in Linear (via the Linear MCP), on
the local filesystem, or in any other system that has an MCP and a
driver written against the contract in this document.

This file is the **single source of truth** for the framework's
contracts. Skills reference it; they do not re-state it.

---

## The Six Phases

Every unit of work moves through six phases:

```
SCOPE → PLAN → APPROVE → DO → EVALUATE → SHIP
```

| Phase     | Who owns it          | Output                                   |
|-----------|----------------------|------------------------------------------|
| Scope     | Human (AI assists)   | A signed-off Scope record                |
| Plan      | AI (human reviews)   | One or more Plan records, with deps      |
| Approve   | Human gate           | `delivery:` routing recorded on the Plan |
| Do        | AI or human (routed) | Implementation artefacts                 |
| Evaluate  | Human (AI assists)   | PASS / PARTIAL / FAIL verdict            |
| Ship      | Mixed                | Deliverable shipped (PR merged, or…)     |

The phases are mandatory and ordered. The only sanctioned shortcut is
the **fast-track path** (see § Fast-Track Path).

### Why six (not five)

v2.0 splits the old "Deliver" phase into **Do** (build the thing) and
**Ship** (release it to where it needs to go). The split exists because
delivery and shipping have different reviewers, different cadences, and
different success conditions: building a feature is not the same as
opening a PR, running review, and merging. Shipping a non-code
deliverable (a server install, a published doc, a sent email) is yet
another kind of work and deserves its own phase.

---

## Hierarchy: Project → Scope → Plan

```
Project (project-slug)             e.g. "closed-door-security-website"
└── Scope (S-<description>)        e.g. "S-add-ai-helper-bot"
    └── Plan (P-<description>-<id>) e.g. "P-create-initial-mastra-bot-28sD"
        ├── (no dependencies)
        └── Plan
            └── "P-rag-pipeline-lookup-3HyD-28sD"
                (depends on the 28sD plan above)
```

- **Project** — a repo, a set of repos, a service, or any other
  long-lived container for work. One project per `.spades/config`.
- **Scope** — an outcome under a project. Scopes hold acceptance
  criteria and constraints; everything downstream is measured against
  them.
- **Plan** — a unit of executable work under a scope. Plans can depend
  on earlier plans within the same scope. Each plan is independently
  approvable, doable, evaluable, and shippable.

### What sits above a Scope

SPADES is the implementation layer. It does not own Strategy, the
Roadmap, OKRs, or Epics — those live in whatever planning tool your
org uses (Linear, Jira, Productboard, a spreadsheet, etc.). A Scope
is the moment a Roadmap item becomes concrete work.

When a Scope is seeded from a Roadmap / OKR / Epic, record the
upstream reference in the Scope's optional `strategy_link:`
frontmatter field. The audit chain then runs unbroken from strategy
through ship:

```
<Roadmap item / OKR / Epic>  →  Scope (strategy_link: <ref>)
                                    →  Plan(s)  →  shipped
```

Scopes can also arise **reactively** — incidents, tech debt, ad-hoc
requests. In that case `strategy_link:` is omitted, and the existing
`origin:` field carries the rationale (`reactive`, `ad-hoc`, `okr`).
The field is optional throughout; SPADES never requires a roadmap
link to create a Scope.

### Two layers of "intent"

SPADES tracks intent at two levels, with one file per project and one
section per Scope:

| Layer | Lives as | Scope of *why* |
|-------|----------|----------------|
| **Project** | `INTENT.md` at the repo root | Why this whole initiative exists |
| **Scope** | The `## Statement of Intent` section in each `S-…md` | Why this specific outcome, now |

The Scope's Statement of Intent IS the scope-level intent doc. There
is no separate per-scope INTENT file; the section is the intent. Each
Scope's intent should be **measured against** the project-level
`INTENT.md`. A Scope whose intent contradicts INTENT is a drift
signal — refresh INTENT before scoping (or revise the Scope so it
fits).

**`/spades:scope` hard-gates on INTENT.md existence.** If `INTENT.md`
is missing at the repo root, the skill refuses to create a Scope
until `/spades:intent` has been run (or the human explicitly
overrides, which records a marker in the Scope's audit trail). This
prevents the most common drift pattern: weeks of scoping with no
north star to measure against.

### Scope status rollup (from child Plans)

A Scope's `status:` field is the **highest phase** any of its child
Plans has reached. Plans drive Scope status, not the other way around:

```
Plan A status   Plan B status   Plan C status   →   Scope status
─────────────   ─────────────   ─────────────       ─────────────
shipped         shipped         shipped             done
shipped         shipping        draft               shipping
delivering      approved        draft               delivering
approved        approved        draft               planning
draft           draft           draft               planning
(none yet)                                          scoped
```

Skill responsibilities:

- `/spades:plan` bumps the Scope from `scoped` → `planning` on the
  first Plan created.
- `/spades:approve` does NOT change the Scope's status — the Plan's
  own `status: approved` carries the gate decision. The Scope stays
  at `planning` through the approval gate.
- `/spades:do` bumps `planning` → `delivering` on the first Plan
  entering Do.
- `/spades:evaluate` bumps to `evaluating` on the first PASS verdict.
- `/spades:ship` bumps to `shipping` on the first PR opened.
- `/spades:close` is the **only** skill that transitions Scope →
  `done`, and only when **every** child Plan has `status: shipped`.

**One-way transitions only.** A Scope never moves backward. If Plan
B is rejected after Plan A has shipped, the Scope stays at `shipping`
(or `done` if A was the last); the rejected Plan is a leaf state on
its own track. The Scope's audit trail records both transitions.

**Rejected Plans do not block rollup.** They're terminal but don't
hold the Scope back from `done` — Scope `done` requires every Plan
to be either `shipped` or `rejected` (with the rejection explicitly
acknowledged). Today the implementation only counts `shipped`;
mixed-terminal Scopes (some shipped, some rejected) require a human
decision via the rollup audit entry.

---

## ID Format

IDs are intended to be human-scannable (you can guess what something is
from its filename), filesystem-safe, and stable.

### Project ID
- Form: `<project-slug>` — lowercase `[a-z0-9-]{1,64}`, no leading
  hyphen, no `..`.
- Stored at: `.spades/projects/<project-slug>.md`.
- The slug doubles as the project's ID.

### Scope ID
- Form: `S-<description-slug>` — `S-` prefix plus the same slug grammar.
- Stored at: `.spades/scopes/S-<description-slug>.md`.
- The frontmatter `title` preserves the human-readable name.

### Plan ID
- Form: `P-<description-slug>-<own-suffix>[-<dep-suffix>...]`.
- `own-suffix` — 4-character base62 (`[A-Za-z0-9]{4}`), randomly minted
  at creation, never reused.
- `dep-suffix` — each prior plan this one depends on appends its
  `own-suffix` to the filename in dependency order (most recent
  dependency first).
- Stored at: `.spades/plans/<filename>.md`.

### Quick-item ID
- Form: `Q-<description-slug>-<own-suffix>`.
- `own-suffix` — 4-character base62 (same generator as Plan IDs).
- Stored at: `.spades/quick/Q-<description-slug>-<own-suffix>.md`.
- A quick item is work being done **under a project** but **outside
  the Scope/Plan loop** — `/spades:quick` creates one when a tiny
  change meets every gate criterion. `/spades:list` and
  `/spades:status` surface quick items in their own subsection,
  distinct from Scopes. `/spades:evaluate` accepts a `Q-…` target
  and runs its Quick-Path Branch (PR retro-validation).

Worked examples:

```
P-create-initial-mastra-bot-28sD.md       # standalone plan
P-rag-pipeline-lookup-3HyD-28sD.md        # depends on 28sD
P-deploy-bot-9XaZ-3HyD-28sD.md            # depends on 3HyD and 28sD
```

The dependency chain is encoded in the filename so a human (or `ls`)
can read the graph at a glance. The authoritative graph still lives in
the `depends_on:` frontmatter field; the filename is a convenience
mirror.

### Why slugs and not random IDs everywhere

Pure random IDs are robust but unreadable. Pure slugs collide. The
chosen compromise — `S-<readable-slug>` for scopes, and slug + 4-char
suffix for plans — gives readability where collisions are rare (scopes,
which name big outcomes) and gives collision resistance where the
volume is high (plans, where the same description may recur).

---

## .spades/ Local Layout

```
.spades/
├── config                                    # backend + active project
├── version                                   # framework version (2.0.0)
├── projects/<project-slug>.md                # project records
├── scopes/S-<description-slug>.md            # scope records
├── plans/P-<desc-slug>-<suffix>[-<dep>...].md # plan records
├── quick/Q-<desc-slug>-<suffix>.md           # quick-path items (no Scope/Plan)
├── learnings/YYYY-MM-DD-<slug>.md            # learning records
└── reviews/<slug>-<date>.md                  # panel-review reports
```

### `.spades/config` schema

```yaml
backend: linear | local
project: <project-slug>             # active project for this repo
scm: github | local-git             # source-code-management tool (default: local-git)
linear:                             # only when backend: linear
  team_id: <uuid>
  project_id: <uuid>                # Linear's own Project ID for this project
github:                             # only when scm: github
  remote: origin                    # which git remote to use (default: origin)
local_git:                          # only when scm: local-git AND a remote is configured
  remote: origin                    # which git remote to push to (optional)
```

Other SCMs (GitLab, Bitbucket, etc.) become drivers per
`docs/EXTENDING-SCM.md`.

There is **no auto-probe**. The `setup` skill writes this file
explicitly when the human chooses a backend. Skills that read it
trust the value verbatim.

### `.spades/projects/<slug>.md` frontmatter

```yaml
---
id: <project-slug>
title: "Closed Door Security Website"
description: "The marketing site and customer portal at cdsec.co.uk."
repos:
  - https://github.com/cdsec/cdsec-site
  - https://github.com/cdsec/cdsec-portal
owners:
  - chris@cdsec.co.uk
status: active | archived | abandoned   # see § Terminal States; default `active` when omitted
created: 2026-05-29
updated: 2026-05-29
linear_project_id: <uuid>           # only if backend: linear
---
```

### `.spades/scopes/S-<slug>.md` frontmatter

```yaml
---
id: S-add-ai-helper-bot
title: "Add AI Helper Bot"
project: closed-door-security-website
status: scoped | planning | delivering | evaluating | shipping | done | abandoned
type: feature | bug | chore | docs | refactor | investigation
created: 2026-05-29
updated: 2026-05-29
priority: urgent | high | this-cycle | medium | low | backlog | exploratory
origin: okr | reactive | ad-hoc
strategy_link: <URL | ID | ref>     # optional; where this scope came from (roadmap item, OKR, epic). Free-form string.
linear_issue_id: <id>               # only if backend: linear and synced
---
```

The body holds: Statement of Intent, Acceptance Criteria, Architectural
Constraints, Dependencies, Context, Out of Scope, Risk / Unknowns,
Delivery Preference.

### `.spades/plans/P-<…>.md` frontmatter

```yaml
---
id: P-rag-pipeline-lookup-3HyD
id_suffix: 3HyD                     # 4-char base62, randomly minted
scope: S-add-ai-helper-bot
title: "RAG Pipeline Lookup"
depends_on: [28sD]                  # list of prior plans' id_suffix values
status: draft | approved | delivering | evaluating | shipped | rejected
delivery: ai | human | hybrid       # set by /spades:approve
evaluation: ai | human | hybrid     # set by /spades:evaluate
deliverable_type: code | artefact | action  # what Ship needs to do
created: 2026-05-29
updated: 2026-05-29
linear_issue_id: <id>               # only if backend: linear and synced
---
```

`deliverable_type` values:
- **`code`** — the plan produces code that lands via a PR. Ship runs
  the PR + review + merge flow.
- **`artefact`** — the plan produces a tangible thing (document, video,
  config, dataset). Ship records the artefact reference (URL, path,
  doc ID).
- **`action`** — the plan is a one-off human action (a server install,
  a vendor call, an email). Ship records the evidence of completion.

The body holds: Technical Approach, Tasks (3–7), Risks & Assumptions,
Testing & Verification, Delivery Sequence.

### `.spades/learnings/YYYY-MM-DD-<slug>.md` frontmatter

```yaml
---
title: "One-line summary of the learning"
area: scope | plan | approve | do | evaluate | ship | other
tags: [tag1, tag2]
created: 2026-05-29
status: active | archived
public_safe: true | false
scope_ref: S-add-ai-helper-bot      # optional
---
```

---

## Backend Interface

Skills never call MCP tools directly. They call the backend contract
below; the active backend driver (Linear, local FS, or a third-party
driver) implements the contract.

The contract is intentionally narrow. Drivers map the operations onto
their storage; skills don't need to know how.

### Operations

| Operation | Purpose |
|-----------|---------|
| `create_project(record)` | Create a project. Returns the project ID. |
| `get_project(id)` | Fetch a project record. |
| `list_projects()` | List all known projects. |
| `create_scope(record)` | Create a scope. Returns the scope ID. |
| `get_scope(id)` | Fetch a scope record. |
| `list_scopes(filter)` | List scopes for the active project, filterable by status/type. |
| `find_scope_fuzzy(query)` | Return scopes whose slug or title fuzzy-matches the query. Used by `/spades:scope` for "are you updating an existing scope?" lookups. |
| `update_scope(id, fields)` | Update specified fields on a scope. |
| `create_plan(record)` | Create a plan. Returns the plan ID. |
| `get_plan(id)` | Fetch a plan record. |
| `list_plans(scope_id)` | List plans under a scope. |
| `update_plan(id, fields)` | Update specified fields on a plan. |
| `record_approval(plan_id, decision, routing, notes)` | Record the approve gate's decision and routing on the plan. |
| `record_evaluation(plan_id, verdict, notes)` | Record an evaluate gate's verdict on the plan. |
| `record_shipment(plan_id, artefact_ref)` | Record the ship phase's deliverable reference (PR URL, doc URL, evidence text). |
| `create_learning(record)` | Append a learning. |
| `list_learnings()` | List active learnings. |

### The two shipped drivers

**Linear driver** (`backend: linear`):
- Project → Linear Project
- Scope → parent Issue
- Plan → sub-issue under the parent
- `record_*` operations → comments on the parent issue
- Statuses → Linear workflow states

**Local driver** (`backend: local`):
- Reads and writes the files described under § .spades/ Local Layout
- `record_*` operations append to the body of the relevant scope/plan
  under an `## Audit Trail` heading

A driver MUST implement every operation; on a no-op platform a driver
may return a documented stub error rather than silently succeeding.

### Adding a backend

See `docs/EXTENDING-BACKENDS.md` for the contract drivers must satisfy
and a worked example for adding (e.g.) a Notion MCP driver.

---

## Asking the Human

When a skill needs a fixed-option decision (priority, routing, verdict,
yes/no), it MUST use the `AskUserQuestion` tool with structured options.
Free-form prose (intent text, acceptance criteria wording, plan task
descriptions) stays as conversation.

The pattern: **decisions are structured; composition is free-form.**

---

## Target Resolution

Several skills act on an existing Scope or Plan: `review`, `plan`,
`approve`, `do`, `evaluate`, `ship`. If the human invokes one without
naming a target (no ID, no slug, no description), the skill must
walk the human through finding the right one — not abort. This
section is the canonical contract; skills reference it rather than
restating it.

### The flow

1. **Determine the artefact type.**
   - For skills that work on exactly one type (e.g. `/spades:approve`
     always operates on a Plan), skip this step.
   - For type-flexible skills (today, only `/spades:review` qualifies
     — Scope review, Plan review, or Full Review of both), ask via
     `AskUserQuestion`:
     - *Scope review* — target is a Scope
     - *Plan review* — target is a Plan
     - *Full review* — target is a Plan together with its parent Scope

2. **List candidates from the backend**, filtered to:
   - The **active project** from `.spades/config`'s `project:` field
   - The **status set** appropriate for this skill (see the per-skill
     table below)

   Use the backend interface (`list_scopes(filter)` /
   `list_plans(scope_id)`) — do NOT hand-roll a filesystem glob in
   `linear` mode or a Linear MCP call in `local` mode.

3. **Present a picker via `AskUserQuestion`.** `AskUserQuestion`
   caps at 4 options, so:
   - If there are ≤ 3 candidates: each candidate is one option,
     plus a *Describe a different one* free-form fallback as the
     fourth option (or omit the fallback if the human almost
     certainly wants one of those three).
   - If there are > 3 candidates: show the top 3 by relevance
     (most-recently-updated first, then alphabetical by ID), plus
     *Describe a different one — list more / search* as the fourth
     option.
   - If there are 0 candidates: do NOT call `AskUserQuestion`. Tell
     the human what's missing and suggest the upstream skill (see
     the per-skill table). Don't pretend to offer choices.

   Each option's label is the artefact's **ID + short title** (e.g.
   `S-add-ai-helper-bot — Add AI Helper Bot`). The description
   field carries status and (for Plans) `delivery:` /
   `deliverable_type:`.

4. **If the human picked *Describe a different one*,** prompt
   free-form for a search term. Fuzzy-match the term against the
   full candidate set (slug substring, title token overlap,
   id_suffix prefix). Then:
   - One strong match → confirm via `AskUserQuestion` (*Use this
     one* / *No, search again*).
   - Multiple matches → present up to 3 via `AskUserQuestion` plus
     a re-search option.
   - No matches → tell the human, offer to re-search or abort.

5. **Resolve and continue.** The resolved ID is what the rest of
   the skill operates on. Echo it back briefly (*Reviewing
   S-add-ai-helper-bot — Add AI Helper Bot*) so the human can
   correct early if it's wrong.

### Per-skill status filter

| Skill | Artefact type | Status filter for the picker |
|-------|---------------|------------------------------|
| `/spades:review` | Scope OR Plan (asked at step 1) | Scopes: any active phase; Plans: `draft`, `approved`, `delivering`, `evaluating` |
| `/spades:plan` | Scope | `scoped`, `planning` |
| `/spades:approve` | Plan | `draft` |
| `/spades:do` | Plan | `approved`, `delivering` (so resume works) |
| `/spades:evaluate` | Plan (or Scope for whole-scope eval) | Plans: `delivering`, `evaluating`. Scopes: `evaluating` |
| `/spades:ship` | Plan | `evaluating` with a PASS verdict recorded in the audit trail |

### Zero-candidate suggestion table

When the filter returns nothing, suggest the upstream skill:

| Skill returning zero | Suggest |
|----------------------|---------|
| `/spades:plan` (no scoped Scopes) | `/spades:scope <title>` to create one |
| `/spades:approve` (no draft Plans) | `/spades:plan S-…` to draft one |
| `/spades:do` (no approved Plans) | `/spades:approve P-…` on a draft plan |
| `/spades:evaluate` (no delivering / evaluating Plans) | `/spades:do P-…` on an approved plan |
| `/spades:ship` (no evaluating + PASS Plans) | `/spades:evaluate P-…` to verify a delivered plan |
| `/spades:review` (no active artefacts) | `/spades:scope <title>` to create one |

### When the human DID name a target

If the invocation passed an argument — an ID, a slug, or a phrase —
skip steps 1–3 and go straight to fuzzy resolution against the
candidate set. If the argument exactly matches an ID, no
confirmation prompt is needed; if it's a slug or phrase, surface
the resolution back via `AskUserQuestion` for one-step confirmation
before continuing.

### Parent-status precondition

Once a target is resolved (or a parent container is picked, in the
case of skills that *create* a new artefact), the skill MUST verify
that no ancestor in the target's container chain has terminal
status `abandoned` (or, for Projects, `archived`). Producing skills
refuse hard when this check fails — there is no override.

| Target | Ancestors to check |
|--------|--------------------|
| Plan | Parent Scope; grandparent Project |
| Scope | Parent Project |
| Project | (no ancestors — skip) |

**The rule applies to:** `/spades:scope` (create and edit modes),
`/spades:plan`, `/spades:approve`, `/spades:do`, `/spades:evaluate`,
`/spades:ship`, and `/spades:close` on the **Pass** route.

**Exemptions:**

- `/spades:close --abandon` and `/spades:close --reject` are the
  actions that *create* terminal status; they do not refuse based
  on their own outcome.
- `/spades:list` and `/spades:status` are read-only; they surface
  abandoned ancestors and their descendants (under the `all` filter)
  without refusing.
- `/spades:quick` is independent of the Scope/Project hierarchy —
  its gate is the fast-track criteria, not parent status.

**Error shape (hard abort):**

> ✗ Cannot &lt;action&gt; &lt;target-id&gt;: parent &lt;Scope|Project&gt;
> &lt;ancestor-id&gt; is `abandoned` (&lt;date&gt;, "&lt;reason&gt;").
>
> Producing work on abandoned ancestors is refused — once the
> container is abandoned, this work is out of scope. To resume the
> work in a fresh container, create a new Scope (or Project) via
> `/spades:scope` (or `/spades:newproject`) and draft Plans there.

**Why hard refusal.** The framework deliberately does not cascade
abandonment to child Plans (see § Terminal states — `rejected` vs
`abandoned` → No cascade). The cost of that deliberate-no-cascade
design is that every producing skill becomes the gatekeeper —
without this rule, new work would silently land on a dead
initiative and the audit trail would lose its meaning. Refusing at
the gate, with a hard abort, is what makes the no-cascade design
safe.

### Why this lives in FRAMEWORK.md

Restating the same picker logic in six skills means six places to
fix when it changes. Skills reference this section by name (*"see
docs/FRAMEWORK.md § Target Resolution"*) and only state their own
artefact type + status filter.

---

## Fast-Track Path

Not every change deserves the full loop. Trivial work — typos, one-line
tweaks, small config nudges, docs changes — routes through
`/spades:quick`. On this path, the PR description is the audit artefact;
no separate Scope or Plan record is created.

### The gate — ALL must be true

1. Single concern
2. ≤ 50 lines of code changed total
3. One file, or a tight cluster in one module
4. No new dependencies
5. No schema, migration, or data-layer changes
6. No architectural changes
7. No security-sensitive code
8. No public API or interface breaking changes
9. Revertible as one commit
10. Existing tests cover the area

If *any* criterion fails, fall back to the full loop. The gate is
all-or-nothing.

---

## Execution Posture

When a plan declares tasks, each task picks one execution posture from
a fixed set shared between `spades` and `spades-anywhere`. The
posture declares *how* to approach the work, not what to do. The set
is identical across plugins so a Plan moving between coding and
non-coding contexts stays legible.

- **`specify-first`** — the target is clear and worth pinning down
  before starting. **Code:** write failing tests first, then satisfy
  them. **Non-code:** draft the outline / success criteria / brief
  before filling in the detail.
- **`discover-first`** — the path isn't clear yet; understand the
  current state before changing or committing. **Code:** characterize
  existing behaviour in tests before refactoring it. **Non-code:**
  talk to stakeholders, read source material, scope vendors before
  picking an approach.
- **`iterate`** — the deliverable improves in small passes. **Code:**
  reshape an area in small refactor steps, or build incrementally.
  **Non-code:** plan multiple short cycles (a draft, a recipe, a
  routine), each producing a reviewable version.
- **`spike`** — the correct approach is genuinely unknown; the output
  is *learning* or *a decision*, not the deliverable. Time-boxed and
  not shippable as-is.
- **`straight-through`** — the change is mechanical enough that extra
  ceremony adds no value. Not a silent default — state the
  justification on the task line.

A task may declare mixed posture (e.g. `discover-first on the venue
options; specify-first on the run-sheet`, or `discover-first on the
existing module; specify-first on the new behaviour`).

---

## Audit Trail

Every piece of work must be traceable through:

1. A project record
2. A signed-off scope
3. One or more approved plans (or, for fast-track work, a filled PR
   template)
4. An approval decision with routing
5. A do-phase record of who/what executed the work
6. An evaluation verdict
7. A shipment record

Work that cannot be traced through this chain must not ship.

### Terminal states — `rejected` vs `abandoned`

Three terminal states exist across the artefact hierarchy, with
deliberately different meanings:

- **`rejected`** (Plans only) — *"We evaluated this attempt and
  said no."* A judgement on **this particular approach**. The
  underlying work may continue with a different Plan. `rejected`
  comes from `/spades:approve` (this approach is wrong) or
  `/spades:evaluate` FAIL (this delivery missed the bar). A rejected
  Plan does NOT terminate the parent Scope — write another Plan and
  keep going.

- **`abandoned`** (Scopes and Projects) — *"We're not doing this
  initiative. Full stop, never."* A terminal walk-away on **the
  whole thing**. Set by `/spades:close <target> --abandon "reason"`.
  The reason text is required; abandoning an initiative without
  recording why is exactly the audit-trail hole this framework
  exists to prevent.

- **`done`** (Scopes) / **`shipped`** (Plans) / **`archived`**
  (Projects) — graceful completion. The artefact ran its arc.

Directional rule: `rejected → abandoned` is allowed (you rejected
several Plans, then decided the whole Scope isn't worth doing →
abandon the Scope). `abandoned → anything` is not. Terminal means
terminal.

**No cascade — but the gate refuses.** Abandoning a Scope does NOT
automatically reject or abandon its in-flight Plans. Those Plans
stay at whatever status they were in; the parent's `abandoned` is
the authoritative signal. `/spades:list` and `/spades:status` hide
children of abandoned parents in the default view but they remain
accessible via `/spades:list all`. Cascading writes that can
partially fail would risk lying about state.

This deliberate-no-cascade design is paired with a hard gate:
producing skills (`/spades:scope`, `/spades:plan`, `/spades:approve`,
`/spades:do`, `/spades:evaluate`, `/spades:ship`, and `/spades:close`
on the Pass route) refuse to act on a child of an `abandoned`
ancestor. See § Target Resolution → Parent-status precondition for
the contract.

Mid-flight abandonment is explicitly allowed. You do not need to
terminate child Plans first; the whole point of `abandoned` is to
walk away from in-flight work cleanly.

Quick items have no `abandoned` state — if you start a quick item
and bail, delete the marker file. Quick is the lightweight path; a
terminal status would be ceremony for a delete.

### Plan rejection — no cascade

A Plan with `status: rejected` does **not** automatically invalidate
Plans that depend on it via `depends_on:`. Dependants stay in
whatever state they were in (`draft`, `approved`) — but they are
**blocked**:

- `/spades:do` refuses to start a Plan whose `depends_on:` chain
  contains a `rejected` ancestor. It aborts with a pointer to
  `/spades:plan` for the rejected ancestor.
- The human decides what to do — either:
  - Replan the rejected ancestor (most common: refine and re-approve),
    after which dependants can proceed; or
  - Mark the dependants `rejected` too, with a one-line rationale in
    each Plan's audit trail.

The framework never makes this decision automatically. Cascading a
rejection silently would risk auto-cancelling work that the human
might have wanted to salvage independently; refusing to start
silently would risk wasted Do-phase cycles on stale dependencies.
The middle ground is explicit refusal + human choice.

### The `Shipped` marker (contract)

Every Plan that reaches `status: shipped` MUST have a line beginning
with `Shipped` as the most recent entry in its `## Audit Trail`
section. The prefix is universal; SCM drivers vary the suffix to
reflect what was shipped and where:

| SCM driver | Marker shape |
|------------|--------------|
| `scm: github` (two-phase) | `Shipped. PR: <URL>. Merge: <sha>. Merged by: <login>.` |
| `scm: local-git` (single-phase) | `Shipped (local-git). Branch: <branch>. Commit: <sha>.` |
| Future drivers (GitLab, Bitbucket, etc.) | `Shipped (<scm-name>). …` or `Shipped. MR: <URL>. Merge: <sha>.` — see `docs/EXTENDING-SCM.md` § 4. |

`/spades:ship` Step 0 and `/spades:close` Step 1 both grep for the
`Shipped` prefix to detect resume state and finalisation state. New
SCM drivers MUST emit the prefix; the suffix is free-form within the
contract. Plans NEVER transition to `status: shipped` without a
matching audit line.

## Freshness

Every SPADES skill reads files from the **local filesystem** — not
from `origin`. If the local checkout is behind the remote (a PR
merged on GitHub but `git pull` hasn't run locally), every read is
against stale code. Audits, plan-drafting, do-phase branch creation,
and review subagents all silently operate on the wrong source of
truth.

### The rule

Before any skill that performs cross-cutting reads or branches off
`main`, the local checkout MUST be in sync with `origin/main`.

How to verify, in one command:

```bash
git fetch origin --quiet && git rev-list --count main..origin/main
```

- Returns `0` → local is fresh. Proceed.
- Returns non-zero → local is behind by N commits. Stop. Run
  `/repo:sync` (from the `repo` plugin), then re-run the skill.

Skills that read repo state outside their own deliverable
(`/spades:plan`, `/spades:do`, `/spades:review`, `/spades:research`,
`/spades:scope`, `/spades:approve`, `/spades:status`,
`/spades:list`) implicitly depend on this check. Skills that already
own the sync responsibility (`/spades:close` calls `/repo:sync`
twice; `/repo:sync` is the sync itself) satisfy it directly.

### Two-layer enforcement

**Layer 1 — Behavioural.** When `/repo:sync`'s "Ready." handoff
fires (i.e. a feature branch was cleaned up after merge), the
operator MUST sync before context-switching to a new SPADES skill.
This is captured as an operating rule in `AGENTS.md § Freshness
Before Read-Across`.

**Layer 2 — Subagent prompts.** Skills that spawn read-across
subagents (`/spades:review`'s panel, `/spades:research`'s
researcher) include a freshness pre-flight directly in the
subagent's prompt: *"Before reading any files, run `git rev-list
--count main..origin/main` — if non-zero, stop and report that local
main is behind origin; the user must `/repo:sync` first."* The
subagent halts before it produces stale findings.

### Why this lives in FRAMEWORK.md

Freshness is not skill-specific — it's a contract every skill
participates in. Defining it once here means individual skills don't
repeat the rule; they reference it. Adding a new skill that does
cross-cutting reads? The skill author reads this section, references
it in their skill's prose, and the convention propagates.

## Output Format (CLI vs HTML)

`/spades:setup` Step 1.7 records `review_format:` in
`.spades/config` — one of `cli` (default) or `html`. The value
controls *whether* an HTML companion file is written alongside
the canonical Markdown, and the *medium* of presentation when a
skill would otherwise paste a large block to the CLI. The skill
flows, prompts, and decisions don't change between modes.

### Universal rule — `.md` always, `.html` additive in HTML mode

**Every producing skill writes its canonical `.md` in BOTH
modes.** The `.md` is the AI-readable source of truth — the AI,
sub-agents, and other harnesses (Cursor, Codex, Aider, Cline,
the GitHub web UI) all read this. The `.md` lives at the
artefact's canonical path in `.spades/<dir>/<id>.md` (or the
repo-root path for project docs: `INTENT.md`,
`ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`).

**In HTML mode, the skill ADDITIONALLY writes an `.html`
companion alongside the `.md`** — same data, rendered through
the skill's bundled `template.html` for the human's view, then
auto-opened via `OPEN_CMD`. The `.html` is purely a human-view
enrichment; it never replaces the `.md`.

This is the load-bearing rule:

- **CLI mode** = `.md` is the only file. Skill body summarises
  inline to the terminal where the skill prose already does
  that.
- **HTML mode** = `.md` PLUS `.html`. Both files coexist on
  disk. The human reviews the `.html`; the AI continues to read
  the `.md`.

Strip `.html` out of HTML mode and you have CLI mode. Add
`.html` to CLI mode and you have HTML mode. The two are
alternatives in the sense that you pick a mode, not in the
sense that they produce different sets of files — HTML is a
strict superset of CLI.

There is no "format swap" — that pattern existed in earlier
versions and has been removed. Any skill prose still mentioning
"format swap only" or "do NOT also write a `.md`" is stale and
should be fixed.

#### What about evaluate's two-page HTML output?

`/spades:evaluate` is a special case in two respects:

1. It does NOT write a per-evaluation `.md` — the verdict lives
   only as an audit-trail line on the Plan's existing `.md`.
   That audit line is the AI-readable source of truth.
2. In HTML mode it writes **two** `.html` files
   (`<plan>-<date>-plan.html` at Step 2.5 and `-report.html` at
   Step 5.5) — the verification plan + the completed evaluation
   report.

The universal rule still applies in spirit: the AI's source of
truth lives in the `.md` (the Plan's audit trail); HTML mode
adds human-viewable `.html` artefacts on top. CLI mode just
omits the `.html`s.

#### What about cross-cutting transient views (status, list)?

`/spades:status` and `/spades:list` don't produce persistent
artefacts — they render a current-state view from existing
artefacts. In CLI mode they print to the terminal; in HTML mode
they additionally write `.spades/.tmp/<view>.html` (gitignored,
regenerated each call) and auto-open it. The terminal output
still appears for short status text in both modes.

### Producing skills — `cli` vs `html` write

Producing skills are `/spades:newproject`, `/spades:scope`,
`/spades:plan`, `/spades:learn`, `/spades:review`,
`/spades:intent`, `/spades:architecture`, `/spades:patterns`,
`/spades:anti-patterns`. Each writes an artefact at the end of
its flow.

- **`review_format: cli`** — write the canonical `.md` under
  `.spades/<dir>/<id>.md` (or repo root for project docs).
  Paste a summary to the terminal where the skill body already
  does that. No HTML written.
- **`review_format: html`** — write the canonical `.md` exactly
  as in CLI mode, AND ADDITIONALLY write `.html` companion at
  `.spades/<dir>/<id>.html` (or `.spades/<name>.html` for
  project docs alongside their `<NAME>.md`) using the skill's
  sibling `template.html` resource (located at
  `${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/template.html`).
  Render by:
  1. Reading the sibling template file end-to-end.
  2. Replacing every `{{spades.field}}` placeholder with the
     artefact's field value (HTML-escape user-supplied strings;
     pre-rendered Markdown→HTML bodies pass through as-is).
  3. Expanding `<!-- SPADES-BLOCK:name --> … <!-- SPADES-ENDBLOCK -->`
     sections by repeating the block content once per item, with
     `{{block.field}}` substituted per item.
  4. Filling the `<script type="application/yaml"
     id="spades-frontmatter">` block with the artefact's
     frontmatter (same fields the `.md` version would have).
  5. Filling the `<script type="application/yaml"
     id="spades-audit-trail">` block (if present) with the audit
     trail entries in chronological order.
  6. Writing the result to `.spades/<dir>/<id>.html`.
  7. Auto-opening via the OPEN_CMD prelude (see below).

The Markdown-to-HTML conversion for body sections (Statement of
Intent, Technical Approach, etc.) follows standard CommonMark; the
skill renders the converted HTML into the `{{spades.X_html}}`
placeholders.

#### HTML mode is review-via-file, not review-via-CLI

In HTML mode the artefact file itself IS the review surface. The
producing skill MUST NOT paste the artefact body (or any substantive
excerpt of it) to the CLI for the human's approval before the write
step runs. Instead:

1. The skill gathers inputs through its existing field-by-field
   conversation step.
2. The write step renders and writes the file as a working draft,
   auto-opens it in the browser, and stands down.
3. The human reviews in the browser.
4. To iterate, the coordinator applies **targeted edits** to the
   file (the human reloads to see changes). Never re-paste a new
   full draft to the CLI.

In CLI mode the existing "draft → paste to terminal → human
approves → write" pattern is preserved unchanged. The
no-pre-write-paste rule applies only to HTML mode.

This rule exists because the value of HTML mode is *not* a fancier
final artefact — it's that the human's review happens against a
rendered page rather than a wall of terminal markdown. A pre-write
CLI paste defeats that and turns HTML mode into "CLI mode plus an
extra file at the end".

#### What counts as "review-form text" (HTML in HTML mode) vs "conversational text" (CLI in both modes)

The rule above forbids pre-write CLI pastes in producing skills. The
same principle applies to consumer skills (`approve`, `evaluate`,
`do`, `ship`, `close`, `intent`): when in HTML mode and the `.html`
file is open, do NOT also paste long review-form text to the CLI.

To make the line crisp:

**Stays CLI in both modes — short, conversational, operational:**

- `AskUserQuestion` prompts and option labels
- Final confirmation summaries (e.g. `✓ Plan shipped: P-…  ✓ Status: shipped`)
- Pre-flight narration ("Reading the Plan…", "Resolving target…")
- Error and abort messages
- "Next:" hand-off pointers between skills
- One-line status acknowledgements ("Plan marked delivering.")

**Routed through the mode-selected surface — long, structured, meant to be read and judged:**

- Artefact bodies (Plan tasks, Scope criteria, INTENT sections,
  Project records, learning entries, full review reports)
- Per-criterion / per-task verdict walks rendered as a *table* of
  results (the per-criterion `AskUserQuestion` poll itself stays
  CLI — that's conversational; the *cumulative table* is review-form)
- The ship-time INTENT success-criteria confirmation record (the
  evidence list lands in the audit trail, not as a CLI paste)
- Any "let me show you what we're about to evaluate / approve /
  ship" preview content

In **HTML mode**, review-form content goes through the open `.html`
(via `OPEN_CMD` to surface it, plus targeted edits to update it).
The CLI carries only the conversational layer.

In **CLI mode**, review-form content goes inline to the terminal as
today. No HTML is written or opened.

The reverse direction is symmetric: **CLI mode never opens an HTML
file or writes one; HTML mode never pastes review-form text to the
terminal**.

#### HTML rendering: validate and use the bundled template, never hand-roll

Every skill that produces an HTML artefact ships a sibling
`template.html` resource at
`${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/template.html`. The
bundled template is the **canonical presentation**: it carries
the sidebar + fluid main grid (375px + `minmax(0, 1fr)`), the
B-style 17.5px typography, the gold/black/white palette, and the
declared `SPADES-BLOCK` sections each skill fills.

The rule:

1. **Before rendering, validate the template.** Read the sibling
   `template.html`. Confirm it exists and is non-empty. If
   missing or empty, **abort** and surface that — do NOT silently
   fall back to a hand-rolled rendering.
2. **Validate the block names you intend to populate exist in
   the template.** Each skill's SKILL.md HTML-mode step
   enumerates which `SPADES-BLOCK` sections it fills. Grep the
   template file for `<!-- SPADES-BLOCK:<name> -->` markers and
   confirm every block name from SKILL.md matches one. If a
   declared block name isn't in the template, abort and surface
   the mismatch — the SKILL.md and template have drifted and a
   framework PR is needed.
3. **Render by substitution only.** Replace `{{spades.field}}`
   placeholders, expand `<!-- SPADES-BLOCK:name --> … <!-- SPADES-ENDBLOCK -->`
   sections per their per-item fields, fill the
   `<script type="application/yaml" id="spades-frontmatter">` tag,
   fill the `<script type="application/yaml" id="spades-audit-trail">`
   tag (when present), write the result to the declared output
   path.
4. **Never invent layout.** No custom `<style>` block, no fresh
   `<head>`, no alternative grid, no `max-width` cap, no
   different colour palette. If the bundled template doesn't
   cover what you want to render, the answer is a framework PR
   that extends the template — not a one-off hand-roll.

The skills that ship a bundled template: `scope`, `plan`,
`newproject`, `learn`, `review`, `status`, `list`, `intent`,
`evaluate`, `architecture`, `patterns`, `anti-patterns`.

This rule exists because the *value* of HTML mode comes from the
agreed-on presentation — the sidebar, the typography, the colour
language, the consistency across artefacts. A hand-rolled
rendering loses all of that even if it looks reasonable on its
own. The bundled template is the canonical form; everything else
is improvisation.

### Consumer skills — `cli` vs `html` presentation

Consumer skills are `/spades:approve`, `/spades:evaluate`,
`/spades:do`, `/spades:ship`, `/spades:close`, `/spades:status`,
`/spades:list`, `/spades:intent`. Each, at some point in its flow,
presents an artefact for the human to review.

`/spades:evaluate` is a **two-page producer** in HTML mode. It
does NOT open the Plan's `.html` at Pre-Flight any more — that
caused users to mistake the Plan render for the eval output. The
two pages it writes are:

1. **Page 1 — Verification plan**:
   `.spades/evaluations/<plan-id>-<date>-plan.html`, written at
   Step 2.5 after the verification plan is proposed and before
   the human approves it at Step 2.6. Shows the concrete
   verification steps with verifier chips (AI / Human / Test /
   Lint / Manual); verdicts: `PENDING`.
2. **Page 2 — Evaluation report**:
   `.spades/evaluations/<plan-id>-<date>-report.html`, written at
   Step 5.5 after the human picks the verdict at Step 5 and
   provides a one-paragraph rationale. Same template; verdicts
   filled in; aggregate verdict pill in the sidebar.

`{{spades.mode}}` (`plan` | `report`) in the template drives the
visible differences between the two pages — sidebar brand, H1
prefix, tagline, browser title.

- **`review_format: cli`** — paste the artefact's content (or a
  summary) to the terminal as today.
- **`review_format: html`** — auto-open the relevant `.html`
  artefact in the default browser via the OPEN_CMD prelude.
  - For artefact-bound reviews (approve / do / ship / close):
    the `.html` already exists at `.spades/<dir>/<id>.html`
    because the producing skill wrote it. Just open it.
    (`evaluate` is **not** in this list — see below; it writes
    its own pair of pages and does NOT open the Plan's `.html`.)
  - For transient cross-cutting views (status / list / intent):
    render to `.spades/.tmp/<view>.html` using the consumer
    skill's sibling `template.html`, then open. Transient files
    are regenerated on every invocation; `/spades:setup` appends
    `.spades/.tmp/` to the consumer repo's `.gitignore` at install
    time, so these files are never committed.
  - For evaluate's *produced* pages: persistent at
    `.spades/evaluations/<plan-id>-<date>-plan.html` (page 1,
    written at Step 2.5) and
    `.spades/evaluations/<plan-id>-<date>-report.html` (page 2,
    written at Step 5.5). Both ship in the feature branch's own
    PR (no separate bookkeeping flow because evaluate runs
    mid-flow, not on `main`).

In CLI mode, every consumer skill behaves exactly as in v2 — no
HTML written, no browser opens.

### OPEN_CMD detection prelude

When a skill needs to open an `.html` file, it runs (once per
session) this detection:

```bash
case "$(uname -s)" in
  Darwin)  OPEN_CMD="open" ;;
  Linux)   OPEN_CMD="xdg-open" ;;
  MINGW*|MSYS*|CYGWIN*) OPEN_CMD="start" ;;
  *)       OPEN_CMD="" ;;
esac
```

Then to open: `$OPEN_CMD "<absolute-path-to.html>"` (run in the
background, don't wait). If `OPEN_CMD` is empty (unknown OS),
print *"Open in your browser: file://<absolute-path>"* and
continue — don't crash.

### Template authoring contract

Templates live as sibling files in their owning skill's directory:

```
plugins/spades/skills/<skill-name>/
├── SKILL.md
└── template.html
```

This is the same shape as `skills/ship/scm-github.md` and
`skills/ship/scm-local-git.md` — sibling resource files travel with
the skill in the plugin install. Every consumer repo that installs
the plugin has the template available verbatim.

Placeholder syntax used by skills at render time:

| Syntax | Meaning |
|--------|---------|
| `{{spades.field}}` | Single-value substitution from the artefact's frontmatter or computed values |
| `{{spades.field\|fallback}}` | Same, with a default when the value is unset |
| `<!-- SPADES-BLOCK:name --> … <!-- SPADES-ENDBLOCK -->` | Repeating section; the block is duplicated once per item, with `{{block.field}}` substituting per-item values |

Templates are fully self-contained — inline CSS, inline JS, no
external assets. They render correctly on `file://`. Each
template's top comment carries a version stamp:
`<!-- SPADES template: <name> vX.Y.Z (matches plugin v3.0.0) -->`.

### Why this lives in FRAMEWORK.md

Same logic as Freshness: the dual-format contract is something
every producing and consumer skill participates in. Defining it
once here means individual skills don't repeat the rendering
instructions; they reference this section and inherit the
contract. Adding a new artefact type later? The skill author
authors a new `template.html` sibling, fills it with the right
placeholders, and references this section's render contract from
the skill body.

## Sub-agent Dispatch (Fan-Out)

Producing and writeback-heavy consumer skills do work that's
naturally independent — render a local file, talk to Linear, append
to a parent artefact — but historically run those operations
serially. SPADES 3.1.0 introduces a parallel **fan-out** dispatch:
the skill spawns one sub-agent per resource in a single tool-call
wave, then stitches the results.

### The rule

> **One sub-agent owns one resource.** Two sub-agents in the same
> dispatch wave MUST NOT write to the same resource.

A *resource* is one of:

- A single local file path (e.g. `.spades/plans/P-foo-3HyD.html`).
- The Linear API surface for one logical operation (create issue
  + capture ID; record comment + status update).
- One bounded analysis / computation whose result the coordinator
  needs (rarely used by today's skills, reserved for future).

### The coordinator is not a sub-agent

The skill body itself remains the orchestrator. It reads, decides,
dispatches, collects, stitches, prints. It is free to read and
write any file. After a fan-out wave it does any small integration
writes — for example, injecting a captured `linear_issue_id` into
the frontmatter of a file the file sub-agent already wrote.
That's two writes to the same file but **sequential** (sub-agent
first, coordinator second) — the no-contention rule only forbids
two sub-agents racing on one file.

### Spawning

Spawn all sub-agents in a single assistant message with multiple
`Agent` tool calls. The Claude Code runtime honours these as
concurrent invocations.

Use `subagent_type: general-purpose` (or `claude` as catch-all)
with inline prompts. The work is parametric — file path + content,
or Linear payload — so it does not need bundled persona files
under `agents/`.

Each sub-agent's prompt should be self-contained and include:

- **Scope** — exactly what file or external resource it owns.
- **Inputs** — the full content to write or the Linear payload.
- **Return schema** — what the coordinator expects back
  (`{ ok: true }` for file writes, `{ linear_issue_id: "<uuid>" }`
  for Linear creates, plus an `error` field on failure).
- **Freshness probe** (Linear-touching sub-agents only) — the same
  Layer-2 pre-flight required by `/spades:review` and
  `/spades:research`: run `git rev-list --count main..origin/main`
  and abort if local is behind.

### Dispatch modes

The same three-mode model from `/spades:review`:

- **`subagent-dispatch`** *(preferred)* — true parallel via
  multiple `Agent` tool calls in one assistant message.
- **`sequential-inproc`** *(fallback)* — runtime only supports one
  sub-agent at a time. Run them sequentially, still in isolated
  contexts. Lose parallelism, preserve isolation.
- **`degraded`** *(last resort)* — no sub-agent dispatch
  available. Coordinator does everything itself, serially. Same
  result, no isolation.

The skill records which mode it used in its confirmation output.

### Failure semantics

Each sub-agent returns:

```
{ status: ok | fail, payload?: <return data>, error?: <message> }
```

The coordinator collects **every** sub-agent's result before
acting on any of them. Then:

- **All ok** → coordinator does its integration writes (e.g.
  `linear_issue_id` back-write), prints confirmation with the
  dispatch mode used.
- **File sub-agent failed, Linear ok** → abort with a clear
  error. The local file is canonical; without it, the Linear
  record has nothing to mirror. The human re-runs.
- **Linear sub-agent failed, file ok** → keep the local file
  (it IS canonical), surface the Linear failure, offer a retry.
  Same contract as today's "Backend Mirror" section in each
  skill — only the dispatch mechanism changes.
- **Multiple file sub-agents failed** → abort, surface all
  failures, recommend manual recovery (the failed files may be
  partial-written; the human inspects and reverts as needed).

### Why this lives in FRAMEWORK.md

The fan-out contract is something multiple skills participate in
(today: `newproject`, `scope`, `plan`, `approve`, `evaluate`;
later: `do`, `ship`, `close`). Defining it once here means
individual skill bodies can reference this section instead of
repeating dispatch-mode bookkeeping and failure-semantics prose.
Adding a new skill that mirrors to Linear later? Author a per-skill
fan-out table (one sub-agent per resource) and reference this
section's contract. The dispatch-mode reporting, freshness probe,
and failure semantics are inherited.

### Drift detection (active probe in `/list` and `/status`)

The failure semantics above handle the cases SPADES knows about — a
worker returned `fail`, the coordinator surfaces it, the human
retries. They do NOT catch:

1. **Silent worker failures** — `worker-linear-*` returns `ok` but
   the write didn't actually land (network glitch, API quirk).
2. **Out-of-band Linear edits** — someone changes a sub-issue status
   directly in Linear's UI.
3. **Out-of-band file edits** — someone hand-edits
   `.spades/plans/*.md` frontmatter without going through a skill.
4. **Forgotten retries** — a Linear worker failed, the human
   acknowledged it, then forgot to re-run the originating skill.

`/spades:list` and `/spades:status` run an **active drift probe**
when `backend: linear` and surface any drift in the same view as the
rest of their output. The probe is *additive* — it uses the local
and Linear data the skills already fetch (per § Sub-agent Dispatch's
"two-source read"), so cost is at most a single comparison pass per
artefact, no extra round-trips beyond what those skills already
make.

#### What gets compared

For each Plan, Scope, and Project surfaced by the skill:

1. Read the local file's frontmatter `status:` value.
2. Read the corresponding Linear artefact's **workflow state type**
   (Linear's universal classification — `backlog`, `unstarted`,
   `started`, `completed`, `canceled` — not the team-specific
   status name, which varies per Linear team).
3. Compare against the expected mapping below.

#### Status-type mapping (canonical)

| Local SPADES status | Expected Linear workflow type |
|---|---|
| Scope `scoped` | `backlog` or `unstarted` |
| Scope `planning` | `unstarted` |
| Scope `delivering` / `evaluating` / `shipping` | `started` |
| Scope `done` | `completed` |
| Scope `abandoned` | `canceled` |
| Plan `draft` | `unstarted` |
| Plan `approved` | `unstarted` or `started` |
| Plan `delivering` / `evaluating` / `shipping` | `started` |
| Plan `shipped` | `completed` |
| Plan `rejected` | `canceled` |
| Project `active` | not `completed`/`canceled` |
| Project `archived` | `completed` |
| Project `abandoned` | `canceled` |

If Linear is in a workflow type that isn't in the expected set,
that's drift.

#### What "drift" surfaces look like

`/list` and `/status` print a one-line warning per drifted artefact:

```
⚠ Linear drift: S-add-newsletter — local `delivering`, Linear `completed` (Done). Re-run /spades:close S-… (Pass) to roll up locally, or edit Linear if the local file is wrong.
```

The warning includes:
- Artefact ID
- Local status value
- Linear's actual workflow state type (and team-specific name, if
  available)
- A pointer to the most likely remediation skill — usually
  re-running the originating writer skill to push local state to
  Linear

The probe is informational, not blocking. `/list` and `/status` still
render their main view; the drift warnings appear in their own
subsection below the table.

#### When the probe runs

- **Always** when `backend: linear` and the active project's Linear
  Project ID resolves.
- **Skipped** when `backend: local` (nothing to compare against) or
  when the Linear API is unreachable (`/list` and `/status` continue
  with a one-line note: *"Drift probe skipped — Linear unreachable.
  Showing local view only."*).

#### Why active probe, not passive markers

A passive-marker scheme (writers record a `pending-reconcile:`
audit-trail line when a worker returns `fail`) would catch the
known failure case but miss silent failures and out-of-band edits.
The active probe catches all three because it always compares the
two truth-claims regardless of how the drift was introduced.

The cost is one extra Linear comparison pass per `/list` or
`/status` invocation — cheap because the skills already fetch both
sides; the probe is just *"do the comparison we previously
skipped"*.
