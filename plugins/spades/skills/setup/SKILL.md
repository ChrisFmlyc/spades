---
name: setup
description: Configure SPADES in this repository — choose a backend (Linear MCP or local filesystem), set the active project, scaffold AGENTS.md / ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md, and write .spades/config. Use when starting fresh, when someone says "set up SPADES", "configure SPADES", "initialise SPADES", "I want to use SPADES in this repo". Re-runnable to reconfigure backend or refresh scaffolding without clobbering existing content.
---

# /spades:setup

You are configuring SPADES in the current repository. This is the entry
point: every other skill assumes setup has been run and that
`.spades/config` exists. Setup is **idempotent and re-runnable** — a
second run never destroys human-written content; it only fills gaps or
updates the backend choice when the human explicitly asks.

Read `docs/FRAMEWORK.md` § Hierarchy and § .spades/ Local Layout before
running. The schemas below are mirrors of that contract; FRAMEWORK.md
is canonical.

## Self-Init Guard

If the current working directory IS the SPADES framework repo itself
(its `package.json` / `.claude-plugin/plugin.json` has `name: spades`
or the `plugins/spades/` directory exists at the root), abort with:

> This is the SPADES framework's own repository. Setup is for consumer
> repositories that want to *use* SPADES, not for the framework itself.

The framework dogfoods itself by running setup against its own
`plugins/spades/` directory — but you only do that when explicitly told
"set up the dogfood project".

## Step 1 — Backend Selection

Ask the human which backend they want, via `AskUserQuestion`:

- **`Linear`** — artefacts live as Linear Issues (Project, parent Issue,
  sub-issues). Requires the Linear MCP to be configured. The skill will
  verify Linear MCP is callable before committing.
- **`Local`** — artefacts live as Markdown files under `.spades/`. No
  external tracker needed. Easiest to start; full audit trail in-repo.

If the human has already run setup and is re-running it, fetch the
current `backend:` from `.spades/config` and offer **Keep current** as
the recommended option.

### If Linear was chosen

1. Probe Linear MCP with a teams list call. If it fails or returns
   nothing, abort: *"Linear MCP isn't reachable from this session.
   Either configure the MCP first, or pick the Local backend."*
2. Ask the human (via `AskUserQuestion`) which team to use.
3. Ask which Linear Project to bind this SPADES project to. Offer
   **Create new Linear Project** as an option (the next step,
   `newproject`, handles creation).
4. Record the chosen team ID and Linear Project ID in `.spades/config`.

### If Local was chosen

Nothing to verify externally. Continue.

## Step 2 — Active Project

Ask which project this repo belongs to.

- If `.spades/projects/` already contains records, offer them as
  options plus **Create a new project**.
- If there are no project records yet, offer **Create a new project**
  as the only option.

If the human picks **Create a new project**, invoke `/spades:newproject`
inline and resume here once it returns with the new project's slug.

Record the project slug in `.spades/config` under `project:`.

## Step 3 — Write `.spades/config`

Write or update `.spades/config` to exactly this shape:

```yaml
backend: linear            # or: local
project: <project-slug>
linear:                    # only when backend: linear
  team_id: <uuid>
  project_id: <uuid>
```

Re-run safety: if a value the human did not change is already in the
file, preserve it. Never blank fields the human still depends on.

## Step 4 — Write `.spades/version`

```
spades_version=2.0.0
```

Idempotent — overwrite is fine.

## Step 5 — Scaffold the .spades/ subdirectories

Create the following empty directories if missing. Do not put any files
in them; that's the job of the per-phase skills.

- `.spades/projects/`
- `.spades/scopes/`
- `.spades/plans/`
- `.spades/learnings/`
- `.spades/reviews/`

## Step 6 — AGENTS.md (idempotent marker block)

Locate `AGENTS.md` at the repo root. If it doesn't exist, create it
with a one-line header: `# AGENTS.md` and a blank line.

Insert or replace the SPADES section between these markers:

```markdown
<!-- SPADES-FRAMEWORK-START v2.0.0 -->
…the content below…
<!-- SPADES-FRAMEWORK-END -->
```

If markers already exist (any version), replace the content between
them in place. If they don't exist, append the marker block (and
content) to the end of the file. **Never** edit content outside the
markers.

The content to write inside the markers:

