
# SPADE Framework — Agent Operating Rules

These rules define mandatory behaviour for AI agents using the SPADE framework
in this project. They augment any existing agent instructions in this file.

## The SPADE Loop

Every unit of work follows five phases:

    SCOPE → PLAN → APPROVE → DELIVER → EVALUATE

Humans own Scope and Evaluate. AI owns Plan and Deliver. Approve is a human gate.
You must never skip a phase or combine phases without explicit human instruction.

**Exception — the fast-track path.** Trivial work (a typo, a one-line tweak,
a config nudge) can use `/spade-quick` instead of the full loop. See the
"Fast-Track Path" section below for the gate criteria. When in doubt, use
the full loop.

## Phase Rules

### 1. Scope (Human-Owned)
- Never begin planning or writing code without a written Scope.
- A Scope must include: statement of intent, acceptance criteria, and constraints.
- If asked to "just do X" without a Scope, help define one first.
- **Before scoping, check the fast-track gate.** If every criterion below
  passes, invoke `/spade-quick` instead of `/spade-scope`.

### 2. Plan (AI-Owned)
- Produce a structured Plan (3-7 tasks) before writing any code.
- Include: technical approach, dependencies, risks, delivery mode, testing strategy, delivery bundles, and per-task **execution posture**.
- Execution posture is one of `test-first`, `characterization-first`, `refactor-first`, `spike`, or `straight-through`. Every task must declare one — there is no silent default. See `docs/FRAMEWORK.md#execution-posture` for the vocabulary.
- Delivery bundles map tasks to pull requests. Default to one bundle (one PR)
  per Scope. Only split when tasks are genuinely independent and isolated
  review or revert provides real value.
- Document the Plan on the parent issue as a first-class artefact.
- Create sub-issues with labels: `ai-planned`, `ai-delivered` or `human-delivery`.
- Do NOT begin delivery until the Plan is approved by a human.

### 3. Approve (Human Gate)
- After producing a Plan, STOP and wait for human approval.
- If rejected, apply `plan-rejected` label, revise, and re-present.
- Do not begin delivery on a rejected or unapproved plan.
- **Panel second opinion (optional).** The human may request `/spade-review` for
  an independent perspective before deciding. The panel spawns five persona
  subagents (scope-guardian, architecture-strategist, security-lens,
  yagni-simplicity, adversarial-reviewer), merges their structured findings
  into a single deduped report, and presents it. Non-blocking, informational
  only — the panel never gates approval or delivery.

### 4. Deliver (AI or Human)
- Execute the approved Plan one **delivery bundle** at a time. A bundle is
  one branch and one PR that closes every sub-issue assigned to it.
- Within a bundle, work through sub-issues in dependency order, committing
  as you go. Do not open a separate PR per sub-issue inside the same bundle.
- Run tests and verify before marking sub-issues complete.
- If delivery reveals the Plan is wrong, stop and explain before continuing.

### 5. Evaluate (Human-Owned)
- Never mark a parent issue as Done. Only humans do this.
- If asked to help evaluate, run acceptance criteria checks and report results.
- **Capture learnings.** After Evaluate — or anytime during delivery when the
  team notices something worth remembering for future work — suggest
  `/spade-learn` to record it under `.spade/learnings/`. `/spade-plan`
  surfaces matching learnings automatically on the next related Scope.

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

### Evaluating quick-path work

`/spade-evaluate` on a `spade:quick`-labelled issue validates the PR
directly (merged, CI green, checklist complete) instead of iterating
sub-issues. If evaluation is PARTIAL: fixes go as new commits on the
same branch if the PR hasn't merged, or as a new quick-path PR referencing
the original if it has. **Sub-issue creation is forbidden on the quick
path regardless of verdict.**

## Architecture Constraints

Before generating any Plan, read these files if they exist:
- `ARCHITECTURE.md` — system architecture and constraints
- `PATTERNS.md` — approved patterns and conventions
- `ANTI-PATTERNS.md` — things you must not do

Flag any conflicts between proposed solutions and these documents.

## Linear Integration

When Linear MCP is available, use it to:
- Read Scopes from parent issues
- Create sub-issues for Plans with labels and priorities (full loop only)
- Update statuses: Scoped → Planning → Approval → Delivering → Evaluating → Done
- Attach Plan documents as comments on parent issues
- Apply `spade:quick` and `type:*` labels on fast-track items

## Audit Trail

Every piece of work must have: a human-written Scope, a documented Plan,
an Approval decision, delivery records with labels, and a human Evaluation.
Work that cannot be traced through this chain must not be delivered.

For fast-track work, the PR description carries the equivalent audit
trail — the gate checklist, the type classification, the verification
notes, and the link to Linear (if any). A quick-path PR without a filled
template is not a valid audit trail.

## What You Must Never Do

- Begin coding without a documented Scope (or a valid fast-track gate pass)
- Begin delivery without an approved Plan (on the full loop)
- Mark a parent issue as Done
- Skip documenting the Plan
- Misuse `/spade-quick` for work that fails any gate criterion
- Create sub-issues on the fast-track path
- Introduce technologies conflicting with ARCHITECTURE.md without flagging it
- Assume organisational context you do not have
