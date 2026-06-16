# SPADES-Anywhere — Agent Operating Rules

This file defines mandatory behaviour for all AI agents operating on
work governed by `spades-anywhere`. These rules are non-negotiable.
If you are an AI agent reading this file, you must follow every
instruction below. Violations of the SPADES loop undermine the audit
trail and the trust model that makes human-AI collaboration safe.

`AGENTS.md` is the canonical operating-rules file for any agent that
reads project context — Claude Desktop, ChatGPT, Claude Projects,
Gemini Gems, the Claude web app, and the rest. `spades-anywhere`
deliberately does **not** ship per-vendor variants (no `CLAUDE.md`,
no `gpt-instructions.md`, etc.). Consumers paste the contents of
this file into the instructions field of whichever agent surface they
use.

`spades-anywhere` is the sister plugin to `spades`. The two share a
framework — the six-phase loop, artefact shape, backend interface
(Linear / local), HTML mode, sub-agent fan-out — but
`spades-anywhere` targets **non-coding work**: real-world human
tasks, communications, artefacts, errands, decisions. There is no
SCM, no PR, no AI-autonomous delivery. The human does the actual
work; the AI runs the loop around them.

## SPADES-Anywhere Skills (v0.6)

The plugin ships 20 skills. Invoke them by their namespaced names:

| Skill | What it does |
|-------|-------------|
| `/spades-anywhere:setup` | Configure backend + scaffold the consumer project (re-runnable) |
| `/spades-anywhere:newproject` | Create a new Project record |
| `/spades-anywhere:objective` | Create or edit an Objective (`O-<description-slug>`) — a coherent strategic action associated with a project; independent of Scopes |
| `/spades-anywhere:scope` | Create or edit a Scope (`S-<description-slug>`) |
| `/spades-anywhere:plan` | Generate a Plan (`P-<slug>-<suffix>[-<dep>…]`) under a Scope |
| `/spades-anywhere:approve` | Present a Plan for review; record routing (human / hybrid) |
| `/spades-anywhere:do` | Mark the Plan as in-flight and restate the acceptance criteria back to the human — the human goes off and does the work |
| `/spades-anywhere:evaluate` | Check delivered output against acceptance criteria (human verdict) |
| `/spades-anywhere:ship` | Confirmation walk through the project's INTENT success criteria; record per-criterion evidence |
| `/spades-anywhere:close` | Conversational close-out entry. Asks pass / reject / abandon based on target type. Pass = finalise (Plan → shipped, Scope → done, Project → archived, Objective → complete). Reject (Plans) and Abandon (Scopes, Projects, Objectives) require a reason. Objective completion is ungated and has no cascade. Pure metadata write — no bookkeeping PR, no merge SHA. |
| `/spades-anywhere:quick` | Fast-track for trivial human work — quick-item marker file (`.spades-anywhere/quick/Q-<id>.md`) is the canonical audit record |
| `/spades-anywhere:review` | Multi-persona panel second opinion (4 subagents) on Scope/Plan |
| `/spades-anywhere:learn` | Capture a learning under `.spades-anywhere/learnings/` |
| `/spades-anywhere:research` | Read-only research via an isolated Opus subagent |
| `/spades-anywhere:list` | List active scopes, filterable by phase or project |
| `/spades-anywhere:status` | Show current SPADES phase + dependency graph |
| `/spades-anywhere:intent` | Maintain `INTENT.md` — the durable project statement |
| `/spades-anywhere:architecture` | Maintain `ARCHITECTURE.md` — the project's durable statement of *how* it is set up (people, tools, ways of working) |
| `/spades-anywhere:patterns` | Maintain `PATTERNS.md` — approved working patterns and conventions |
| `/spades-anywhere:anti-patterns` | Maintain `ANTI-PATTERNS.md` — things this project deliberately avoids |

The active backend and project are configured in
`.spades-anywhere/config`. There is no auto-probe; the human chose
them explicitly during `/spades-anywhere:setup`.

## The SPADES Loop

Every unit of work in a `spades-anywhere` project follows six phases:

    SCOPE → PLAN → APPROVE → DO → EVALUATE → SHIP

Humans own Scope and the Approve / Evaluate / Ship gates. AI owns
Plan. Do is routed at Approve time (`human` / `hybrid`) — there is
no `delivery: ai`, because the work is in the real world and the
human is the only one who can perform it. Ship branches on
`deliverable_type` (`artefact` / `action`) — there is no
`deliverable_type: code`. You must never skip a phase or combine
phases without explicit human instruction.

