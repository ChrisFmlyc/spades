# spades-anywhere Framework v0.1.0

`spades-anywhere` is a human–AI operating model for **real-world,
non-coding work**. It is the sister plugin to `spades` (which targets
code work in coding harnesses). The two share a framework — the
six-phase loop, artefact shape, backend interface (Linear / local),
HTML mode, sub-agent fan-out — but `spades-anywhere` runs in
non-coding contexts (Claude Desktop, ChatGPT, web/mobile) where the
human does the actual work and there is no PR.

This file is the **single source of truth** for `spades-anywhere`'s
contracts. Skills reference it; they do not re-state it.

The cross-plugin parity rule between `spades` and `spades-anywhere`
lives in the repo-root maintainer `AGENTS.md`. Most cross-cutting
framework changes apply to both plugins; this file mirrors
`plugins/spades/docs/FRAMEWORK.md` everywhere it can, and adapts only
where the code-versus-human distinction forces a difference.

---

## The Six Phases

Every unit of work moves through six phases:

```
SCOPE → PLAN → APPROVE → DO → EVALUATE → SHIP
```

| Phase     | Who owns it          | Output                                              |
|-----------|----------------------|-----------------------------------------------------|
| Scope     | Human (AI assists)   | A signed-off Scope record                           |
| Plan      | AI (human reviews)   | One or more Plan records, with deps                 |
| Approve   | Human gate           | `delivery:` routing recorded on the Plan (`human` or `hybrid`) |
| Do        | Human (AI marker only) | Human goes off and does the work; the AI restated the acceptance criteria back |
| Evaluate  | Human verdict        | PASS / PARTIAL / FAIL against the Scope's acceptance criteria |
| Ship      | Confirmation walk    | Per-criterion evidence captured against the project's `INTENT.md` success criteria |

The phases are mandatory and ordered for any work that touches
project intent or runs against acceptance criteria. For genuinely
trivial human work — a single errand, a one-line doc tweak, sending
one email — there is a **fast-track path** via
`/spades-anywhere:quick`, mirroring the sister `spades` plugin's
shape. The gate criteria differ (time-bound, single-action, no
intent shift — not LoC-based) but the marker-file shape and the
relationship to `/evaluate`, `/list`, and `/status` is the same.
See `/spades-anywhere:quick` for the gate and `§ ID Format → Quick-item
ID` below for the file layout.

### Why six (not five)

The split between **Do** (the human acts) and **Ship** (the human
confirms outcomes against project success criteria) keeps "did I do
the task?" separate from "did doing the task move the project's
intent forward?". For human work that distinction matters even more
than for code — a wedding is "done" when the day ends, but only
"shipped" when the photos are filed and the thank-yous sent.

### The Do → Evaluate loop

For human work, Evaluate often produces PARTIAL or FAIL on the first
pass — the human did some of the work but not all. The intended flow
is **Do → Evaluate → Do → Evaluate** until PASS. Evaluate routes back
to Do when it isn't a PASS, and the human keeps going.

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
  long-lived container for work. One project per `.spades-anywhere/config`.
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

