# SPADES Framework

**A human-AI operating model for engineering teams.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-green.svg)](.claude-plugin/plugin.json)
[![Claude Code](https://img.shields.io/badge/Claude_Code-plugin-blueviolet.svg)](https://claude.ai/code)

SPADES defines clear boundaries between what humans own and what AI handles,
creating a loop that is fast, auditable, and safe.

```
SCOPE ──► PLAN ──► APPROVE ──► DO ──► EVALUATE ──► SHIP
 (H)       (AI)      (H)      (AI/H)    (H)      (AI/H)
```

**Humans own the edges** (deciding what to build and verifying it was built correctly).
**AI owns the middle** (planning the approach and executing the work).

Six phases with a **Project layer above Scopes** and **pluggable
backends** (Linear MCP, local filesystem, extensible to any MCP).

---

## Quick Start

Three commands to get SPADES working:

```text
# 1. Install the plugin (one-time, in Claude Code)
/plugin marketplace add ChrisFmlyc/spades
/plugin install spades@spades-framework

# 2. In your repo, configure the backend:
/spades:setup

# 3. Create your first project:
/spades:newproject "My Service"
```

That's it. No clone, no setup script, no bash. The `setup` skill asks
which backend to use (Linear MCP or local filesystem), scaffolds the
framework files, and analyses your codebase to seed `ARCHITECTURE.md`.
Commit the generated files and your team has SPADES automatically.

---

## The Problem

Without a framework, teams fall into one of two failure modes:

1. **Too manual.** AI is used as fancy autocomplete. Humans do all the planning,
   structuring, and project management. Slow, no leverage.

2. **Too unsupervised.** AI is given open-ended goals with no review gates.
   Output may be technically functional but architecturally wrong, insecure,
   or solving the wrong problem. Confidently wrong slop.

SPADES prevents both by enforcing human gates at the right points in the loop.

---

## Prerequisites

- **Claude Code** (CLI, desktop app, or IDE extension) — the primary AI agent.
  Install from [claude.ai/code](https://claude.ai/code).
- **A project tracker** (recommended: [Linear](https://linear.app)) — SPADES
  uses parent issues as Scopes and sub-issues as Plan tasks. Any tracker works,
  but Linear integration via MCP is fully automated.
- **Git** — SPADES files are designed to be committed to your repo so the whole
  team gets them automatically.

Optional:
- **Linear MCP** — enables Claude Code to read/write issues, create sub-tasks,
  and update statuses automatically. Without it, you manage issues manually.

---

## Installation

SPADES is distributed as a single Claude Code plugin. Cross-platform
(macOS / Linux / Windows), no bash, no clone, no setup script.

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
   belongs to. Use `/spades:newproject` first if you don't have one
   yet.

3. **Framework file scaffolding** — `AGENTS.md`, `ARCHITECTURE.md`,
   `PATTERNS.md`, `ANTI-PATTERNS.md`. If any exist, they're left
   untouched (the SPADES section inside `AGENTS.md` is replaced in
   place via marker blocks; everything else is your own content).

   SPADES writes only `AGENTS.md` — the cross-agent convention that
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
2. `/spades:newproject "My Service"` — create the project record this
   repo belongs to. Once per project.
3. `/spades:scope "Add the thing"` — write the outcome you want, with
   acceptance criteria.
4. `/spades:plan S-add-the-thing` — break it down into 3–7 tasks, with
   dependencies among plans if needed.
5. `/spades:approve P-add-the-thing-…` — human gate; pick the routing
   (AI auto / human / mixed).
6. `/spades:do P-add-the-thing-…` — execute, routed per the approval.
7. `/spades:evaluate P-add-the-thing-…` — verify against the Scope's
   acceptance criteria (PASS / PARTIAL / FAIL).
8. `/spades:ship P-add-the-thing-…` — open PR + review + merge for
   code, or record the artefact / action for non-code deliverables.

Steps 3–8 repeat per piece of work. Steps 1–2 are one-time.

### The 15 skills

SPADES ships 15 skills, grouped by *when you reach for them*:

#### One-time setup

| Skill | Purpose |
|-------|---------|
| `/spades:setup` | Configure backend + scaffold this repo. Re-runnable to switch backend or refresh the SPADES marker block inside `AGENTS.md`. |
| `/spades:newproject` | Create a new Project record (`.spades/projects/<slug>.md`) — the long-lived container above Scopes. A project is a repo, a set of repos, or any other long-lived thing you ship work into. |

#### The core loop (run for every piece of work)

| Skill | Purpose |
|-------|---------|
| `/spades:scope` | Create or edit a Scope (`S-<description-slug>`). The outcome record — intent, acceptance criteria, constraints. Fuzzy-matches existing scopes so you don't accidentally double up. |
| `/spades:plan` | Generate a Plan (`P-<slug>-<suffix>[-<dep>…]`) under a Scope. Plans can depend on prior plans within the same Scope; the dependency chain is encoded in the filename. |
| `/spades:approve` | Human gate. Walks the 6-point approval checklist, then asks the routing question (AI / human / mixed) and records it on the Plan. |
| `/spades:do` | Execute the Plan, routed per the approval. AI runs autonomously; human is assigned and acknowledged; mixed splits per task. |
| `/spades:evaluate` | Check delivered output against the Scope's acceptance criteria. PASS → Ship. PARTIAL → back to Do. FAIL → back to Plan or Scope. |
| `/spades:ship` | Release the deliverable. For `deliverable_type: code` it runs the inline PR + review + merge checklist; for `artefact` it records a reference (URL / doc ID / file path); for `action` it records evidence of completion. |

#### Side path — skip the full loop for trivial work

| Skill | Purpose |
|-------|---------|
| `/spades:quick` | Fast-track for typos, one-line tweaks, small config nudges, docs changes. The PR description is the audit artefact; no Scope or Plan record is created. Walks a 10-criteria gate first — if any criterion fails, falls back to the full loop. **Use when you say:** "just fix this typo", "tiny tweak", "one-line change", "small fix". |

#### Optional helpers — reach for them when applicable

| Skill | Purpose |
|-------|---------|
| `/spades:review` | Multi-persona panel second opinion. Spawns four reviewer subagents in parallel (scope-guardian, architecture-strategist, security-lens, adversarial-reviewer), merges their findings, and presents a tiered report. Advisory only — never gates approval. **Use when you say:** "second opinion", "outside view", "challenge this", "review this". Also auto-offered by `/spades:scope` and `/spades:approve`. |
| `/spades:research` | Outside fact-finding via an isolated read-only Opus subagent. Returns a structured findings report; optional comment on the active Scope with explicit consent. Distinct from `review` — research looks *outward* at libraries, frameworks, prior art; review looks *inward* at our own work. **Use when you say:** "look into X", "prior art on Y", "check the SOTA for Z", "properly research this", "what does the landscape look like for…". |
| `/spades:learn` | Capture a learning under `.spades/learnings/` so future Plans automatically surface it on related Scopes. The framework's antidote to "AI repeats the same mistakes." `--refresh` archives stale entries and flags contradictions. **Use when you say:** "we should remember this", "we just learned X", "log this learning", "capture what we figured out". Also auto-offered by `/spades:ship` after a successful shipment. |
| `/spades:intent` | Create or maintain `INTENT.md` — the project's durable statement (problem, users, what-it-does, success, non-goals, maturity). Different cadence from a Scope: a Scope describes one unit of work; INTENT describes the project's reason for existing. **Use when you say:** "what is this project for", "set up INTENT.md", "review our non-goals", "the intent doc is stale". Also auto-offered by `/spades:setup` on first run. |

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
- `/spades:setup` offers `/spades:intent` to scaffold `INTENT.md` if
  it's missing.

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
The Plan is documented on the parent issue as a first-class artefact.

### Approve (Human)

The engineer reviews the Plan against reality: architecture alignment,
completeness, feasibility, risk, and scope. This is a gate, not a rubber stamp.
Rejected plans go back with specific feedback.

### Do (AI or Human — routed)

Tasks get executed. `/spades:approve` records a routing decision on
each Plan (`ai`, `human`, or `mixed`); `/spades:do` reads that and
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
action. Shipping is the moment value reaches users; SPADES treats it
as an explicit final step rather than an implicit afterthought.

### Supporting skills (around the loop)

Seven skills sit around the loop rather than inside it:

- **One-time** — `setup` (configure backend, re-runnable) and
  `newproject` (create a Project record).
- **Side path** — `quick` (fast-track for trivial work; skips the
  whole loop, uses the PR description as the audit).
- **Optional helpers** — `review` (independent panel second opinion),
  `research` (outside fact-finding), `learn` (capture a learning for
  future Plans), `intent` (maintain the durable `INTENT.md`).
- **Observability** — `list` (inventory of scopes by phase) and
  `status` (what's in flight, dep graph, next action).

See "The 15 skills" above for trigger phrases and when each one fires.

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

SPADES is a pattern, not a product integration. The framework works with any
project tracker and any AI agent that can read structured context.

### AI Agents

| Agent | Support Level | Notes |
|-------|--------------|-------|
| **Claude Code** | Full | Native skills, Linear MCP, automated workflow |
| **Cursor** | Partial | Reads AGENTS.md for rules, no skill support |
| **GitHub Copilot** | Partial | Reads AGENTS.md for rules, no skill support |
| **Codex** | Partial | Reads AGENTS.md for rules, no skill support |
| **Any MCP-compatible agent** | Varies | Can slot into the Do phase |

The key insight: AGENTS.md works as a universal enforcement layer. Any AI agent
that reads project context files will follow SPADES rules. The skills add
convenience but are not required for the pattern to work.

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
scaffolds the framework files, and walks you through filling in the
architecture docs.

**What if I already have an AGENTS.md?**
The setup skill replaces only the SPADES section between marker
comments. Your existing content is untouched.

**What if I already have ARCHITECTURE.md?**
It will not be overwritten. The setup skill skips files that already
exist and moves straight to helping you fill in content.

**Can I use SPADES without Linear?**
Yes. Linear integration is optional. Without it, you manage Scopes and Plans
manually (in any tracker or even in markdown files). The SPADES loop is the
same regardless of tooling.

**Can I use SPADES without Claude Code?**
Yes, partially. AGENTS.md works with any AI agent that reads project context.
You lose the `/spades:*` skills but keep the enforcement rules and the
workflow pattern.

**How do I scale ceremony for small tasks?**
The loop compresses. For a bug fix, the ticket is the Scope, planning is a
quick comment, approval is a fast check. The structure exists but the ceremony
is light. See `docs/FRAMEWORK.md` for details.

**Do teammates need to install SPADES too?**
They need the plugin installed (Step 1). The project files created by
`/spades:setup` should be committed to the repo so they're available
automatically — `AGENTS.md` works for any AI agent that reads project
context, even ones without the SPADES plugin.

---

## Principles

1. **Humans own the edges.** AI never decides what to build. AI output is never
   shipped without human verification.
2. **Plans are artefacts, not ephemeral.** Every plan is documented and attached
   to the work item.
3. **Approval is a gate, not a rubber stamp.** If you approve every plan in
   30 seconds, the gate is not working.
4. **Delivery mode is explicit.** Every task is labelled AI-delivered or
   human-delivered.
5. **Feedback loops are first-class.** Rejected plans and failed evaluations
   go back into the loop with specific feedback.
6. **Architecture constraints are codified, not memorised.** Maintain living
   documents that AI reads during planning.
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

MIT. Use it, fork it, make it yours.

---

*The SPADES Framework — Chris Powell (Closed Door Security), 2026*
