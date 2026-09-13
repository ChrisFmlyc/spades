# SPADES Framework — Agent Operating Rules

This file defines mandatory behaviour for all AI agents operating in this project.
Follow the phase rules and record each decision in the audit trail.

`AGENTS.md` is the only operating-rules file SPADES maintains for agents
that read project context, including Claude Code, Cursor, Codex and Aider.

## SPADES Skills

This repo ships SPADES itself, so the plugin's 23 skills are available
when working in it. Invoke the main ones by their namespaced names:

| Skill | What it does |
|-------|-------------|
| `/spades:setup` | Configure backend + scaffold this repo (re-runnable) |
| `/spades:loop` | Drive an existing Scope through Plan, Approve, Deliver, Evaluate, Ship, review, merge and close-out. Runs on explicit invocation or delegation by a user-defined goal; pauses for checks that require the human. |
| `/spades:newproject` | Create a new Project record |
| `/spades:projectlead` | Assign a Project lead locally or confirm a Linear user before assignment |
| `/spades:objective` | Create or edit an Objective (`O-<description-slug>`) — a coherent strategic action associated with a project; independent of Scopes |
| `/spades:scope` | Create or edit a Scope (`S-<description-slug>`) |
| `/spades:plan` | Generate a Plan (`P-<slug>-<suffix>[-<dep>…]`) under a Scope |
| `/spades:approve` | Present a Plan for review; record routing (AI / human / hybrid) |
| `/spades:deliver` | Execute an approved Plan, routed per the approval decision |
| `/spades:evaluate` | Check delivered output against acceptance criteria |
| `/spades:ship` | Open the PR (code) or record the deliverable (artefact / action) |
| `/spades:close` | Conversational close-out entry. Asks pass / reject / abandon based on target type. Pass = finalise (Plan → shipped, Scope → done, Project → archived, Objective → complete). Reject (Plans) and Abandon (Scopes, Projects, Objectives) require a reason. Objective completion is ungated and has no cascade. Opens a bookkeeping PR for any file change. |
| `/spades:quick` | Fast-track for trivial work — quick-item marker file (`.spades/quick/Q-<id>.md`) is the canonical audit record |
| `/spades:review` | Multi-persona panel second opinion (4 subagents) on Scope/Plan |
| `/spades:learn` | Capture a learning under `.spades/learnings/` |
| `/spades:leads` | Raise an out-of-scope discovery as a Lead mid-task without derailing the work; `--list`, `--show`, `--promote`, `--close` manage them |
| `/spades:research` | Read-only research via an isolated Opus subagent |
| `/spades:list` | List active scopes, filterable by phase or project |
| `/spades:status` | Show current SPADES phase + dependency graph |
| `/spades:intent` | Maintain `INTENT.md` — the durable project statement |
| `/spades:architecture` | Maintain `ARCHITECTURE.md` — how the system is built |
| `/spades:patterns` | Maintain `PATTERNS.md` — approved conventions |
| `/spades:anti-patterns` | Maintain `ANTI-PATTERNS.md` — deliberate exclusions |

The active backend is **linear** (see `.spades/config`); the active
project is `spades-framework` — the framework dogfooding itself.

## The SPADES Loop

Every unit of work in this project follows six phases:

    SCOPE → PLAN → APPROVE → DELIVER → EVALUATE → SHIP

Humans own Scope and the Approve / Evaluate gates. AI owns Plan; Deliver is
routed at Approve time (`ai` / `human` / `hybrid`). Ship branches on
`deliverable_type` (`code` / `artefact` / `action`). You must never
skip a phase or combine phases without explicit human instruction.

**Exception — the fast-track path.** Trivial work (a typo, a one-line
tweak, a config nudge) can use `/spades:quick` instead of the full
loop. See "Fast-Track Path (Small Work)" below for the gate criteria.
When in doubt, use the full loop.

### Running the phases: by hand, or via `/spades:loop`

Drive each phase by its command, or invoke `/spades:loop` after a
human-owned Scope exists. The loop executes the phase skills and answers
their questions from the Scope, Plan, config and project documents.
It records those answers as `AI (/spades:loop)`.

