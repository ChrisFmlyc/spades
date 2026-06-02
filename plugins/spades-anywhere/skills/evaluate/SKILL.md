---
name: evaluate
description: Check delivered work against a Plan's parent Scope acceptance criteria. Returns PASS / PARTIAL / FAIL. Human-only verdict — no test execution, no automated checks. Use after `/spades-anywhere:do` has marked a Plan as delivering and the human has done the work, when someone says "evaluate this", "check if this is done", "verify the work", or when a Plan is in status `delivering` or `evaluating`. If not PASS, this skill routes the work back to `/spades-anywhere:do` and the human keeps going.
version: 0.1.0
---

# /spades-anywhere:evaluate

You are evaluating delivered work against a Plan's acceptance
criteria. In `spades-anywhere`, evaluation is **human-only** —
there is no test suite, no automated check. The human walks the
Scope's acceptance criteria one by one and judges each as
*met / partial / not met*. The verdict aggregates to
PASS / PARTIAL / FAIL.

The Do → Evaluate loop is intentional: for human work, first
attempts often produce PARTIAL. The skill routes back to
`/spades-anywhere:do` on anything below PASS and the human keeps
going. Loop until PASS.

Read `docs/FRAMEWORK.md` § Hierarchy, § Target Resolution, and
§ Audit Trail before running.

### Output format

This skill honours `review_format:` from `.spades-anywhere/config`
per `docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. In HTML
mode, auto-open the Plan's `.html` (and the parent Scope's
`.html`) via the OPEN_CMD prelude at the start so the human can
see what's being evaluated. In CLI mode, summarise inline. The
verdict-walk and audit-trail writes are identical between modes.

## Pre-Flight

1. **Confirm setup + active project.** Abort otherwise.
2. **Resolve the target** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill can take either a Plan or a Scope
   (whole-scope evaluation when every Plan under it is done):
   - **If the human passed an ID,** resolve directly:
     `P-<slug>-<suffix>` → Plan; `S-<slug>` → Scope.
   - **If invoked bare,** ask via `AskUserQuestion`:
     - *One plan* → Plan picker, status filter `delivering` or
       `evaluating`.
     - *Whole scope* → Scope picker, status filter `evaluating`.
   - **Zero-candidate suggestions:**
     - No Plans in `delivering` / `evaluating` →
       `/spades-anywhere:do P-…` on an approved plan first.
     - No Scopes in `evaluating` → keep delivering Plans.
3. **Read the target.** Plan + parent Scope, OR Scope + every Plan
   under it.
4. **Open the artefact (HTML mode only).** When `review_format:
   html`, run the OPEN_CMD prelude and open the Plan's (or each
   Plan's) `.html` plus the parent Scope's. In CLI mode,
   summarise inline.

## Step 1 — Walk the Scope's acceptance criteria

This is the whole skill. Read the Scope's `## Acceptance
Criteria` section. For each criterion in turn, ask the human via
`AskUserQuestion`:

> *Criterion <N>: "<criterion text>". How did this turn out?*

Options:

- **Met** — the criterion is fully satisfied. Optionally capture a
  one-line note (what evidence / how confirmed).
- **Partial** — moved forward but not all the way. Capture a
  one-line note on what's missing.
- **Not met** — not done; capture a one-line note on why (blocked,
  ran out of time, scope changed, deprioritised).

Free-form follow-up after each is fine — for example, the human
might say "met, but the cake was a different flavour than planned"
and the note records that nuance.

Record each `(criterion, verdict, note)` tuple in the audit trail
as you go.

## Step 2 — Aggregate the overall verdict

Apply the rule:

- **PASS** — every criterion is *met*. (Notes are still captured
  for the record.)
- **PARTIAL** — at least one *met* and at least one *partial* or
  *not met*. The work moved forward but isn't complete.
- **FAIL** — every criterion is *not met*, OR the human chose
  *FAIL — fundamental approach was wrong* via the override below.

Confirm the aggregated verdict back to the human via
`AskUserQuestion`:

- **PASS** — proceed to `/spades-anywhere:ship`
- **PARTIAL** — route back to `/spades-anywhere:do` and keep going
- **FAIL — fundamental approach was wrong** — route back to
  `/spades-anywhere:plan` (or `/spades-anywhere:scope` if the
  problem was mis-scoped)
- **FAIL — keep this as-is, mark rejected** — record `status:
  rejected`; the human has decided this Plan isn't worth
  continuing

The human owns the final verdict. The aggregation above is a
suggestion; the override lets the human pick a different verdict
when context (frustration with the approach, schedule pressure,
new information) trumps the mechanical aggregation.

## Step 3 — Write the verdict (fan-out dispatch)

Apply the fan-out pattern from
`docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`. Spawn the
following sub-agents **in parallel in a single assistant message
with multiple `Agent` tool calls** (`subagent_type:
general-purpose`):

| Sub-agent | Resource owned | Returns |
|-----------|---------------|---------|
| `worker-file-plan-evaluate` | `.spades-anywhere/plans/P-<…>.<ext>` — update Plan frontmatter (PASS: keep `status: evaluating`; PARTIAL: roll back to `status: delivering` so `/spades-anywhere:do` can resume; FAIL-rejected: `status: rejected`; FAIL-replan: keep `status: evaluating` and append a "needs re-plan" note) and append to audit trail: `- YYYY-MM-DD: Evaluation — verdict: <PASS\|PARTIAL\|FAIL>. Criteria: <met/partial/not-met counts>. Notes: <…>.` | `{ status: ok }` |
| `worker-file-scope-evaluate` *(only when this evaluation triggers a Scope rollup)* | `.spades-anywhere/scopes/S-<scope-slug>.<ext>` — update rollup per `docs/FRAMEWORK.md § Hierarchy → Scope status rollup` and append audit-trail entry. Skip this sub-agent when no rollup change is required. | `{ status: ok }` |
| `worker-linear-evaluate` *(only when `backend: linear`)* | Linear — call `record_evaluation(plan_id, verdict, notes)`: post the verdict + per-criterion notes as a comment on the sub-issue and update sub-issue status. | `{ status: ok }` |

After sub-agents return, the coordinator collects results per the
failure semantics in `FRAMEWORK.md § Sub-agent Dispatch`. No
back-write — `linear_issue_id` is already in the files. Record
the dispatch mode in the confirmation output.

## Step 4 — Route to the next phase

### PASS
```
✓ Plan evaluated: P-host-birthday-party-3HyD
✓ Verdict:        PASS (3/3 criteria met)
✓ Status:         evaluating (ready for /spades-anywhere:ship)

