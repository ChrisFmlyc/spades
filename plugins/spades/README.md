# SPADES Framework

**A human-AI operating model for engineering teams.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-6.2.1-green.svg)](.claude-plugin/plugin.json)
[![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-blueviolet.svg)](https://claude.ai/code)

SPADES assigns ownership to each phase and records the decisions,
verification results, and shipment evidence.

```
SCOPE ──► PLAN ──► APPROVE ──► DELIVER ──► EVALUATE ──► SHIP
 (H)       (AI)     (AI/H)      (AI/H)      (AI/H)     (AI/H)
```

Humans define the outcome. AI drafts the Plan; approval records who
will deliver it, and evaluation checks the result. `/spades:loop`
can perform the approval and verification steps when the AI can
complete them; checks requiring a human wait for that person.

Six phases with a **Project layer above Scopes** and **pluggable
backends** (Linear MCP, local filesystem, extensible to any MCP).

---

## Quick Start

Install the plugin, then configure your repo:

```text
# 1. Install the plugin (one-time, in Claude Code)
/plugin marketplace add ChrisFmlyc/spades
/plugin install spades@spades-framework

# 2. In your repo, configure the backend:
/spades:setup
```

The `setup` skill asks for a backend, SCM, review format, and active
project. It creates a project when needed and offers empty templates
for incomplete project documents. Use the document skills to fill
them in, then commit the generated files for your team.

---

## The Problem

Teams can leave all planning and project management to humans while
using AI only for code completion, or give AI open-ended goals without
review gates. The first limits what AI contributes; the second can
produce work that is architecturally wrong, insecure, or solves the
wrong problem.

SPADES gives AI a planning role and requires approval and evaluation
before shipment.

---

## Prerequisites

- **Claude Code** (CLI, desktop app, or IDE extension) — the primary AI agent.
  Install from [claude.ai/code](https://claude.ai/code).
- **A backend** — choose local Markdown records or [Linear](https://linear.app)
  mirrors via MCP. Linear uses parent issues for Scopes and sub-issues
  for Plans.
- **Git** — SPADES files are designed to be committed to your repo so the whole
  team gets them automatically.

Optional:
- **Linear MCP** — enables Claude Code to read/write issues, create sub-tasks,
  and update statuses. Local mode needs no external tracker.

---

## Installation

SPADES is distributed as a single Claude Code plugin for macOS,
Linux, and Windows. See the [repository README](../../README.md)
for installation in other coding harnesses.

### Step 1: Install the plugin (one-time)

In Claude Code:

```text
/plugin marketplace add ChrisFmlyc/spades
/plugin install spades@spades-framework
```

Updates:

```text
/plugin marketplace update
/plugin update spades@spades-framework
```

### Step 2: Configure SPADES in your repo

Open Claude Code in your repo and run:

```text
/spades:setup
```

This walks you through:

1. **Backend selection** — Linear (artefacts in a Linear Project) or
   Local (artefacts under `.spades/`). Re-runnable to switch later.

2. **Active project binding** — names the SPADES Project this repo
   belongs to. Setup invokes `/spades:newproject` if you need one.

3. **Framework file scaffolding** — refresh the SPADES marker block
   in `AGENTS.md`, preserving content outside it. For `INTENT.md`,
   `ARCHITECTURE.md`, `PATTERNS.md`, and `ANTI-PATTERNS.md`, setup
   offers scaffolding for missing or incomplete documents and
   preserves complete ones.

   SPADES writes `AGENTS.md` as its only agent-rules file — the convention that
   Claude Code, Cursor, Codex, Aider and other coding agents all read.
   No `CLAUDE.md` or other per-vendor variants.

Once setup is done, commit the generated files:

```bash
git add AGENTS.md ARCHITECTURE.md PATTERNS.md ANTI-PATTERNS.md INTENT.md .spades/
git commit -m "Initialise project with SPADES framework"
```

Teammates who clone the repo will have SPADES working as soon as they
also install the plugin (Step 1).

### Upgrading

The plugin marketplace handles framework updates:

```text
/plugin marketplace update
/plugin update spades@spades-framework
```

To refresh the SPADES section inside an individual project's
`AGENTS.md` after upgrading, re-run `/spades:setup` in that project —
the marker-replace flow re-stamps the version block in place and
preserves the rest of your file.

---

## Using SPADES

The typical first run, end to end:

1. `/spades:setup` — pick a backend (Linear or local), scaffold the
   framework files. Once per repo (re-runnable to switch backend).
2. Fill the project documents with `/spades:intent`,
   `/spades:architecture`, `/spades:patterns`, and `/spades:anti-patterns`.
   Setup has already bound or created the active project.
3. `/spades:scope "Add the thing"` — write the outcome you want, with
   acceptance criteria.
4. `/spades:plan S-add-the-thing` — break it down into 3–7 tasks, with
   dependencies among plans if needed.
5. `/spades:approve P-add-the-thing-…` — human gate; pick the routing
   (AI auto / human / hybrid).
6. `/spades:deliver P-add-the-thing-…` — create the separate delivery branch/worktree, then execute per the approval.
7. `/spades:evaluate P-add-the-thing-…` — verify against the Scope's
   acceptance criteria (PASS / PARTIAL / FAIL).
8. `/spades:ship P-add-the-thing-…` — open the Scope's delivery PR
   for GitHub code work, or record the artefact / action evidence.
   After the PR merges, `/spades:close P-add-the-thing-…` records
   shipment through a bookkeeping PR.

Steps 3–8 repeat per piece of work. Steps 1–2 are one-time.

### Or: write the Scope and let it run

Steps 4–8 (plus the PR review, the merge, and the close-out
bookkeeping) are the same sequence every time. `/spades:loop` runs
it for you:

```
/spades:scope "Add the thing"    # reuses the documentation session; records the delivery branch
/spades:loop                     # drives the remaining phases
```

The loop handles approval and verification when the AI can complete
them. Evaluation pauses for your confirmation when it includes checks
only a human can perform. You can discuss the evidence or ask for a
check to be rerun before confirming.

It then proceeds through shipment, bot review, squash-merge,
`/spades:close`, and the bookkeeping PR's review and merge. Branches
and worktrees remain available after completion. Other blockers and
human decisions follow `skills/loop/SKILL.md § Pauses`.

### The 22 skills

SPADES ships 22 skills, grouped by *when you reach for them*:

#### One-time setup

| Skill | Purpose |
|-------|---------|
| `/spades:setup` | Configure backend + scaffold this repo. Re-runnable to switch backend or refresh the SPADES marker block inside `AGENTS.md`. |
| `/spades:newproject` | Create a Project record for a repo, service, or set of repos. |
| `/spades:objective` | Create or edit an Objective (`O-<slug>`), a strategic action associated with a Project. |

#### The core loop (run for every piece of work)

| Skill | Purpose |
|-------|---------|
| `/spades:scope` | Create or edit a Scope (`S-<description-slug>`). The outcome record — intent, acceptance criteria, constraints. Fuzzy-matches existing scopes so you don't accidentally double up. |
| `/spades:plan` | Generate a Plan (`P-<slug>-<suffix>[-<dep>…]`) under a Scope. Plans can depend on prior plans within the same Scope; the dependency chain is encoded in the filename. |
| `/spades:approve` | Human gate. Walks the 6-point approval checklist, then asks the routing question (AI / human / hybrid) and records it on the Plan. |
| `/spades:deliver` | Execute the Plan, routed per the approval. AI runs autonomously; human is assigned and acknowledged; hybrid splits per task. |
| `/spades:evaluate` | Check delivered output against the Scope's acceptance criteria. PASS → Ship. PARTIAL → back to Deliver. FAIL → back to Plan or Scope. |
| `/spades:ship` | Release the deliverable. For `deliverable_type: code` it follows the selected SCM driver; GitHub opens the shared Scope PR and Close records the verified merge; for `artefact` it records a reference (URL / doc ID / file path); for `action` it records evidence of completion. |

#### Autopilot — run the core loop without driving it

| Skill | Purpose |
|-------|---------|
| `/spades:loop` | Drive one Scope from Plan to closed-out. Chains `plan → approve → deliver → evaluate → ship → CodeRabbit/Greptile review → squash-merge → close → review → merge`, with human sign-off when evaluation requires it, Plans delivered in dependency order in one Scope worktree, then one shared delivery PR. Your invocation, or delegation from a goal or driver you established, supplies authorization to push, open PRs, resolve **bot** review threads, and squash-merge, bounded to this Scope's own branches and PRs. It never writes a Scope or resolves a human's review comment. See `skills/loop/SKILL.md` for invocation and verification rules. |

#### Side path — skip the full loop for trivial work

| Skill | Purpose |
|-------|---------|
| `/spades:quick` | Fast-track for typos, one-line tweaks, small config nudges, docs changes. The `.spades/quick/Q-<id>.md` marker is the audit record; no Scope or Plan record is created. Walks a 10-criteria gate first — if any criterion fails, falls back to the full loop. **Use when you say:** "just fix this typo", "tiny tweak", "one-line change", "small fix". |

#### Optional helpers — reach for them when applicable

| Skill | Purpose |
|-------|---------|
| `/spades:review` | Multi-persona panel second opinion. Spawns four reviewer subagents in parallel (scope-guardian, architecture-strategist, security-lens, adversarial-reviewer), merges their findings, and presents a tiered report. Advisory only — never gates approval. **Use when you say:** "second opinion", "outside view", "challenge this", "review this". Also auto-offered by `/spades:scope` and `/spades:approve`. |
| `/spades:research` | Outside fact-finding via an isolated read-only Opus subagent. Returns a structured findings report; optional comment on the active Scope with explicit consent. Distinct from `review` — research looks *outward* at libraries, frameworks, prior art; review looks *inward* at our own work. **Use when you say:** "look into X", "prior art on Y", "check the SOTA for Z", "properly research this", "what does the landscape look like for…". |
| `/spades:learn` | Capture a learning under `.spades/learnings/` so future Plans automatically surface it on related Scopes. `--refresh` archives stale entries and flags contradictions. **Use when you say:** "we should remember this", "we just learned X", "log this learning", "capture what we figured out". Also auto-offered by `/spades:ship` after a successful shipment. |
| `/spades:intent` | Create or maintain `INTENT.md` — the project's durable statement (problem, users, what-it-does, success, non-goals, maturity). Different cadence from a Scope: a Scope describes one unit of work; INTENT describes the project's reason for existing. **Use when you say:** "what is this project for", "set up INTENT.md", "review our non-goals", "the intent doc is stale". Run it after `/spades:setup` scaffolds `INTENT.md`. |
| `/spades:close` | Record shipment, rejection, or abandonment for the selected record; code shipment follows verified merge. |
| `/spades:leads` | Capture an out-of-scope discovery, or list, inspect, promote, close, or reconcile Leads. |
| `/spades:architecture` | Create or update the project's architecture document. |
| `/spades:patterns` | Create or update approved conventions in `PATTERNS.md`. |
| `/spades:anti-patterns` | Create or update deliberate exclusions in `ANTI-PATTERNS.md`. |

#### Observability — see what's happening

| Skill | Purpose |
|-------|---------|
| `/spades:list` | Active scopes, filterable by phase or project. Table view, grouped by SPADES phase. The "what scopes exist and where are they?" question. **Use when you say:** "show my scopes", "what's active", "what needs planning". |
| `/spades:status` | Current SPADES phase, progress, and dependency graph for active work. Highlights what's *unblocked and ready to start*, what's blocked, and what the recommended next action is. The "what should I do right now?" question. **Use when you say:** "where are we", "what's the status", "what should I work on next". |

The two observability skills overlap a little but answer different
questions. `list` is the inventory; `status` is the focus tool.

### How skills compose

A few of the supporting skills hook into the core loop automatically,
so you'll often invoke them without typing the slash command:

- `/spades:scope` offers `/spades:review` (Scope Review mode) before
  writing the Scope.
- `/spades:approve` offers `/spades:review` (Full Review mode) before
  the approval decision.
- `/spades:plan` automatically surfaces matching `.spades/learnings/`
  entries when drafting a Plan.
- `/spades:ship` offers `/spades:learn` after a successful shipment.
- `/spades:setup` offers empty scaffolding for incomplete project
  documents and lists their facilitator skills as next steps.

You can always invoke any skill directly too — the auto-offers are
prompts, not requirements.

---

## How It Works

### Scope (Human)

The engineer defines what needs to be achieved and why. A good Scope includes
acceptance criteria, architectural constraints, and upstream/downstream context.
Scopes originate from OKRs, milestones, or reactive work (tickets, incidents).

### Plan (AI)

The AI agent produces a structured plan: 3-7 discrete tasks with technical
approach, dependencies, risks, delivery mode (AI or human), and testing strategy.
The Plan is a local Markdown record, mirrored to a sub-issue when
using Linear.

### Approve (Human)

The engineer checks architecture alignment, completeness, feasibility,
risk, granularity, and deliverable fit before approving the Plan.
Rejected plans go back with specific feedback.

### Deliver (AI or Human — routed)

`/spades:approve` records a routing decision on
each Plan (`ai`, `human`, or `hybrid`); `/spades:deliver` reads that and
either runs the work autonomously, records a human assignment, or
splits the work per the Plan's per-task routing. AI handles code,
pipelines, configuration, documentation. Humans handle stakeholder
conversations, hardware testing, vendor negotiations, and anything
requiring organisational context.

### Evaluate (Human)

The engineer verifies output against the original Scope's acceptance criteria.
Passing work proceeds to Ship. Failing work goes back into the loop.

### Ship (Mixed)

The verified work is released — merged to main, deployed, or otherwise
handed off to its destination. `/spades:ship` branches on the Plan's
`deliverable_type:` — `code` runs the PR + review + merge flow,
`artefact` records the artefact reference (URL, doc ID, file path),
`action` records the evidence of completion for a one-off human
action.

### Supporting skills (around the loop)

Supporting skills handle setup, reporting, and work outside the six phases:

- **One-time** — `setup` (configure backend, re-runnable) and
  `newproject` (create a Project record).
- **Side path** — `quick` (fast-track for trivial work; skips the
  whole loop, uses a Quick marker as the audit).
- **Optional helpers** — `review` (independent panel second opinion),
  `research` (outside fact-finding), `learn` (capture a learning for
  future Plans), `intent` (maintain the durable `INTENT.md`).
- **Observability** — `list` (inventory of scopes by phase) and
  `status` (what's in flight, dep graph, next action).

See "The 22 skills" above for trigger phrases and when each one fires.

---

## Project Structure

After onboarding, your project will contain:

```
your-project/
├── AGENTS.md              # Mandatory agent behaviour — the single cross-agent rules file
├── ARCHITECTURE.md        # System architecture and constraints
├── PATTERNS.md            # Approved patterns and conventions
├── ANTI-PATTERNS.md       # Things not to do
├── INTENT.md              # Project's durable statement of intent
└── .spades/
    ├── version            # SPADES framework version this repo was set up against
    ├── config             # backend + active project
    ├── projects/          # Project records (one per project)
    ├── scopes/            # Scope records (S-<description-slug>.md)
    ├── plans/             # Plan records (P-<slug>-<suffix>[-<dep>…].md)
    ├── learnings/         # Compounding learnings store
    └── reviews/           # Persisted multi-persona review reports
```

---

## Compatibility

SPADES defines a workflow in Markdown. Its skills need the tools
required by each phase; supported integrations and fallback modes
are documented in `docs/FRAMEWORK.md`.

### AI Agents

| Agent | Support Level | Notes |
|-------|--------------|-------|
| **Claude Code** | Full | Native skills, Linear MCP, automated workflow |
| **Cursor** | Partial | Reads AGENTS.md for rules, no skill support |
| **GitHub Copilot** | Partial | Reads AGENTS.md for rules, no skill support |
| **Codex** | Partial | Reads AGENTS.md and installed skills; tool names and dispatch capabilities differ |
| **Any MCP-compatible agent** | Varies | Can slot into the Deliver phase |

`AGENTS.md` supplies the operating rules to agents that read it.
The skills provide the procedures and tool calls for each phase.

### Project Trackers

| Tracker | Support Level | Notes |
|---------|--------------|-------|
| **Linear** | Full | Automated via MCP (issue creation, status updates, labels) |
| **GitHub Issues** | Manual | Use the SPADES loop manually; issues as Scopes |
| **Jira** | Manual | Use the SPADES loop manually; tickets as Scopes |
| **Any tracker** | Manual | The pattern holds regardless of tooling |

---

## FAQ

**How do I add SPADES to a new project?**
Run `/spades:setup` in Claude Code. It asks which backend to use,
scaffolds the framework files, and lists the document skills to run
when you are ready to fill them in.

**What if I already have an AGENTS.md?**
The setup skill replaces only the SPADES section between marker
comments. Your existing content is untouched.

**What if I already have ARCHITECTURE.md?**
Setup preserves complete documents. If a document is missing or
incomplete, it offers an empty scaffold or a skip; the document
skill helps you fill it in later.

**Can I use SPADES without Linear?**
Yes. Choose `backend: local` and the skills read and write Markdown
records under `.spades/`.

**Can I use SPADES without Claude Code?**
Yes. See the [repository README](../../README.md) for installation
and capability differences in other coding harnesses.

**How do I scale ceremony for small tasks?**
Use `/spades:quick` when all ten fast-track criteria pass. Otherwise,
use the full loop with a written Scope and Plan. See
`docs/FRAMEWORK.md § Fast-Track Path` for the criteria.

**Do teammates need to install SPADES too?**
They need the plugin installed (Step 1). The project files created by
`/spades:setup` should be committed to the repo so they're available
automatically — `AGENTS.md` works for any AI agent that reads project
context, even ones without the SPADES plugin.

---

## Principles

1. **Humans define the outcome.** AI never decides what to build.
   Evaluation routing determines which checks the AI or a human performs.
2. **Plans are recorded.** Every plan is documented and attached
   to the work item.
3. **Approval checks the Plan.** Review alignment, completeness,
   feasibility, risk, granularity, and deliverable fit.
4. **Delivery mode is explicit.** Every task is labelled AI-delivered or
   human-delivered.
5. **Feedback loops are first-class.** Rejected plans and failed evaluations
   go back into the loop with specific feedback.
6. **Architecture constraints are documented.** Maintain documents
   that AI reads during planning.
7. **Scope determines approval depth.** Strategic decisions get deep review.
   Granular tasks get light review.

---

## Contributing

Contributions are welcome. If you have ideas for improving the framework:

1. Fork the repo
2. Create a branch for your change
3. Submit a pull request with a clear description of the improvement

### Development

Run the framework's own lint suite before pushing a PR:

```bash
./scripts/lint/run-all.sh
```

See `scripts/lint/README.md` for what each check does. The same lints run in CI on every PR (`.github/workflows/lint.yml`).

---

## Licence

MIT.

---

*The SPADES Framework — Chris Powell (Closed Door Security), 2026*
