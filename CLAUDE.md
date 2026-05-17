# CLAUDE.md

This project uses the SPADE Framework for human-AI collaboration.
Read AGENTS.md before doing anything. It defines mandatory behaviour.

## SPADE Skills

Skills live in `.claude/skills/`. Invoke them by name.

| Skill | What it does |
|-------|-------------|
| `/spade-scope` | Help write a well-formed Scope with acceptance criteria |
| `/spade-plan` | Generate a structured Plan from a Scope; each task declares an execution posture; surfaces matching prior learnings |
| `/spade-approve` | Present a Plan for human review against the approval checklist |
| `/spade-review` | Multi-persona panel second opinion (4 subagents) on a Scope, Plan, or both |
| `/spade-learn` | Capture a learning for `.spade/learnings/` so future Plans reference it; `--refresh` for housekeeping |
| `/spade-quick` | Fast-track path for trivial work (typos, tweaks, small fixes) |
| `/spade-research` | Landscape research via an isolated Opus 4.7 subagent (read-only); optional Linear artefact with explicit consent (v1.3.0+) |
| `/spade-evaluate` | Run acceptance criteria checks against delivered output |
| `/spade-status` | Show current SPADE phase and progress for active work |
| `/spade-onboard` | Analyse codebase and fill in architecture docs for a new project |
| `/spade-intent` | Create or maintain INTENT.md — the project's durable statement of intent (problem, users, what it does, success, non-goals, maturity) |

## Architecture

Read these files before generating any Plan:

- `ARCHITECTURE.md` — system architecture, constraints, and tech stack
- `PATTERNS.md` — approved patterns and conventions
- `ANTI-PATTERNS.md` — things not to do

## Linear Integration

This project tracks work in Linear. When Linear MCP is available:

- Parent issues are Scopes (human-written)
- Sub-issues are Plan tasks (AI-generated, full loop only)
- Use SPADE status labels: Scoped, Planning, Approval, Delivering, Evaluating, Done
- Full-loop labels: `ai-planned`, `ai-delivered`, `human-delivery`, `plan-rejected`, `needs-arch-review`, `bundle:<name>`
- Fast-track labels: `spade:quick`, `type:bug`, `type:tweak`, `type:chore`, `type:docs`, `type:refactor`

## Fast-Track Path

For trivial work — typos, one-line tweaks, small config changes, docs
updates — use `/spade-quick` instead of the full loop. The PR description
is the audit artefact. No sub-issues, no separate Plan, no approval gate
beyond PR review. Gate criteria and rules live in AGENTS.md under
"Fast-Track Path (Small Work)". When in doubt, use the full loop.

## Key Rules

- Never write code without a Scope (or a valid fast-track gate pass)
- Never deliver without an approved Plan (on the full loop)
- Be certain before marking a parent issue Done — verify every acceptance criterion against the delivered artefact (PR merged, CI green, smoke-test evidence) and confirm all sub-issues are Done. AI may close parent issues when those conditions hold.
- Always document Plans on the parent issue
- Always read ARCHITECTURE.md before planning
- Flag any architectural conflicts before proceeding
- Never create sub-issues on the fast-track path
- Never misuse `/spade-quick` for work that fails any gate criterion

<!--
  Framework-repo note: consumer repos carry a compressed SPADE section
  between `SPADE-FRAMEWORK-START vX.Y.Z` and `SPADE-FRAMEWORK-END`
  markers. This repo is the framework itself, so the content above IS
  the source of truth and no wrapped block is needed. /spade-onboard
  refuses to run here.
-->