```markdown

# SPADES Framework — Agent Operating Rules

These rules define mandatory behaviour for AI agents using the SPADES
framework in this project. They augment any existing agent instructions
in this file and apply to **every** agent that reads this file —
Claude Code, Cursor, Codex, Aider, or anything else that honours
`AGENTS.md`.

## SPADES Skills (v2.0)

The SPADES plugin (`spades`) provides these 15 skills:

| Skill | What it does |
|-------|-------------|
| `/spades:setup` | Configure backend + scaffold this repo (re-runnable) |
| `/spades:newproject` | Create a new project record |
| `/spades:scope` | Create or edit a Scope (`S-<description-slug>`) |
| `/spades:plan` | Generate a Plan (`P-<slug>-<suffix>[-<dep>…]`) under a Scope |
| `/spades:approve` | Present a Plan for human review and record routing |
| `/spades:do` | Execute an approved Plan (routed AI / human / mixed) |
| `/spades:evaluate` | Check delivered output against the Plan |
| `/spades:ship` | Open PR + review + merge (code) or record deliverable (artefact / action) |
| `/spades:quick` | Fast-track for trivial work — PR description is the audit trail |
| `/spades:review` | Multi-persona panel second opinion (4 subagents) on Scope/Plan |
| `/spades:learn` | Capture a learning under `.spades/learnings/` |
| `/spades:research` | Read-only research via an isolated Opus subagent |
| `/spades:list` | List active scopes, filterable by phase |
| `/spades:status` | Show current SPADES phase + dependency graph |
| `/spades:intent` | Maintain `INTENT.md` — the durable project statement |

## The SPADES Loop

Every unit of work follows six phases:

    SCOPE → PLAN → APPROVE → DO → EVALUATE → SHIP

- Humans own Scope, Approve gate, and Evaluate gate.
- AI owns Plan, Do (when routed AI-auto), and Ship (when the deliverable
  is code).
- Approve records a routing decision (`ai` / `human` / `mixed`) that
  determines who executes Do.

Never skip a phase or combine phases without explicit human
instruction.

**Exception — the fast-track path.** Trivial work can use
`/spades:quick` instead of the full loop. See "Fast-Track Path" below.

## Phase Rules

### 1. Scope (Human-owned)
- Never begin planning or writing code without a signed-off Scope.
- A Scope must include: intent, acceptance criteria, constraints,
  dependencies, context, out-of-scope, risk, delivery preference,
  priority.
- Scopes have IDs of the form `S-<description-slug>`.

### 2. Plan (AI-owned, human reviews)
- Produce one or more structured Plans for a Scope before writing code.
- Each Plan has an ID of the form
  `P-<description-slug>-<4-char-suffix>[-<dep-suffix>...]`.
- Plans declare dependencies on prior Plans via `depends_on:`.
- Each task in a Plan declares an execution posture (`test-first`,
  `characterization-first`, `refactor-first`, `spike`,
  `straight-through`).
- Do NOT begin Do-phase work until the Plan is approved.

### 3. Approve (Human gate)
- After producing a Plan, STOP and wait for human approval.
- Approval records a `delivery:` routing on the Plan (`ai`, `human`,
  `mixed`) and a `deliverable_type:` (`code`, `artefact`, `action`).
- If revised or rejected, do not begin delivery.

### 4. Do (AI or Human — routed)
- Execute the approved Plan. Routing comes from the Plan's `delivery:`
  field set at Approve time.
- For `ai`: run the work autonomously, committing as you go.
- For `human`: record the assignment in the backend; do not auto-do.
- For `mixed`: split per the Plan's task-level routing.
- Run tests and verify before moving the Plan to Evaluate.

### 5. Evaluate (Human-owned, AI assists)
- Check delivered output against the Plan's acceptance criteria.
- Verdict is PASS / PARTIAL / FAIL.
- AI may assist but a human signs off the verdict.

### 6. Ship (Mixed)
- For `deliverable_type: code` — open PR, run review, merge.
- For `deliverable_type: artefact` — record the artefact reference.
- For `deliverable_type: action` — record evidence of completion.
- Ship is the moment the deliverable becomes real to the outside world.

## Fast-Track Path (Small Work)

Not every change deserves a Scope. Trivial work — typos, one-line
tweaks, small config nudges, docs changes — uses `/spades:quick`. On
this path the PR description is the audit artefact; no separate Scope
or Plan is created.

### The gate — ALL must be true

1. Single concern
2. ≤ 50 lines of code changed total
3. One file or a tight cluster in one module
4. No new dependencies
5. No schema or data-layer changes
6. No architectural changes
7. No security-sensitive code
8. No public API or interface breaking changes
9. Revertable as one commit
10. Existing tests cover the area

If any criterion fails, fall back to the full loop.

## Architecture Constraints

Before generating any Plan, read these files if they exist:
- `ARCHITECTURE.md` — system architecture and constraints
- `PATTERNS.md` — approved patterns and conventions
- `ANTI-PATTERNS.md` — things you must not do

Flag any conflicts between proposed solutions and these documents.

## Audit Trail

Every piece of work must trace through: project → scope → plan(s) →
approval (with routing) → do-phase record → evaluation verdict →
shipment record. Work that cannot be traced through this chain must
not ship.
```

