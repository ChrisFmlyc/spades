---
name: evaluate
description: Check delivered output against a Plan's acceptance criteria. Returns PASS / PARTIAL / FAIL. Use after `/spades:deliver` has completed delivery, when someone says "evaluate this", "check if this is done", "verify the output", or when a Plan is in status `evaluating`. Quick-path items (`/spades:quick`) skip the full evaluation and validate the PR directly.
version: 3.9.2
---

# /spades:evaluate

You are running the Evaluate gate. Approve validated the plan;
Evaluate validates the output against the Scope's acceptance
criteria. The human owns the verdict in every routing mode.

Read `docs/FRAMEWORK.md` § .spades/ Local Layout, § Target
Resolution, § Asking the Human, and § Output Format before running.

### Output format

The evaluation has two review surfaces in both modes: the locked
verification plan before any check runs (Step 3) and the report
after (Step 6). The verdict itself lives as audit-trail lines on the
Plan's `.md`; that is the AI-readable record.

- **CLI mode** — the table printed in each step is the surface,
  anchored by a one-line pointer.
- **HTML mode** — each surface is a page rendered from
  `${CLAUDE_PLUGIN_ROOT}/skills/evaluate/template.html` by
  `worker-html-evaluation` into `.spades/evaluations/` and
  auto-opened; the terminal gets a one-line "opened" nudge. The
  template's `{{spades.mode}}` (`plan` | `report`) sets the page's
  brand, heading, tagline, and title. This skill opens its own two
  pages only; the Plan's `.html` stays closed.

Read completion events per `docs/FRAMEWORK.md § Delivery audit markers`
so older Plans resume the correct evaluation cycle.

## Pre-Flight

1. **Confirm setup and active project.** Abort otherwise.
2. **Read `backend:` and `review_format:`** from `.spades/config`.
3. **Resolve the target** per `docs/FRAMEWORK.md § Target
   Resolution`. This skill takes a Plan, a Scope (whole-scope
   evaluation), or a Quick item.
   - **ID passed** — `P-…` → Plan; `S-…` → Scope; `Q-…` → Quick
     item, go to § Quick path.
   - **Bare invocation** — ask via `AskUserQuestion`: *One plan*
     (picker over `delivering` / `evaluating`), *Whole scope* (picker
     over `evaluating`), *Quick item* (glob `.spades/quick/Q-*.md`
     for the active project without an `Evaluate — verdict:` line).
   - **Zero candidates** — no Plans → `/spades:deliver P-…`; no Scopes →
     keep delivering; no Quick items → `/spades:quick`.
4. **Read the target** — Plan plus parent Scope, or Scope plus every
   Plan under it — from the `.md` files.
5. **Verify ancestors active** per § Target Resolution →
   Parent-status precondition; hard abort on an `abandoned` Scope or
   an `abandoned` / `archived` Project. Quick items sit outside the
   hierarchy and skip this.
6. **Read `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`.**
7. **Note the Plan's `delivery:` routing.** It shapes Step 2's
   proposal: AI-delivered Plans skew to AI / Test / Lint verifiers,
   human-delivered to Human / Manual, hybrid follows the per-task
   split.

## Step 0 — Fresh run or resume

Read the Plan's audit trail:

- No `Evaluation started` since the last `Deliver phase complete` →
  fresh run, Step 1.
- Latest `Evaluation started` followed by `AI verification phase
  complete. Awaiting human report on …` (hybrid) or `Verification
  plan written, awaiting human execution.` (human) → resume at
  Step 5.
- Already followed by `Evaluation — verdict:` → the evaluation is
  complete; ask whether to re-evaluate fresh or go to
  `/spades:ship`.

## Step 1 — Routing — `AskUserQuestion`

Same wording as `/spades:approve`'s routing question:

1. **AI** — runs verification autonomously: executes test commands,
   inspects the diff, checks each criterion, proposes the verdict.
2. **Human** — the AI builds the checklist and runs nothing; the
   human verifies and reports back.
