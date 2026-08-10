# AGENTS.md marker-block content

The consumer-facing operating rules `/spades-anywhere:setup` Step 6
writes between the `SPADES-ANYWHERE-FRAMEWORK-START` /
`SPADES-ANYWHERE-FRAMEWORK-END` markers in a consumer knowledge
store's `AGENTS.md`.

This is a **template, written verbatim** — not instructions for you
to act on. Copy everything inside the fenced block below into the
markers, stamping the marker line with `agents_version` from
`.spades-anywhere/version`. Never edit content outside the markers.

This block is a compressed subset of the framework's canonical
rules. It is versioned by `agents_version`: change anything inside
the fence and that version must bump, because consumer stores carry
this content and the marker tells them when their copy went stale.

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
| Deliver | Do, Ship |
| Reflect | Evaluate, Status |
| Improve | Learn, Intent / Architecture / Patterns / Anti-Patterns refresh |

## spades-anywhere Skills (v0.5)

| Skill | What it does |
|-------|-------------|
| `/spades-anywhere:setup` | Configure backend + scaffold this project (re-runnable) |
| `/spades-anywhere:newproject` | Create a new project record |
| `/spades-anywhere:intent` | Maintain `INTENT.md` — why the project exists |
| `/spades-anywhere:architecture` | Maintain `ARCHITECTURE.md` — how the work is structured (stages, stakeholders, cadence, tools, constraints) |
| `/spades-anywhere:patterns` | Maintain `PATTERNS.md` — approved process conventions |
| `/spades-anywhere:anti-patterns` | Maintain `ANTI-PATTERNS.md` — explicit "we don't do X" rules |
| `/spades-anywhere:scope` | Create or edit a Scope (`S-<description-slug>`) |
| `/spades-anywhere:plan` | Generate a Plan (`P-<slug>-<suffix>[-<dep>…]`) under a Scope |
| `/spades-anywhere:approve` | Present a Plan for human review and record routing |
| `/spades-anywhere:do` | Mark a Plan delivering + restate the Scope's acceptance criteria back to you |
| `/spades-anywhere:evaluate` | Human verdict against the Scope's acceptance criteria — PASS / PARTIAL / FAIL |
| `/spades-anywhere:ship` | Capture shipment evidence + confirmation walk through `INTENT.md` success criteria; Plan → `shipping` |
| `/spades-anywhere:close` | Conversational close-out: pass / reject / abandon based on target. Pass finalises (Plan → shipped, Scope → done, Project → archived); reject (Plans) and abandon (Scopes, Projects) require a reason. Pure metadata — no SCM, no PR. |
| `/spades-anywhere:quick` | Fast-track for trivial human work — quick-item marker file (`.spades-anywhere/quick/Q-<id>.md`) is the canonical audit record |
| `/spades-anywhere:review` | Multi-persona panel second opinion (4 subagents) on Scope/Plan |
| `/spades-anywhere:learn` | Capture a learning under `.spades-anywhere/learnings/` |
| `/spades-anywhere:research` | Read-only research via an isolated Opus subagent |
| `/spades-anywhere:list` | List active scopes, filterable by phase |
| `/spades-anywhere:status` | Show current phase + dependency graph |

**Note:** the spades-anywhere `/close` and `/quick` skills mirror
the **process** of their `spades` siblings, but the **mechanics**
differ. `/close` has no bookkeeping PR (no SCM); it's pure metadata
finalisation. `/quick`'s gate is time- and action-based (≤30 min,
single concrete action, no project-intent shift) rather than
LoC-based, because the work it covers is human, not code.

## The Loop

Every unit of work follows six phases:

    SCOPE → PLAN → APPROVE → DO → EVALUATE → SHIP

- Humans own Scope, Approve gate, Do (the actual work), Evaluate
  gate, and Ship (the confirmation walk).
- AI owns Plan, and assists with Do under `delivery: hybrid`.
- Approve records a routing decision (`human` / `hybrid`) that
  determines whether AI helps during Do. **There is no `ai`
  routing in `spades-anywhere`** — autonomous code execution
  doesn't apply to non-code work.