The loop runs all six approval checks and self-approves only when they
pass. It derives evaluation from the verification rows: when every row has been
AI-verified, it confirms the verdict; when a row requires a human, that
human performs the check and confirms the verdict. Other pauses follow
`skills/loop/SKILL.md § Pauses`.

Route tasks and checks to `ai` by default, and to `human` when the agent
cannot perform them. The loop uses the same status fields and audit records
as manual execution, so the human can take over at any stage. Completed
branches and worktrees remain available.

See `docs/FRAMEWORK.md § Orchestration Order (/spades:loop)` for invocation
boundaries, capped rework and resumption.

## Hierarchy

```
Project (a repo, a service, a set of repos)
├── Objective (O-<description-slug>) — a coherent strategic action; independent
└── Scope (S-<description-slug>) — one outcome
    └── Plan (P-<description-slug>-<suffix>[-<dep>...]) — one unit of executable work
```

Plans can depend on prior plans within the same Scope. The dependency
chain is encoded in the filename (each prior plan's 4-char suffix
appended) and authoritatively in the `depends_on:` frontmatter field.

A Project has **two independent kinds of child**: Objectives and Scopes.
An Objective is *not* a parent or child of a Scope — they are parallel.
Objectives are optional, repeatable, do not run the six-phase loop, and have
states `open → complete | abandoned`. Completing/abandoning an Objective is
the human's ungated judgement and never cascades to the Project or Scopes.
See `docs/FRAMEWORK.md § Hierarchy → Objectives` for the full contract.

## Phase Rules

The rules below describe manually driven phases. An explicitly invoked
`/spades:loop` answers child-skill questions under the orchestration contract
above.

Before producing work, verify the target's ancestors under
`docs/FRAMEWORK.md § Target Resolution → Parent-status precondition`.
That contract defines the hard refusal for abandoned or archived containers
and the exemptions for closure and read-only views.

### 1. Scope (Human-Owned)

- You must NEVER begin planning or writing code without a written Scope.
- A Scope has an ID of the form `S-<description-slug>` and lives at
  `.spades/scopes/S-<slug>.md` (with a backend mirror when `backend:
  linear`).
- A Scope must include: statement of intent, acceptance criteria,
  architectural constraints, dependencies, context, out-of-scope, risk,
  delivery preference, priority.
- If a human asks you to "just do X" without a Scope, ask them to
  define one first. Help them write it if needed via `/spades:scope`,
  but do not proceed to Plan without a documented Scope.
- Ask the human for organisational context that is missing. Combining
  multiple Scopes into one delivery requires human agreement.
- **Before writing a Scope, check the fast-track gate.** If every
  criterion in "Fast-Track Path" below passes, invoke `/spades:quick`
  instead of `/spades:scope`.

### 2. Plan (AI-Owned)

- When a Scope exists, you produce one or more structured Plans before
  writing any code.
- Each Plan has an ID of the form
  `P-<description-slug>-<4-char-suffix>[-<dep-suffix>...]`. The 4-char
  suffix is randomly minted at creation; dependency suffixes encode
  which prior Plans must be ready first per § Scope Worktrees and Freshness.
- Plans declare dependencies via `depends_on:` in frontmatter. A dependency
  is ready when shipped, or confirmed PASS on this Scope branch; readiness
  permits dependent delivery without claiming the dependency is shipped.
- Each Plan body includes: technical approach, 3–7 tasks, risks &
  assumptions, testing & verification, delivery sequence.
- Each task in a Plan declares an execution posture (`specify-first`,
  `discover-first`, `iterate`, `spike`, `straight-through`). No silent
  defaults.
- A Plan also declares its `deliverable_type:` (`code`, `artefact`, or
  `action`) — this drives what Ship does later.
- You must NOT begin Deliver-phase work until the Plan is approved.

### 3. Approve (Human Gate)

- After producing a Plan, STOP and wait for human approval via
  `/spades:approve`.
- The approve gate walks a 6-point checklist (architecture alignment,
  completeness, feasibility, risk, granularity, deliverable fit) and
  asks for a decision: Approve / Approve with notes / Revise / Reject.
- On approval, the gate ALSO records a **routing decision** on the
  Plan's frontmatter: `delivery: ai | human | hybrid`. This determines
  who executes Deliver.
- If revised or rejected, do not begin delivery. Apply `plan-rejected`
  (Linear) or note in the local audit trail.
