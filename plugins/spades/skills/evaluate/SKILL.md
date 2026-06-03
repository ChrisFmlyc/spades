---
name: evaluate
description: Check delivered output against a Plan's acceptance criteria. Returns PASS / PARTIAL / FAIL. Use after `/spades:do` has completed delivery, when someone says "evaluate this", "check if this is done", "verify the output", or when a Plan is in status `evaluating`. Quick-path items (`/spades:quick`) skip the full evaluation and validate the PR directly.
version: 3.1.2
---

# /spades:evaluate

You are running the Evaluate gate. This is distinct from Approve:
Approve validates the *plan*; Evaluate validates the *output*.

Read `docs/FRAMEWORK.md` § .spades/ Local Layout and § Target
Resolution before running.

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. Anywhere this
skill would today paste the Plan's content to the terminal for the
human's evaluation review, in HTML mode it auto-opens the Plan's
existing `.html` file via the OPEN_CMD prelude. The PASS / PARTIAL /
FAIL verdict prompts and audit-trail writes stay identical between
modes.

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
   under it. Read `review_format:` from `.spades/config` first — in
   CLI mode artefacts are `.md`, in HTML mode `.html`.
4. **Read `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`.**
5. **Open the artefact (HTML mode only).** When `review_format: html`,
   run the OPEN_CMD prelude from
   `docs/FRAMEWORK.md § OPEN_CMD detection prelude` and open the
   Plan's (or each Plan's) `.html` so the human can see what's being
   evaluated. **In HTML mode the open `.html` IS the review surface
   — do NOT also paste / summarise / restate the Plan body, the
   acceptance criteria list, or the cumulative verdict table to the
   CLI; the human has the browser tab.** Short conversational text
   (the per-criterion `AskUserQuestion` polls, the final `✓ Plan
   evaluated …` confirmation, error messages) stays in the CLI as
   today. In CLI mode, summarise the target inline as today. See
   `docs/FRAMEWORK.md § Output Format → What counts as review-form
   text` for the canonical line.

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

For non-quick items, the evaluation flow is **routed** (like `/spades:do`)
and supports **two-phase resume** for Hybrid and Human routings — so
"I'll test it tomorrow" is a normal pattern.

### Step 0 — Detect fresh run vs resume

Read the Plan's `## Audit Trail` section before doing anything else.

- **Fresh run** — the audit trail has no `Evaluation started` line
  since the last `Do phase complete` line. Proceed to Step 1.
- **Resume run** — the most recent `Evaluation started` line is
  followed by either `AI verification phase complete. Awaiting human
  report on …` (Hybrid) or `Verification plan written, awaiting
  human execution.` (Human). Jump to Step 4 (Resume).

If the most recent `Evaluation started` line is already followed by
a verdict (`Evaluation — verdict: …`) the prior evaluation is
complete. Ask the human (via `AskUserQuestion`) whether they want to
re-evaluate fresh or just go to Ship.

### Step 1 — Pick the routing (fresh run)

Ask the human via `AskUserQuestion`. The three options use the same
wording as `/spades:approve`'s delivery-routing question, so the
vocabulary is consistent across the loop:

1. **AI** — AI runs the verification autonomously. Executes test
   commands, inspects the diff, checks evidence against each
   acceptance criterion, and proposes a verdict. Human confirms.
2. **Human** — AI builds a verification checklist (no commands run).
   The human does all the verification work and reports results
   back. AI compiles the report.
3. **Hybrid** — split work. AI handles the mechanical checks (test
   suites, lints, automated criterion checks); the human handles
   manual or exploratory verification. You'll agree the
   per-criterion split before AI starts running.

Record the choice on the Plan frontmatter:

```yaml
evaluation: ai | human | hybrid
```

Append to the audit trail:

```markdown
- YYYY-MM-DD: Evaluation started — routing: <ai|human|hybrid>.
```

### Step 2 — Build (and for Hybrid/Human, agree) the verification plan

Read the parent Scope's acceptance criteria and the Plan's
`## Testing & Verification` section. Construct a verification plan
as a table — one row per acceptance criterion plus any orthogonal
quality checks (functionality, regressions, code quality, edge
cases, docs).