Next:
  /spades-anywhere:ship P-host-birthday-party-3HyD   — confirm against INTENT success criteria
```

### PARTIAL
```
⚠ Plan evaluated: P-host-birthday-party-3HyD
⚠ Verdict:        PARTIAL (2 met, 1 partial)
⚠ Note:           Photographer didn't show; got phone-camera photos instead
⚠ Status:         delivering (returning to /spades-anywhere:do)

Next:
  /spades-anywhere:do P-host-birthday-party-3HyD   — keep going on the partial criterion
```

### FAIL — replan
```
✗ Plan evaluated: P-host-birthday-party-3HyD
✗ Verdict:        FAIL — fundamental approach was wrong
✗ Status:         evaluating

Next:
  /spades-anywhere:plan S-plan-birthday-party   — re-plan with what you learned
  /spades-anywhere:scope S-plan-birthday-party  — re-scope if the problem was misunderstood
```

### FAIL — rejected
```
✗ Plan evaluated: P-host-birthday-party-3HyD
✗ Verdict:        FAIL — abandoned
✗ Status:         rejected

Next:
  Consider whether the parent Scope still holds, or revise it.
```

## Scope-level evaluation

When the target is a Scope (not a single Plan), evaluate every
Plan under it in turn. The Scope's overall verdict is the **floor**
of the individual Plan verdicts:

- Every Plan PASS → Scope PASS.
- Any Plan PARTIAL → Scope PARTIAL.
- Any Plan FAIL → Scope FAIL.

Surface the matrix to the human (each Plan, its verdict, notes)
before confirming the Scope-level aggregate.

## Edge cases

- **Acceptance criteria changed mid-flight.** If the human said
  "the criterion text doesn't match what we actually did" — capture
  it as a `not met` with the explanation, then suggest revising the
  Scope (`/spades-anywhere:scope` edit mode) before re-evaluating.
  Don't silently retcon criteria to match outcome.
- **Plan was never run through `/spades-anywhere:do`.** If status
  is `approved` (not `delivering` / `evaluating`), abort and
  suggest `/spades-anywhere:do P-…` first. Evaluating undelivered
  work is meaningless.
- **The human can't answer a criterion yet.** Allow *Defer — come
  back later* as an option. Record `deferred` in the audit trail;
  treat as PARTIAL for aggregation; the human re-runs `evaluate`
  later. Useful for criteria that have a delayed verification
  (e.g. "guests reported a good time" — needs a few days).