- **Panel second opinion (optional).** The human may request
  `/spades:review` before deciding. It spawns four persona subagents —
  scope-guardian, architecture-strategist, security-lens,
  adversarial-reviewer — in parallel, merges their findings by
  convergence, and presents a tiered report. Non-blocking: the panel
  never gates approval or delivery.

### 4. Deliver (AI or Human — Routed)

- Execute the approved Plan via `/spades:deliver`. Routing comes from the
  Plan's `delivery:` field set at Approve time.
- Deliver creates the Scope's separate delivery branch and worktree through
  `/repo:newbranch`, using the intended `branch:` recorded on the Scope.
  Every Plan in the Scope shares it; `/spades:ship` publishes the branch
  through its PR after the participating code Plans pass evaluation.
- For `delivery: ai`: run the work autonomously, honouring each task's
  execution posture. Commit as you go.
- For `delivery: human`: record the assignment in the backend and
  stand down. Do not auto-deliver.
- For `delivery: hybrid`: split per the Plan's per-task routing.
- Before starting, verify dependencies are ready per § Scope Worktrees
  and Freshness. A rejected dependency requires replanning.
- If you discover the Plan is wrong mid-Deliver, STOP. Surface the
  discrepancy; do not silently change direction.

### 5. Evaluate (Human-Owned)

- After Deliver completes, the Plan moves to `status: evaluating`. Run
  `/spades:evaluate` to check delivered output against the Scope's
  acceptance criteria.
- Verdict is one of PASS / PARTIAL / FAIL.
  - **PASS** → proceed to Ship.
  - **PARTIAL** → specific gaps, work returns to Deliver for fixes.
  - **FAIL** → fundamental issue, route back to Plan or Scope.
- AI may assist with evaluation but a human signs off the verdict.

### 6. Ship (Mixed)

- After a PASS verdict, run `/spades:ship`. Behaviour branches on
  `deliverable_type:`:
  - **`code`** — routed by the `scm:` field in `.spades/config`:
    - **`scm: github`** — two-phase: `/spades:ship` pushes and
      opens the PR (Phase 1); review-bot feedback commits to the
      same branch; after the squash-merge `/spades:close P-<id>`
      verifies the merge and records the `Shipped` marker on main
      via a bookkeeping PR (Phase 2).
    - **`scm: local-git`** — single-phase: push to the configured
      remote (if any), record the commit SHA, mark shipped. No PR,
      no CodeRabbit.
    - Other SCMs (GitLab, Bitbucket) follow the contract in
      `docs/EXTENDING-SCM.md`.
  - **`artefact`** — record the artefact reference (URL, doc ID, file
    path) on the Plan.
  - **`action`** — record evidence of completion (photo, email
    reference, receipt, signed doc).
- A Plan reaches `status: shipped` only when its deliverable is real
  to the outside world. A Scope reaches `status: done` when every
  Plan under it is terminal — either `shipped` or `rejected` — with
  at least one `shipped`. When any sibling is `rejected`, the rollup
  is human-acknowledged via `AskUserQuestion` so the rejection is
  recorded explicitly in the Scope audit trail. A Scope where every
  Plan was `rejected` does not roll up to `done` — it remains at
  `shipping` until the human re-scopes or abandons explicitly.

## Architecture Constraints

Before generating any Plan, you must read these files if they exist:

- `ARCHITECTURE.md` — system architecture, infrastructure, and data flow
- `PATTERNS.md` — approved patterns, libraries, and conventions
- `ANTI-PATTERNS.md` — things you must not do, with rationale

If a proposed solution conflicts with these documents, flag the
conflict in the Plan and get explicit human approval before
proceeding.

## Scope Worktrees and Freshness

Scope, Plan and Approve reuse the current non-default working branch.
From main/master, prepare one documentation worktree through `/repo:newbranch`
before writing, then reuse it across the session's Scopes and Plans. Main
stays clean; pending records can accumulate without a PR at every phase.

Scope records its intended delivery `branch:` without creating it. The first
`/spades:deliver` creates that separate branch/worktree through `/repo:newbranch`,
transfers the selected Scope's authorised records and adds `base_commit:`.
Deliver, Evaluate and Ship use that worktree; subsequent Plans share it.
Established delivery resumes via `/repo:newbranch --resume <branch>`.
The documentation branch and its other Scopes remain available.