3. **Hybrid** — the AI takes the mechanical checks (suites, lints,
   automated criteria), the human takes manual or exploratory work.

Record `evaluation: ai | human | hybrid` in the Plan frontmatter and
append `- YYYY-MM-DD: Evaluation started — routing: <routing>.`

## Step 2 — Build and agree the verification plan

From the Scope's acceptance criteria and the Plan's Testing &
Verification section, build one row per criterion plus the
orthogonal quality checks (regressions, code quality, edge cases,
docs). Each row names a **verifier** and a concrete **method**:

```markdown
| # | Acceptance criterion / check  | Verifier | Method |
|---|-------------------------------|----------|--------|
| 1 | Embedding API <200ms p99      | AI       | `npm run bench:embedding` |
| 2 | Index updates within 5min     | Human    | Manual against staging |
| 3 | Zero dropped records on load  | AI       | `npm run test:load` |
| 4 | UI feels responsive           | Human    | Local browser session |
| Q | No regressions in core flow   | AI       | `npm test` |
```

Propose and confirm per routing:

- **AI** — every verifier is AI. *Run this plan* / *Adjust first*
  (Adjust switches to hybrid and asks for the split).
- **Hybrid** — propose the split by what each criterion needs. *Run
  this plan* / *Adjust the split* (free-form; loop until confirmed).
- **Human** — every verifier is Human; each method is written
  clearly enough to execute without guessing. *Looks good* /
  *Adjust*.

Append the agreed plan:

```markdown
- YYYY-MM-DD: Verification plan agreed:
    - C1: AI (`npm run bench:embedding`) — pending
    - C2: Human (manual against staging) — pending
    - Q : AI (`npm test`) — pending
```

## Step 3 — Present the locked plan

**CLI mode** — the Step 2 table stays on screen; print one anchor:

```
○ Verification plan locked above — approve, edit, or reject at the prompt next.
```

**HTML mode — page 1.** Dispatch `worker-html-evaluation` per
`docs/FRAMEWORK.md § worker-html-*`:

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/evaluate/template.html`
- `output_path`: `.spades/evaluations/<plan_id_lower>-<YYYY-MM-DD>-plan.html`
  (the worker creates the directory when missing)
- `frontmatter`:
  ```
  { mode: "plan",
    brand_label: "Verification Plan",
    h1_prefix: "Verification plan",
    page_title: "Verification",
    tagline: "Concrete verification steps to confirm this plan is
              done. Each row shows the check and who runs it.
              Verdicts fill in when the evaluation completes.",
    verdict: "PENDING", verdict_class: "pending",
    verdict_summary_html: "<p>Verification plan proposed — awaiting
              your approval at the prompt. The listed checks run
              next.</p>",
    pass_count: 0, partial_count: 0, fail_count: 0,
    plan_id, plan_title, scope_id, scope_title,
    project, evaluated, evaluator, plugin_version }
  ```
- `blocks`:
  - `objective-banner` — 0 or 1 item `{ id, title }` per
    `docs/FRAMEWORK.md § Objective banner`, resolved from the parent
    Scope's `strategy_link`; else `[]`.
  - `verification-rows` — one per agreed row. Fields: `step`,
    `criterion_ref` (`C1`, `Q1`), `verifier` (`AI` / `Human` /
    `Test` / `Lint` / `Manual`), `verifier_class` (lowercase),
    `method`, `verdict` (`PENDING`), `verdict_class` (`pending`),
    `notes` (empty).
  - `audit-events` — every Plan audit entry whose `desc` contains
    `Evaluation` or `Verification plan`, chronological. Fields:
    `date, desc`.

Required markers: `verification-rows`, `audit-events`. Then print:

```
○ Verification plan opened: .spades/evaluations/<plan-id>-<date>-plan.html
○ Approve, edit, or reject below — then I'll run the checks.
```

## Step 4 — Approve the verification plan — `AskUserQuestion`

1. **Approve as proposed** *(Recommended)* → append
   `- YYYY-MM-DD: Verification plan APPROVED by human.` and continue.
2. **Edit specific rows** → free-form; update the agreed-plan entry
   in place, re-render page 1 in HTML mode, and return to this gate.
3. **Reject** → append `- YYYY-MM-DD: Verification plan rejected —
   evaluation abandoned.` and exit.

## Step 5 — Execute the rows

**AI rows (fresh run).** Run each method or perform the inspection,
capture PASS / FAIL / PARTIAL, and note one line of evidence — a
cause for failures, a pointer (`tests/perf.ts:42`, an output
excerpt) for passes. Update the agreed-plan lines in place:

```markdown
    - C1: AI (`npm run bench:embedding`) — PASS (p99 = 187ms)
    - Q : AI (`npm test`) — PASS (143/143)