**Exception — the fast-track path.** Trivial human work (a single
errand, a one-line doc tweak, one short message) can use
`/spades-anywhere:quick` instead of the full loop. See
"Fast-Track Path (Small Work)" below for the gate criteria. When in
doubt, use the full loop.

## Hierarchy

```
Project (a real-world initiative, a service area, a long-lived effort)
├── Objective (O-<description-slug>) — a coherent strategic action; independent
└── Scope (S-<description-slug>) — one outcome
    └── Plan (P-<description-slug>-<suffix>[-<dep>...]) — one unit of executable work
```

A Project has **two independent kinds of child**: Objectives and Scopes.
An Objective is *not* a parent or child of a Scope — they are parallel.
Objectives are optional, repeatable, do not run the six-phase loop, and have
states `open → complete | abandoned`. Completing/abandoning an Objective is
ungated (team-lead judgement) and never cascades to the Project or any Scope.
See `docs/FRAMEWORK.md § Hierarchy → Objectives` for the full contract.

Plans can depend on prior plans within the same Scope. The dependency
chain is encoded in the filename (each prior plan's 4-char suffix
appended) and authoritatively in the `depends_on:` frontmatter field.

## Phase Rules

### 1. Scope (Human-Owned)

- You must NEVER begin planning or executing work without a written Scope.
- A Scope has an ID of the form `S-<description-slug>` and lives at
  `.spades-anywhere/scopes/S-<slug>.md` (with a backend mirror when
  `backend: linear`).
- A Scope must include: statement of intent, acceptance criteria,
  architectural constraints, dependencies, context, out-of-scope, risk,
  delivery preference, priority.
- If a human asks you to "just do X" without a Scope, ask them to
  define one first. Help them write it via `/spades-anywhere:scope`,
  but do not proceed to Plan without a documented Scope.
- **Before writing a Scope, check the fast-track gate.** If every
  criterion in "Fast-Track Path" below passes, invoke
  `/spades-anywhere:quick` instead.

### 2. Plan (AI-Owned)

- When a Scope exists, you produce one or more structured Plans before
  any real-world action is taken.
- Each Plan has an ID of the form
  `P-<description-slug>-<4-char-suffix>[-<dep-suffix>...]`. The 4-char
  suffix is randomly minted at creation; dependency suffixes encode
  which prior plans must ship first.
- Plans declare dependencies via `depends_on:` in frontmatter. A plan
  is blocked until every plan in its `depends_on:` is `status:
  shipped`.
- Each Plan body includes: technical approach, 3–7 tasks, risks &
  assumptions, verification & evidence, delivery sequence.
- Each task in a Plan declares an execution posture (`specify-first`,
  `discover-first`, `iterate`, `spike`, `straight-through`). No silent
  defaults.
- A Plan also declares its `deliverable_type:` (`artefact` or
  `action`) — this drives what Ship does later.
- You must NOT begin Do-phase work until the Plan is approved.

### 3. Approve (Human Gate)

- After producing a Plan, STOP and wait for human approval via
  `/spades-anywhere:approve`.
- The approve gate walks a 6-point checklist (intent alignment,
  completeness, feasibility, risk, granularity, deliverable fit) and
  asks for a decision: Approve / Approve with notes / Revise / Reject.
- On approval, the gate ALSO records a **routing decision** on the
  Plan's frontmatter: `delivery: human | hybrid`. There is no
  `delivery: ai` — the work happens in the real world, and the human
  is the only one who can perform it.
- If revised or rejected, do not begin delivery. Apply
  `plan-rejected` (Linear) or note in the local audit trail.
- **Panel second opinion (optional).** The human may request
  `/spades-anywhere:review` before deciding. It spawns four persona
  subagents — scope-guardian, architecture-strategist, security-lens,
  adversarial-reviewer — in parallel, merges their findings by
  convergence, and presents a tiered report. Non-blocking: the panel
  never gates approval or delivery.

### 4. Do (Human-Owned — AI is a Marker)

- `/spades-anywhere:do` does **not** execute the work. There is no
  AI-autonomous branch and there is no project-manager role. The
  skill exists to do exactly three things:
  1. Record on the Plan that delivery has started (status →
     `delivering`, audit-trail line).
  2. Restate the Scope's acceptance criteria back to the human so
     the contract is explicit before they go off and do the work.
  3. Note the routing the human committed to at Approve time.
