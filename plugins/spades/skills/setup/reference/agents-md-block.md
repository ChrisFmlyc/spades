# AGENTS.md marker-block content

The consumer-facing operating rules `/spades:setup` Step 12 writes
between the `SPADES-FRAMEWORK-START` / `SPADES-FRAMEWORK-END`
markers in a consumer repo's `AGENTS.md`.

This is a template, written verbatim. Copy everything inside the
fenced block below into the markers, stamping the marker line with
`agents_version` from `.spades/version`. Content outside the markers
is untouched.

The block is a compressed subset of the framework's canonical rules,
versioned by `agents_version`: any change inside the fence bumps
that version, because consumer repos carry this content and the
marker tells them when their copy went stale.

## Contents

- Operating Principles — the four agile pillars and their skill map
- SPADES Skills — the 22-skill table
- The SPADES Loop — six phases, ownership, the fast-track exception
- Phase Rules — per-phase contracts for Scope through Ship
- Fast-Track Path — the 10-criterion gate
- Artefacts Carry Forward
- Architecture Constraints
- Freshness Before Read-Across
- Defer to the `repo` and `codereview` Plugins
- Versioning
- Audit Trail

---

```markdown

# SPADES Framework — Agent Operating Rules

These rules define mandatory behaviour for AI agents using the SPADES
framework in this project. They augment any existing agent instructions
in this file and apply to **every** agent that reads this file —
Claude Code, Cursor, Codex, Aider, or anything else that honours
`AGENTS.md`.

## Operating Principles — Agile, four pillars

SPADES is an agile-by-design operating model. The whole loop, every
skill, and every gate ladder back to four pillars. Hold these as the
"why" behind any individual rule below.

1. **Collaborate.** Humans and AI work in close-loop conversation.
   Scope, Plan, and Approve are explicit collaboration gates — the
   AI proposes structure; the human owns intent and acceptance.
   `/spades:review` exists to broaden collaboration with multiple
   perspectives (four reviewer personas) on demand.
2. **Deliver.** Working output beats documentation about output.
   Deliver and Ship close the loop with something real — code merged,
   an artefact recorded, an action evidenced. Quick-path
   (`/spades:quick`) exists so small work can deliver without
   ceremony.
3. **Reflect.** Evaluate is a real gate, not a rubber stamp.
   PASS / PARTIAL / FAIL is captured with reasoning. Every Plan
   produces an evaluation record the human can revisit. The next
   pass starts with reflection on the last one.
4. **Improve.** Learnings (`/spades:learn`) and Leads
   (`/spades:leads`) are first-class. INTENT, ARCHITECTURE,
   PATTERNS, ANTI-PATTERNS all carry a `last_reviewed` field and
   get refreshed when reality drifts. Drift between docs and code
   is a signal to act.

Skill mapping:

| Pillar | Where it lives |
|--------|----------------|
| Collaborate | Scope, Plan, Approve, Review |
| Deliver | Deliver, Ship, Close, Quick, Loop |
| Reflect | Evaluate, Status, List |
| Improve | Learn, Leads, Intent / Architecture / Patterns / Anti-Patterns refresh |

## SPADES Skills

The SPADES plugin (`spades`) provides these 22 skills:

| Skill | What it does |
|-------|-------------|
| `/spades:setup` | Configure backend + scaffold this repo (re-runnable) |
| `/spades:newproject` | Create a new project record |
| `/spades:objective` | Create or edit an Objective (`O-<slug>`) — a strategic action associated with a project; independent of Scopes |
| `/spades:scope` | Create or edit a Scope (`S-<description-slug>`) |
| `/spades:plan` | Generate a Plan (`P-<slug>-<suffix>[-<dep>…]`) under a Scope |
| `/spades:approve` | Present a Plan for human review and record routing |
| `/spades:deliver` | Execute an approved Plan (routed AI / human / hybrid) |
| `/spades:evaluate` | Check delivered output against the Scope's acceptance criteria |
| `/spades:ship` | Open the PR (code) or record the deliverable (artefact / action) |
| `/spades:close` | Conversational close-out: pass / reject / abandon based on target. Pass finalises (Plan → shipped, Scope → done, Project → archived, Objective → complete); reject (Plans) and abandon (Scopes, Projects, Objectives) require a reason. Lands via a bookkeeping PR. |
| `/spades:loop` | Drive one Scope from Plan to closed-out — plan → approve → deliver → evaluate → **human sign-off** → ship → bot review → merge → close. Slash-only; never writes a Scope. |
| `/spades:quick` | Fast-track for trivial work — quick-item marker file (`.spades/quick/Q-<id>.md`) is the canonical audit record |
| `/spades:review` | Multi-persona panel second opinion (4 subagents) on Scope/Plan |
| `/spades:learn` | Capture a learning under `.spades/learnings/` |
| `/spades:leads` | Raise an out-of-scope discovery as a Lead mid-task without derailing the work; `--list`, `--show`, `--promote`, `--close` manage them |
| `/spades:research` | Read-only research via an isolated researcher subagent |
| `/spades:list` | List active scopes, filterable by phase |
| `/spades:status` | Show current SPADES phase + dependency graph |
| `/spades:intent` | Maintain `INTENT.md` — the durable project statement (why) |
| `/spades:architecture` | Maintain `ARCHITECTURE.md` — how the system is built |
| `/spades:patterns` | Maintain `PATTERNS.md` — approved conventions |
| `/spades:anti-patterns` | Maintain `ANTI-PATTERNS.md` — explicit prohibitions |

## The SPADES Loop

Every unit of work follows six phases:

    SCOPE → PLAN → APPROVE → DELIVER → EVALUATE → SHIP

- Humans own Scope, the Approve gate, and the Evaluate gate.
- AI owns Plan, Deliver (when routed AI), and Ship (when the deliverable
  is code).
- Approve records a routing decision (`ai` / `human` / `hybrid`) that
  determines who executes Deliver.

Every phase runs, in order, unless the human explicitly instructs
otherwise.

**Exception — the fast-track path.** Trivial work can use
`/spades:quick` instead of the full loop. See "Fast-Track Path" below.

**Running the phases.** Drive them one command at a time, or run
`/spades:loop` after the Scope exists to walk Plan → Ship → close-out
in one invocation. The loop executes the same gates: it pauses for
the human to sign off an evaluation that needed a human to verify
part of it, and pauses again on a failed approval check, a human
review comment, or a red CI check.

## Phase Rules

### 1. Scope (Human-owned)
- Planning and coding begin from a signed-off Scope.
- A Scope must include: intent, acceptance criteria, constraints,
  dependencies, context, out-of-scope, risk, delivery preference,
  priority.
- Scopes have IDs of the form `S-<description-slug>`.

### 2. Plan (AI-owned, human reviews)
- Produce one or more structured Plans for a Scope before writing code.
- Each Plan has an ID of the form
  `P-<description-slug>-<4-char-suffix>[-<dep-suffix>...]`.
- Plans declare dependencies on prior Plans via `depends_on:`.
- Each task in a Plan declares an execution posture (`specify-first`,
  `discover-first`, `iterate`, `spike`, `straight-through`).
- Deliver-phase work begins once the Plan is approved.

### 3. Approve (Human gate)
- After producing a Plan, STOP and wait for human approval.
- Approval records a `delivery:` routing on the Plan (`ai`, `human`,
  `hybrid`); the Plan already carries its `deliverable_type:`
  (`code`, `artefact`, `action`).
- A revised or rejected Plan does not enter delivery.

### 4. Deliver (AI or Human — routed)
- Execute the approved Plan. Routing comes from the Plan's `delivery:`
  field set at Approve time.
- First delivery creates the Scope's intended delivery branch and worktree
  through `/repo:newbranch`, separate from the documentation session.
- For `ai`: run in the Scope's delivery branch and worktree, committing approved
  changes as you go. All Plans share that branch.
- For `human`: record the assignment in the backend and stand down.
- For `hybrid`: split per the Plan's task-level routing.
- Run tests and verify before moving the Plan to Evaluate.

### 5. Evaluate (Human-owned, AI assists)
- Check delivered output against the Scope's acceptance criteria.
- Verdict is PASS / PARTIAL / FAIL.
- AI may assist but a human signs off the verdict.

### 6. Ship (Mixed)
- For `deliverable_type: code` — routed by the `scm:` field in
  `.spades/config`:
  - **`scm: github`** — `/spades:ship` pushes the Deliver branch and
    opens the PR; review feedback lands on the same branch; after the
    squash-merge, `/spades:close P-<id>` verifies the merge, records
    the `Shipped` markers on main via a bookkeeping PR for the Scope,
    and retains the worktrees. New work starts through `/repo:newbranch`.
  - **`scm: local-git`** — single-phase: push to the configured
    remote (if any), record the commit SHA, mark `shipped`.
- For `deliverable_type: artefact` — record the artefact reference.
- For `deliverable_type: action` — record evidence of completion.
- Ship is the moment the deliverable becomes real to the outside world.

## Fast-Track Path (Small Work)

Not every change deserves a Scope. Trivial work — typos, one-line
tweaks, small config nudges, docs changes — uses `/spades:quick`. On
this path the quick-item marker file is the audit artefact; no
separate Scope or Plan is created.

### The gate — ALL must be true

1. Single concern
2. ≤ 50 lines of code changed total
3. One file or a tight cluster in one module
4. No new dependencies
5. No schema or data-layer changes
6. No architectural changes
7. No security-sensitive code
8. No public API or interface breaking changes
9. Revertible as one commit
10. Existing tests cover the area

If any criterion fails, use the full loop.

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

## Architecture Constraints

Before generating any Plan, read these files if they exist:
- `ARCHITECTURE.md` — system architecture and constraints
- `PATTERNS.md` — approved patterns and conventions
- `ANTI-PATTERNS.md` — things this project deliberately avoids

Flag any conflicts between proposed solutions and these documents.

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

## Defer to the `repo` and `codereview` Plugins

SPADES does not own git-level operations or review-bot triage. The
`repo` and `codereview` plugins (from the `ai-skills` marketplace) do.
Use the appropriate slash command rather than re-implementing the
logic inside a SPADES skill.

| When you need to… | Use |
|-------------------|-----|
| Initialise a new git repo | `/repo:init` — `git init`, placeholder README, wires origin, pushes to main. |
| Start new work on a branch and worktree | `/repo:newbranch` — owns naming, clean/current default-branch preparation and worktree creation. |
| Explicitly request post-merge cleanup | `/repo:sync` — separate from starting or completing work. |
| Refuse to commit on `main` / `master` | `/repo:branch` enforces this absolutely — no overrides. |
| Drive a PR to zero review-bot findings | `/codereview:loop` — waits for each review, hands findings to `/codereview:fix`, pushes, re-checks. |
| Fix a block of review findings, one or many | `/codereview:fix` — one subagent per finding. Never pushes. |

Deliver, Quick and Close call `/repo:newbranch`; established delivery
resumes the Scope worktree. Documentation reuses a working branch. The commit guardrail remains `/repo:branch`.
The dependency is one-directional: SPADES → `repo` / `codereview`.

**If you don't have a git repo yet**, `/spades:setup` runs
`/repo:init` for you automatically as its first prerequisite —
setup is the single entry point and drives `/repo:init` inline (a
one-directional `setup → repo:init` edge). SPADES expects an
initialised repo — it scaffolds files (`AGENTS.md`,
`ARCHITECTURE.md`, `.spades/config`) under git's expectation that
they will be committed — so setup guarantees the repo exists before
it scaffolds. See `docs/FRAMEWORK.md § Bootstrap Order`.

## Versioning

Every PR to the SPADES plugin must bump the plugin version. Per-skill
versions in the plugin's own SKILL.md frontmatter bump only when that
skill's body changes, and the **AGENTS.md version** bumps only when the
operating rules change. The marker block above (`vX.Y.Z`) carries the
AGENTS.md version — it tells you which version of the rules your
AGENTS.md was last stamped against, and only reads as stale when those
rules actually changed (not on every unrelated plugin upgrade).
Re-running `/spades:setup` re-stamps it.

Choose major / minor / patch by semver. When in doubt, lean higher.

## Audit Trail

Every piece of work must trace through: project → scope → plan(s) →
approval (with routing) → delivery-phase record → evaluation verdict →
shipment record. Work that cannot be traced through this chain must
not ship.
```
