# SPADE Framework — Agent Operating Rules

This file defines mandatory behaviour for all AI agents operating in this project.
These rules are non-negotiable. If you are an AI agent reading this file, you must
follow every instruction below. Violations of the SPADE loop undermine the audit
trail and the trust model that makes human-AI collaboration safe.

## The SPADE Loop

Every unit of work in this project follows five phases:

    SCOPE → PLAN → APPROVE → DELIVER → EVALUATE

Humans own Scope and Evaluate. AI owns Plan and Deliver. Approve is a human gate.
You must never skip a phase or combine phases without explicit human instruction.

## Phase Rules

### 1. Scope (Human-Owned)

- You must NEVER begin planning or writing code without a written Scope.
- A Scope is a parent issue (in Linear or your project tracker) with:
  - A clear statement of intent (what and why)
  - Acceptance criteria (how we know it is done)
  - Architectural constraints (tech stack, patterns, security requirements)
- If a human asks you to "just do X" without a Scope, ask them to define one first.
  Help them write it if needed, but do not proceed to Plan without a documented Scope.
- Scopes may originate from OKRs, milestones, or reactive work (tickets, incidents).
  The origin does not matter. The clarity of intent does.

### 2. Plan (AI-Owned)

- When a Scope exists, you produce a structured Plan before writing any code.
- The Plan must include:
  - 3-7 discrete tasks, each completable in a focused session
  - Technical approach and rationale for each task
  - Dependencies between tasks
  - Risk callouts (assumptions, unknowns, things that might go wrong)
  - Which tasks are AI-delivered vs human-delivered
  - Testing and verification approach (what tests, what "passing" looks like)
- The Plan is a first-class artefact. You must:
  - Document it as a comment or attached document on the parent issue
  - Create sub-issues for each task with appropriate labels
  - Apply labels: `ai-planned`, and either `ai-delivered` or `human-delivery` per task
- You must NOT begin delivery until the Plan is approved by a human.
- If using Linear via MCP, create sub-issues on the parent issue automatically.
  Set status on the parent issue to "Planning" while generating the plan.

### 3. Approve (Human Gate)

- After producing a Plan, you must STOP and wait for human approval.
- Present the Plan clearly and ask the human to review it against:
  - Architecture alignment (does this fit established patterns?)
  - Completeness (are there obvious gaps?)
  - Feasibility (can this actually be built this way?)
  - Risk (are assumptions valid?)
  - Scope (is the task breakdown at the right granularity?)
- If the human rejects the Plan or requests changes:
  - Apply the `plan-rejected` label to the parent issue
  - Revise the Plan based on their specific feedback
  - Present the revised Plan for approval again
  - Do not begin delivery on a rejected plan
- If the human approves, update the parent issue status to "Delivering".
- A fast approval is acceptable for low-risk, granular tasks.
  A thorough review is mandatory for tasks touching architecture, security,
  or cross-system boundaries.

### 4. Deliver (AI or Human)

- Execute tasks from the approved Plan, one sub-issue at a time.
- For each AI-delivered task:
  - Read the sub-issue context before starting
  - Write code, tests, configuration, or documentation as specified
  - Run tests and verify they pass before marking complete
  - Update the sub-issue status to "Done" when complete
  - Apply the `ai-delivered` label if not already present
- For human-delivered tasks:
  - Leave the task clearly described with all necessary context
  - Do not attempt work that requires organisational context, physical access,
    stakeholder relationships, or decisions you cannot make
- If you encounter a problem during delivery that invalidates the Plan:
  - Stop delivering
  - Explain what went wrong
  - Suggest whether a Plan revision or Scope revision is needed
  - Wait for human guidance before continuing

### 5. Evaluate (Human-Owned)

- After all sub-issues are complete, the human evaluates the output against
  the original Scope's acceptance criteria.
- You must NOT mark the parent issue as "Done". Only a human can do this.
- If asked to help with evaluation, you may:
  - Run the acceptance criteria as checks and report results
  - Highlight areas where output may not fully meet the Scope
  - Suggest additional verification steps
- If evaluation fails:
  - Minor issues: work goes back to Deliver with specific fix instructions
  - Fundamental issues: work goes back to Plan for a revised approach

## Architecture Constraints

Before generating any Plan, you must read the following files if they exist in this
repository. These define the architectural boundaries you must operate within:

- `ARCHITECTURE.md` — system architecture, infrastructure, and data flow
- `PATTERNS.md` — approved patterns, libraries, and conventions
- `ANTI-PATTERNS.md` — things you must not do, with rationale

If a proposed solution conflicts with these documents, you must flag the conflict
in the Plan and get explicit human approval before proceeding.

## Linear Integration

When Linear MCP is available, you must use it to:

- Read Scope from parent issues (including acceptance criteria and constraints)
- Create sub-issues for the Plan with descriptions, labels, and priorities
- Update issue statuses as work progresses through SPADE phases
- Attach Plan documents as comments on the parent issue
- Apply labels consistently: `ai-planned`, `ai-delivered`, `human-delivery`,
  `plan-rejected`, `needs-arch-review`

Parent issue statuses map to SPADE phases:

| Status      | SPADE Phase |
|-------------|-------------|
| Scoped      | S           |
| Planning    | P           |
| Approval    | A           |
| Delivering  | D           |
| Evaluating  | E           |
| Done        | ✓           |

Sub-issues use a simpler workflow: Todo → In Progress → Done.

## Audit Trail

Every piece of work must have a traceable chain:

1. A human-written Scope (the "what")
2. An AI-generated Plan (the "how"), documented on the issue
3. An Approval decision (the "approved by")
4. Delivery records (the "done"), with labels showing who delivered each task
5. An Evaluation (the "verified"), done by a human

You must never deliver work that cannot be traced back through this chain.
This is not optional. The audit trail is the mechanism by which AI-delivered
work remains trustworthy.

## Reactive and Unplanned Work

Not all work originates from OKRs. Tickets, incidents, and ad-hoc requests follow
the same SPADE loop, but the ceremony scales to the size of the work:

- Small reactive items (bug fix, config change): the ticket is the Scope.
  Planning may be a single comment proposing an approach. Approval is a quick check.
  The loop still exists; it just runs in minutes.
- Larger reactive work (incident response, multi-system investigation): gets a
  proper parent issue, scoped with acceptance criteria, and runs the full loop.

## What You Must Never Do

- Begin writing code without a documented Scope
- Begin delivery without an approved Plan
- Mark a parent issue as Done (only humans do this)
- Skip the Plan documentation step (plans are artefacts, not ephemeral)
- Introduce technologies or patterns that conflict with ARCHITECTURE.md
  without flagging the conflict and getting explicit approval
- Assume organisational context you do not have (ask the human)
- Combine multiple Scopes into one delivery without human agreement
