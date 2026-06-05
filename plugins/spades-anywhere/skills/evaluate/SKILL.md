---
name: evaluate
description: Check delivered work against a Plan's parent Scope acceptance criteria. Returns PASS / PARTIAL / FAIL. Human-only verdict — no test execution, no automated checks. Use after `/spades-anywhere:do` has marked a Plan as delivering and the human has done the work, when someone says "evaluate this", "check if this is done", "verify the work", or when a Plan is in status `delivering` or `evaluating`. If not PASS, this skill routes the work back to `/spades-anywhere:do` and the human keeps going.
version: 0.4.0
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
per `docs/FRAMEWORK.md § Output Format (CLI vs HTML)`.

In CLI mode this skill is consumer-only: the verdict-walk happens
inline in the conversation and the result lives as an audit-trail
line on the Plan file.

In HTML mode this skill is **also a producer**. Two things happen:

1. The Plan's `.html` (and the parent Scope's `.html`) are
   auto-opened at the Pre-Flight step so the human can see what
   is being evaluated — same as today.
2. After Step 2 picks an aggregated verdict, render the
   per-criterion table + verdict via
   `${CLAUDE_PLUGIN_ROOT}/skills/evaluate/template.html` and
   write `.spades-anywhere/evaluations/<plan-id>-<YYYY-MM-DD>.html`,
   then auto-open via OPEN_CMD. The audit-trail line on the Plan
   is unchanged (still authoritative for the AI reader); the HTML
   report is the **human's** rich view of the verdict.

In `spades-anywhere`, the evaluator is **always the human** —
there is no `delivery:` routing; render `{{spades.evaluator}}` as
`human` in every report.

CLI mode does NOT write any evaluation file.

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
4. **Do NOT auto-open the Plan's or Scope's `.html` in HTML
   mode.** This is a deliberate change from prior versions. The
   Plan/Scope `.html` files are not the eval review surface; the
   verification-plan HTML (page 1, written at Pre-Flight Step 5
   below) is. Opening the wrong page caused confusion in the
   field. The eval pages carry the Plan ID + parent Scope in
   their breadcrumb if the human wants to cross-check.

