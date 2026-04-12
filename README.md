# SPADE Framework

**A human-AI operating model for engineering teams.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](setup)
[![Claude Code](https://img.shields.io/badge/Claude_Code-compatible-blueviolet.svg)](https://claude.ai/code)

SPADE defines clear boundaries between what humans own and what AI handles,
creating a loop that is fast, auditable, and safe.

```
SCOPE ──► PLAN ──► APPROVE ──► DELIVER ──► EVALUATE
 (H)       (AI)      (H)        (AI/H)       (H)
```

**Humans own the edges** (deciding what to build and verifying it was built correctly).
**AI owns the middle** (planning the approach and executing the work).

---

## Quick Start

Two steps to get SPADE working:

```bash
# 1. Install SPADE globally (one-time)
git clone https://github.com/m-kopa/spade-framework.git ~/.spade
~/.spade/setup

# 2. In any project, open Claude Code and run:
/spade-onboard
```

That's it. The onboard skill creates all the framework files in your project,
analyses your codebase, and helps you fill in architecture docs. Commit the
generated files and your team has SPADE automatically.

---

## The Problem

Without a framework, teams fall into one of two failure modes:

1. **Too manual.** AI is used as fancy autocomplete. Humans do all the planning,
   structuring, and project management. Slow, no leverage.

2. **Too unsupervised.** AI is given open-ended goals with no review gates.
   Output may be technically functional but architecturally wrong, insecure,
   or solving the wrong problem. Confidently wrong slop.

SPADE prevents both by enforcing human gates at the right points in the loop.

---

## Prerequisites

- **Claude Code** (CLI, desktop app, or IDE extension) — the primary AI agent.
  Install from [claude.ai/code](https://claude.ai/code).
- **A project tracker** (recommended: [Linear](https://linear.app)) — SPADE
  uses parent issues as Scopes and sub-issues as Plan tasks. Any tracker works,
  but Linear integration via MCP is fully automated.
- **Git** — SPADE files are designed to be committed to your repo so the whole
  team gets them automatically.

Optional:
- **Linear MCP** — enables Claude Code to read/write issues, create sub-tasks,
  and update statuses automatically. Without it, you manage issues manually.

---

## Installation

### Step 1: Install SPADE (one-time)

Clone the framework and run setup. This installs the SPADE skills globally
into `~/.claude/skills/` so they're available in every Claude Code session.

**macOS / Linux / WSL:**

```bash
git clone https://github.com/m-kopa/spade-framework.git ~/.spade
~/.spade/setup
```

**Windows (PowerShell):**

```powershell
git clone https://github.com/m-kopa/spade-framework.git $HOME\.spade
& $HOME\.spade\setup.ps1
```

That's the only setup step. Skills are now available globally.

### Step 2: Onboard a project

Open Claude Code in any project and run:

```
/spade-onboard
```

This does two things:

1. **Creates framework files** — `AGENTS.md`, `CLAUDE.md`, architecture
   templates (`ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`), example
   files, and `.spade/` metadata. If any of these already exist, they are
   left untouched or augmented (not overwritten).

2. **Analyses your codebase** — explores your project structure, dependencies,
   patterns, and infrastructure, then helps you fill in the architecture docs
   with real content specific to your project.

Once onboarding is done, commit the generated files:

```bash
git add AGENTS.md CLAUDE.md ARCHITECTURE.md PATTERNS.md ANTI-PATTERNS.md .claude/ .spade/
git commit -m "Onboard project with SPADE framework"
```

Teammates who clone the repo will have SPADE working immediately — they just
need the global skills install (Step 1).

### Upgrading

```bash
# macOS / Linux / WSL
cd ~/.spade && git pull && ~/.spade/setup
```

```powershell
# Windows (PowerShell)
cd $HOME\.spade; git pull; & $HOME\.spade\setup.ps1
```

This updates the global skills. To update SPADE files in a specific project,
run `/spade-onboard` again — it will update framework sections while
preserving your project-specific content.

---

## Using SPADE

Once installed and onboarded:

1. Write a Scope in Linear (parent issue with acceptance criteria)
2. Run `/spade-plan` and point it at the issue
3. Review the Plan with `/spade-approve`
4. Let delivery run (AI handles code, you handle the rest)
5. Verify output with `/spade-evaluate`
6. Check progress any time with `/spade-status`

### Available Skills

| Skill | What it does |
|-------|-------------|
| `/spade-onboard` | Initialise SPADE in a project and fill in architecture docs |
| `/spade-scope` | Create or edit a well-formed Scope (enforces 10 required fields) |
| `/spade-list` | List active Scopes from Linear, filtered by SPADE phase |
| `/spade-plan` | Generate a structured Plan from a Scope |
| `/spade-approve` | Present a Plan for human review against the approval checklist |
| `/spade-review` | Get an independent second opinion on a Scope, Plan, or both |
| `/spade-evaluate` | Check delivered output against acceptance criteria |
| `/spade-status` | Show current SPADE phase and progress for active work |
| `/spade-update` | Check for and install SPADE framework updates |

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

### Deliver (AI or Human)

Tasks get executed. AI handles code, pipelines, configuration, documentation.
Humans handle stakeholder conversations, hardware testing, vendor negotiations,
and anything requiring organisational context.

### Evaluate (Human)

The engineer verifies output against the original Scope's acceptance criteria.
Passing work ships. Failing work goes back into the loop.

---

## Project Structure

After onboarding, your project will contain:

```
your-project/
├── AGENTS.md              # Mandatory agent behaviour (the enforcement layer)
├── CLAUDE.md              # Claude Code project configuration
├── ARCHITECTURE.md        # Your system architecture and constraints
├── PATTERNS.md            # Approved patterns and conventions
├── ANTI-PATTERNS.md       # Things not to do
├── .claude/
│   └── skills/            # (empty — skills are installed globally)
└── .spade/
    ├── version            # Install metadata
    ├── plans/             # Approved SPADE plans (generated by /spade-plan)
    │   └── M-68-plan.md
    ├── docs/              # Framework reference documentation
    │   └── FRAMEWORK.md
    └── examples/          # Example Scope and Plan
        ├── example-scope.md
        └── example-plan.md
```

---

## Compatibility

SPADE is a pattern, not a product integration. The framework works with any
project tracker and any AI agent that can read structured context.

### AI Agents

| Agent | Support Level | Notes |
|-------|--------------|-------|
| **Claude Code** | Full | Native skills, Linear MCP, automated workflow |
| **Cursor** | Partial | Reads AGENTS.md for rules, no skill support |
| **GitHub Copilot** | Partial | Reads AGENTS.md for rules, no skill support |
| **Codex** | Partial | Reads AGENTS.md for rules, no skill support |
| **Any MCP-compatible agent** | Varies | Can slot into the Deliver phase |

The key insight: AGENTS.md works as a universal enforcement layer. Any AI agent
that reads project context files will follow SPADE rules. The skills add
convenience but are not required for the pattern to work.

### Project Trackers

| Tracker | Support Level | Notes |
|---------|--------------|-------|
| **Linear** | Full | Automated via MCP (issue creation, status updates, labels) |
| **GitHub Issues** | Manual | Use the SPADE loop manually; issues as Scopes |
| **Jira** | Manual | Use the SPADE loop manually; tickets as Scopes |
| **Any tracker** | Manual | The pattern holds regardless of tooling |

---

## FAQ

**How do I add SPADE to a new project?**
Run `/spade-onboard` in Claude Code. It creates all the files and walks you
through filling in the architecture docs.

**What if I already have an AGENTS.md?**
The onboard skill appends its section between marker comments. Your existing
content is untouched.

**What if I already have ARCHITECTURE.md?**
It will not be overwritten. The onboard skill skips files that already exist
and moves straight to helping you fill in content.

**Can I use SPADE without Linear?**
Yes. Linear integration is optional. Without it, you manage Scopes and Plans
manually (in any tracker or even in markdown files). The SPADE loop is the
same regardless of tooling.

**Can I use SPADE without Claude Code?**
Yes, partially. AGENTS.md works with any AI agent that reads project context.
You lose the `/spade-*` skills but keep the enforcement rules and the workflow
pattern.

**How do I scale ceremony for small tasks?**
The loop compresses. For a bug fix, the ticket is the Scope, planning is a
quick comment, approval is a fast check. The structure exists but the ceremony
is light. See `docs/FRAMEWORK.md` for details.

**Do teammates need to install SPADE too?**
They need the global skills install (Step 1). The project files created by
`/spade-onboard` should be committed to the repo so they're available
automatically.

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

For bugs in the setup script, please include your OS and shell version.

---

## Licence

MIT. Use it, fork it, make it yours.

---

*The SPADE Framework — M-KOPA Product Security Team, April 2026*