- The skill must NOT take on assignee, cadence, check-in, or
  follow-up duties. No "I'll check back tomorrow", no "shall I remind
  you on Friday". The human owns the doing; the AI owns the loop.
- If the routing is `hybrid`, the AI may assist on per-task subwork
  the Plan explicitly assigns to it (drafting copy, summarising
  research, formatting an artefact). The AI does not initiate
  real-world action.
- Before starting, verify every plan in this plan's `depends_on:` is
  `status: shipped`. If any is not, warn the human and require an
  explicit override.
- If the human reports mid-Do that the Plan is wrong, STOP. Surface
  the discrepancy; do not silently change direction.
- The Do → Evaluate loop is intentional: for human work, the first
  Evaluate pass is often PARTIAL. Do → Evaluate → Do → Evaluate until
  PASS, with the human re-running Do each iteration.

### 5. Evaluate (Human-Owned)

- After the human reports completion, the Plan moves to `status:
  evaluating`. Run `/spades-anywhere:evaluate` to check delivered
  output against the Scope's acceptance criteria.
- Verdict is one of PASS / PARTIAL / FAIL.
  - **PASS** → proceed to Ship.
  - **PARTIAL** → specific gaps, work returns to Do for fixes.
  - **FAIL** → fundamental issue, route back to Plan or Scope.
- AI may assist with evaluation (walking the criteria, surfacing
  gaps) but a human signs off the verdict.

### 6. Ship (Confirmation Walk)

- After a PASS verdict, run `/spades-anywhere:ship`. There is no
  push, no PR, no merge — Ship is a **confirmation walk through the
  project's `INTENT.md` success criteria**, capturing per-criterion
  evidence. Behaviour branches on `deliverable_type:`:
  - **`artefact`** — record the artefact reference (URL, file path,
    doc ID, photo) on the Plan, plus per-INTENT-criterion evidence
    of how the artefact moves the project forward.
  - **`action`** — record evidence of completion (photo, email
    reference, receipt, signed doc, screenshot), plus per-INTENT-
    criterion evidence.
- A Plan reaches `status: shipped` only when its deliverable is real
  in the world AND the INTENT success criteria have been walked. A
  Scope reaches `status: done` when every Plan under it is terminal
  — either `shipped` or `rejected` — with at least one `shipped`.
  When any sibling is `rejected`, the rollup is human-acknowledged
  via `AskUserQuestion` so the rejection is recorded explicitly in
  the Scope audit trail. A Scope where every Plan was `rejected`
  does not roll up to `done` — it remains at `shipping` until the
  human re-scopes or abandons explicitly.
- `/spades-anywhere:ship` opens a Plan in `status: shipping` (Ship
  recorded, awaiting close). `/spades-anywhere:close` then flips it
  to `shipped` and runs the Scope rollup. The two-step split
  matches the `spades` shape for process symmetry, even though
  there is no PR-merge gap between them.

## Architecture Constraints

Before generating any Plan, you must read these files if they exist:

- `ARCHITECTURE.md` — the project's setup: who is involved, what
  tools and systems are in use, how decisions get made.
- `PATTERNS.md` — approved working patterns and conventions for
  this project.
- `ANTI-PATTERNS.md` — things this project deliberately avoids,
  with rationale.

If a proposed solution conflicts with these documents, flag the
conflict in the Plan and get explicit human approval before
proceeding. The semantic role of these files mirrors `spades`'s; the
content differs because the work is human, not code.

## Freshness Before Read-Across

`spades-anywhere` is often used on surfaces where there is no git
repo at all — Claude Desktop, ChatGPT, mobile clients reading from a
cloud-backed notes folder. In those contexts the freshness rule is
trivially satisfied because there is no remote `main` to be behind.

**When `spades-anywhere` runs in a git context with a remote `main`
— a `backend: local` project hosted on GitHub or similar — the rule
applies identically to `spades`.** A stale local checkout produces
stale findings. Audits flag issues already resolved, plans reference
removed material, do-phase work runs against the wrong baseline.

### The rule

Before any `spades-anywhere` skill that reads cross-cutting state,
the local checkout MUST be in sync with `origin/main`.

Verify with one command:

```bash
git fetch origin --quiet && git rev-list --count main..origin/main
```

- Returns `0` → fresh, proceed.
- Non-zero → stop. Run `/repo:sync` (from the `repo` plugin) or pull
  manually, then re-invoke the `spades-anywhere` skill.
- Not a git repo → rule satisfied; proceed.

### When the rule applies

To every `spades-anywhere` skill that:

