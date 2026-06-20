# SPADES Framework — Agent Operating Rules

This file defines mandatory behaviour for all AI agents operating in this project.
These rules are non-negotiable. If you are an AI agent reading this file, you must
follow every instruction below. Violations of the SPADES loop undermine the audit
trail and the trust model that makes human-AI collaboration safe.

`AGENTS.md` is the canonical operating-rules file for any agent that
reads project context — Claude Code, Cursor, Codex, Aider, and the
rest. SPADES deliberately does **not** ship a `CLAUDE.md`,
`CURSOR.md`, or any other per-vendor variant.

## SPADES Skills (v2.0)

This repo ships SPADES itself, so the plugin's 16 skills are available
when working in it. Invoke them by their namespaced names:

| Skill | What it does |
|-------|-------------|
| `/spades:setup` | Configure backend + scaffold this repo (re-runnable) |
| `/spades:newproject` | Create a new Project record |
| `/spades:objective` | Create or edit an Objective (`O-<description-slug>`) — a coherent strategic action associated with a project; independent of Scopes |
| `/spades:scope` | Create or edit a Scope (`S-<description-slug>`) |
| `/spades:plan` | Generate a Plan (`P-<slug>-<suffix>[-<dep>…]`) under a Scope |
| `/spades:approve` | Present a Plan for review; record routing (AI / human / hybrid) |
| `/spades:do` | Execute an approved Plan, routed per the approval decision |
| `/spades:evaluate` | Check delivered output against acceptance criteria |
| `/spades:ship` | Open PR + review + merge (code) or record deliverable (artefact / action) |
| `/spades:close` | Conversational close-out entry. Asks pass / reject / abandon based on target type. Pass = finalise (Plan → shipped, Scope → done, Project → archived, Objective → complete). Reject (Plans) and Abandon (Scopes, Projects, Objectives) require a reason. Objective completion is ungated and has no cascade. Opens a bookkeeping PR for any file change; run `/repo:sync` first. |
| `/spades:quick` | Fast-track for trivial work — quick-item marker file (`.spades/quick/Q-<id>.md`) is the canonical audit record |
| `/spades:review` | Multi-persona panel second opinion (4 subagents) on Scope/Plan |
| `/spades:learn` | Capture a learning under `.spades/learnings/` |
| `/spades:research` | Read-only research via an isolated Opus subagent |
| `/spades:list` | List active scopes, filterable by phase or project |
| `/spades:status` | Show current SPADES phase + dependency graph |
| `/spades:intent` | Maintain `INTENT.md` — the durable project statement |

The active backend is **linear** (see `.spades/config`); the active
project is `spades-framework` — the framework dogfooding itself.

## The SPADES Loop

Every unit of work in this project follows six phases:

    SCOPE → PLAN → APPROVE → DO → EVALUATE → SHIP

Humans own Scope and the Approve / Evaluate gates. AI owns Plan; Do is
routed at Approve time (`ai` / `human` / `hybrid`). Ship branches on
`deliverable_type` (`code` / `artefact` / `action`). You must never
skip a phase or combine phases without explicit human instruction.

**Exception — the fast-track path.** Trivial work (a typo, a one-line
tweak, a config nudge) can use `/spades:quick` instead of the full
loop. See "Fast-Track Path (Small Work)" below for the gate criteria.
When in doubt, use the full loop.

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
- **Before writing a Scope, check the fast-track gate.** If every
  criterion in "Fast-Track Path" below passes, invoke `/spades:quick`
  instead of `/spades:scope`.

### 2. Plan (AI-Owned)

- When a Scope exists, you produce one or more structured Plans before
  writing any code.
- Each Plan has an ID of the form
  `P-<description-slug>-<4-char-suffix>[-<dep-suffix>...]`. The 4-char
  suffix is randomly minted at creation; dependency suffixes encode
  which prior plans must ship first.
- Plans declare dependencies via `depends_on:` in frontmatter. A plan
  is blocked until every plan in its `depends_on:` is `status:
  shipped`.