Never skip a phase or combine phases without explicit human
instruction.

If the human Evaluate step returns PARTIAL or FAIL,
`/spades-anywhere:evaluate` routes back to `/spades-anywhere:do`
and the human keeps going. The do → evaluate loop runs until PASS.

## Phase Rules

### 1. Scope (Human-owned)
- Never begin planning without a signed-off Scope.
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
- Do NOT begin Do-phase work until the Plan is approved.

### 3. Approve (Human gate)
- After producing a Plan, STOP and wait for human approval.
- Approval records a `delivery:` routing on the Plan
  (`human` or `hybrid`) and a `deliverable_type:` (`artefact` or
  `action`). **There is no `code` deliverable_type and no `ai`
  routing in `spades-anywhere`.**
- If revised or rejected, do not begin delivery.

### 4. Do (Human acts; AI marks the start)
- `/spades-anywhere:do` is a **marker**, not autonomous work. The
  AI updates the Plan's status, restates the Scope's acceptance
  criteria so the human knows what "done" looks like, and stands
  down. The human does the actual work.
- For `delivery: hybrid` plans, AI offers to help with tasks
  marked `Routing: ai` — drafts, research, structuring — but
  never executes the task autonomously.
- No assignee tracking, no cadence enforcement. `spades-anywhere`
  is not a project manager.

### 5. Evaluate (Human verdict)
- Walk the Scope's acceptance criteria, mark each met / partial /
  not met, aggregate to PASS / PARTIAL / FAIL.
- No test execution, no AI verdict — the human's word is the
  verdict.
- If not PASS, route back to `/spades-anywhere:do` and keep going.

### 6. Ship (Confirmation walk against INTENT)
- Walk the project's `INTENT.md` success criteria one at a time,
  capture evidence per criterion (URL / file / photo / note).
- For `deliverable_type: artefact` — record a primary reference
  (URL, file path, doc ID) alongside the per-criterion evidence.
- For `deliverable_type: action` — record evidence of the action
  (photos, receipts, signed docs, witness notes).
- Mark Plan `shipped`. If every Plan under the Scope is shipped,
  Scope rolls up to `done`.

## Freshness Before Read-Across

`spades-anywhere` runs in contexts where there is often no git
repo at all (Claude Desktop project, ChatGPT conversation, mobile
client). The freshness rule from the sister `spades` plugin still
applies *conceptually* — read against the latest source of truth —
but the mechanism varies:

- **Linear backend** — Linear is canonical. Sub-agents always see
  current state. No probe needed.
- **Local backend without git** — `.spades-anywhere/` files on
  disk are the source of truth. No remote to compare against.
- **Local backend inside a git repo** — if the consumer has chosen
  to version-control `.spades-anywhere/`, the same staleness rule
  applies: run `git fetch && git rev-list --count
  main..origin/main`; if non-zero, sync first.

`spades-anywhere` does NOT require any `repo` plugin. Sync is
the consumer's responsibility, by any mechanism they prefer.

The full contract lives in `docs/FRAMEWORK.md § Freshness`.

## Versioning

Every PR to the plugin must bump the plugin version. Per-skill
versions in the plugin's own SKILL.md frontmatter bump only when
that skill's body changes, and the **AGENTS.md version** bumps only
when the operating rules change. The marker block above (`vX.Y.Z`)
carries the AGENTS.md version — it tells you which version of the
rules your AGENTS.md was last stamped against, and only reads as
stale when those rules actually changed (not on every unrelated
plugin upgrade). Re-running `/spades-anywhere:setup` re-stamps it.

Choose major / minor / patch by semver. When in doubt, lean
higher.

## Audit Trail

Every piece of work must trace through: project → scope → plan(s)
→ approval (with routing) → do-phase marker → evaluation verdict
→ shipment record (with per-INTENT-criterion evidence). Work that
cannot be traced through this chain must not ship.
```