- Reads files outside `.spades-anywhere/` to inform a decision
  (`scope`, `plan`, `approve`, `review`, `research`).
- Reports cross-cutting state (`status`, `list`).

### Subagent prompts

Skills that spawn read-across subagents (`/spades-anywhere:review`'s
panel of four personas, `/spades-anywhere:research`'s researcher)
include the freshness check directly in the subagent's prompt. The
subagent runs the check before reading any files and halts if local
is behind — surfaces the staleness to the operator rather than
producing findings against a stale snapshot.

The canonical definition lives in `docs/FRAMEWORK.md § Freshness`.
This section is the operating-rules-level statement; that section is
the contract.

The sister `spades` plugin enforces the same rule with identical
hard-refusal behaviour. See `plugins/spades/AGENTS.md § Freshness
Before Read-Across` and `plugins/spades/docs/FRAMEWORK.md §
Freshness`.

## Sub-agent Fan-Out

Producing skills (`/spades-anywhere:newproject`,
`/spades-anywhere:objective`, `/spades-anywhere:scope`,
`/spades-anywhere:plan`) and writeback-heavy
consumer skills (`/spades-anywhere:approve`,
`/spades-anywhere:evaluate`) parallelize their Linear + local file
work via sub-agent fan-out: one sub-agent per resource (one file, one
Linear operation), dispatched in a single tool-call wave, with the
coordinator (the skill body) stitching results post-dispatch — e.g.
injecting a captured `linear_issue_id` into a file the file sub-agent
already wrote.

The canonical contract — including the one-sub-agent-per-resource
rule, dispatch modes (`subagent-dispatch` / `sequential-inproc` /
`degraded`), and failure semantics — lives in
`docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`. This is the
operating-rules-level statement; that section is the contract.

## No SCM, No PR Machinery

`spades-anywhere` deliberately has **no `scm:` field**. There is no
two-phase ship, no PR opening, no merge SHA, no CodeRabbit, no
bookkeeping PR in `/close`. Where `spades` has a multi-driver SCM
dispatch (`scm-github.md`, `scm-local-git.md`, the `EXTENDING-SCM.md`
contract), `spades-anywhere` has nothing equivalent — the deliverable
is an artefact reference or an action evidence record, written
directly to the Plan and (when `backend: linear`) mirrored as a
comment.

If your work needs to ship code, use the `spades` plugin, not this
one. The two are explicitly distinct surfaces for distinct work
types.

## Backend

The backend is configured in `.spades-anywhere/config` under
`backend:`. `spades-anywhere` ships two drivers:

- **`backend: linear`** — Project ↔ Linear Project; Scope ↔ parent
  Issue; Plan ↔ sub-issue. Audit records (approval, evaluation,
  shipment) post as comments on the parent issue. The Scope's
  Statement of Intent is mirrored to the Linear parent issue; the
  project's `INTENT.md` is **not** mirrored — Linear is for doing
  work, not for project documentation.
- **`backend: local`** — every artefact lives under
  `.spades-anywhere/`. Audit records append to an `## Audit Trail`
  heading on the scope/plan file.

There is no auto-probe: the human chose the backend explicitly during
`/spades-anywhere:setup`. See `docs/FRAMEWORK.md` § Backend Interface
for the full contract drivers must satisfy.

## Versioning

Every PR to this plugin **must** bump the plugin version. The
component versions (per-skill and AGENTS.md) bump only when that
component's own content changes.

### The principle

The plugin version is the umbrella: **if anything inside the plugin
changes, the plugin version bumps.** A change to a skill, a change to
`AGENTS.md`, a change to `docs/`, a metadata tweak — any of them forces
a plugin bump. The component versions are narrower: each bumps **only**
when its own content changes. A component change always implies a
plugin bump; a plugin bump does not imply any given component changed.

This is what makes consumer updates work: the plugin updater dedups by
version string, so an unchanged plugin version after a real change
means the update is silently skipped and never reaches anyone.

### Three levels of versioning

- **Plugin version** — declared in
  `plugins/spades-anywhere/.claude-plugin/plugin.json`, mirrored in
  `.claude-plugin/marketplace.json` (both the marketplace
  `metadata.version` and the plugin entry's `version`), and pinned
  in `plugins/spades-anywhere/.spades-anywhere/version` as
  `spades_anywhere_version=X.Y.Z`. All four values must match. Bumps
  on **every** merged PR.
- **Skill version** — declared as a `version:` field in each skill's
  frontmatter (`plugins/spades-anywhere/skills/<name>/SKILL.md`).
  Bumps **only** when that skill's body, frontmatter, or behaviour
  changes.
- **AGENTS.md version** — the operating rules are themselves a
  versioned, consumer-facing unit. Pinned in
  `plugins/spades-anywhere/.spades-anywhere/version` as
  `agents_version=X.Y.Z`, and stamped into the consumer-repo marker
  (`<!-- SPADES-ANYWHERE-FRAMEWORK-START vX.Y.Z -->`) by
  `/spades-anywhere:setup`. Bumps **only** when the rules consumers
  carry change. Because the marker tracks the AGENTS.md version (not
  the plugin version), a consumer's block reads as stale only when the
  rules they hold actually moved — not on every unrelated plugin PR.

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
  - Wording change with no behavioural shift
  - Formatting / presentation change to output

When in doubt, **lean toward bumping higher**.

### Per-skill semver follows the same rules

A skill's own `version:` field follows semver independently. The
plugin version is always **at least** the highest of the skill
versions that changed — a breaking change in any one skill forces
the plugin to bump major.

### Where versions live

| Where | What |
|-------|------|
| `plugins/spades-anywhere/.claude-plugin/plugin.json` `"version"` | Plugin |
| `.claude-plugin/marketplace.json` `metadata.version` + plugins[*].`version` for the `spades-anywhere` entry | Plugin (mirror — must match) |
| `plugins/spades-anywhere/.spades-anywhere/version` (`spades_anywhere_version=X.Y.Z`) | Plugin pin |
| `plugins/spades-anywhere/.spades-anywhere/version` (`agents_version=X.Y.Z`) | AGENTS.md pin (canonical) |
| `plugins/spades-anywhere/skills/<name>/SKILL.md` frontmatter `version:` | Per-skill |
| Consumer AGENTS.md marker block (`<!-- SPADES-ANYWHERE-FRAMEWORK-START vX.Y.Z -->`) | AGENTS.md version (consumer-facing) |

### CHANGELOG

Every PR adds an entry to `plugins/spades-anywhere/CHANGELOG.md` at
the top under the new plugin version. Entry shape:

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
5. A do-phase record (Plan moves to `delivering`; AC restated)
6. An evaluation verdict
7. A shipment record (artefact reference or action evidence) plus
   a confirmation walk against `INTENT.md` success criteria

Work that cannot be traced through this chain must not ship. The
audit trail is the mechanism by which AI-assisted human work remains
trustworthy.

## Fast-Track Path (Small Work)

Not every change deserves a Scope. The fast-track path handles
trivial human work — a single errand, a one-line doc tweak, a
single short message — through `/spades-anywhere:quick`. On this
path the **quick-item marker file is the audit artefact**: no
separate Scope or Plan record is created.

**When a human describes a small task, check the fast-track gate
BEFORE invoking `/spades-anywhere:scope`.** If every criterion below
passes, run `/spades-anywhere:quick`. Otherwise fall back to the
full loop.

### The Gate — ALL must be true

1. **Single concrete action.** One errand, one email, one tweak.
2. **≤ 30 minutes of human time.** Soft cap. Hard stop above ~60 min.
3. **One artefact or one recipient.** Not spread across multiple
   documents, multiple people, or multiple systems.
4. **No new external commitment.** No new contracts, no new vendor
   relationships, no new financial obligations over the project's
   stated threshold.
5. **No project-intent shift.** The action does not change what the
   project is *for*.
6. **No coordination across multiple people.** A single message to a
   single person is fine; chairing a four-way thread is not.
7. **No irreversible commitment.** A "test booking" you can cancel
   is fine; a non-refundable payment is not.
8. **No new dependency on external state.** No "waiting for X to
   reply". Quick items are self-contained.
9. **Revertible.** If the action turns out wrong, undoing it is cheap.
10. **No verification against project success criteria.** Quick items
    do not run through `INTENT.md` confirmation — they are too small
    to move project-level criteria.

If *any* criterion fails, stop and invoke `/spades-anywhere:scope`
for the full loop. The gate is all-or-nothing.

### Incident response

Reactive work of any meaningful weight does NOT use the fast-track
path. Ceremony is cheap when something has gone wrong — use the full
loop so the audit trail is complete.

### Evaluating quick-path work

`/spades-anywhere:evaluate` on a quick-path item validates the marker
file directly (action confirmed, evidence captured, gate criteria
satisfied) instead of iterating per-plan tasks. Sub-records are
forbidden on the quick path regardless of verdict.

## Deliberate Non-Goals

Things `spades-anywhere` does NOT do, by design. Each entry records
the decision and why, so a future contributor can tell *"deliberately
omitted"* apart from *"never thought of it"*.

### No cross-Scope dependencies

`depends_on:` links Plans within the same Scope. There is no
`depends_on_scopes:` field on Scopes, and no cross-Scope blocking in
`/status`, `/list`, or `/close`.

**Why:** Scopes should be isolated outcomes managed via an external
roadmap, not via in-framework wiring. The cardinal rule is that a
Scope must be able to ship a change — even one intended for the
future — without breaking or blocking another Scope. If two Scopes
genuinely need each other to ship in order, the Scope boundaries are
wrong: combine them, or accept that the sequencing lives in the
roadmap (a human-readable artefact outside `.spades-anywhere/`), not
in the dependency graph. The same applies to `spades`.

### No `delivery: ai`, ever

Approve in `spades-anywhere` only offers `human` or `hybrid`. The
sister `spades` plugin has `ai` for autonomous code delivery; here
the work is real-world action and only a human can do it. This is
enforced at the schema level (the Approve picker, the worker enum,
and `/spades-anywhere:do`'s defensive abort).

### No SCM, no PR, no merge SHA

There is no `scm:` field, no SCM driver dispatch, no two-phase Ship,
no bookkeeping PR in `/close`. `/ship` writes metadata; `/close`
writes metadata. If your work needs code, use the `spades` plugin.

### `/do` is not a project manager

`/spades-anywhere:do` is a marker + acceptance-criteria restatement.
It does not take an assignee, propose a cadence, schedule check-ins,
remind the human, or chase progress. The human does the work; the
AI runs the loop. This is a deliberate constraint — accepting
project-manager duties would inflate the framework into a workflow
tool, which it is not.

### No `abandoned` status for Quick items

`/spades-anywhere:close --abandon` applies to Scopes and Projects
only. Plans use `rejected` (via `/spades-anywhere:approve` or
`/spades-anywhere:evaluate` FAIL); Quick items have no terminal
walk-away status at all.

**Why:** Quick items are intentionally the lightweight path — the
whole point is to skip ceremony. If you start a quick item and bail,
just delete the marker file at
`.spades-anywhere/quick/Q-<id>.md`. A deleted file is a sufficient
signal; if you want a trace, the git history (when applicable)
records the delete. The same applies to `spades/quick/Q-<id>.md`.

## What You Must Never Do

- Begin work without a documented Scope (or a valid fast-track gate
  pass)
- Begin Do without an approved Plan (on the full loop)
- Begin any producing work (Scope, Plan, Approve, Do, Evaluate,
  Ship, or Close-Pass) on a child of an `abandoned` Scope or an
  `abandoned`/`archived` Project. Producing skills refuse hard at
  the gate — see `docs/FRAMEWORK.md § Target Resolution →
  Parent-status precondition`. The deliberate no-cascade design
  (abandoning a Scope does not auto-reject its Plans) is paired
  with this hard refusal; without it, work would silently land on
  a dead initiative.
- Mark work shipped without verifying the deliverable is real
  (artefact reachable, action evidenced) AND walking the INTENT
  success criteria
- Skip the Plan documentation step — Plans are first-class artefacts
- Misuse `/spades-anywhere:quick` for work that fails any gate
  criterion
- Create sub-records on the fast-track path
- Take on assignee, cadence, or check-in duties in `/do`
- Attempt AI-autonomous delivery of real-world action
- Introduce ways of working that conflict with `ARCHITECTURE.md` or
  `ANTI-PATTERNS.md` without flagging the conflict and getting
  explicit approval
- Assume organisational context you do not have (ask the human)
- Combine multiple Scopes into one delivery without human agreement
- Write a `CLAUDE.md` (or any other per-vendor agent file) —
  AGENTS.md is the only file `spades-anywhere` maintains in consumer
  projects

<!--
  Framework-repo note: this file is the canonical spades-anywhere
  agent operating rules. Consumer projects carry a compressed,
  marker-wrapped subset of the rules above, delimited by
  `SPADES-ANYWHERE-FRAMEWORK-START vX.Y.Z` and
  `SPADES-ANYWHERE-FRAMEWORK-END` markers, scaffolded by
  `/spades-anywhere:setup`. We deliberately do NOT carry that block
  here — this repo is the source of truth.
-->