One Scope's code Plans share one delivery PR. Dependencies can proceed on
the same branch after a confirmed PASS; they become shipped only after the
PR merge is verified. Ship waits for all participating code Plans to pass.
Close records their shipment in one separate bookkeeping worktree/PR,
also prepared through `/repo:newbranch`.

Read-only workers receive the intended Scope/PR worktree and revision,
and verify that context. They do not switch or pull main. A moving remote
base is handled deliberately on the PR branch, with affected checks rerun.

Completion retains branches and worktrees. New work prepares its own base;
cleanup is a separate explicit request. The full contracts live in
`docs/FRAMEWORK.md § Scope Worktrees` and § Freshness.

## Review-page ownership

Present only the active skill's review page: Scope opens its Scope, Plan its
Plan, and project-document skills their own document. Read reference Markdown
and refresh related HTML quietly. The coordinator selects one `open_path` per
presentation step; workers open only that exact output. Use `open_path: null`
for background renders and refreshes of an already-presented page. Helpers
inherit the active task's presentation context. See `docs/FRAMEWORK.md
§ Review-page ownership` for consumer targets and Evaluate's staged pages.

## Artefacts Carry Forward

Authorised records produced during the current run travel in its branch's
PR. Existing commits on that branch are already part of the PR; they need
no further inclusion decision and are not transferred to other branches.

Pre-existing uncommitted changes, including staged changes and deletions,
require the human's inclusion decision before incorporation. Reuse decisions
for the same changes; surface unknown new edits even inside SPADES paths.
The usual artefact paths identify records, not ownership of every diff.

Before each commit, inspect the entire proposed commit and preserve excluded
staged/unstaged work. Allowlisted `git add` arguments do not protect against
unrelated content already in the index. Follow
`docs/FRAMEWORK.md § Carry-Forward of SPADES-Owned Artefacts` for approved
hunk selection, index preservation and post-commit verification. Close
transfers only approved records to its fresh bookkeeping worktree.

## Sub-agent Fan-Out

Producing skills (`/spades:newproject`, `/spades:objective`,
`/spades:scope`, `/spades:plan`) and writeback-heavy consumer skills (`/spades:approve`,
`/spades:evaluate`) parallelize their Linear + local file work via
sub-agent fan-out: one sub-agent per resource (one file, one Linear
operation), dispatched in a single tool-call wave, with the
coordinator (the skill body) stitching results post-dispatch — e.g.
injecting a captured `linear_issue_id` into a file the file
sub-agent already wrote.

The canonical contract — including the one-sub-agent-per-resource
rule, dispatch modes (`subagent-dispatch` / `sequential-inproc` /
`degraded`), and failure semantics — lives in
`docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`. This is the
operating-rules-level statement; that section is the contract.

## Defer to the `repo` Plugin for Git Operations

SPADES does not own git-level operations. The `repo` plugin (from
the `ai-skills` marketplace) does. For any git operation, use the
appropriate `repo` slash command — never reinvent the equivalent
logic inside a SPADES skill.

| When you need to… | Use |
|-------------------|-----|
| Initialise a new git repo | `/repo:init` — `git init`, placeholder README, wires origin, pushes to main. |
| Start new work on a branch and worktree | `/repo:newbranch` — owns naming, clean/current default-branch preparation and worktree creation. |
| Explicitly request post-merge cleanup | `/repo:sync` — separate from starting or completing work. |
| Refuse to commit on `main` / `master` | `/repo:branch` enforces this absolutely — no overrides. |

Deliver, Quick, and Close call `/repo:newbranch` for new work; existing
delivery phases resume its worktree. `/repo:branch` remains the commit and
name guardrail, invoked by the repo workflow. The dependency is
one-directional: SPADES → `repo`, never the reverse.

### The same rule for CodeRabbit — defer to the `codereview` plugin

SPADES does not own PR review triage either. The `codereview` plugin
(same `ai-skills` marketplace) does.

| When you need to… | Use |
|-------------------|-----|
| Drive a PR to zero outstanding review-bot findings | `/codereview:loop` — waits for each review, hands findings to `/codereview:fix`, pushes, re-checks. |
| Fix a block of review findings, one or many | `/codereview:fix` — one subagent per finding; fixes in code or answers on GitHub. Never pushes. |

`/spades:loop` Stage 7 invokes `/codereview:loop` rather than
re-implementing the fix-or-answer contract, and handles only what
`/codereview:loop` deliberately leaves alone — human review threads,
and the final sweep before merge. A human's thread is never
auto-resolved by either plugin. Same one-directional rule: SPADES →
`codereview`, never the reverse.

Before any commit or `/spades:ship` that touches `plugins/spades/`, run
the § Versioning release gate (version bump + changed skills + CHANGELOG).

### Repository setup

When the directory is not a git repo, `/spades:setup` invokes `/repo:init`
inline, then continues scaffolding. Setup owns this sequence; the repo
plugin owns git initialisation. See `docs/FRAMEWORK.md § Bootstrap Order`.

## Backend

The backend is configured in `.spades/config` under `backend:`. SPADES
ships two drivers:

- **`backend: linear`** — Project ↔ Linear Project; Scope ↔ parent
  Issue; Plan ↔ sub-issue. Audit records (approval, evaluation,
  shipment) post as comments on the Plan sub-issue.
- **`backend: local`** — every artefact lives under `.spades/`. Audit
  records append to an `## Audit Trail` heading on the scope/plan
  file.

