# AGENTS.md marker-block content

The consumer-facing operating rules `/spades:setup` Step 6 writes
between the `SPADES-FRAMEWORK-START` / `SPADES-FRAMEWORK-END`
markers in a consumer repo's `AGENTS.md`.

This is a **template, written verbatim** — not instructions for you
to act on. Copy everything inside the fenced block below into the
markers, stamping the marker line with `agents_version` from
`.spades/version`. Never edit content outside the markers.

This block is a compressed subset of the framework's canonical
rules. It is versioned by `agents_version`: change anything inside
the fence and that version must bump, because consumer repos carry
this content and the marker tells them when their copy went stale.

## Contents

- Operating Principles — the four agile pillars and their skill map
- SPADES Skills — the 21-skill table
- The SPADES Loop — six phases, ownership, the fast-track exception
- Phase Rules — per-phase contracts for Scope through Ship
- Fast-Track Path — the 10-criterion gate
- Architecture Constraints
- Freshness Before Read-Across
- Defer to the `repo` Plugin for Git Operations
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
   Do and Ship close the loop with something real — code merged,
   an artefact recorded, an action evidenced. Quick-path
   (`/spades:quick`) exists so small work can deliver without
   ceremony.
3. **Reflect.** Evaluate is a real gate, not a rubber stamp.
   PASS / PARTIAL / FAIL is captured with reasoning. Every Plan
   produces an evaluation HTML the human can revisit. The next
   pass starts with reflection on the last one.
4. **Improve.** Learnings (`/spades:learn`) are first-class. INTENT,
   ARCHITECTURE, PATTERNS, ANTI-PATTERNS all carry a
   `last_reviewed` field and get refreshed when reality drifts.
   Drift between docs and code is a signal to act, not paper
   over.

Skill mapping:

| Pillar | Where it lives |
|--------|----------------|
| Collaborate | Scope, Plan, Approve, Review |
| Deliver | Do, Ship, Quick, Loop |
| Reflect | Evaluate, Status |
| Improve | Learn, Intent / Architecture / Patterns / Anti-Patterns refresh |

## SPADES Skills

The SPADES plugin (`spades`) provides these 21 skills:

| Skill | What it does |
|-------|-------------|
| `/spades:setup` | Configure backend + scaffold this repo (re-runnable) |
| `/spades:newproject` | Create a new project record |
| `/spades:objective` | Create or edit an Objective (`O-<slug>`) — a strategic action associated with a project; independent of Scopes |
| `/spades:scope` | Create or edit a Scope (`S-<description-slug>`) |
| `/spades:plan` | Generate a Plan (`P-<slug>-<suffix>[-<dep>…]`) under a Scope |
| `/spades:approve` | Present a Plan for human review and record routing |
| `/spades:do` | Execute an approved Plan (routed AI / human / hybrid) |
| `/spades:evaluate` | Check delivered output against the Plan |
| `/spades:ship` | Open PR + review + merge (code) or record deliverable (artefact / action) |
| `/spades:close` | Conversational close-out: pass / reject / abandon based on target. Pass finalises (Plan → shipped, Scope → done, Project → archived); reject (Plans) and abandon (Scopes, Projects) require a reason. Opens a bookkeeping PR; run `/repo:sync` first. |
| `/spades:loop` | Drive one Scope from Plan to closed-out unattended — plan → approve → do → evaluate → **human sign-off** → ship → bot review → merge → sync → close. Slash-only; never writes a Scope. |
| `/spades:quick` | Fast-track for trivial work — quick-item marker file (`.spades/quick/Q-<id>.md`) is the canonical audit record |
| `/spades:review` | Multi-persona panel second opinion (4 subagents) on Scope/Plan |
| `/spades:learn` | Capture a learning under `.spades/learnings/` |
| `/spades:research` | Read-only research via an isolated Opus subagent |
| `/spades:list` | List active scopes, filterable by phase |
| `/spades:status` | Show current SPADES phase + dependency graph |
| `/spades:intent` | Maintain `INTENT.md` — the durable project statement (why) |
| `/spades:architecture` | Maintain `ARCHITECTURE.md` — how the system is built |
| `/spades:patterns` | Maintain `PATTERNS.md` — approved conventions |
| `/spades:anti-patterns` | Maintain `ANTI-PATTERNS.md` — explicit prohibitions |

## The SPADES Loop

Every unit of work follows six phases:

    SCOPE → PLAN → APPROVE → DO → EVALUATE → SHIP

- Humans own Scope, Approve gate, and Evaluate gate.
- AI owns Plan, Do (when routed AI-auto), and Ship (when the deliverable
  is code).
- Approve records a routing decision (`ai` / `human` / `hybrid`) that
  determines who executes Do.

Never skip a phase or combine phases without explicit human
instruction.

**Exception — the fast-track path.** Trivial work can use
`/spades:quick` instead of the full loop. See "Fast-Track Path" below.

**Running the phases.** Drive them one command at a time, or run
`/spades:loop` after the Scope exists to walk Plan → Ship → close-out
in one invocation. The loop executes the same gates rather than
skipping them: it pauses for the human to sign off the Evaluate
verdict, and pauses again on any failed approval check, sensitive-area
Plan, human review comment, or red CI check.

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
- Each task in a Plan declares an execution posture (`specify-first`,
  `discover-first`, `iterate`, `spike`, `straight-through`).