## Step 7 — Scaffold ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md

For each of these files at the repo root, create it if missing.
**Never overwrite if it exists.** If the human wants the latest
scaffolding inside an existing file, they can rename theirs aside and
re-run setup.

### `ARCHITECTURE.md` (template content)

```markdown
# Architecture

<!-- Describe the system at a high level. What are the major components,
how do they talk to each other, what runs where? -->

## Overview
<!-- 2-3 paragraphs of context. What does this system do? -->

## Tech Stack
<!-- Languages, frameworks, databases, infra primitives. -->

## Data Flow
<!-- How information moves through the system. -->

## Security Requirements
<!-- Auth, secrets, data classification, compliance constraints. -->

## Operational Posture
<!-- Hosting, deployment, monitoring, incident response. -->
```

### `PATTERNS.md` (template content)

```markdown
# Patterns

<!-- Approved patterns and conventions this codebase uses. Reference
these in Plans so reviewers can compare proposals against them. -->

## Code organisation
<!-- e.g. "feature-folders, not layers" -->

## Error handling
<!-- e.g. "Result<T,E> for fallible operations; never throw across
boundaries" -->

## Testing
<!-- e.g. "test-first for new features; characterization-first for
changes to untested code" -->

## Naming
<!-- conventions for files, functions, types -->
```

### `ANTI-PATTERNS.md` (template content)

```markdown
# Anti-Patterns

<!-- Things this codebase deliberately avoids. The Plan must not
introduce any of these. -->

## Runtime dependencies
<!-- e.g. "No runtime dependency on PyYAML; stdlib-only Markdown lint" -->

## Hidden state
<!-- e.g. "No singletons; thread the dependency explicitly" -->

## Premature abstraction
<!-- e.g. "Three similar lines are fine; don't extract until N=4" -->
```

## Step 8 — Optional: scaffold INTENT.md

If `INTENT.md` is missing at the repo root, ask the human (via
`AskUserQuestion`) whether to scaffold it now:

- **Yes, scaffold now** — invokes `/spades:intent` inline.
- **Skip for now** — leave it.

INTENT.md is the project's durable statement of intent (problem,
users, what-it-does, success, non-goals, maturity). It's distinct
from `ARCHITECTURE.md`, which is *how*; INTENT is *why*.

## Step 9 — Confirm and summarise

Print a concise summary:

```
✓ Backend: linear (team: <your-team>, project: <your-project>)
✓ Active project: spades-framework
✓ Config:   plugins/spades/.spades/config
✓ Version:  2.0.0
✓ Updated:  AGENTS.md  (SPADES marker block replaced in place)
✓ Created:  ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md  (templates)
○ Skipped:  INTENT.md (re-run /spades:intent to scaffold)

Next steps:
  /spades:newproject       — if you haven't created one yet
  /spades:scope <title>    — start a new Scope
```

Use `○` for skipped items, `✓` for done, `✗` for failed. Be brief —
the human should be able to confirm correctness in 10 seconds.

## Re-Run Behaviour

When setup runs against a repo that already has `.spades/config`:

1. Confirm via `AskUserQuestion` what the human wants to change:
   - **Keep current backend, refresh scaffolding** — re-runs Steps 5–8.
   - **Switch backend** — re-runs Steps 1–4. Warn that switching backends
     does NOT migrate existing scopes/plans; explain the human is
     responsible for that.
   - **Change active project** — re-runs Step 2.
2. Never destroy human-written content. The AGENTS.md marker block is
   replaced in-place; template files are only created if missing.

## Why AGENTS.md, not CLAUDE.md

SPADES targets `AGENTS.md` because it is the cross-agent convention —
Claude Code, Cursor, Codex, Aider and most other agentic coding tools
honour `AGENTS.md` as the source of project rules. A consumer repo
that adopts SPADES gets one operating-rules file that every agent
reads, instead of one file per vendor. Do not write `CLAUDE.md`,
`CURSOR.md`, or similar per-agent variants.
