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

```bash
git clone https://github.com/m-kopa/spade-framework.git ~/.spade
~/.spade/setup .
```

Then open Claude Code in your project and run `/spade-onboard` to fill in your
architecture docs. Start working with `/spade-scope`.

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

### Method 1: Install into a specific project

```bash
# Clone the SPADE framework
git clone https://github.com/m-kopa/spade-framework.git ~/.spade

# Install into your project
~/.spade/setup /path/to/your/project
```

This copies the framework files into your project:

- `AGENTS.md` and `CLAUDE.md` (framework-owned, updated on upgrade)
- `.claude/skills/` (all SPADE skills)
- `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md` (templates, never overwritten)
- `.spade/examples/` (example Scope and Plan)

### Method 2: Install skills globally (all Claude Code sessions)

```bash
git clone https://github.com/m-kopa/spade-framework.git ~/.spade
~/.spade/setup --global
```

Global skills are available everywhere, but you still need to install
AGENTS.md and architecture docs per-project.

### Method 3: One-liner install into current project

```bash
git clone https://github.com/m-kopa/spade-framework.git ~/.spade && ~/.spade/setup .
```

### Integrating into an Existing Project

If your project already has `AGENTS.md` or `CLAUDE.md`, SPADE will not
overwrite them. Instead, it injects SPADE sections between marker comments:

```html
<!-- SPADE-FRAMEWORK-START v1.0.0 -->
...SPADE content...
<!-- SPADE-FRAMEWORK-END -->
```

Your existing content outside the markers is preserved. On upgrade, only
the content between markers is replaced. This means SPADE works cleanly
alongside other agent configurations or project instructions you already have.

If your project has no existing agent configuration, SPADE creates the files
from scratch.

Architecture templates (`ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`)
are only created if they do not already exist. They are never overwritten,
so your project-specific content is always safe.

### Upgrading

```bash
cd ~/.spade && git pull
~/.spade/setup --upgrade /path/to/your/project
```

Framework files (AGENTS.md, CLAUDE.md, skills) are updated. Your architecture
docs are never overwritten.

### Removing

```bash
~/.spade/setup --remove /path/to/your/project
```

SPADE sections are removed from AGENTS.md and CLAUDE.md (your content is
preserved). Skills and `.spade/` directory are deleted. Architecture docs
are kept since they contain your project-specific content.

### Adding to a Team Repo

Commit the installed files so teammates get SPADE automatically:

```bash
cd /path/to/your/project
git add AGENTS.md CLAUDE.md .claude/ ARCHITECTURE.md PATTERNS.md ANTI-PATTERNS.md .spade/
git commit -m "Install SPADE framework"
```

Teammates who clone the repo will have SPADE working immediately in Claude Code.
They can then run `/spade-onboard` to fill in architecture docs if needed.

---

## Onboarding a Project

After installing, open Claude Code in your project and run:

```
/spade-onboard
```

This analyses your codebase and helps you fill in ARCHITECTURE.md, PATTERNS.md,
and ANTI-PATTERNS.md with real content specific to your project. These documents
are what AI agents read during the Plan phase, so the better the context, the
better the Plans.

Alternatively, fill them in manually. The template structure guides you through
what to document.

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
| `/spade-scope` | Help write a well-formed Scope with acceptance criteria |
| `/spade-plan` | Generate a structured Plan from a Scope |
| `/spade-approve` | Present a Plan for human review against the approval checklist |
| `/spade-evaluate` | Check delivered output against acceptance criteria |
| `/spade-status` | Show current SPADE phase and progress for active work |
| `/spade-onboard` | Analyse codebase and fill in architecture docs for a new project |

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

After installation, your project will contain:

```
your-project/
├── AGENTS.md              # Mandatory agent behaviour (the enforcement layer)
├── CLAUDE.md              # Claude Code project configuration
├── ARCHITECTURE.md        # Your system architecture and constraints
├── PATTERNS.md            # Approved patterns and conventions
├── ANTI-PATTERNS.md       # Things not to do
├── .claude/
│   └── skills/
│       ├── spade-scope/   # Skill: write well-formed Scopes
│       │   └── SKILL.md
│       ├── spade-plan/    # Skill: generate structured Plans
│       │   └── SKILL.md
│       ├── spade-approve/ # Skill: run the approval checklist
│       │   └── SKILL.md
│       ├── spade-evaluate/# Skill: check output against acceptance criteria
│       │   └── SKILL.md
│       ├── spade-status/  # Skill: show current phase and progress
│       │   └── SKILL.md
│       └── spade-onboard/ # Skill: analyse codebase and fill in architecture docs
│           └── SKILL.md
└── .spade/
    ├── version            # Install metadata
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

**What if I already have an AGENTS.md?**
SPADE appends its section between marker comments. Your existing content is
untouched. On upgrade, only the SPADE section is replaced.

**What if I already have ARCHITECTURE.md?**
SPADE will not overwrite it. Architecture templates are only created if the
files do not exist.

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

**Can I remove SPADE later?**
Yes. Run `~/.spade/setup --remove /path/to/your/project`. SPADE sections are
cleaned from your files and your content is preserved.

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