**`/spades-anywhere:scope` hard-gates on INTENT.md existence.** If `INTENT.md`
is missing at the repo root, the skill refuses to create a Scope
until `/spades-anywhere:intent` has been run (or the human explicitly
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

- `/spades-anywhere:plan` bumps the Scope from `scoped` → `planning` on the
  first Plan created.
- `/spades-anywhere:approve` does NOT change the Scope's status — the
  Plan's own `status: approved` carries the gate decision. The Scope
  stays at `planning` through the approval gate.
- `/spades-anywhere:do` bumps `planning` → `delivering` on the first
  Plan entering Do.
- `/spades-anywhere:evaluate` bumps to `evaluating` on the first PASS verdict.
- `/spades-anywhere:ship` bumps to `shipping` on the first Plan
  entering Ship (`spades-anywhere` has no PRs — Ship is the
  shipment-evidence-capture step).
- `/spades-anywhere:close` is the **only** skill that transitions
  Scope → `done`. It applies the mixed-terminal rollup rules below.

**One-way transitions only.** A Scope never moves backward. If Plan
B is rejected after Plan A has shipped, the Scope stays at `shipping`
(or `done` if A was the last); the rejected Plan is a leaf state on
its own track. The Scope's audit trail records both transitions.

**Rejected Plans do not block rollup, but require explicit
acknowledgement.** They're terminal — `/spades-anywhere:close`
classifies each sibling as `shipped`, `rejected`, or still in flight,
then applies the rollup rules:

- Every sibling `shipped` → roll up silently to `done`.
- Mix of `shipped` and `rejected`, at least one `shipped` →
  `/spades-anywhere:close` prompts via `AskUserQuestion` listing the
  rejected siblings; on confirmation the Scope rolls up to `done`
  with the rejections acknowledged in the audit trail.
- Every sibling `rejected` (no `shipped`) → no rollup. The Scope
  didn't ship anything; it stays at `shipping` until the human
  re-scopes or abandons explicitly.
- Any sibling still in flight → no rollup.

---

## ID Format

IDs are intended to be human-scannable (you can guess what something is
from its filename), filesystem-safe, and stable.

### Project ID
- Form: `<project-slug>` — lowercase `[a-z0-9-]{1,64}`, no leading
  hyphen, no `..`.
- Stored at: `.spades-anywhere/projects/<project-slug>.md`.
- The slug doubles as the project's ID.

### Scope ID
- Form: `S-<description-slug>` — `S-` prefix plus the same slug grammar.
- Stored at: `.spades-anywhere/scopes/S-<description-slug>.md`.
- The frontmatter `title` preserves the human-readable name.

### Plan ID
- Form: `P-<description-slug>-<own-suffix>[-<dep-suffix>...]`.
- `own-suffix` — 4-character base62 (`[A-Za-z0-9]{4}`), randomly minted
  at creation, never reused.
- `dep-suffix` — each prior plan this one depends on appends its
  `own-suffix` to the filename in dependency order (most recent
  dependency first).
- Stored at: `.spades-anywhere/plans/<filename>.md`.

### Quick-item ID
- Form: `Q-<description-slug>-<own-suffix>`.
- `own-suffix` — 4-character base62 (same generator as Plan IDs).
- Stored at: `.spades-anywhere/quick/Q-<description-slug>-<own-suffix>.md`.
- A quick item is work being done **under a project** but **outside
  the Scope/Plan loop** — `/spades-anywhere:quick` creates one when a
  tiny action meets every gate criterion. `/spades-anywhere:list`
  and `/spades-anywhere:status` surface quick items in their own
  subsection, distinct from Scopes. `/spades-anywhere:evaluate`
  accepts a `Q-…` target and runs its Quick-Path Branch
  (action + evidence retro-validation).
- **Two-phase lifecycle.** `/spades-anywhere:quick` opens the marker
  at `status: shipping` with the planned action declared. The human
  then goes off and does the thing. When they come back with
  evidence, `/spades-anywhere:close Q-<id>` captures the evidence,
  fills in the Action-taken and Evidence body sections, and flips
  to `status: shipped`. Same shape as the sister `spades` plugin's
  two-phase quick; different trigger — human-confirms-with-evidence
  here, PR-merge over there. `status: shipped` always means *the
  human reported back with evidence*. See `/spades-anywhere:quick`
  and the Quick Close Flow in `/spades-anywhere:close`.

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

## .spades-anywhere/ Local Layout

```
.spades-anywhere/
├── config                                    # backend + active project
├── version                                   # framework version (2.0.0)
├── projects/<project-slug>.md                # project records
├── scopes/S-<description-slug>.md            # scope records
├── plans/P-<desc-slug>-<suffix>[-<dep>...].md # plan records
├── quick/Q-<desc-slug>-<suffix>.md           # quick-path items (no Scope/Plan)
├── learnings/YYYY-MM-DD-<slug>.md            # learning records
└── reviews/<slug>-<date>.md                  # panel-review reports
```

### `.spades-anywhere/config` schema

```yaml
backend: linear | local
project: <project-slug>             # active project
review_format: cli | html           # output format for review surfaces
linear:                             # only when backend: linear
  team_id: <uuid>
  project_id: <uuid>                # Linear's own Project ID for this project
```

`spades-anywhere` deliberately has **no `scm:` field** — there is no
SCM layer in this plugin. The sister `spades` plugin documents how
SCM drivers work; `spades-anywhere` is not concerned with code
publishing.

There is **no auto-probe**. The `setup` skill writes this file
explicitly when the human chooses a backend. Skills that read it
trust the value verbatim.

### `.spades-anywhere/projects/<slug>.md` frontmatter

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

### `.spades-anywhere/scopes/S-<slug>.md` frontmatter

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

### `.spades-anywhere/plans/P-<…>.md` frontmatter

```yaml
---
id: P-rag-pipeline-lookup-3HyD
id_suffix: 3HyD                     # 4-char base62, randomly minted
scope: S-add-ai-helper-bot
title: "RAG Pipeline Lookup"
depends_on: [28sD]                  # list of prior plans' id_suffix values
status: draft | approved | delivering | evaluating | shipped | rejected
delivery: human | hybrid            # set by /spades-anywhere:approve (no `ai` — spades-anywhere has no autonomous branch)
evaluation: ai | human | hybrid     # set by /spades-anywhere:evaluate
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

### `.spades-anywhere/learnings/YYYY-MM-DD-<slug>.md` frontmatter

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
| `find_scope_fuzzy(query)` | Return scopes whose slug or title fuzzy-matches the query. Used by `/spades-anywhere:scope` for "are you updating an existing scope?" lookups. |
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
- Reads and writes the files described under § .spades-anywhere/ Local Layout
- `record_*` operations append to the body of the relevant scope/plan
  under an `## Audit Trail` heading

A driver MUST implement every operation; on a no-op platform a driver
may return a documented stub error rather than silently succeeding.

### Adding a backend

The sister `spades` plugin documents an `EXTENDING-BACKENDS.md`
contract for adding new backend drivers (Notion, Confluence, etc.).
The same contract applies here — `spades-anywhere` and `spades`
share the backend interface — but each plugin ships its own driver
implementations. A new backend added in one should be ported to the
other per the parity rule (see the repo-root maintainer `AGENTS.md`).

`spades-anywhere` deliberately has **no SCM layer** — there is no
`scm:` config field, no two-phase ship resume, no PR opening. Ship
in this plugin is a confirmation walk against the project's
`INTENT.md` success criteria, not a code merge.

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
   - For skills that work on exactly one type (e.g. `/spades-anywhere:approve`
     always operates on a Plan), skip this step.
   - For type-flexible skills (today, only `/spades-anywhere:review` qualifies
     — Scope review, Plan review, or Full Review of both), ask via
     `AskUserQuestion`:
     - *Scope review* — target is a Scope
     - *Plan review* — target is a Plan
     - *Full review* — target is a Plan together with its parent Scope

2. **List candidates from the backend**, filtered to:
   - The **active project** from `.spades-anywhere/config`'s `project:` field
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
| `/spades-anywhere:review` | Scope OR Plan (asked at step 1) | Scopes: any active phase; Plans: `draft`, `approved`, `delivering`, `evaluating` |
| `/spades-anywhere:plan` | Scope | `scoped`, `planning` |
| `/spades-anywhere:approve` | Plan | `draft` |
| `/spades-anywhere:do` | Plan | `approved`, `delivering` (so resume works) |
| `/spades-anywhere:evaluate` | Plan (or Scope for whole-scope eval) | Plans: `delivering`, `evaluating`. Scopes: `evaluating` |
| `/spades-anywhere:ship` | Plan | `evaluating` with a PASS verdict recorded in the audit trail |

### Zero-candidate suggestion table

When the filter returns nothing, suggest the upstream skill:

| Skill returning zero | Suggest |
|----------------------|---------|
| `/spades-anywhere:plan` (no scoped Scopes) | `/spades-anywhere:scope <title>` to create one |
| `/spades-anywhere:approve` (no draft Plans) | `/spades-anywhere:plan S-…` to draft one |
| `/spades-anywhere:do` (no approved Plans) | `/spades-anywhere:approve P-…` on a draft plan |
| `/spades-anywhere:evaluate` (no delivering / evaluating Plans) | `/spades-anywhere:do P-…` on an approved plan |
| `/spades-anywhere:ship` (no evaluating + PASS Plans) | `/spades-anywhere:evaluate P-…` to verify a delivered plan |
| `/spades-anywhere:review` (no active artefacts) | `/spades-anywhere:scope <title>` to create one |

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

**The rule applies to:** `/spades-anywhere:scope` (create and edit
modes), `/spades-anywhere:plan`, `/spades-anywhere:approve`,
`/spades-anywhere:do`, `/spades-anywhere:evaluate`,
`/spades-anywhere:ship`, and `/spades-anywhere:close` on the **Pass**
route.

**Exemptions:**

- `/spades-anywhere:close --abandon` and `/spades-anywhere:close
  --reject` are the actions that *create* terminal status; they do
  not refuse based on their own outcome.
- `/spades-anywhere:list` and `/spades-anywhere:status` are
  read-only; they surface abandoned ancestors and their descendants
  (under the `all` filter) without refusing.
- `/spades-anywhere:quick` is independent of the Scope/Project
  hierarchy — its gate is the fast-track criteria, not parent
  status.

**Error shape (hard abort):**

> ✗ Cannot &lt;action&gt; &lt;target-id&gt;: parent &lt;Scope|Project&gt;
> &lt;ancestor-id&gt; is `abandoned` (&lt;date&gt;, "&lt;reason&gt;").
>
> Producing work on abandoned ancestors is refused — once the
> container is abandoned, this work is out of scope. To resume the
> work in a fresh container, create a new Scope (or Project) via
> `/spades-anywhere:scope` (or `/spades-anywhere:newproject`) and
> draft Plans there.

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

## Execution Posture

When a plan declares tasks, each task picks one execution posture from
a fixed set shared between `spades` and `spades-anywhere`. The
posture declares *how* to approach the work, not what to do. The set
is identical across plugins so a Plan moving between coding and
non-coding contexts stays legible.

- **`specify-first`** — the target is clear and worth pinning down
  before starting. **Non-code:** draft the outline / success criteria
  / brief (party run-sheet, chapter outline, hiring stages) before
  filling in the detail. **Code:** write failing tests first, then
  satisfy them.
- **`discover-first`** — the path isn't clear yet; understand the
  current state before changing or committing. **Non-code:** talk to
  stakeholders, read source material, scope vendors before picking an
  approach. **Code:** characterize existing behaviour in tests before
  refactoring it.
- **`iterate`** — the deliverable improves in small passes.
  **Non-code:** plan multiple short cycles (a draft, a recipe, a
  routine), each producing a reviewable version. **Code:** reshape
  an area in small refactor steps, or build incrementally.
- **`spike`** — the correct approach is genuinely unknown; the output
  is *learning* or *a decision* (which venue, which candidate, which
  tool), not the deliverable. Time-boxed.
- **`straight-through`** — the task is mechanical enough that extra
  ceremony adds no value. Not a silent default — state the
  justification on the task line.

A task may declare mixed posture (e.g. `discover-first on the venue
options; specify-first on the run-sheet`).

---

## Audit Trail

Every piece of work must be traceable through:

1. A project record
2. A signed-off scope
3. One or more approved plans
4. An approval decision with routing
5. A do-phase marker (the human acknowledged starting the work)
6. An evaluation verdict
7. A shipment record

Work that cannot be traced through this chain must not ship.

### Terminal states — `rejected` vs `abandoned`

Three terminal states exist across the artefact hierarchy, with
deliberately different meanings:

- **`rejected`** (Plans only) — *"We evaluated this attempt and
  said no."* A judgement on **this particular approach**. The
  underlying work may continue with a different Plan. `rejected`
  comes from `/spades-anywhere:approve` or
  `/spades-anywhere:evaluate` FAIL. A rejected Plan does NOT
  terminate the parent Scope — write another Plan and keep going.

- **`abandoned`** (Scopes and Projects) — *"We're not doing this
  initiative. Full stop, never."* A terminal walk-away on **the
  whole thing**. Set by
  `/spades-anywhere:close <target> --abandon "reason"`. The reason
  text is required; abandoning an initiative without recording why
  is exactly the audit-trail hole this framework exists to prevent.

- **`done`** (Scopes) / **`shipped`** (Plans) / **`archived`**
  (Projects) — graceful completion. The artefact ran its arc.

Directional rule: `rejected → abandoned` is allowed (you rejected
several Plans, then decided the whole Scope isn't worth doing →
abandon the Scope). `abandoned → anything` is not. Terminal means
terminal.

**No cascade — but the gate refuses.** Abandoning a Scope does NOT
automatically reject or abandon its in-flight Plans. Those Plans
stay at whatever status they were in; the parent's `abandoned` is
the authoritative signal. `/spades-anywhere:list` and
`/spades-anywhere:status` hide children of abandoned parents in the
default view but they remain accessible via `/spades-anywhere:list
all`. Cascading writes that can partially fail would risk lying
about state.

This deliberate-no-cascade design is paired with a hard gate:
producing skills (`/spades-anywhere:scope`, `/spades-anywhere:plan`,
`/spades-anywhere:approve`, `/spades-anywhere:do`,
`/spades-anywhere:evaluate`, `/spades-anywhere:ship`, and
`/spades-anywhere:close` on the Pass route) refuse to act on a child
of an `abandoned` ancestor. See § Target Resolution → Parent-status
precondition for the contract.

Mid-flight abandonment is explicitly allowed. You do not need to
terminate child Plans first; the whole point of `abandoned` is to
walk away from in-flight work cleanly.

Quick items have no `abandoned` (or `rejected`) state — if you
start a quick item and bail, delete the marker file. Quick is the
lightweight path; a terminal status would be ceremony for a
delete. `/spades-anywhere:close Q-<id>` handles the drop
conversationally: if the human reports the action didn't happen,
it offers *Drop* alongside the normal *Done — flip to shipped
with evidence* option.

### Plan rejection — no cascade

A Plan with `status: rejected` does **not** automatically invalidate
Plans that depend on it via `depends_on:`. Dependants stay in
whatever state they were in (`draft`, `approved`) — but they are
**blocked**:

- `/spades-anywhere:do` refuses to start a Plan whose `depends_on:` chain
  contains a `rejected` ancestor. It aborts with a pointer to
  `/spades-anywhere:plan` for the rejected ancestor.
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
section. The prefix is universal; the suffix records what was
delivered:

| `deliverable_type` | Marker shape |
|--------------------|--------------|
| `artefact` (URL, file path, doc ID) | `Shipped. Artefact: <ref>. Type: artefact.` |
| `action` (real-world action with evidence) | `Shipped. Action: <description>. Evidence: <list>.` |

`spades-anywhere` does NOT have a `deliverable_type: code` branch —
there is no PR, no merge SHA, no SCM driver in this plugin (see the
sister `plugins/spades/docs/FRAMEWORK.md` for that case).

The `Shipped` line is appended by `/spades-anywhere:ship` after the
confirmation walk against the project's `INTENT.md` success criteria
completes. Plans NEVER transition to `status: shipped` without a
matching audit line.

## Freshness

`spades-anywhere` runs in contexts where there is often no git repo
at all (Claude Desktop project, ChatGPT conversation, mobile client).
The freshness contract from the sister `spades` plugin still
applies — read against the latest source of truth, not a stale
snapshot. The contract is identical; what differs is which scenarios
the contract activates in:

- **Linear backend** — Linear is the canonical source. Sub-agents
  and skills that read state via the Linear MCP always see the
  current state; there is no "local main is behind" problem.
  Freshness is a no-op in this scenario.
- **Local backend, no git** — `.spades-anywhere/` lives on disk in
  the user's project folder. There is no remote to compare against;
  freshness is a no-op. The user owns their own files.
- **Local backend, inside a git repo** — the consumer has chosen to
  put their `.spades-anywhere/` under version control (e.g. for a
  shared family project). **The same hard-refusal rule as `spades`
  applies**: before any cross-cutting read or read-across sub-agent
  spawn, the local checkout MUST be in sync with `origin/main`.

  Verify with one command:

  ```bash
  git fetch origin --quiet && git rev-list --count main..origin/main
  ```

  - Returns `0` → fresh, proceed.
  - Non-zero → **stop**. Sync (`git pull`, or `/repo:sync` if the
    `ai-skills/repo` plugin is installed, or the equivalent in your
    environment) and re-invoke the skill. `spades-anywhere` does
    NOT require the `/repo` plugin — sync is the consumer's
    responsibility — but proceeding against stale state is **not
    permitted**. Read-across sub-agents will halt rather than
    produce findings against a stale snapshot.

This is a hard rule, not informational. The skill-level enforcement
lives in `/spades-anywhere:review` Step 1 and
`/spades-anywhere:research` Step 1; both abort with a clear sync
instruction when stale. Operators should run sync immediately after
any pull/merge on the project repo, before invoking a SPADES skill.

### Subagent prompts

Skills that spawn read-across sub-agents
(`/spades-anywhere:review`'s panel, `/spades-anywhere:research`'s
researcher) include the freshness pre-flight directly in the
sub-agent's prompt — but only the in-git scenario activates the
check; Linear-backend and no-git local scenarios skip the probe
entirely (because there's nothing to check). When the probe runs and
returns stale, the sub-agent halts and surfaces the staleness to the
operator. Sub-agents never produce findings against a stale
snapshot.

This matches the sister `spades` plugin's `/spades:review` and
`/spades:research` enforcement exactly. Process symmetry is the
point: a panel review run on stale state corrupts the audit trail
the same way regardless of which plugin spawned it.

### Why this lives in FRAMEWORK.md

Freshness is not skill-specific — it's a contract every skill
participates in (in the scenarios where it applies). Defining it
once here means individual skills don't repeat the rule; they
reference it. The sister `spades` plugin documents the rule in
**both** `AGENTS.md` § Freshness Before Read-Across (operating-rules
summary) and `docs/FRAMEWORK.md` § Freshness (full contract);
`spades-anywhere` keeps the contract in this single location because
the plugin has no separate AGENTS.md surface today.

## Output Format (CLI vs HTML)

`/spades-anywhere:setup` Step 1.7 records `review_format:` in
`.spades-anywhere/config` — one of `cli` (default) or `html`.
The value controls *whether* an HTML companion file is written
alongside the canonical Markdown, and the *medium* of
presentation when a skill would otherwise paste a large block
to the CLI. The skill flows, prompts, and decisions don't
change between modes.

### Universal rule — `.md` always, `.html` additive in HTML mode

**Every producing skill writes its canonical `.md` in BOTH
modes.** The `.md` is the AI-readable source of truth — the AI,
sub-agents, and any other tool reading the knowledge store all
consume the `.md`. The `.md` lives at the artefact's canonical
path in `.spades-anywhere/<dir>/<id>.md` (or the repo-root path
for project docs: `INTENT.md`, `ARCHITECTURE.md`, `PATTERNS.md`,
`ANTI-PATTERNS.md`).

**In HTML mode, the skill ADDITIONALLY writes an `.html`
companion alongside the `.md`** — same data, rendered through
the skill's bundled `template.html` for the human's view, then
auto-opened via `OPEN_CMD`. The `.html` is purely a human-view
enrichment; it never replaces the `.md`.

This is the load-bearing rule:

- **CLI mode** = `.md` is the only file. Skill body summarises
  inline to the terminal where the skill prose already does
  that.
- **HTML mode** = `.md` PLUS `.html`. Both files coexist. The
  human reviews the `.html`; the AI continues to read the
  `.md`.

Strip `.html` out of HTML mode and you have CLI mode. Add
`.html` to CLI mode and you have HTML mode. HTML is a strict
superset of CLI.

There is no "format swap" — that pattern existed in earlier
versions and has been removed. Any skill prose still mentioning
"format swap only" or "do NOT also write a `.md`" is stale and
should be fixed.

#### What about evaluate's two-page HTML output?

`/spades-anywhere:evaluate` is a special case in two respects:

1. It does NOT write a per-evaluation `.md` — the verdict lives
   only as an audit-trail line on the Plan's existing `.md`.
   That audit line is the AI-readable source of truth.
2. In HTML mode it writes **two** `.html` files
   (`<plan>-<date>-plan.html` at Pre-Flight Step 5 and
   `-report.html` at Step 2.5) — the verification plan + the
   completed evaluation report.

The universal rule still applies in spirit: the AI's source of
truth lives in the `.md` (the Plan's audit trail); HTML mode
adds human-viewable `.html` artefacts on top. CLI mode just
omits the `.html`s.

#### What about cross-cutting transient views (status, list)?

`/spades-anywhere:status` and `/spades-anywhere:list` don't
produce persistent artefacts — they render a current-state view
from existing artefacts. In CLI mode they print to the
terminal; in HTML mode they additionally write
`.spades-anywhere/.tmp/<view>.html` (gitignored, regenerated
each call) and auto-open it. The terminal output still appears
for short status text in both modes.

### Producing skills — `cli` vs `html` write

Producing skills are `/spades-anywhere:newproject`,
`/spades-anywhere:scope`, `/spades-anywhere:plan`,
`/spades-anywhere:learn`, `/spades-anywhere:review`,
`/spades-anywhere:intent`, `/spades-anywhere:architecture`,
`/spades-anywhere:patterns`, `/spades-anywhere:anti-patterns`.
Each writes an artefact at the end of its flow.

- **`review_format: cli`** — write the canonical `.md` under
  `.spades-anywhere/<dir>/<id>.md` (or repo root for project
  docs). Paste a summary to the terminal where the skill body
  already does that. No HTML written.
- **`review_format: html`** — write the canonical `.md` exactly
  as in CLI mode, AND ADDITIONALLY write `.html` companion at
  `.spades-anywhere/<dir>/<id>.html` (or
  `.spades-anywhere/<name>.html` for project docs alongside
  their `<NAME>.md`) using the skill's sibling `template.html`
  resource (located at
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
  6. Writing the result to `.spades-anywhere/<dir>/<id>.html`.
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
`do`, `ship`, `intent`): when in HTML mode and the `.html` file is
open, do NOT also paste long review-form text to the CLI.

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

Consumer skills are `/spades-anywhere:approve`, `/spades-anywhere:evaluate`,
`/spades-anywhere:do`, `/spades-anywhere:ship`, `/spades-anywhere:status`,
`/spades-anywhere:list`, `/spades-anywhere:intent`. Each, at some point in its flow,
presents an artefact for the human to review.

`/spades-anywhere:evaluate` is a **two-page producer** in HTML
mode. It does NOT open the Plan's or Scope's `.html` at
Pre-Flight any more — that caused users to mistake the Plan
render for the eval output. The two pages it writes are:

1. **Page 1 — Verification plan**:
   `.spades-anywhere/evaluations/<plan-id>-<date>-plan.html`,
   written at Pre-Flight Step 5 before the per-criterion walk
   starts. Shows each acceptance criterion as a row with
   `verifier: Human` (gold chip), verdict `PENDING`. The human
   previews what's about to be asked.
2. **Page 2 — Evaluation report**:
   `.spades-anywhere/evaluations/<plan-id>-<date>-report.html`,
   written at Step 2.5 after the human picks the verdict at
   Step 2 and provides a one-paragraph rationale. Same template;
   verdicts filled in.

`{{spades.mode}}` (`plan` | `report`) drives sidebar brand, H1
prefix, tagline, browser title.

- **`review_format: cli`** — paste the artefact's content (or a
  summary) to the terminal as today.
- **`review_format: html`** — auto-open the relevant `.html`
  artefact in the default browser via the OPEN_CMD prelude.
  - For artefact-bound reviews (approve / do / ship): the
    `.html` already exists at `.spades-anywhere/<dir>/<id>.html`
    because the producing skill wrote it. Just open it.
    (`evaluate` is **not** in this list — see above; it writes
    its own pair of pages and does NOT open the Plan's `.html`.)
  - For transient cross-cutting views (status / list / intent):
    render to `.spades-anywhere/.tmp/<view>.html` using the consumer
    skill's sibling `template.html`, then open. Transient files
    are regenerated on every invocation; `/spades-anywhere:setup` appends
    `.spades-anywhere/.tmp/` to the consumer repo's `.gitignore` at install
    time, so these files are never committed.
  - For evaluate's *produced* pages: persistent at
    `.spades-anywhere/evaluations/<plan-id>-<date>-plan.html`
    (page 1, written at Pre-Flight Step 5) and
    `.spades-anywhere/evaluations/<plan-id>-<date>-report.html`
    (page 2, written at Step 2.5). There is no SCM in
    spades-anywhere — the human saves both rendered files to
    their chat-surface knowledge store on their own cadence.
  - For intent's *produced* persistent HTML: when
    `review_format: html`, `/spades-anywhere:intent` writes
    `.spades-anywhere/intent.html` alongside `INTENT.md` (in
    addition to the transient `.spades-anywhere/.tmp/intent.html`
    preview during the edit flow). Same principle: `.md` for the
    AI to read, `.html` for the human to view.

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

- A single local file path (e.g. `.spades-anywhere/plans/P-foo-3HyD.html`).
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
  Layer-2 pre-flight required by `/spades-anywhere:review` and
  `/spades-anywhere:research`: run `git rev-list --count main..origin/main`
  and abort if local is behind.

### Dispatch modes

The same three-mode model from `/spades-anywhere:review`:

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
   the write didn't actually land.
2. **Out-of-band Linear edits** — someone changes a sub-issue
   status directly in Linear's UI.
3. **Out-of-band file edits** — someone hand-edits
   `.spades-anywhere/plans/*.md` frontmatter without going through
   a skill.
4. **Forgotten retries** — a Linear worker failed, the human
   acknowledged it, then forgot to re-run the originating skill.

`/spades-anywhere:list` and `/spades-anywhere:status` run an
**active drift probe** when `backend: linear` and surface any drift
in the same view as the rest of their output. The probe is
*additive* — it uses the local and Linear data the skills already
fetch, so cost is at most a single comparison pass per artefact, no
extra round-trips.

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

`/list` and `/status` print a one-line warning per drifted
artefact:

```
⚠ Linear drift: S-plan-birthday-party — local `delivering`, Linear `completed` (Done). Re-run /spades-anywhere:close S-… (Pass) to roll up locally, or edit Linear if the local file is wrong.
```

The warning includes:
- Artefact ID
- Local status value
- Linear's actual workflow state type (and team-specific name, if
  available)
- A pointer to the most likely remediation skill — usually
  re-running the originating writer skill to push local state to
  Linear

The probe is informational, not blocking. `/list` and `/status`
still render their main view; drift warnings appear in their own
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
