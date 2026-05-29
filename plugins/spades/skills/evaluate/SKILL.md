---
name: evaluate
description: Check delivered output against a Plan's acceptance criteria. Returns PASS / PARTIAL / FAIL. Use after `/spades:do` has completed delivery, when someone says "evaluate this", "check if this is done", "verify the output", or when a Plan is in status `evaluating`. Quick-path items (`/spades:quick`) skip the full evaluation and validate the PR directly.
---

# /spades:evaluate

You are running the Evaluate gate. This is distinct from Approve:
Approve validates the *plan*; Evaluate validates the *output*.

Read `docs/FRAMEWORK.md` § .spades/ Local Layout and § Target
Resolution before running.

## Pre-Flight

1. **Confirm setup + active project.** Abort otherwise.
2. **Resolve the target** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill is unusual: it can take either a Plan or a
   Scope (whole-scope evaluation when every Plan under it is done).
   - **If the human passed an ID,** resolve directly: `P-<slug>-<suffix>`
     → Plan; `S-<slug>` → Scope.
   - **If invoked bare,** ask via `AskUserQuestion`:
     - *One plan* → Plan picker, status filter `delivering` or
       `evaluating`.
     - *Whole scope* → Scope picker, status filter `evaluating`.
   - **Zero-candidate suggestions:**
     - No Plans in `delivering`/`evaluating` → `/spades:do P-…` on an
       approved plan first.
     - No Scopes in `evaluating` → none yet — keep delivering Plans.
3. **Read the target.** Plan + parent Scope, OR Scope + every Plan
   under it.
4. **Read `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`.**

## Quick-Path Branch

If the target Scope (or the Plan's parent Scope) has the `quick` flag
set in its audit trail or carries a `spades:quick` label in Linear,
this is a fast-track item. Skip the full evaluation and validate the
PR directly:

1. Find the PR (search audit trail, or comments in Linear, or recent
   PRs in the repo referencing the issue).
2. Verify: merged or open; CI green; PR description follows the
   `/spades:quick` template (Type, What, Why, Verification, Gate
   checklist).
3. Validate the gate retrospectively — does the diff still satisfy
   every fast-track criterion?
4. Verdict (via `AskUserQuestion`):
   - **PASS** — PR merged, CI green, gate retrospect still holds
   - **PARTIAL** — small fix needed (new commits on same branch if
     PR open; new quick-path PR referencing original if merged)
   - **FAIL** — gate violated retrospectively; roll back and re-route
     through `/spades:scope` + full loop

Record the verdict via `record_evaluation`. No sub-issues are ever
created for quick-path items.

## Full-Loop Evaluation

For non-quick items, run the full checklist.

### Step 1 — Acceptance Criteria

For each acceptance criterion in the parent Scope:

1. **State the criterion** verbatim.
2. **Check the evidence** — run tests, inspect code, verify behaviour,
   check the artefact, etc.
3. **Verdict per criterion**: PASS / FAIL / PARTIAL.
4. **Notes** on FAIL or PARTIAL — what specifically is missing or
   wrong.

### Step 2 — Quality Checks

Beyond the criteria themselves:

- **Does it actually work in practice?** Not just in theory.
- **Code quality** — edge cases, error handling, logging, docs.
- **Regressions** — has anything previously working broken?
- **Would you ship this?** The gut check.

### Step 3 — Output

Present the evaluation report:

```markdown
## Evaluation: P-rag-pipeline-lookup-3HyD

### Acceptance Criteria

| # | Criterion | Verdict | Notes |
|---|-----------|---------|-------|
| 1 | Embedding API returns within 200ms p99 | PASS | Benchmark in tests/perf.ts |
| 2 | Index updates within 5 minutes of source | PARTIAL | Median is good; p99 spikes to 8min |
| 3 | Zero dropped records under normal load | PASS | Verified across 1M test corpus |

### Quality Assessment

- Functionality:  Works as specified for the PASS criteria
- Code quality:   Good (well-tested, conforms to PATTERNS.md)
- Test coverage:  Adequate (88% per coverage report)
- Edge cases:     Partial — see criterion 2 notes
- Documentation:  Complete

### Overall Verdict

PARTIAL — criterion 2 needs a follow-up.
```

### Step 4 — Verdict Decision

Ask the human (via `AskUserQuestion`):

1. **PASS — ready to ship**
2. **PARTIAL — specific fixes needed**
3. **FAIL — rework required**

For PARTIAL: capture the specific fixes as a free-form follow-up.
These become new tasks on the Plan (or a new dependent Plan).

For FAIL: discuss whether to re-Plan (approach was wrong) or re-Scope
(the problem was misunderstood).

## Write the Verdict

Update the Plan frontmatter:
- For PASS: keep `status: evaluating`, record verdict in audit trail.
  The human will run `/spades:ship` next.
- For PARTIAL: keep `status: evaluating`, record the gaps. The work
  routes back to `/spades:do` for the fixes; this skill stays open.
- For FAIL: `status: rejected`. Route back to `/spades:plan` or
  `/spades:scope`.

Append to the Plan's `## Audit Trail`:

```markdown
- YYYY-MM-DD: Evaluation — verdict: PASS. Notes: <…>.
```

Call the backend's `record_evaluation(plan_id, verdict, notes)`. When
`backend: linear`, the driver posts the report as a comment on the
sub-issue.

## After Verdict

### PASS
```
✓ Plan evaluated: P-rag-pipeline-lookup-3HyD
✓ Verdict:        PASS
✓ Status:         evaluating (ready for /spades:ship)

Next:
  /spades:ship P-rag-pipeline-lookup-3HyD   — release the deliverable
```

### PARTIAL
```
⚠ Plan evaluated: P-rag-pipeline-lookup-3HyD
⚠ Verdict:        PARTIAL — criterion 2 needs work
⚠ Status:         evaluating (returning to /spades:do)

Next:
  /spades:do P-rag-pipeline-lookup-3HyD   — apply the fixes
```

### FAIL
```
✗ Plan evaluated: P-rag-pipeline-lookup-3HyD
✗ Verdict:        FAIL — approach was wrong
✗ Status:         rejected

Next:
  /spades:plan S-add-ai-helper-bot   — re-plan with lessons learned
  /spades:scope S-add-ai-helper-bot  — re-scope if the problem was misunderstood
```

## Scope-Level Evaluation

When the target is a Scope (not a single Plan), evaluate every Plan
under it. The Scope's overall verdict is the floor of the individual
verdicts (any FAIL → Scope FAIL; any PARTIAL with no FAIL → Scope
PARTIAL; all PASS → Scope PASS).
