# AGENTS.md marker-block content

The consumer-facing operating rules `/spades-anywhere:setup` Step 11
writes between the `SPADES-ANYWHERE-FRAMEWORK-START` /
`SPADES-ANYWHERE-FRAMEWORK-END` markers in a consumer knowledge
store's `AGENTS.md`.

This is a template, written verbatim. Copy everything inside the
fenced block below into the markers, stamping the marker line with
`agents_version` from `.spades-anywhere/version`. Content outside
the markers is untouched.

The block is versioned by `agents_version`: any change inside the
fence bumps that version, because consumer stores carry this
content and the marker tells them when their copy went stale.

## Contents

- Operating Principles — the four agile pillars and their skill map
- spades-anywhere Skills — the skill table
- The Loop — six phases and ownership
- Phase Rules — per-phase contracts
- Freshness Before Read-Across
- Versioning
- Audit Trail

---

```markdown

# spades-anywhere — Agent Operating Rules

These rules define mandatory behaviour for AI agents using the
`spades-anywhere` framework in this project. They apply to every
agent that reads this file — Claude Desktop, ChatGPT, the Claude
web app, mobile clients, or anything else that honours `AGENTS.md`.

`spades-anywhere` is the sister plugin to `spades` (which targets
code work in coding harnesses). The two share a framework but
target different runtimes and different kinds of work — see
[`README.md`](README.md) for what `spades-anywhere` is for.

## Operating Principles — Agile, four pillars

`spades-anywhere` is an agile-by-design operating model for
non-coding work. The whole loop, every skill, and every gate
ladder back to four pillars.

1. **Collaborate.** Humans and AI work in close-loop
   conversation. Scope, Plan, Approve, and Review are explicit
   collaboration gates.
2. **Deliver.** Working output beats documentation about output.
   Do and Ship close the loop with something real — an artefact
   produced, an action evidenced.
3. **Reflect.** Evaluate is a real human gate. The do →
   evaluate loop runs until PASS, and verdicts are captured
   with reasoning.
4. **Improve.** Learnings (`/spades-anywhere:learn`) are
   first-class. INTENT, ARCHITECTURE, PATTERNS, ANTI-PATTERNS
   all carry a `last_reviewed` field and get refreshed when
   reality drifts.

| Pillar | Where it lives |
|--------|----------------|
| Collaborate | Scope, Plan, Approve, Review |
| Deliver | Do, Ship, Close, Quick |
| Reflect | Evaluate, Status, List |
| Improve | Learn, Intent / Architecture / Patterns / Anti-Patterns refresh |

## spades-anywhere Skills

| Skill | What it does |
|-------|-------------|
| `/spades-anywhere:setup` | Configure backend + scaffold this project (re-runnable) |
| `/spades-anywhere:newproject` | Create a new project record |
| `/spades-anywhere:objective` | Create or edit an Objective (`O-<slug>`) — a strategic action associated with a project; independent of Scopes |
| `/spades-anywhere:intent` | Maintain `INTENT.md` — why the project exists |
| `/spades-anywhere:architecture` | Maintain `ARCHITECTURE.md` — how the work is structured (stages, stakeholders, cadence, tools, constraints) |
| `/spades-anywhere:patterns` | Maintain `PATTERNS.md` — approved process conventions |
| `/spades-anywhere:anti-patterns` | Maintain `ANTI-PATTERNS.md` — explicit "we don't do X" rules |
| `/spades-anywhere:scope` | Create or edit a Scope (`S-<description-slug>`) |
| `/spades-anywhere:plan` | Generate a Plan (`P-<slug>-<suffix>[-<dep>…]`) under a Scope |
| `/spades-anywhere:approve` | Present a Plan for human review and record routing (`human` / `hybrid`) |
| `/spades-anywhere:do` | Mark a Plan delivering + restate the Scope's acceptance criteria back to you |
| `/spades-anywhere:evaluate` | Human verdict against the Scope's acceptance criteria — PASS / PARTIAL / FAIL |
| `/spades-anywhere:ship` | Capture shipment evidence + confirmation walk through `INTENT.md` success criteria; Plan → `shipping` |
| `/spades-anywhere:close` | Conversational close-out: pass / reject / abandon based on target. Pass finalises (Plan → shipped, Scope → done, Project → archived, Objective → complete); reject (Plans) and abandon (Scopes, Projects, Objectives) require a reason. Pure metadata — no SCM, no PR. |
| `/spades-anywhere:quick` | Fast-track for trivial human work — quick-item marker file (`.spades-anywhere/quick/Q-<id>.md`) is the canonical audit record |
| `/spades-anywhere:review` | Multi-persona panel second opinion (4 subagents) on Scope/Plan |
| `/spades-anywhere:learn` | Capture a learning under `.spades-anywhere/learnings/` |
| `/spades-anywhere:research` | Read-only research via an isolated researcher subagent |
| `/spades-anywhere:list` | List active scopes, filterable by phase |
| `/spades-anywhere:status` | Show current phase + dependency graph |

`/close` and `/quick` mirror the **process** of their `spades`
siblings with different **mechanics**: `/close` is pure metadata
finalisation (no bookkeeping PR); `/quick`'s gate is time- and
action-based (≤30 min, single concrete action, no project-intent
shift) because the work it covers is human, not code.

## The Loop

Every unit of work follows six phases:

    SCOPE → PLAN → APPROVE → DO → EVALUATE → SHIP

- Humans own Scope, the Approve gate, Do (the actual work), the
  Evaluate gate, and Ship (the confirmation walk).
- AI owns Plan, and assists with Do under `delivery: hybrid`.
- Approve records a routing decision (`human` / `hybrid`) that
  determines whether AI helps during Do. The routing set is
  `human` and `hybrid`; the human performs every real-world act.

Every phase runs, in order, unless the human explicitly instructs
otherwise. A PARTIAL or FAIL at Evaluate routes back to
`/spades-anywhere:do`, and the do → evaluate loop runs until PASS.

## Phase Rules

### 1. Scope (Human-owned)
- Planning begins from a signed-off Scope.
- A Scope must include: statement of intent, acceptance criteria,
  constraints (budget / schedule / tools / stakeholders),
  dependencies, context, out-of-scope, risk, delivery preference.
- Scopes have IDs of the form `S-<description-slug>`.

### 2. Plan (AI-owned, human reviews)
- Produce one or more structured Plans for a Scope before
  starting work.
- Each Plan has an ID of the form
  `P-<description-slug>-<4-char-suffix>[-<dep-suffix>...]`.
- Plans declare dependencies on prior Plans via `depends_on:`.
- Each task in a Plan declares an execution posture (`specify-first`,
  `discover-first`, `iterate`, `spike`, `straight-through`).
- Do-phase work begins once the Plan is approved.

### 3. Approve (Human gate)
- After producing a Plan, STOP and wait for human approval.
- Approval records a `delivery:` routing on the Plan
  (`human` or `hybrid`); the Plan already carries its
  `deliverable_type:` (`artefact` or `action`).
- A revised or rejected Plan does not enter delivery.

### 4. Do (Human acts; AI marks the start)
- `/spades-anywhere:do` is a **marker**. The AI updates the Plan's
  status, restates the Scope's acceptance criteria so the human
  knows what "done" looks like, and stands down. The human does
  the actual work.
- For `delivery: hybrid` plans, AI offers to help with tasks
  marked `Routing: ai` — drafts, research, structuring — and the
  human applies the result and takes the action.
- The skill carries no assignee, cadence, or check-in duties;
  `spades-anywhere` runs the loop, the human runs the work.

### 5. Evaluate (Human verdict)
- Walk the Scope's acceptance criteria, mark each met / partial /
  not met, aggregate to PASS / PARTIAL / FAIL.
- The human's word is the verdict.
- Anything below PASS routes back to `/spades-anywhere:do`.

### 6. Ship (Confirmation walk against INTENT)
- Walk the project's `INTENT.md` success criteria one at a time,
  capturing evidence per criterion (URL / file / photo / note).
- For `deliverable_type: artefact` — record a primary reference
  alongside the per-criterion evidence.
- For `deliverable_type: action` — record evidence of the action
  (photos, receipts, signed docs, witness notes).
- The Plan reaches `shipping`; `/spades-anywhere:close` flips it to
  `shipped` and rolls the Scope up to `done` when every Plan under
  it is terminal.

## Freshness Before Read-Across

`spades-anywhere` runs in contexts where there is often no git
repo at all. The freshness principle — read against the latest
source of truth — applies with a mechanism that depends on the
setup:

- **Linear backend** — Linear is canonical; sub-agents see current
  state. No probe.
- **Local backend without git** — the `.spades-anywhere/` files on
  disk are the source of truth. No remote to compare against.
- **Local backend inside a git repo** — run `git fetch &&
  git rev-list --count main..origin/main`; if non-zero, sync
  first.

`spades-anywhere` requires no `repo` plugin; sync is the
consumer's responsibility by any mechanism they prefer. The full
contract lives in `docs/FRAMEWORK.md § Freshness`.

## Versioning

Every PR to the plugin must bump the plugin version. Per-skill
versions in the plugin's own SKILL.md frontmatter bump only when
that skill's body changes, and the **AGENTS.md version** bumps only
when the operating rules change. The marker block above (`vX.Y.Z`)
carries the AGENTS.md version — it tells you which version of the
rules your AGENTS.md was last stamped against, and only reads as
stale when those rules actually changed. Re-running
`/spades-anywhere:setup` re-stamps it.

Choose major / minor / patch by semver. When in doubt, lean
higher.

## Audit Trail

Every piece of work must trace through: project → scope → plan(s)
→ approval (with routing) → do-phase marker → evaluation verdict
→ shipment record (with per-INTENT-criterion evidence) → close.
Work that cannot be traced through this chain must not ship.
```