For each row, propose a **verifier** (AI or Human) and a **method**
(a concrete command, a manual step, or a recorded observation):

```markdown
| # | Acceptance Criterion / Check | Verifier | Method |
|---|------------------------------|----------|--------|
| 1 | Embedding API <200ms p99      | AI       | `npm run bench:embedding` |
| 2 | Index updates within 5min     | Human    | Manual against staging |
| 3 | Zero dropped records on load  | AI       | `npm run test:load` |
| 4 | UI feels responsive           | Human    | Local browser session |
| Q | No regressions in core flow   | AI       | `npm test` |
```

**Routing-specific propose-and-confirm:**

- **AI mode** — every row's verifier is AI by default. Show the
  table, confirm via `AskUserQuestion` (*Run this plan* / *Adjust
  first*). If adjust → switch to Hybrid implicitly and ask for the
  split.
- **Hybrid mode** — propose a split based on what each criterion
  needs. Confirm via `AskUserQuestion` (*Run this plan* / *Adjust
  the split*). If adjust → open free-form prompt; let the human
  move rows between AI / Human; loop until they confirm.
- **Human mode** — every row's verifier is Human. AI's job is to
  write each row's Method clearly enough that the human can
  execute it without guessing. Confirm the checklist via
  `AskUserQuestion` (*Looks good* / *Adjust*).

Append the agreed verification plan to the Plan's audit trail:

```markdown
- YYYY-MM-DD: Verification plan agreed:
    - C1: AI (`npm run bench:embedding`) — pending
    - C2: Human (manual against staging) — pending
    - C3: AI (`npm run test:load`) — pending
    - C4: Human (local browser session) — pending
    - Q : AI (`npm test`) — pending
```

### Step 3 — Execute the AI rows (fresh run only)

For every row whose verifier is AI:

1. Run the Method command (or perform the inspection if it's a
   diff/code review row).
2. Capture the verdict for that row: PASS / FAIL / PARTIAL.
3. Capture short notes — for failures, a one-line cause; for
   passes, a one-line evidence pointer (`tests/perf.ts:42`,
   `<command output excerpt>`, etc.).

Update the audit-trail verification-plan lines in place with each
row's verdict:

```markdown
    - C1: AI (`npm run bench:embedding`) — PASS (p99 = 187ms)
    - C3: AI (`npm run test:load`) — PASS (1M corpus, 0 dropped)
    - Q : AI (`npm test`) — PASS (143/143)
```

**Then branch on routing:**

#### Branch A: `evaluation: ai` (no human rows)

Skip to Step 5 (Compile the report and pick a verdict).

#### Branch B: `evaluation: hybrid` or `human`

There are pending human rows. Stop here, append a hand-off line, and
exit cleanly:

```markdown
- YYYY-MM-DD: AI verification phase complete. Awaiting human report
  on C2, C4.
```

Print a hand-off prompt:

```
✓ AI verification: 3/3 PASS
○ Awaiting human verification on:
    - C2: Index updates within 5min — Manual against staging
    - C4: UI feels responsive — Local browser session

When you've finished those, re-run:
  /spades:evaluate P-rag-pipeline-lookup-3HyD

… and I'll ask you the results, compile the report, and you pick
the verdict.

Take as long as you need.
```

Plan status stays `evaluating`. Do NOT proceed to Step 4 / 5 on
this run — exit.

For Branch B with `evaluation: human` (no AI rows at all): the
"AI verification" line above won't have anything to report. Instead
append:

```markdown
- YYYY-MM-DD: Verification plan written, awaiting human execution.
```

Print the hand-off prompt with the full plan as the checklist.

### Step 4 — Resume (re-invocation in Hybrid / Human mode)

You arrive here because Step 0 detected an `Awaiting human report`
or `awaiting human execution` line in the audit trail.