- Each Plan body includes: technical approach, 3–7 tasks, risks &
  assumptions, testing & verification, delivery sequence.
- Each task in a Plan declares an execution posture (`specify-first`,
  `discover-first`, `iterate`, `spike`, `straight-through`). No silent
  defaults.
- A Plan also declares its `deliverable_type:` (`code`, `artefact`, or
  `action`) — this drives what Ship does later.
- You must NOT begin Do-phase work until the Plan is approved.

### 3. Approve (Human Gate)

- After producing a Plan, STOP and wait for human approval via
  `/spades:approve`.
- The approve gate walks a 6-point checklist (architecture alignment,
  completeness, feasibility, risk, granularity, deliverable fit) and
  asks for a decision: Approve / Approve with notes / Revise / Reject.
- On approval, the gate ALSO records a **routing decision** on the
  Plan's frontmatter: `delivery: ai | human | hybrid`. This determines
  who executes Do.
- If revised or rejected, do not begin delivery. Apply `plan-rejected`
  (Linear) or note in the local audit trail.
- **Panel second opinion (optional).** The human may request
  `/spades:review` before deciding. It spawns four persona subagents —
  scope-guardian, architecture-strategist, security-lens,
  adversarial-reviewer — in parallel, merges their findings by
  convergence, and presents a tiered report. Non-blocking: the panel
  never gates approval or delivery.

### 4. Do (AI or Human — Routed)

- Execute the approved Plan via `/spades:do`. Routing comes from the
  Plan's `delivery:` field set at Approve time.