```

Then:

- **`evaluation: ai`** → Step 6.
- **`hybrid`** → append `- YYYY-MM-DD: AI verification phase
  complete. Awaiting human report on C2, C4.` and exit with the Plan
  at `evaluating`.
- **`human`** → append `- YYYY-MM-DD: Verification plan written,
  awaiting human execution.` and exit likewise.

The hand-off for a paused run:

```
✓ AI verification: 3/3 PASS
○ Awaiting human verification on:
    - C2: Index updates within 5min — Manual against staging
    - C4: UI feels responsive — Local browser session

When you've finished those, re-run:
  /spades:evaluate P-rag-pipeline-lookup-3HyD

… and I'll collect your results, compile the report, and you pick
the verdict.
```

**Human rows (resume).** Show the AI verdicts already recorded
verbatim, then ask row by row: *"C2 — Index updates within 5min.
You were testing this manually against staging. What did you
find?"* Record verdict and notes in place, append `- YYYY-MM-DD:
Human verification complete.`, and continue.

## Step 6 — Compile, derive, present

Derive the overall verdict from the rows: any FAIL → **FAIL**; all
PASS → **PASS**; otherwise **PARTIAL**. Draft a two- or
three-sentence rationale the next reader should take away.

```markdown
## Evaluation: P-rag-pipeline-lookup-3HyD

Routing: hybrid (AI verified C1, C3, Q; Human verified C2, C4)

| # | Criterion                    | Verifier | Verdict | Notes |
|---|------------------------------|----------|---------|-------|
| 1 | Embedding API <200ms p99     | AI       | PASS    | p99 = 187ms |
| 2 | Index updates within 5min    | Human    | PASS    | 1-3min observed |
| 4 | UI feels responsive          | Human    | PARTIAL | Slow on mobile <600px |
| Q | No regressions in core flow  | AI       | PASS    | 143/143 tests |

Overall: PARTIAL — C4 needs a follow-up.
```

**CLI mode** — print the table, then:

```
○ Verdict (proposed): <PASS|PARTIAL|FAIL>. Confirm or override below.
```

**HTML mode — page 2.** Dispatch `worker-html-evaluation` again
with `output_path` ending `-report.html`, `mode: "report"`,
`brand_label: "Evaluation Report"`, `h1_prefix: "Evaluation
report"`, `page_title: "Evaluation"`, `tagline: "All verdicts
confirmed. The Plan's audit-trail line is the authoritative record;
this report is the human's rich view."`, the derived `verdict` /
`verdict_class`, the rationale as `verdict_summary_html` (escaped,
in `<p>`), and `pass_count` / `partial_count` / `fail_count` from
the rows. `verification-rows` carry the recorded verdicts and notes;
`objective-banner` and `audit-events` resolve as for page 1. Then:

```
○ Evaluation report opened: .spades/evaluations/<plan-id>-<date>-report.html
○ Verdict (proposed): <PASS|PARTIAL|FAIL>. Confirm or override below.
```

## Step 7 — Confirm the verdict — `AskUserQuestion`

1. **Confirm `<derived>`** — accept verdict and rationale.
2. **Override to <the two verdicts not derived>**.
3. **Edit rationale** — keep the verdict, capture new text.

