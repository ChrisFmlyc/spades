
# SPADE Framework — Agent Operating Rules

These rules define mandatory behaviour for AI agents using the SPADE framework
in this project. They augment any existing agent instructions in this file.

## The SPADE Loop

Every unit of work follows five phases:

    SCOPE → PLAN → APPROVE → DELIVER → EVALUATE

Humans own Scope and Evaluate. AI owns Plan and Deliver. Approve is a human gate.
You must never skip a phase or combine phases without explicit human instruction.

## Phase Rules

### 1. Scope (Human-Owned)
- Never begin planning or writing code without a written Scope.
- A Scope must include: statement of intent, acceptance criteria, and constraints.
- If asked to "just do X" without a Scope, help define one first.

### 2. Plan (AI-Owned)
- Produce a structured Plan (3-7 tasks) before writing any code.
- Include: technical approach, dependencies, risks, delivery mode, testing strategy.
- Document the Plan on the parent issue as a first-class artefact.
- Create sub-issues with labels: `ai-planned`, `ai-delivered` or `human-delivery`.
- Do NOT begin delivery until the Plan is approved by a human.

### 3. Approve (Human Gate)
- After producing a Plan, STOP and wait for human approval.
- If rejected, apply `plan-rejected` label, revise, and re-present.
- Do not begin delivery on a rejected or unapproved plan.

### 4. Deliver (AI or Human)
- Execute tasks one sub-issue at a time from the approved Plan.
- Run tests and verify before marking tasks complete.
- If delivery reveals the Plan is wrong, stop and explain before continuing.

### 5. Evaluate (Human-Owned)
- Never mark a parent issue as Done. Only humans do this.
- If asked to help evaluate, run acceptance criteria checks and report results.

## Architecture Constraints

Before generating any Plan, read these files if they exist:
- `ARCHITECTURE.md` — system architecture and constraints
- `PATTERNS.md` — approved patterns and conventions
- `ANTI-PATTERNS.md` — things you must not do

Flag any conflicts between proposed solutions and these documents.

## Linear Integration

When Linear MCP is available, use it to:
- Read Scopes from parent issues
- Create sub-issues for Plans with labels and priorities
- Update statuses: Scoped → Planning → Approval → Delivering → Evaluating → Done
- Attach Plan documents as comments on parent issues

## Audit Trail

Every piece of work must have: a human-written Scope, a documented Plan,
an Approval decision, delivery records with labels, and a human Evaluation.
Work that cannot be traced through this chain must not be delivered.

## What You Must Never Do

- Begin coding without a documented Scope
- Begin delivery without an approved Plan
- Mark a parent issue as Done
- Skip documenting the Plan
- Introduce technologies conflicting with ARCHITECTURE.md without flagging it
- Assume organisational context you do not have
