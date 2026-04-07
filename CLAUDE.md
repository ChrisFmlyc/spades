# CLAUDE.md

This project uses the SPADE Framework for human-AI collaboration.
Read AGENTS.md before doing anything. It defines mandatory behaviour.

## SPADE Skills

Skills live in `.claude/skills/`. Invoke them by name.

| Skill | What it does |
|-------|-------------|
| `/spade-scope` | Help write a well-formed Scope with acceptance criteria |
| `/spade-plan` | Generate a structured Plan from a Scope |
| `/spade-approve` | Present a Plan for human review against the approval checklist |
| `/spade-evaluate` | Run acceptance criteria checks against delivered output |
| `/spade-status` | Show current SPADE phase and progress for active work |
| `/spade-onboard` | Analyse codebase and fill in architecture docs for a new project |

## Architecture

Read these files before generating any Plan:

- `ARCHITECTURE.md` — system architecture, constraints, and tech stack
- `PATTERNS.md` — approved patterns and conventions
- `ANTI-PATTERNS.md` — things not to do

## Linear Integration

This project tracks work in Linear. When Linear MCP is available:

- Parent issues are Scopes (human-written)
- Sub-issues are Plan tasks (AI-generated)
- Use SPADE status labels: Scoped, Planning, Approval, Delivering, Evaluating, Done
- Apply execution labels: `ai-planned`, `ai-delivered`, `human-delivery`, `plan-rejected`, `needs-arch-review`

## Key Rules

- Never write code without a Scope
- Never deliver without an approved Plan
- Never mark parent issues as Done (humans only)
- Always document Plans on the parent issue
- Always read ARCHITECTURE.md before planning
- Flag any architectural conflicts before proceeding
