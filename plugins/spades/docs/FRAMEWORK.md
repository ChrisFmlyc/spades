# SPADES Framework v2.0

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
├── learnings/YYYY-MM-DD-<slug>.md            # learning records
└── reviews/<slug>-<date>.md                  # panel-review reports
```

### `.spades/config` schema

```yaml
backend: linear | local
project: <project-slug>             # active project for this repo
linear:                             # only when backend: linear
  team_id: <uuid>
  project_id: <uuid>                # Linear's own Project ID for this project
```

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
status: scoped | planning | approval | delivering | evaluating | shipping | done
type: feature | bug | chore | docs | refactor | investigation
created: 2026-05-29
updated: 2026-05-29
priority: urgent | high | this-cycle | medium | low | backlog | exploratory
origin: okr | reactive | ad-hoc
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
delivery: ai | human | mixed        # set by /spades:approve
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
9. Revertable as one commit
10. Existing tests cover the area

If *any* criterion fails, fall back to the full loop. The gate is
all-or-nothing.

---

## Execution Posture

When a plan declares tasks, each task picks one execution posture. The
posture declares *how* to approach the build, not what to build.

- **`test-first`** — desired behaviour is well-specified; write failing
  tests first, then satisfy them.
- **`characterization-first`** — existing code without adequate tests;
  pin current behaviour in tests *before* changing it.
- **`refactor-first`** — the area can't cleanly absorb the new
  behaviour; reshape it first, then add the new behaviour.
- **`spike`** — the correct approach is genuinely unknown; the output
  is *learning*, not shippable code.
- **`straight-through`** — the change is mechanical enough that extra
  ceremony adds no value. Not a silent default — state the
  justification.

A task may declare mixed posture (e.g. `characterization-first on the
existing module; test-first on the new behaviour`).

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