- Do NOT begin Do-phase work until the Plan is approved.

### 3. Approve (Human gate)
- After producing a Plan, STOP and wait for human approval.
- Approval records a `delivery:` routing on the Plan (`ai`, `human`,
  `hybrid`) and a `deliverable_type:` (`code`, `artefact`, `action`).
- If revised or rejected, do not begin delivery.

### 4. Do (AI or Human — routed)
- Execute the approved Plan. Routing comes from the Plan's `delivery:`
  field set at Approve time.
- For `ai`: run the work autonomously, committing as you go.
- For `human`: record the assignment in the backend; do not auto-do.
- For `hybrid`: split per the Plan's task-level routing.
- Run tests and verify before moving the Plan to Evaluate.

### 5. Evaluate (Human-owned, AI assists)
- Check delivered output against the Plan's acceptance criteria.
- Verdict is PASS / PARTIAL / FAIL.
- AI may assist but a human signs off the verdict.

### 6. Ship (Mixed)
- For `deliverable_type: code` — routed by the `scm:` field in
  `.spades/config`:
  - **`scm: github`** — two-phase: Phase 1 pushes the Do branch and
    opens the PR; address CodeRabbit feedback on the same branch;
    after squash-merge, run `/repo:sync`, then re-invoke
    `/spades:ship` to record the merge SHA and mark `shipped`.
  - **`scm: local-git`** — single-phase: push to the configured
    remote (if any), record commit SHA, mark `shipped`. No PR loop.
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
9. Revertible as one commit
10. Existing tests cover the area

If any criterion fails, fall back to the full loop.

## Architecture Constraints

Before generating any Plan, read these files if they exist:
- `ARCHITECTURE.md` — system architecture and constraints
- `PATTERNS.md` — approved patterns and conventions
- `ANTI-PATTERNS.md` — things you must not do

Flag any conflicts between proposed solutions and these documents.

## Freshness Before Read-Across

SPADES skills read files from the local filesystem, not from
`origin`. A stale local `main` produces stale findings — audits flag
issues already shipped, plans reference removed code, do-phase work
branches off the wrong base.

**The rule:** before any SPADES skill that reads cross-cutting state
or branches off `main`, verify the local checkout is in sync with
`origin/main`:

```bash
git fetch origin --quiet && git rev-list --count main..origin/main
```

Returns `0` → proceed. Non-zero → run `/repo:sync` first, then
re-invoke the SPADES skill.

**The behavioural reflex:** after any PR merge on this repo (yours
or someone else's), run `/repo:sync` immediately, before
context-switching to a new SPADES skill.

**Subagent prompts:** skills that spawn read-across subagents
(`/spades:review`, `/spades:research`) include the freshness check
in the subagent's own prompt — the subagent halts on stale-main
rather than producing findings against a stale snapshot.

The full contract lives in `docs/FRAMEWORK.md § Freshness`.

## Defer to the `repo` and `crx` Plugins

SPADES does not own git-level operations or CodeRabbit triage. The
`repo` and `crx` plugins (from the `ai-skills` marketplace) do. Use
the appropriate slash command — never reinvent the equivalent logic
inside a SPADES skill.

| When you need to… | Use |
|-------------------|-----|
| Initialise a new git repo | `/repo:init` — `git init`, placeholder README, wires origin, pushes to main. |
| Create a new branch off main | `/repo:branch` (validates the name) plus `git switch -c <name>` to create in place, or `/repo:newbranch` for create-with-worktree. |
| Sync local main after a PR merge | `/repo:sync` — fetches, ff-pulls main, force-deletes the merged feature branch. |
| Refuse to commit on `main` / `master` | `/repo:branch` enforces this absolutely — no overrides. |
| Drive a PR to zero CodeRabbit findings | `/crx:loop` — waits for the review, fixes or rebuts each finding, pushes, re-checks. |
| Fix one pasted CodeRabbit finding | `/crx:single`; a pasted batch → `/crx:multi` |

SPADES skills that branch off main (`/spades:do`, `/spades:close`)
go through `/repo:branch`'s regex validation. SPADES skills that
need to verify post-merge state (`/spades:close`, `/spades:loop`)
invoke `/repo:sync` directly. The dependency is **one-directional**:
SPADES → `repo` / `crx`, never the reverse.

**If you don't have a git repo yet**, `/spades:setup` runs
`/repo:init` for you automatically as its first prerequisite — you
don't run it by hand or re-invoke setup afterwards. Setup is the
single entry point and drives `/repo:init` inline (a one-directional
`setup → repo:init` edge). SPADES expects an initialised repo — it
scaffolds files (`AGENTS.md`, `ARCHITECTURE.md`, `.spades/config`)
under git's expectation that they will be committed — so setup
guarantees the repo exists before it scaffolds. See
`docs/FRAMEWORK.md § Bootstrap Order`.

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
approval (with routing) → do-phase record → evaluation verdict →
shipment record. Work that cannot be traced through this chain must
not ship.
```
