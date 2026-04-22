---
name: spade-plan
description: Generate a structured SPADE Plan from a Scope. Use when a Scope exists and the human wants to move to planning, when someone says "plan this", "generate a plan", "break this down", or when an issue is in "Scoped" status and needs a plan. Also triggers when a human references a Linear issue and asks the AI to plan against it.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using the
Bash tool and show the output to the user if it is non-empty. If the script
does not exist or fails, skip silently and continue with the skill.

## Project Config

Read `.spade/config` in the current project directory. This file specifies
which Linear team, project, and default assignee to use. Use these values
for all Linear operations. If the file doesn't exist, ask the human which
team and project to use, or suggest running `/spade-onboard` first.

# SPADE Plan

You are generating a structured Plan for an approved Scope. The Plan is a
first-class artefact that gets documented and attached to the parent issue.
It is not something that happens invisibly.

## Conversational Style

Planning is collaborative, not a monologue. You generate the Plan, but
the human validates it before anything gets created in Linear.

**How to run this conversation:**

1. **Start by showing your understanding.** Before producing any tasks,
   summarise what you understand from the Scope in 3-4 sentences. Ask
   the human to confirm or correct. This catches misunderstandings early.
2. **Propose the plan, then discuss.** Present the full draft plan, then
   ask targeted questions: "Does the task breakdown feel right? Is there
   anything I'm underestimating? Should any of these be human-delivered
   instead?"
3. **Challenge your own assumptions.** Call out where you're guessing:
   "I'm assuming the Databricks connector supports scheduled queries —
   is that confirmed, or should Task 1 include a spike?"
4. **Be opinionated about task sizing.** If a task feels too large, say
   so and propose a split. If two tasks could be one, suggest merging.
5. **Ask about delivery preference.** Don't assume everything is
   AI-delivered. Some tasks need human context — flag these explicitly.
6. **Iterate before committing.** Do NOT create sub-issues in Linear
   until the human explicitly approves. The plan may need 2-3 rounds.

## Before You Start

1. Read the Scope carefully. Understand the intent, acceptance criteria, and
   constraints.
2. Read ARCHITECTURE.md, PATTERNS.md, and ANTI-PATTERNS.md if they exist in
   the repository. Your Plan must conform to these documents.
3. **Check `.spade/learnings/` for prior learnings.** If the directory
   exists, glob `.spade/learnings/*.md` (ignore `private/` unless the
   human explicitly opts in). For each file, read the frontmatter and
   surface entries that match the current Scope.

   **Cold-start threshold (v1.1.1).** Count the number of active
   non-archived entries under `.spade/learnings/` (exclude
   `status: archived` and the `private/` subdirectory unless
   opted-in). Call this count `N`.

   - When `N < 20`, the tag-match threshold is **1** — a single shared
     tag is enough to surface a learning. This is the cold-start
     regime: a repo adopting SPADE starts with zero learnings, so
     `≥ 2` means the loop looks dead on day one.
   - When `N ≥ 20`, the tag-match threshold is **2** — require at
     least two matching tags to surface a learning. At this volume
     single-tag coincidence becomes noise; the higher bar filters it.
   - The scope_ref path is unaffected by the threshold. An entry
     whose `scope_ref` equals the current Scope's Linear identifier
     always surfaces, regardless of `N`.

   So the match rule is: an entry surfaces if its `scope_ref` equals
   the current Scope's identifier OR at least `T` of its `tags` appear
   (case-insensitive, word-boundary match) in the Scope title or the
   tech stack row of `ARCHITECTURE.md`, where `T = 1 if N < 20 else 2`.

   Skip entries with `status: archived`.

   The `20` is a deliberate, named number. Changing it requires a new
   Scope. The rationale is documented in
   `docs/FRAMEWORK.md#learnings`.
4. If the Scope references specific systems or components, review the relevant
   code or documentation to understand the current state.