5. **Render PAGE 1: verification plan HTML (HTML mode only).**
   When `review_format: html`, render the upcoming acceptance-
   criteria walk as a table the human can preview *before*
   Step 1 starts asking per-criterion questions. This is the
   "before we start" page, paired with page 2 written at
   Step 2.5.

   **You MUST render via the bundled `template.html`. Do NOT
   hand-roll the HTML.**

   1. **Read the template** at
      `${CLAUDE_PLUGIN_ROOT}/skills/evaluate/template.html`.
   2. **Validate** it contains:
      - `<!-- SPADES-BLOCK:verification-rows -->`
      - `<!-- SPADES-BLOCK:audit-events -->`

      Abort if either is missing.
   3. **Substitute placeholders** with `mode: plan`:
      - `{{spades.mode}}` = `plan`
      - `{{spades.brand_label}}` = `Verification Plan`
      - `{{spades.h1_prefix}}` = `Verification plan`
      - `{{spades.page_title}}` = `Verification`
      - `{{spades.tagline}}` = `What we're about to walk through. One row per acceptance criterion. After you answer each, the completed report appears as page 2.`
      - `{{spades.verdict}}` = `PENDING`
      - `{{spades.verdict_class}}` = `pending`
      - `{{spades.verdict_summary_html}}` = `<p>Walk-through not started yet. The completed report appears at Step 2.5 once you've answered each criterion.</p>`
      - `{{spades.plan_id}}`, `{{spades.plan_title}}`,
        `{{spades.scope_id}}`, `{{spades.scope_title}}`,
        `{{spades.evaluated}}` (today's date),
        `{{spades.evaluator}}` = `human` (always in
        spades-anywhere),
        `{{spades.plugin_version}}`.
      - `<!-- SPADES-BLOCK:verification-rows -->` — one row per
        acceptance criterion from the parent Scope. Per-item:
        - `{{block.step}}` — the criterion text rephrased as a
          concrete check action ("Verify the venue was set up
          on time", "Confirm guests were happy with the food").
        - `{{block.criterion_ref}}` — `C1`, `C2`, etc.
        - `{{block.verifier}}` = `Human` (always).
        - `{{block.verifier_class}}` = `human`.
        - `{{block.method}}` = `Eyes-on` (placeholder; the human
          fills in the actual method in their note at Step 1).
        - `{{block.verdict}}` = `PENDING`.
        - `{{block.verdict_class}}` = `pending`.
        - `{{block.notes}}` = empty.
      - `<!-- SPADES-BLOCK:audit-events -->` — every audit-trail
        entry on the Plan whose `desc` contains `Evaluation`
        (likely empty at this point — just the audit line about
        the evaluation having started).
   4. **Write** to
      `.spades-anywhere/evaluations/<plan_id_lower>-<YYYY-MM-DD>-plan.html`
      (creating `.spades-anywhere/evaluations/` if missing).
   5. **Auto-open** via the OPEN_CMD prelude. Print:

      ```
      ○ Verification plan opened: .spades-anywhere/evaluations/<plan-id>-<date>-plan.html
      ○ I'll walk you through each row next.
      ```

   In CLI mode this step is skipped; the per-criterion walk in
   Step 1 is the review surface.

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

**Then capture a one-paragraph rationale.** After the verdict
choice, ask free-form: *"In a sentence or two, why this verdict?
What's the take-away the next reader should have?"* The reply
becomes `{{spades.verdict_summary_html}}` in page 2's
summary card.

## Step 2.5 — Render PAGE 2: evaluation report HTML (HTML mode only)

When `review_format: html`, after Step 2 captures the verdict
and rationale, produce the completed evaluation report. Same
template as page 1; different `mode` framing.

**You MUST render via the bundled `template.html`. Do NOT
hand-roll the HTML.**

1. **Read the template** at
   `${CLAUDE_PLUGIN_ROOT}/skills/evaluate/template.html`.
2. **Validate** it contains:
   - `<!-- SPADES-BLOCK:verification-rows -->`
   - `<!-- SPADES-BLOCK:audit-events -->`

   Abort if either is missing.
3. **Substitute placeholders** with `mode: report`:
   - `{{spades.mode}}` = `report`
   - `{{spades.brand_label}}` = `Evaluation Report`
   - `{{spades.h1_prefix}}` = `Evaluation report`
   - `{{spades.page_title}}` = `Evaluation`
   - `{{spades.tagline}}` = `All verdicts confirmed. The Plan's audit-trail line on \`.spades-anywhere/plans/<plan-id>.md\` is the authoritative record; this report is your rich view.`
   - `{{spades.verdict}}` — `PASS` / `PARTIAL` / `FAIL` from
     Step 2.
   - `{{spades.verdict_class}}` — `pass` / `partial` / `fail`.
   - `{{spades.verdict_summary_html}}` — the one-paragraph
     rationale captured at Step 2, HTML-escaped and wrapped in
     `<p>` tags.
   - `{{spades.plan_id}}`, `{{spades.plan_title}}`,
     `{{spades.scope_id}}`, `{{spades.scope_title}}`,
     `{{spades.evaluated}}` (today's date),
     `{{spades.evaluator}}` = `human` (always),
     `{{spades.plugin_version}}`.
   - `<!-- SPADES-BLOCK:verification-rows -->` — same rows as
     page 1, now with verdicts filled in from Step 1's
     per-criterion walk. Per-item:
     - `{{block.step}}` — the criterion text as a concrete
       check action (same as page 1).
     - `{{block.criterion_ref}}` — `C1`, `C2`, etc.
     - `{{block.verifier}}` = `Human` (always).
     - `{{block.verifier_class}}` = `human`.
     - `{{block.method}}` — the concrete method, taken from the
       human's note at Step 1 if they mentioned one (`Eyes-on`,
       `Asked guest for feedback`, `Compared to photo brief`).
     - `{{block.verdict}}` — `PASS` (met) / `PARTIAL` (partial) /
       `FAIL` (not met); `NA` if deferred.
     - `{{block.verdict_class}}` — `pass` / `partial` / `fail` /
       `na`.
     - `{{block.notes}}` — the one-line note the human captured.
   - `<!-- SPADES-BLOCK:audit-events -->` — every audit-trail
     entry on the Plan whose `desc` contains `Evaluation`, in
     chronological order. Per-item: `{{block.date}}`,
     `{{block.desc}}`.
4. **Write** to
   `.spades-anywhere/evaluations/<plan_id_lower>-<YYYY-MM-DD>-report.html`
   (note the `-report.html` suffix — distinct from page 1's
   `-plan.html`).
5. **Auto-open** via the OPEN_CMD prelude. Print the file path
   with "open this in your browser" if `OPEN_CMD` is empty.

There is **no SCM in spades-anywhere** — no branch, no PR, no
wait-for-merge gate. The human saves both pages to their
chat-surface knowledge store (Claude Project files, ChatGPT GPT
files, Gemini Gem references, Notion, wherever) on their own
cadence. The framework just writes the files; persistence beyond
that is the human's call.

In CLI mode this step is skipped entirely; the Plan's
audit-trail line is the only output as today.

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
