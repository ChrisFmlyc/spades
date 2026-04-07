---
name: spade-approve
description: Present a SPADE Plan for human review against the approval checklist. Use when a Plan has been generated and needs approval, when someone says "review the plan", "check this plan", "approve", or when an issue is in "Approval" status. Also use when a human wants to see the approval checklist for a specific piece of work.
---

# SPADE Approve

You are helping a human review and approve (or reject) an AI-generated Plan.
Approval is a gate, not a rubber stamp. The biggest risk in SPADE is a weak
Approval gate.

## The Approval Checklist

Present each check to the human with your assessment, then ask for their
decision.

### 1. Architecture Alignment

- Does the Plan conform to ARCHITECTURE.md?
- Does it use approved patterns from PATTERNS.md?
- Does it avoid everything listed in ANTI-PATTERNS.md?
- Are any new technologies, databases, or frameworks being introduced?
  If so, flag with `needs-arch-review`.

**Your assessment:** [State whether the Plan aligns with architecture docs,
and flag any concerns]

### 2. Completeness

- Are there obvious gaps or missing edge cases?
- Does the Plan cover all acceptance criteria from the Scope?
- Is error handling addressed?
- Is the testing approach sufficient for the risk level?

**Your assessment:** [State whether you see gaps]

### 3. Feasibility

- Can this actually be built this way with the project's constraints?
- Are the effort estimates realistic?
- Are the dependencies between tasks correctly identified?
- Are there external dependencies (APIs, services, access) that might block?

**Your assessment:** [State whether the approach is feasible]

### 4. Risk

- Are the AI's assumptions valid?
- Are the identified risks genuine, or are there risks not mentioned?
- What is the worst case if the Plan is wrong?
- Is there a fallback approach if the primary approach fails?

**Your assessment:** [State your risk assessment]

### 5. Scope

- Is the task breakdown at the right granularity?
- Are tasks small enough for focused delivery sessions?
- Are there tasks that should be split further?
- Are there tasks that could be combined?
- Is the split between AI-delivered and human-delivered tasks correct?

**Your assessment:** [State whether the granularity is right]

## Approval Depth

Scale the review to the risk:

- **Architecture-touching work**: Deep review. Check every pattern choice,
  every new dependency, every integration point. Slow down.
- **Standard feature work**: Normal review. Verify approach and completeness.
  Check the acceptance criteria are covered.
- **Granular/low-risk tasks**: Light review. Quick sanity check that the
  approach is reasonable. Move fast.

If you are approving every plan in 30 seconds, the gate is not working.
If you are spending an hour on every trivial plan, the gate is a bottleneck.
Calibrate.

## Decision

After presenting the checklist, ask the human for one of:

1. **Approve** — Plan is good. Proceed to delivery.
2. **Approve with notes** — Plan is acceptable but note specific concerns
   to watch during delivery.
3. **Revise** — Plan needs changes. Specify what needs to change and why.
4. **Reject** — Fundamental approach is wrong. Go back to scoping or
   rethink the approach entirely.

## After Approval

If approved:
- Update parent issue status to "Delivering" (if Linear available)
- Record the approval decision as a comment on the parent issue
- Begin delivery of the first task

If revision requested:
- Apply `plan-rejected` label
- Revise the Plan per feedback
- Present revised Plan for approval

If rejected:
- Apply `plan-rejected` label
- Discuss whether the Scope needs revision or whether a completely
  different approach is needed
- Do not attempt to salvage the Plan if the human has rejected the
  fundamental approach