1. **Show the human what AI already did** (Hybrid only) — read the
   audit-trail verification-plan lines and surface AI's verdicts so
   the human can see them. (Verbatim — don't re-summarise.)
2. **Ask the human, row-by-row, for their results.** For each
   pending human row, prompt free-form: *"C2 — Index updates within
   5min. You were testing this manually against staging. What did
   you find?"* Capture verdict + notes.

   Update the audit-trail lines in place:

   ```markdown
       - C2: Human (manual against staging) — PASS (1-3min observed)
       - C4: Human (local browser session) — PARTIAL (slow on
         mobile width <600px)
   ```

3. **Append a completion line:**

   ```markdown
   - YYYY-MM-DD: Human verification complete.
   ```

4. Proceed to Step 5.

### Step 5 — Compile the report and pick a verdict

Combine AI rows + Human rows into the standard report:

```markdown
## Evaluation: P-rag-pipeline-lookup-3HyD

Routing: hybrid (AI verified C1, C3, Q; Human verified C2, C4)

### Acceptance Criteria

| # | Criterion | Verifier | Verdict | Notes |
|---|-----------|----------|---------|-------|
| 1 | Embedding API <200ms p99      | AI    | PASS    | p99 = 187ms |
| 2 | Index updates within 5min     | Human | PASS    | 1-3min observed |
| 3 | Zero dropped records on load  | AI    | PASS    | 1M corpus, 0 dropped |
| 4 | UI feels responsive           | Human | PARTIAL | Slow on mobile <600px |
| Q | No regressions in core flow   | AI    | PASS    | 143/143 tests |

### Quality Assessment

- Functionality:  Works as specified for the PASS criteria
- Code quality:   Good
- Test coverage:  Adequate
- Edge cases:     Partial — mobile width breakpoint, see C4
- Documentation:  Complete

### Overall Verdict

PARTIAL — C4 needs a follow-up.
```

Ask the human via `AskUserQuestion`:

1. **PASS — ready to ship**
2. **PARTIAL — specific fixes needed** (capture them free-form;
   they become new tasks on the Plan or a new dependent Plan)
3. **FAIL — rework required** (discuss re-Plan vs re-Scope)

The human owns the final verdict in every routing mode — even AI
mode where AI proposed it.

## Write the Verdict (fan-out dispatch)

Apply the fan-out pattern from
`docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`. Spawn the
following sub-agents **in parallel in a single assistant message
with multiple `Agent` tool calls** (`subagent_type:
general-purpose`):

| Sub-agent | Resource owned | Returns |
|-----------|---------------|---------|
| `worker-file-plan-evaluate` | `.spades/plans/P-<…>.<ext>` — update Plan frontmatter (PASS: keep `status: evaluating`; PARTIAL: keep `status: evaluating`, record gaps; FAIL: `status: rejected`) and append to audit trail: `- YYYY-MM-DD: Evaluation — verdict: <PASS\|PARTIAL\|FAIL>. Notes: <…>.` | `{ status: ok }` |
| `worker-file-scope-evaluate` *(only when this evaluation triggers a Scope rollup)* | `.spades/scopes/S-<scope-slug>.<ext>` — update rollup per `docs/FRAMEWORK.md § Hierarchy → Scope status rollup` and append audit-trail entry. Skip this sub-agent when no rollup change is required. | `{ status: ok }` |
| `worker-linear-evaluate` *(only when `backend: linear`)* | Linear — call `record_evaluation(plan_id, verdict, notes)`: the driver posts the report as a comment on the sub-issue and updates sub-issue status. Includes the Layer-2 freshness probe. | `{ status: ok }` |

No back-write. After sub-agents return, the coordinator collects
results per the failure semantics in
`FRAMEWORK.md § Sub-agent Dispatch`:

- **All ok** → record dispatch mode and proceed to After Verdict.
- **`worker-file-plan-evaluate` failed** → abort with the error.
- **`worker-file-scope-evaluate` failed** → surface; the plan
  file's verdict is recorded but Scope rollup needs manual patch.
- **`worker-linear-evaluate` failed** → keep local files
  (canonical), surface the Linear failure, offer retry. Do NOT
  block.

### When `backend: local`

Only the file sub-agent(s) are dispatched (no Linear).

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
