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

**Exception — the fast-track path.** Trivial work (a typo, a one-line tweak,
a config nudge) can use `/spade-quick` instead of the full loop. See the
"Fast-Track Path (Small Work)" section below for the gate criteria. When
in doubt, use the full loop.

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
- **Before writing a Scope, check the fast-track gate.** If every criterion
  in "Fast-Track Path (Small Work)" below passes, invoke `/spade-quick`
  instead of `/spade-scope`. The full loop is for work that deserves the
  ceremony; trivial changes deserve speed.

### 2. Plan (AI-Owned)

- When a Scope exists, you produce a structured Plan before writing any code.
- The Plan must include:
  - 3-7 discrete tasks, each completable in a focused session
  - Technical approach and rationale for each task
  - Dependencies between tasks
  - Risk callouts (assumptions, unknowns, things that might go wrong)
  - Which tasks are AI-delivered vs human-delivered
  - Testing and verification approach (what tests, what "passing" looks like)
  - Delivery bundles: how tasks map to pull requests. Default is one bundle
    (one PR) per Scope. Only split into multiple bundles when tasks are
    genuinely independent — no shared files or symbols, no dependency arrows,
    and isolated review or revert provides real value (e.g. a risky migration
    separated from related feature code, or docs-only work separated from code).
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
- **Panel second opinion (optional).** Before deciding, the human may request
  a panel review via `/spade-review`. It spawns four persona subagents —
  scope-guardian, architecture-strategist, security-lens,
  adversarial-reviewer — in parallel where the runtime supports it. Each
  returns structured findings; the coordinating skill merges them by
  convergence and presents a tiered report. Non-blocking: the panel never
  gates approval or delivery.

### 4. Deliver (AI or Human)

- Execute tasks from the approved Plan one **delivery bundle** at a time.
  A bundle is a single branch and a single pull request that closes one or
  more sub-issues. The approved Plan defines which tasks belong to which
  bundle. The default is one bundle per Scope.
- For each bundle:
  - Create one branch for the whole bundle
  - Work through the sub-issues in dependency order, committing as you go
  - Open a single PR that closes every sub-issue in the bundle
    (e.g. `Closes M-68-1, Closes M-68-2`)
  - Do not open additional PRs for sub-issues inside the same bundle
- For each AI-delivered task within a bundle:
  - Read the sub-issue context before starting
  - Write code, tests, configuration, or documentation as specified
  - Run tests and verify they pass before marking the sub-issue complete
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
- You may mark the parent issue as "Done" once you have verified every
  acceptance criterion against the delivered artefact (PR merged, CI
  green, smoke-test or evaluation evidence in hand) and every sub-issue
  is Done. Be certain before flipping it — Done is the audit-trail
  endpoint and downstream readers treat it as authoritative. If you are
  not certain, leave it in "Evaluating" and surface the gaps to the
  human.
- If asked to help with evaluation, you may:
  - Run the acceptance criteria as checks and report results
  - Highlight areas where output may not fully meet the Scope
  - Suggest additional verification steps
- If evaluation fails:
  - Minor issues: work goes back to Deliver with specific fix instructions
  - Fundamental issues: work goes back to Plan for a revised approach
- **Capture learnings.** After Evaluate, or anytime during delivery when the
  team notices something worth carrying forward, suggest `/spade-learn` to
  record it under `.spade/learnings/`. `/spade-plan` surfaces matching prior
  learnings automatically when a related Scope comes through next time, so
  each pass of the loop strengthens the next.

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

## Fast-Track Path (Small Work)

Not every change deserves a Scope. The fast-track path handles trivial work
— typo fixes, one-line tweaks, small config nudges, docs changes — through
`/spade-quick`. On this path, the **PR description is the audit artefact**:
no sub-issues, no separate Plan, no approval gate beyond PR review.

**When a human describes a small fix, tweak, config nudge, or docs change,
check the fast-track gate BEFORE invoking `/spade-scope`.** If every
criterion below passes, run `/spade-quick`. Only fall back to the full
loop if the gate fails.

### The Gate — ALL must be true

1. Single concern (one bug, one tweak, one touch-up)
2. ≤ 50 lines of code changed total; hard stop above ~100
3. One file, or a tight cluster in one module
4. No new dependencies (package.json / go.mod / pyproject / Cargo.toml untouched)
5. No schema, migration, or data-layer changes
6. No architectural changes, no new patterns, no new abstractions
7. No security-sensitive code (auth, crypto, secrets, permissions)
8. No public API or interface breaking changes
9. Revertable as one commit
10. Existing tests cover the area (trivial extension is fine; new test
    scaffolding is not)

If *any* criterion fails, stop and invoke `/spade-scope` for the full loop.
The gate is all-or-nothing — do not attempt to "partially" fast-track.

### Linear tracking on the fast-track

- Parent issue gets labels: `spade:quick`, one `type:*` label
  (`type:bug`, `type:tweak`, `type:chore`, `type:docs`, `type:refactor`),
  and `ai-delivered` or `human-delivery`.
- **No sub-issues are created.** The parent issue IS the work unit.
- The PR description is the audit trail. PR URL is posted as a comment on
  the parent issue. Human owns the Done transition, as always.

### Incident response

Incidents and larger reactive work do NOT use the fast-track path. Ceremony
is cheap during an incident — use the full loop so the audit trail is
complete.

### Evaluating quick-path work

`/spade-evaluate` on a `spade:quick`-labelled issue validates the PR
directly (merged, CI green, checklist complete) instead of iterating
sub-issues. If evaluation is PARTIAL: fixes go as new commits on the
same branch if the PR hasn't merged, or as a new quick-path PR referencing
the original if it has. **Sub-issue creation is forbidden on the quick
path regardless of verdict.**

## What You Must Never Do

- Begin writing code without a documented Scope (or a valid fast-track gate pass)
- Begin delivery without an approved Plan (on the full loop)
- Mark a parent issue as Done (only humans do this)
- Skip the Plan documentation step (plans are artefacts, not ephemeral)
- Misuse `/spade-quick` for work that fails any gate criterion
- Create sub-issues on the fast-track path
- Introduce technologies or patterns that conflict with ARCHITECTURE.md
  without flagging the conflict and getting explicit approval
- Assume organisational context you do not have (ask the human)
- Combine multiple Scopes into one delivery without human agreement

<!--
  Framework-repo note: this file is the canonical SPADE agent operating
  rules. Consumer repos carry a compressed, fragment-wrapped subset of
  the rules above, delimited by `SPADE-FRAMEWORK-START vX.Y.Z` and
  `SPADE-FRAMEWORK-END` markers. We deliberately do NOT carry that block
  here — this repo is the source of truth. The /spade-onboard skill
  refuses to run inside this repository for the same reason.
-->