There is no auto-probe: the human chose the backend explicitly during
`/spades:setup`. See `docs/FRAMEWORK.md` § Backend Interface for the
full contract drivers must satisfy.

## Versioning

Every PR to this plugin **must** bump the plugin version. The
component versions (per-skill and AGENTS.md) bump only when that
component's own content changes.

### Release gate

Before any commit that touches `plugins/spades/`, you MUST report all
four checks below with actual `old → new` values or an explicit `n/a`.
Commit only when every applicable check is complete:

```
[ ] plugin version  X.Y.Z → X.Y.Z   (plugin.json + marketplace ×2 + .spades/version — all four)
[ ] skills bumped   <name> a.b.c → a.b.c, …   (every skill dir with ANY changed file, incl. template.html)
[ ] agents_version  X.Y.Z → X.Y.Z   (only if AGENTS.md changed; else n/a)
[ ] CHANGELOG entry added under the new plugin version
```

The updater deduplicates by plugin version, so every plugin change needs
a version bump in the same PR. Lints check version-field presence; the
release gate checks that changed components received a bump.

### Three levels of versioning

- **Plugin version** — declared in
  `plugins/spades/.claude-plugin/plugin.json`, mirrored in
  `.claude-plugin/marketplace.json` (both the marketplace `metadata.version`
  and the plugin entry's `version`), and pinned in
  `plugins/spades/.spades/version` as `spades_version=X.Y.Z`. All four
  values must match. Bumps on **every** merged PR.
- **Skill version** — declared as a `version:` field in each skill's
  frontmatter (`plugins/spades/skills/<name>/SKILL.md`). Bumps **only**
  when any file in that skill's directory changes, including references
  and templates.
- **AGENTS.md version** — the operating rules are themselves a
  versioned, consumer-facing unit. Pinned in
  `plugins/spades/.spades/version` as `agents_version=X.Y.Z`, and
  stamped into the consumer-repo marker
  (`<!-- SPADES-FRAMEWORK-START vX.Y.Z -->`) by `/spades:setup`. Bumps
  **only** when the rules consumers carry change, including
  `skills/setup/reference/agents-md-block.md`. The marker tracks this
  rules version so consumers can detect stale operating instructions.

### Choosing major / minor / patch

Apply semver based on what changed:

- **Major (X.0.0)** — breaking changes:
  - Removing a skill, or renaming its slash-command name
  - Removing or renaming a frontmatter field, status enum value,
    backend interface operation, or ID format
  - Removing a required field
- **Minor (x.Y.0)** — additive, backwards-compatible changes:
  - New skill
  - New frontmatter field (optional or with default)
  - New status enum value, new routing mode, new deliverable_type
  - New backend driver
- **Patch (x.y.Z)** — fixes and refinements:
  - Bug fix in a skill body
  - Doc improvement
  - Lint refinement
  - Wording change with no behavioural shift
  - Formatting / presentation change to output

When the classification is uncertain, choose the higher semver level.

### Per-skill semver follows the same rules

A skill's own `version:` field follows semver independently. If a PR
changes skill A breakingly and skill B additively, both bump at
different levels:

- Skill A: `2.0.0` → `3.0.0` (breaking)
- Skill B: `2.0.0` → `2.1.0` (additive)
- Plugin: `2.0.0` → `3.0.0` (at least the highest of the skill bumps)

The plugin version is always **at least** the highest of the skill
versions that changed — a breaking change in any one skill forces
the plugin to bump major.

`scripts/lint/lint-skill-frontmatter.sh` requires a `version:` field on
every skill's SKILL.md. Missing versions fail CI.

### CHANGELOG

Every PR adds an entry to `plugins/spades/CHANGELOG.md` at the top
under the new plugin version. Entry shape:

```markdown
## [X.Y.Z] — YYYY-MM-DD

- **<bump kind>**: <one-line summary of the change>
- Skills bumped: `<skill-a>` x.y.z → x.y+1.0, `<skill-b>` x.y.z → x.y.z+1
- (or "Skills bumped: none" for plugin-only changes)
```

## Audit Trail

Every piece of work must trace through:

1. A Project record
2. A signed-off Scope
3. One or more approved Plans (with dependency relationships)
4. An approval decision with routing
5. A delivery-phase record of who/what executed each task
6. An evaluation verdict
7. A shipment record

Work that cannot be traced through this chain must not ship.

## Fast-Track Path (Small Work)

Trivial work that passes every criterion below uses `/spades:quick`.
The quick-item marker is the canonical audit record; the PR description
carries its checklist. No separate Scope or Plan record is created.

**When a human describes a small fix, check the fast-track gate
BEFORE invoking `/spades:scope`.** If every criterion below passes,
run `/spades:quick`. Otherwise fall back to the full loop.

### The Gate — ALL must be true

1. Single concern (one bug, one tweak, one touch-up)
2. ≤ 50 lines of code changed total
3. One file, or a tight cluster in one module
4. No new dependencies (package manifests untouched)
5. No schema, migration, or data-layer changes
6. No architectural changes, no new patterns, no new abstractions
7. No security-sensitive code (auth, crypto, secrets, permissions)
8. No public API or interface breaking changes
9. Revertible as one commit
10. Existing tests cover the area (trivial extension is fine; new
    test scaffolding is not)

If *any* criterion fails, stop and invoke `/spades:scope` for the full
loop. The gate is all-or-nothing.

### Incident response

Incidents and larger reactive work use the full loop and its audit trail.

### Evaluating quick-path work

`/spades:evaluate` on a quick-path item validates the PR directly
(merged, CI green, checklist complete) instead of iterating per-plan
tasks. Sub-records are forbidden on the quick path regardless of
verdict.

## Deliberate Non-Goals

These exclusions define the framework's scope.

### No cross-Scope dependencies

`depends_on:` links Plans within the same Scope. There is no
`depends_on_scopes:` field on Scopes, and no cross-Scope blocking in
`/status`, `/list`, or `/close`.

**Why:** Scopes should be isolated outcomes managed via an external
roadmap, not via in-framework wiring. The cardinal rule is that a
Scope must be able to release a change — even one intended for the
future — without breaking or blocking another Scope. If two Scopes
genuinely need each other to ship in order, the Scope boundaries are
wrong: combine them, or accept that the sequencing lives in the
roadmap (a human-readable artefact outside `.spades/`), not in the
dependency graph.

### No `abandoned` status for Quick items

`/spades:close --abandon` applies to Scopes, Projects and Objectives.
Plans use `rejected` (via `/spades:approve` or `/spades:evaluate`
FAIL); Quick items have no terminal walk-away status at all.

An unfinished Quick item is dropped by deleting its marker at
`.spades/quick/Q-<id>.md`; git history records the deletion. Quick items
therefore need no separate abandonment status.



<!--
  Framework-repo note: this file is the canonical SPADES agent
  operating rules. Consumer repos carry a compressed,
  marker-wrapped subset of the rules above, delimited by
  `SPADES-FRAMEWORK-START vX.Y.Z` and `SPADES-FRAMEWORK-END` markers.
  This source file remains unwrapped. /spades:setup targets consumer
  repositories; explicit dogfood setup follows its self-init guard.
-->