An override or edit is applied, re-rendered (page 2, or the table),
and the question is asked again; the flow advances on Confirm. The
human owns the final verdict in every routing mode.

## Step 8 — Write the verdict (fan-out)

One wave per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`,
`subagent_type: general-purpose`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-plan-evaluate` | `.spades/plans/P-<…>.md` — PASS keeps `status: evaluating`; PARTIAL rolls back to `delivering` so `/spades:deliver` resumes; FAIL sets `rejected`. Appends `- YYYY-MM-DD: Evaluation — verdict: <PASS\|PARTIAL\|FAIL>. Notes: <rationale>.` | `{ status: ok }` |
| `worker-file-scope-evaluate` *(Scope rollup only)* | `.spades/scopes/S-<…>.md` — `status: evaluating` on the first PASS per `docs/FRAMEWORK.md § Scope status rollup`, plus an audit line. | `{ status: ok }` |
| `worker-linear-evaluate` *(`backend: linear`)* | Linear — `record_evaluation(plan_id, verdict, notes)`: the report as a sub-issue comment and the matching workflow state. Carries the resolved worktree context per § Freshness. | `{ status: ok }` |

In HTML mode, re-dispatch `worker-html-plan` after the file write.
After the wave: all ok → record the dispatch mode; plan file failed
→ abort with the error; scope file failed → surface for a manual
patch; Linear failed → keep local files, surface, offer a retry.

## After the verdict

```
✓ Plan evaluated: P-rag-pipeline-lookup-3HyD
✓ Verdict:        PASS
✓ Status:         evaluating (ready for /spades:ship)

Next:
  /spades:ship P-rag-pipeline-lookup-3HyD   — release the deliverable
```

```
⚠ Plan evaluated: P-rag-pipeline-lookup-3HyD
⚠ Verdict:        PARTIAL — criterion 4 needs work
⚠ Status:         delivering (returning to /spades:deliver)

Next:
  /spades:deliver P-rag-pipeline-lookup-3HyD   — apply the fixes
```

```
✗ Plan evaluated: P-rag-pipeline-lookup-3HyD
✗ Verdict:        FAIL — approach was wrong
✗ Status:         rejected

Next:
  /spades:plan S-add-ai-helper-bot   — re-plan with lessons learned
  /spades:scope S-add-ai-helper-bot  — re-scope if the problem was misunderstood
```

## Scope-level evaluation

For a Scope target, evaluate every Plan under it in turn. The
Scope's verdict is the floor of the Plan verdicts: any FAIL → FAIL;
any PARTIAL → PARTIAL; all PASS → PASS.

## Quick path

Reached for a `Q-…` target, or with `backend: linear` an issue
carrying the `spades:quick` label. The marker file is the whole
record; the check is against the PR.

1. **Read the marker** `.spades/quick/<Q-id>.md`: `pr_url`, `type`,
   `branch`, `delivery`, and the Gate Check.
2. **Find the PR** from `pr_url`; with `scm: local-git` the shipment
   commit named in the marker's `Shipped` line stands in for it.
3. **Verify** — merged or open, CI green, description follows the
   `/spades:quick` template.
4. **Re-walk the gate** against the actual diff.
5. **Verdict** via `AskUserQuestion`: **PASS** (merged, CI green,
   gate holds) / **PARTIAL** (a small fix is needed) / **FAIL** (the
   gate was violated; the work belongs in the full loop).
6. **On PARTIAL, route the follow-up** via a second
   `AskUserQuestion`: **Add commits to the existing PR**
   (`add-commits`; push to the same branch and re-run) / **Open a
   new quick-path PR** (`new-quick-pr`; reference this Q-id in the
   new item's Why) / **Re-route through the full loop**
   (`full-loop`; `/spades:scope`). Print the exact next command.
7. **Append** `- YYYY-MM-DD: Evaluate — verdict: <verdict>.
   <rationale>.[ Follow-up: <route>.]`, and with `backend: linear`
   post the same line as a comment on the issue.