5. If the Scope is missing required fields, flag this and suggest running
   `/spade-scope` to complete it before planning.

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
- **Execution posture**: one of `test-first`, `characterization-first`,
  `refactor-first`, `spike`, or `straight-through`. This is a required
  field on every task — see the posture selection guide below.

### Choosing an execution posture

Posture declares the delivery strategy for a task: not *what* to build
but *how* to approach the build. The canonical vocabulary and definitions
live in `docs/FRAMEWORK.md#execution-posture`. Quick selection:

- **`test-first`** — the desired behaviour is well-specified; write
  failing tests first, then satisfy them. Default for new features with
  clear acceptance criteria.
- **`characterization-first`** — touching existing code without adequate
  tests; pin down current behaviour in tests *before* changing it.
  Default for bug fixes and refactors of untested code.
- **`refactor-first`** — the area can't cleanly absorb the new behaviour;
  reshape it first, then add the new behaviour. The Plan must name the
  refactor explicitly so reviewers can confirm it's in scope.
- **`spike`** — the correct approach is genuinely unknown; the task's
  output is *learning*, not shippable code. A spike-postured task should
  produce a decision record or follow-up task, not a merged PR.
- **`straight-through`** — the change is mechanical enough that extra
  ceremony adds no value (typo fixes, config bumps, docs edits, one-liners
  covered by existing tests). **Not a silent default.** If you choose
  this, state the justification in the task body (usually "covered by
  existing tests" or "mechanical change"). If you can't justify it,
  pick a different posture.

A task may declare mixed posture when the work naturally splits — e.g.
`characterization-first on the existing module; test-first on the new
behaviour`. Write it on a single line.

### Technical Approach

For each task, explain the technical approach:
- What will be built and how
- Which existing patterns from PATTERNS.md apply
- Which libraries or tools will be used
- How it integrates with existing code

### Prior Learnings Considered

If any `.spade/learnings/*.md` entries matched the Scope (see "Before You
Start" step 3), include a **Prior Learnings Considered** section near the
top of the Plan. Each matched learning gets:

1. The learning's title (verbatim, from its frontmatter).
2. Its filename in parentheses, e.g. `(2026-04-22-onboarding-must-be-idempotent.md)`.
3. A one-line note on how the Plan honours it.
4. **A match-reason log line (v1.1.1)** underneath, showing *why* the
   learning surfaced. This lets a human scanning the Plan see when
   matching is off:
   - `Match reason: scope_ref=<ID>` when the scope_ref path fired.
   - `Match reason: tags matched [<tag1>, <tag2>, ...]` when the tag
     path fired — list only the tags that actually matched the Scope
     title / tech stack, not the entry's full tag set.

If a matched learning has `status: archived`, do not include it.
(The framework has no "supersedes" field — `/spade-learn --refresh`
resolves conflicts by archiving the superseded entry explicitly, so
the archived filter is the single source of truth.)

If no entries match, do not include the section at all. Silence is
cheaper than padding — no "no matches found" line.

Example (cold-start regime, one-tag match):

```markdown
### Prior Learnings Considered

- *Any write into a consumer file must be idempotent via delimited markers*
  (`2026-04-22-onboarding-must-be-idempotent.md`) — Plan Bundle A extends
  the existing `spade-marker-replace` contract rather than inventing a
  new mechanism.
  Match reason: tags matched [markers]
```

Example (scope_ref match):

```markdown
### Prior Learnings Considered

- *For review and evaluation gates, a panel of persona-specific reviewers
  beats one generalist*
  (`2026-04-22-single-reviewer-is-weaker-than-panel.md`) — this Scope
  preserves the panel shape; only adds verifiability layers.
  Match reason: scope_ref=M-323
```

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

### Delivery Bundles

Group the tasks into **delivery bundles**. A bundle is the unit of shipping:
one branch, one pull request, closing every sub-issue assigned to it.

**Default: a single bundle containing every task in the Scope.** Six
interlinked tasks should not produce six PRs. Reviewers want the whole
story in one place, and interlinked code that moves together should land
together.

**Only split into multiple bundles when all of these hold:**

- The tasks are genuinely independent — no shared files, no shared
  symbols, and no dependency arrows between them.
- Splitting yields real value: isolated review, isolated revert, or
  independent deploy timing (e.g. a risky migration separated from
  related feature code, or docs-only work separated from code).
- The split does not force the reviewer to mentally stitch the Scope
  back together to understand either half.

If you are unsure, use one bundle. You can always split later; you cannot
easily re-merge six PRs.

For each bundle, specify:

- **Bundle name**: Short identifier, e.g. `etl-core`
- **Branch name**: Suggested git branch, e.g. `spade/M-68-etl-core`
- **PR title**: What the PR will be called
- **Tasks included**: Which task numbers land in this bundle
- **Rationale**: Why this grouping (especially if splitting from the default)

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
- **Execution posture:** test-first | characterization-first | refactor-first | spike | straight-through
- **Description:** [What needs to be done]
- **Approach:** [How it will be done]
- **Tests:** [What tests / what evidence of completion]

[Repeat for each task]

### Delivery Sequence
1. [Task X] (no dependencies, start immediately)
2. [Task Y] (depends on Task X)
3. [Task Z] and [Task W] (parallel, both depend on Task Y)

### Delivery Bundles

#### Bundle 1: [name]
- **Branch:** spade/[issue-id]-[name]
- **PR title:** [title]
- **Tasks:** Task 1, Task 2, Task 3, Task 4
- **Rationale:** Single bundle — all tasks share the ETL module and must
  land together to keep the pipeline coherent.

[If splitting, repeat per bundle with rationale for the split]
```

## Saving the Plan

The Plan is stored in two places: locally in the repo AND in Linear.
Both happen when the human approves the plan (not before).

### Local Storage

Write the approved Plan to `.spade/plans/` using the issue identifier
as the filename:

```
.spade/plans/M-68-plan.md
```

The file should contain:
- The full plan in the output format above
- A metadata header with the issue ID, title, date, and status

Example header:

```markdown
---
issue: M-68
title: Build ETL pipeline for device telemetry
date: 2026-04-08
status: approved
---
```

Create the `.spade/plans/` directory if it doesn't exist. If a plan file
already exists for this issue (from a previous revision), overwrite it —
the git history preserves the old version.

After writing the file, suggest the human commit it:

```bash
git add .spade/plans/M-68-plan.md
git commit -m "SPADE plan for M-68: Build ETL pipeline"
```

### Linear Integration

If Linear MCP is available:
1. Update the parent issue status to "Planning"
2. Create sub-issues for each task with:
   - Title and description from the Plan
   - Label: `ai-planned`
   - Label: `ai-delivered` or `human-delivery` as appropriate
   - Label: `needs-arch-review` if the task touches architecture
   - Label: `bundle:<bundle-name>` so delivery can group them under one PR
   - Priority set based on delivery sequence
3. Attach the full Plan document (including the Delivery Bundles section)
   as a comment on the parent issue
4. Update the parent issue status to "Approval" when the Plan is ready

## After Planning

After presenting the Plan, explicitly ask the human to review and approve it.
Do not begin delivery. Do NOT save the plan locally or create sub-issues
until the human approves. Say something like:

"The Plan is ready for your review. Please check it against architecture
alignment, completeness, feasibility, risk, task granularity, and delivery
bundling. Let me know if you want changes, or approve it so I can begin
delivery."

Once approved:
1. Write the plan to `.spade/plans/`
2. Create sub-issues in Linear
3. Post the plan as a comment on the parent issue
4. Update the parent issue status to "Approval"

You must wait for explicit approval before proceeding to Deliver.

## Plan Revision

If the human requests changes:
1. Apply the `plan-rejected` label to the parent issue (if Linear available)
2. Revise the Plan based on their specific feedback
3. Present the revised Plan for approval again
4. Once re-approved, update the local plan file and Linear sub-issues
5. Remove `plan-rejected` and update status to "Approval" when ready