- **For `deliverable_type: code`**, Do creates a feature branch
  (`feat/`, `fix/`, or `refactor/` per the change's nature) derived
  from the Plan's title before any commits land. The branch name is
  recorded in the audit trail. Do-phase commits go onto this branch;
  `/spades:ship` later pushes it and opens the PR.
- For `delivery: ai`: run the work autonomously, honouring each task's
  execution posture. Commit as you go.
- For `delivery: human`: record the assignment in the backend and
  stand down. Do not auto-do.
- For `delivery: hybrid`: split per the Plan's per-task routing.
- Before starting, verify every plan in this plan's `depends_on:` is
  `status: shipped`. If any is not, warn the human and require an
  explicit override.
- If you discover the Plan is wrong mid-Do, STOP. Surface the
  discrepancy; do not silently change direction.

### 5. Evaluate (Human-Owned)

- After Do completes, the Plan moves to `status: evaluating`. Run
  `/spades:evaluate` to check delivered output against the Scope's
  acceptance criteria.
- Verdict is one of PASS / PARTIAL / FAIL.
  - **PASS** → proceed to Ship.
  - **PARTIAL** → specific gaps, work returns to Do for fixes.
  - **FAIL** → fundamental issue, route back to Plan or Scope.
- AI may assist with evaluation but a human signs off the verdict.

### 6. Ship (Mixed)

- After a PASS verdict, run `/spades:ship`. Behaviour branches on
  `deliverable_type:`:
  - **`code`** — routed by the `scm:` field in `.spades/config`:
    - **`scm: github`** — two-phase: push + `gh pr create` (Phase
      1), then resume after squash-merge to record the merge SHA
      (Phase 2). CodeRabbit feedback commits to the same branch
      between phases.
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

## Freshness Before Read-Across

SPADES skills read files from the **local filesystem**, not from
`origin`. A stale local `main` produces stale findings — audits flag
issues already shipped, plans reference removed code, do-phase work
branches off the wrong base. The fix is mechanical.

### The rule

Before any SPADES skill that reads cross-cutting state or branches
off `main`, the local checkout MUST be in sync with `origin/main`.

Verify with one command:

```bash
git fetch origin --quiet && git rev-list --count main..origin/main
```

- Returns `0` → fresh, proceed.
- Non-zero → stop. Run `/repo:sync` (from the `repo` plugin), then
  re-invoke the SPADES skill.

### When the rule applies

To every SPADES skill that:

- Reads files outside `.spades/` to inform a decision (`scope`,
  `plan`, `approve`, `review`, `research`).
- Creates a branch off `main` (`do`, `close`).
- Reports cross-cutting state (`status`, `list`).

Skills that already own the sync responsibility — `/spades:close`
invokes `/repo:sync` directly at Steps 2 and 7 — satisfy the rule
by construction.

### The behavioural reflex

After any PR merge on this repo (yours or someone else's), the
operator runs `/repo:sync` immediately, before context-switching to
a new SPADES skill. `/repo:sync`'s `"Ready."` handoff is the cue
that the next prompt is fresh work; pre-empt the staleness instead
of catching it mid-audit.

### Subagent prompts

Skills that spawn read-across subagents (`/spades:review`'s panel of
four personas, `/spades:research`'s researcher) include the
freshness check directly in the subagent's prompt. The subagent
runs the check before reading any files and halts if local is
behind — surfaces the staleness to the operator rather than
producing findings against a stale snapshot.

The canonical definition lives in `docs/FRAMEWORK.md § Freshness`.
This section is the operating-rules-level statement; that section is
the contract.

The sister `spades-anywhere` plugin enforces the same rule, with
identical hard-refusal behaviour, in the local-backend + git
scenario (the only `spades-anywhere` scenario where a remote main
exists to compare against). See
`plugins/spades-anywhere/docs/FRAMEWORK.md § Freshness` for the
plugin-specific framing. The skill-level checks in
`/spades-anywhere:review` Step 1 and `/spades-anywhere:research`
Step 1 mirror `/spades:review` and `/spades:research`: same probe,
same abort message structure, same "do not proceed" semantics.

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
| Create a new branch off main | `/repo:branch` (validates the name and enforces the no-commits-on-main rule) plus `git switch -c <name>` to create in place, or `/repo:newbranch` for create-with-worktree. |
| Sync local main after a PR merge | `/repo:sync` — fetches, ff-pulls main, force-deletes the merged feature branch. |
| Refuse to commit on `main` / `master` | `/repo:branch` enforces this absolutely — no overrides. |

SPADES skills that branch off main (`/spades:do`, `/spades:close`)
MUST go through `/repo:branch`'s regex validation. SPADES skills
that need to verify post-merge state (`/spades:close`) invoke
`/repo:sync` directly. The dependency is **one-directional**:
SPADES → `repo`, never the reverse.

### If you don't have a git repo yet

Running SPADES in a directory that isn't a git repo? Run
`/repo:init` first, then re-invoke `/spades:setup`. SPADES expects
an initialised repo — it scaffolds files under git's expectation
that they will be committed (`AGENTS.md`, `ARCHITECTURE.md`,
`.spades/config`, etc.).

### Why this rule

SPADES is the **implementation framework**; the `repo` plugin is the
**git-discipline framework**. Each owns its concern. Mixing them —
e.g. a SPADES skill that runs `git init` inline, or one that
hand-rolls a post-merge cleanup — splits ownership and risks the two
plugins drifting out of agreement. Always defer.

## Backend

The backend is configured in `.spades/config` under `backend:`. SPADES
v2.0 ships two drivers:

- **`backend: linear`** — Project ↔ Linear Project; Scope ↔ parent
  Issue; Plan ↔ sub-issue. Audit records (approval, evaluation,
  shipment) post as comments on the parent issue.
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

### Release gate — do not merge a PR without all of these

The bump is **part of the change, not a follow-up.** Before a PR
merges, confirm every item:

1. **Plugin version bumped.** If *any* file under `plugins/spades/`
   changed, the plugin version moved — in **all four** locations (see
   "Where versions live"). No exceptions: a one-word doc fix still
   bumps. An unchanged version after a real change is silently deduped
   by the updater and reaches **no one**.
2. **Every changed skill bumped.** A skill counts as changed if its
   `SKILL.md`, its `template.html`, or any other file in its directory
   changed — a template-only edit still bumps the skill's `version:`.
3. **AGENTS.md change ⇒ `agents_version` bumped** (plus the plugin).
4. **CHANGELOG entry added** under the new plugin version, listing the
   skills bumped (or "Skills bumped: none").

This gate exists because the rule below is easy to forget: PR #57
redesigned all 26 skill templates and shipped at the unchanged plugin
version — the updater deduped it and no consumer ever received the
redesign. A green CI run does **not** mean the bump happened (see
Enforcement).

### Enforcement

CI's `lint-skill-frontmatter.sh` checks only that each skill *has* a
valid `version:` — it does **not** verify that a change bumped
anything, so a PR can touch every file and bump nothing while CI stays
green. The durable guard is a **bump-on-change check** that, on a PR,
diffs against the merge base and fails when: plugin files changed
without a plugin-version bump; a skill directory changed without that
skill's `version:` bump; the four plugin-version locations disagree; or
no CHANGELOG entry was added for the new version. Until that check
runs, the release gate above is manual and the reviewer owns it — so
review it explicitly on every PR.

### The principle

The plugin version is the umbrella: **if anything inside the plugin
changes, the plugin version bumps.** A change to a skill, a change to
`AGENTS.md`, a change to `docs/`, a metadata tweak — any of them forces
a plugin bump. The component versions are narrower: each bumps **only**
when its own content changes. A component change always implies a
plugin bump; a plugin bump does not imply any given component changed.

This is what makes consumer updates work: Claude Code's plugin updater
dedups by version string, so an unchanged plugin version after a real
change means the update is silently skipped and never reaches anyone.

### Three levels of versioning

- **Plugin version** — declared in
  `plugins/spades/.claude-plugin/plugin.json`, mirrored in
  `.claude-plugin/marketplace.json` (both the marketplace `metadata.version`
  and the plugin entry's `version`), and pinned in
  `plugins/spades/.spades/version` as `spades_version=X.Y.Z`. All four
  values must match. Bumps on **every** merged PR.
- **Skill version** — declared as a `version:` field in each skill's
  frontmatter (`plugins/spades/skills/<name>/SKILL.md`). Bumps **only**
  when that skill's body, frontmatter, or behaviour changes.
- **AGENTS.md version** — the operating rules are themselves a
  versioned, consumer-facing unit. Pinned in
  `plugins/spades/.spades/version` as `agents_version=X.Y.Z`, and
  stamped into the consumer-repo marker
  (`<!-- SPADES-FRAMEWORK-START vX.Y.Z -->`) by `/spades:setup`. Bumps
  **only** when the rules consumers carry change. Because the marker
  tracks the AGENTS.md version (not the plugin version), a consumer's
  block reads as stale only when the rules they hold actually moved —
  not on every unrelated plugin PR.

So a PR that touches three skills bumps those three skills plus the
plugin; a PR that edits `AGENTS.md` bumps `agents_version` plus the
plugin; a PR that only touches `docs/FRAMEWORK.md` bumps only the
plugin.

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

When in doubt, **lean toward bumping higher**. A minor that should
have been patch costs nothing; a patch that should have been minor
hides a real change from anyone reading the changelog.

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

### Where versions live

| Where | What |
|-------|------|
| `plugins/spades/.claude-plugin/plugin.json` `"version"` | Plugin |
| `.claude-plugin/marketplace.json` `metadata.version` + plugins[0].`version` | Plugin (mirror — must match) |
| `plugins/spades/.spades/version` (`spades_version=X.Y.Z`) | Plugin pin |
| `plugins/spades/.spades/version` (`agents_version=X.Y.Z`) | AGENTS.md pin (canonical) |
| `plugins/spades/skills/<name>/SKILL.md` frontmatter `version:` | Per-skill |
| AGENTS.md marker block (`<!-- SPADES-FRAMEWORK-START vX.Y.Z -->`) | AGENTS.md version (consumer-facing) |

### Lint enforces presence

`scripts/lint/lint-skill-frontmatter.sh` requires a `version:` field
on every skill's SKILL.md. CI fails if a skill is missing one.

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
5. A do-phase record of who/what executed each task
6. An evaluation verdict
7. A shipment record

Work that cannot be traced through this chain must not ship. The audit
trail is the mechanism by which AI-delivered work remains trustworthy.

## Fast-Track Path (Small Work)

Not every change deserves a Scope. The fast-track path handles trivial
work — typo fixes, one-line tweaks, small config nudges, docs changes
— through `/spades:quick`. On this path the **PR description is the
audit artefact**: no separate Scope or Plan record is created.

**When a human describes a small fix, check the fast-track gate
BEFORE invoking `/spades:scope`.** If every criterion below passes,
run `/spades:quick`. Otherwise fall back to the full loop.

### The Gate — ALL must be true

1. Single concern (one bug, one tweak, one touch-up)
2. ≤ 50 lines of code changed total; hard stop above ~100
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

Incidents and larger reactive work do NOT use the fast-track path.
Ceremony is cheap during an incident — use the full loop so the audit
trail is complete.

### Evaluating quick-path work

`/spades:evaluate` on a quick-path item validates the PR directly
(merged, CI green, checklist complete) instead of iterating per-plan
tasks. Sub-records are forbidden on the quick path regardless of
verdict.

## Deliberate Non-Goals

Things SPADES does NOT do, by design. Each entry records the
decision and why, so a future contributor can tell *"deliberately
omitted"* apart from *"never thought of it"*.

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
dependency graph. The same applies to `spades-anywhere`.

### No `abandoned` status for Quick items

`/spades:close --abandon` applies to Scopes and Projects only.
Plans use `rejected` (via `/spades:approve` or `/spades:evaluate`
FAIL); Quick items have no terminal walk-away status at all.

**Why:** Quick items are intentionally the lightweight path — the
whole point is to skip ceremony. If you start a quick item and
bail, just delete the marker file at `.spades/quick/Q-<id>.md`.
Adding a status enum + a setter skill for the quick path would
inflate exactly the ceremony the quick path exists to avoid. A
deleted file is a sufficient signal; if you want a trace, the git
history records the delete. The same applies to
`spades-anywhere/quick/Q-<id>.md`.

## What You Must Never Do

- Begin writing code without a documented Scope (or a valid fast-track
  gate pass)
- Begin Do without an approved Plan (on the full loop)
- Begin any producing work (Scope, Plan, Approve, Do, Evaluate,
  Ship, or Close-Pass) on a child of an `abandoned` Scope or an
  `abandoned`/`archived` Project. Producing skills refuse hard at
  the gate — see `docs/FRAMEWORK.md § Target Resolution →
  Parent-status precondition`. The deliberate no-cascade design
  (abandoning a Scope does not auto-reject its Plans) is paired
  with this hard refusal; without it, work would silently land on
  a dead initiative.
- Mark work shipped without verifying the deliverable is real (PR
  merged, artefact reachable, action evidenced)
- Skip the Plan documentation step — Plans are first-class artefacts
- Misuse `/spades:quick` for work that fails any gate criterion
- Create sub-records on the fast-track path
- Introduce technologies or patterns that conflict with
  `ARCHITECTURE.md` without flagging the conflict and getting explicit
  approval
- Assume organisational context you do not have (ask the human)
- Combine multiple Scopes into one delivery without human agreement
- Write a `CLAUDE.md` (or any other per-vendor agent file) — AGENTS.md
  is the only file SPADES maintains in consumer repos

<!--
  Framework-repo note: this file is the canonical SPADES agent
  operating rules. Consumer repos carry a compressed,
  marker-wrapped subset of the rules above, delimited by
  `SPADES-FRAMEWORK-START vX.Y.Z` and `SPADES-FRAMEWORK-END` markers.
  We deliberately do NOT carry that block here — this repo is the
  source of truth. The /spades:setup skill refuses to run inside this
  repository for the same reason.
-->
