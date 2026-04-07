---
name: spade-plan
description: Generate a structured SPADE Plan from a Scope. Use when a Scope exists and the human wants to move to planning, when someone says "plan this", "generate a plan", "break this down", or when an issue is in "Scoped" status and needs a plan. Also triggers when a human references a Linear issue and asks the AI to plan against it.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using the
Bash tool and show the output to the user if it is non-empty. If the script
does not exist or fails, skip silently and continue with the skill.

# SPADE Plan

You are generating a structured Plan for an approved Scope. The Plan is a
first-class artefact that gets documented and attached to the parent issue.
It is not something that happens invisibly.

## Before You Start

1. Read the Scope carefully. Understand the intent, acceptance criteria, and
   constraints.
2. Read ARCHITECTURE.md, PATTERNS.md, and ANTI-PATTERNS.md if they exist in
   the repository. Your Plan must conform to these documents.
3. If the Scope references specific systems or components, review the relevant
   code or documentation to understand the current state.

## Plan Structure

Every Plan must include:

### Tasks (3-7)

Break the Scope into 3-7 discrete tasks. Each task must be:

- **Small enough** to complete in a focused session (2-4 hours of AI work,
  or a comparable human effort)
- **Independent enough** to pick up without extensive context-switching
  (though dependencies between tasks are normal)
- **Clearly scoped** so the deliverer knows when they are done

For each task, specify:

- **Title**: Short, descriptive
- **Description**: What needs to be built/done
- **Delivery mode**: `ai-delivered` or `human-delivery`
- **Dependencies**: Which other tasks must complete first
- **Estimated effort**: Brief (< 1 hour), moderate (1-4 hours), significant (4+ hours)

### Technical Approach

For each task, explain the technical approach:
- What will be built and how
- Which existing patterns from PATTERNS.md apply
- Which libraries or tools will be used
- How it integrates with existing code

### Risk Callouts

Identify risks and assumptions:
- What might go wrong?
- What assumptions are being made?
- Where might the Plan need to change based on what we discover during delivery?
- Are there any ANTI-PATTERNS.md conflicts to flag?

### Testing and Verification

For each task:
- **Software tasks**: What tests are expected (unit, integration, E2E)?
  What does "passing" look like?
- **Non-software tasks**: What evidence demonstrates completion?

### Delivery Sequence

Present the tasks in recommended execution order, noting which can run in
parallel and which are sequential.

## Output Format

Present the Plan in this format:

```
## Plan for: [Scope Title]

**Technical Approach Summary:**
[2-3 sentence overview of the overall approach]

**Risks and Assumptions:**
- [Risk 1]
- [Risk 2]

### Tasks

#### Task 1: [Title]
- **Mode:** ai-delivered | human-delivery
- **Depends on:** none | Task N
- **Effort:** brief | moderate | significant
- **Description:** [What needs to be done]
- **Approach:** [How it will be done]
- **Tests:** [What tests / what evidence of completion]

[Repeat for each task]

### Delivery Sequence
1. [Task X] (no dependencies, start immediately)
2. [Task Y] (depends on Task X)
3. [Task Z] and [Task W] (parallel, both depend on Task Y)
```

## Linear Integration

If Linear MCP is available:
1. Update the parent issue status to "Planning"
2. Create sub-issues for each task with:
   - Title and description from the Plan
   - Label: `ai-planned`
   - Label: `ai-delivered` or `human-delivery` as appropriate
   - Label: `needs-arch-review` if the task touches architecture
   - Priority set based on delivery sequence
3. Attach the full Plan document as a comment on the parent issue
4. Update the parent issue status to "Approval" when the Plan is ready

## After Planning

After presenting the Plan, explicitly ask the human to review and approve it.
Do not begin delivery. Say something like:

"The Plan is ready for your review. Please check it against architecture
alignment, completeness, feasibility, risk, and task granularity. Let me
know if you want changes, or approve it so I can begin delivery."

You must wait for explicit approval before proceeding to Deliver.

## Plan Revision

If the human requests changes:
1. Apply the `plan-rejected` label to the parent issue (if Linear available)
2. Revise the Plan based on their specific feedback
3. Update sub-issues to reflect changes
4. Present the revised Plan for approval again
5. Remove `plan-rejected` and update status to "Approval" when ready
