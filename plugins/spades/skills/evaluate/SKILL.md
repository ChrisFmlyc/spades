---
name: evaluate
description: Check delivered output against a Plan's acceptance criteria. Returns PASS / PARTIAL / FAIL. Use after `/spades:do` has completed delivery, when someone says "evaluate this", "check if this is done", "verify the output", or when a Plan is in status `evaluating`. Quick-path items (`/spades:quick`) skip the full evaluation and validate the PR directly.
version: 3.8.0
---

# /spades:evaluate

You are running the Evaluate gate. Approve validates the *plan*;
Evaluate validates the *output*.

Read `docs/FRAMEWORK.md` § .spades/ Local Layout and § Target
Resolution before running.

### Output format

This skill honours `review_format:` per `docs/FRAMEWORK.md § Output
Format (CLI vs HTML)`. The flow is **two-surface** in both modes —
the locked verification plan before anything runs (Step 2.5), the
report after (Step 5.5). Logic, prompts, and audit writes are
identical between modes; only the surface differs:

- **CLI** — the table emitted in-step stays on screen as the review
  surface, under an anchor line.
- **HTML** — a page is rendered via the bundled template, written to
  `.spades/evaluations/`, and auto-opened; the CLI gets a brief
  "opened" nudge only.

`{{spades.mode}}` (`plan` | `report`) drives the differences between
the two pages — sidebar brand, H1 prefix, tagline, browser title.

**The Plan's own `.html` is never auto-opened by this skill** — in
either mode, at any step. Users mistook that page for the evaluation
output. Each eval page carries the Plan ID + parent Scope in its
breadcrumb; if the human wants the Plan view they open it
themselves.

### Routing

The Plan's `delivery:` field (read at Pre-Flight) drives **how Step 1
proposes the verification plan** — AI-led plans skew toward AI / Test
/ Lint rows, human-led toward Human / Manual, hybrid mixes per the
Plan's per-task routing. Every Plan goes through this skill
regardless; even pure-human plans get the AI structuring help.

## Pre-Flight

1. **Confirm setup + active project.** Abort otherwise.
2. **Resolve the target** per § Target Resolution. This skill takes a
   Plan, a Scope (whole-scope evaluation), or a Quick item.
   - **ID passed** — resolve by prefix: `P-…` → Plan; `S-…` → Scope;
     `Q-…` → Quick item → jump to **Quick-Path Branch**, skipping the
     rest of Pre-Flight.
   - **Bare invocation** — ask via `AskUserQuestion`:
     - *One plan* → Plan picker, status `delivering` or `evaluating`.
     - *Whole scope* → Scope picker, status `evaluating`.
     - *Quick item* → glob `.spades/quick/Q-*.md`, active project,
       no `Evaluate — verdict:` line yet.
   - **Zero-candidate suggestions:** no Plans → `/spades:do P-…`
     first; no Scopes → keep delivering Plans; no Quick items →
     `/spades:quick` first, or pick a Plan/Scope.
3. **Read the target** — Plan + parent Scope, or Scope + every Plan
   under it. Read `review_format:` first: `.md` in CLI mode, `.html`
   in HTML mode.
4. **Verify ancestors active** per § Target Resolution →
   Parent-status precondition. Any `abandoned` ancestor (or
   `archived` Project) → abort hard, no override. Quick items are
   exempt — they sit outside the hierarchy.
5. **Read `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`.**
6. **Record the routing** — the Plan's `delivery:` field, saved as
   `<routing>` for Step 1.

## Quick-Path Branch

Reached when the target ID begins with `Q-`, or — for `backend:
linear` — the issue carries a `spades:quick` label. Skip the full
evaluation and validate the PR directly.

1. **Read the marker** at `.spades/quick/<Q-id>.md`: `pr_url`,
   `type`, `branch`, `delivery`, and the Gate Check retrospect.
2. **Find the PR** — prefer `pr_url`; fall back to Linear comments
   or recent `spades-quick/*` branches if empty.
3. **Verify** — merged or open; CI green; description follows the
   `/spades:quick` template (Type, What, Why, Verification, Gate).
4. **Validate the gate retrospectively** — does the diff still
   satisfy every fast-track criterion the marker ticked?
5. **Verdict** via `AskUserQuestion`:
   - **PASS** — merged, CI green, gate retrospect holds.
   - **PARTIAL** — small fix needed.
   - **FAIL** — gate violated retrospectively; roll back and re-route
     through `/spades:scope` + the full loop.
6. **If PARTIAL, route the follow-up** immediately — don't leave the
   human guessing. Second `AskUserQuestion`:
   - **Add commits to the existing PR** (`add-commits`) — PR still
     open; no SPADES skill needed. Push to the same
     `spades-quick/*` branch, re-run `/spades:evaluate Q-<id>`.
   - **Open a new quick-path PR** (`new-quick-pr`) — original
     merged. Run `/spades:quick` again, referencing this Q-id in the
     new item's *Why* so the linkage is readable.
   - **Re-route through the full loop** (`full-loop`) — gate is
     violated; run `/spades:scope`, then plan/approve/do.

   Print the exact next command for the chosen route as the last
   conversational line.
7. **Append to the marker's audit trail:**

   ```markdown
   - YYYY-MM-DD: Evaluate — verdict: <PASS|PARTIAL|FAIL>. <one-line rationale>.[ Follow-up: <route>.]
   ```

   The `Follow-up:` clause appears only on PARTIAL. When `backend:
   linear`, post the same line as a comment on the issue.

Sub-issues are never created for quick-path items. The marker file
is the canonical record.

## Full-Loop Evaluation

Routed like `/spades:do`, with **two-phase resume** for Hybrid and
Human routings — "I'll test it tomorrow" is a normal pattern.

### Step 0 — Fresh run vs resume

Read the Plan's `## Audit Trail` first.

- No `Evaluation started` line since the last `Do phase complete` →
  fresh run, go to Step 1.
- Most recent `Evaluation started` followed by `AI verification
  phase complete. Awaiting human report on …` (Hybrid) or
  `Verification plan written, awaiting human execution.` (Human) →
  jump to Step 4.
- Already followed by `Evaluation — verdict: …` → the prior
  evaluation is complete. Ask whether to re-evaluate fresh or go to
  Ship.

### Step 1 — Pick the routing (fresh run)

`AskUserQuestion`, using the same wording as `/spades:approve`'s
delivery-routing question so the vocabulary is consistent:

1. **AI** — runs verification autonomously: executes test commands,
   inspects the diff, checks each criterion, proposes a verdict.
2. **Human** — AI builds the checklist and runs nothing; the human
   verifies and reports back; AI compiles.
3. **Hybrid** — AI takes the mechanical checks (suites, lints,
   automated criteria), the human takes manual or exploratory work.
   Agree the per-criterion split before AI starts.

Record `evaluation: ai | human | hybrid` on the Plan frontmatter and
append:

```markdown
- YYYY-MM-DD: Evaluation started — routing: <ai|human|hybrid>.
```

### Step 2 — Build and agree the verification plan

Read the Scope's acceptance criteria and the Plan's `## Testing &
Verification`. Build a table — one row per criterion, plus
orthogonal quality checks (regressions, code quality, edge cases,
docs). Each row gets a **verifier** and a concrete **method**:

```markdown
| # | Acceptance Criterion / Check | Verifier | Method |
|---|------------------------------|----------|--------|
| 1 | Embedding API <200ms p99      | AI       | `npm run bench:embedding` |
| 2 | Index updates within 5min     | Human    | Manual against staging |
| 3 | Zero dropped records on load  | AI       | `npm run test:load` |
| 4 | UI feels responsive           | Human    | Local browser session |
| Q | No regressions in core flow   | AI       | `npm test` |
```

Propose-and-confirm per routing:

- **AI** — every verifier is AI. Confirm (*Run this plan* / *Adjust
  first*). Adjust → switch to Hybrid implicitly and ask for the split.
- **Hybrid** — propose a split based on what each criterion needs.
  Confirm (*Run this plan* / *Adjust the split*). Adjust → free-form;
  let the human move rows; loop until confirmed.
- **Human** — every verifier is Human. Write each Method clearly
  enough to execute without guessing. Confirm (*Looks good* /
  *Adjust*).

Append the agreed plan:

```markdown
- YYYY-MM-DD: Verification plan agreed:
    - C1: AI (`npm run bench:embedding`) — pending
    - C2: Human (manual against staging) — pending
    - Q : AI (`npm test`) — pending
```

### Step 2.5 — Present the locked plan

Step 2 agreed it; this presents it as the locked review surface
before Step 2.6's gate. Branch on `review_format:`.

**CLI** — the Step 2 table is the surface; leave it on screen and
print one anchor:

```
○ Verification plan locked above — approve, edit, or reject at the prompt next.
```

**HTML — page 1.** After the audit line is written but before any
verification runs, dispatch `worker-html-evaluation` per
`docs/FRAMEWORK.md § worker-html-*`. No inline render.

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/evaluate/template.html`
- `output_path`:
  `.spades/evaluations/<plan_id_lower>-<YYYY-MM-DD>-plan.html`
  (worker creates the directory if missing)
- `frontmatter`:
  ```
  { mode: "plan",
    brand_label: "Verification Plan",
    h1_prefix: "Verification plan",
    page_title: "Verification",
    tagline: "Concrete verification steps to confirm this plan is
              done. Each row shows the test, who runs it. Verdicts
              populate when the evaluation completes (Step 5).",
    verdict: "PENDING", verdict_class: "pending",
    verdict_summary_html: "<p>Verification plan proposed — awaiting
              your approval. Reject or edit at the prompt in the
              CLI; otherwise the listed checks will run next.</p>",
    pass_count: 0, partial_count: 0, fail_count: 0,
    plan_id, plan_title, scope_id, scope_title,
    project, evaluated, evaluator, plugin_version }
  ```
  Counts are `0` pre-verification — no verdicts exist, so the deck
  shows its default. `project` is the active project slug; optional.
- `blocks`:
  - `objective-banner` — 0 or 1 item `{ id, title }` per
    `FRAMEWORK.md § Objective banner`. Resolve from the Plan's
    parent Scope's `strategy_link`, counting it **only** when it
    matches an existing `.spades/objectives/O-<slug>.md`; else `[]`.
  - `verification-rows` — one per step from the just-written
    `Verification plan agreed:` entry. Fields: `step`,
    `criterion_ref` (`C1`, `Q1`), `verifier`
    (`AI`/`Human`/`Test`/`Lint`/`Manual`), `verifier_class`
    (lowercase), `method` (exact command/path), `verdict`
    (`PENDING`), `verdict_class` (`pending`), `notes` (empty).
  - `audit-events` — every Plan audit entry whose `desc` contains
    `Evaluation` or `Verification plan`, chronological.
    Fields: `date, desc`.

Required markers: `<!-- SPADES-BLOCK:verification-rows -->`,
`<!-- SPADES-BLOCK:audit-events -->`.

After the worker returns:

```
○ Verification plan opened: .spades/evaluations/<plan-id>-<date>-plan.html
○ Approve, edit, or reject below — then I'll run the checks.
```

### Step 2.6 — Approve the verification plan (the gate)

`AskUserQuestion`:

1. **Approve as proposed** (Recommended) → Step 3.
2. **Edit specific rows** → free-form; update the `Verification plan
   agreed:` entry in place; in HTML mode **re-render page 1** so the
   tab matches what was agreed; loop back to this gate.
3. **Reject** → append `- YYYY-MM-DD: Verification plan rejected —
   evaluation abandoned.` and exit.

On Approve, append `- YYYY-MM-DD: Verification plan APPROVED by
human.` and continue.

### Step 3 — Execute the AI rows (fresh run only)

For every AI row: run the Method (or perform the inspection),
capture PASS / FAIL / PARTIAL, and capture short notes — a one-line
cause for failures, a one-line evidence pointer for passes
(`tests/perf.ts:42`, a command-output excerpt).

Update the audit-trail plan lines in place:

```markdown
    - C1: AI (`npm run bench:embedding`) — PASS (p99 = 187ms)
    - Q : AI (`npm test`) — PASS (143/143)
```

Then branch:

**`evaluation: ai`** (no human rows) → skip to Step 5.

**`hybrid` / `human`** — human rows are pending. Append a hand-off
line and exit cleanly:

```markdown
- YYYY-MM-DD: AI verification phase complete. Awaiting human report on C2, C4.
```

For `human` with no AI rows at all, append instead:

```markdown
- YYYY-MM-DD: Verification plan written, awaiting human execution.
```

Print the hand-off (for `human`, with the full plan as the
checklist):

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

Plan stays `evaluating`. Do **not** proceed to Step 4/5 on this run.

### Step 4 — Resume (Hybrid / Human re-invocation)

1. **Show what AI already did** (Hybrid only) — surface the
   audit-trail verdicts verbatim; don't re-summarise.
2. **Ask row by row** for the human's results: *"C2 — Index updates
   within 5min. You were testing this manually against staging. What
   did you find?"* Capture verdict + notes, updating the lines in
   place:

   ```markdown
       - C2: Human (manual against staging) — PASS (1-3min observed)
       - C4: Human (local browser session) — PARTIAL (slow on mobile <600px)
   ```

3. Append `- YYYY-MM-DD: Human verification complete.`
4. Continue to Step 5.

### Step 5 — Compile, auto-derive verdict + draft rationale

Combine AI and Human rows, then **auto-derive** the overall verdict
(no `AskUserQuestion` yet):

- Any row FAIL → **FAIL**.
- All rows PASS → **PASS**.
- Otherwise → **PARTIAL**.

**Draft a 2–3 sentence rationale** summarising the row outcomes —
the take-away the next reader should have. The human can edit it at
Step 5.6.

```markdown
## Evaluation: P-rag-pipeline-lookup-3HyD

Routing: hybrid (AI verified C1, C3, Q; Human verified C2, C4)

### Acceptance Criteria

| # | Criterion | Verifier | Verdict | Notes |
|---|-----------|----------|---------|-------|
| 1 | Embedding API <200ms p99      | AI    | PASS    | p99 = 187ms |
| 2 | Index updates within 5min     | Human | PASS    | 1-3min observed |
| 4 | UI feels responsive           | Human | PARTIAL | Slow on mobile <600px |
| Q | No regressions in core flow   | AI    | PASS    | 143/143 tests |

### Quality Assessment

- Functionality:  Works as specified for the PASS criteria
- Code quality:   Good
- Test coverage:  Adequate
- Edge cases:     Partial — mobile width breakpoint, see C4
- Documentation:  Complete

### Overall Verdict

PARTIAL — C4 needs a follow-up. (AI-derived; human confirms at Step 5.6.)
```

### Step 5.5 — Render the report

Branch on `review_format:`. The verdict and rationale come from Step
5's derivation, so the human reviews a **complete** artefact before
approving at 5.6.

**CLI** — print the Step 5 table inline, then anchor:

```
○ Verdict (proposed): <PASS|PARTIAL|FAIL>. Confirm or override below.
```

**HTML — page 2.** Dispatch `worker-html-evaluation` again and wait
for the tab to open before 5.6 fires. Identical to page 1 except:

- `output_path` ends `-report.html` (not `-plan.html`).
- `frontmatter` changes: `mode: "report"`, `brand_label:
  "Evaluation Report"`, `h1_prefix: "Evaluation report"`,
  `page_title: "Evaluation"`, `tagline: "All verdicts confirmed. The
  Plan's audit-trail line is the authoritative record; this report is
  the human's rich view."`, `verdict` / `verdict_class` from Step 5,
  `verdict_summary_html` = the Step 5 rationale HTML-escaped in
  `<p>`, and `pass_count` / `partial_count` / `fail_count` counted
  from the rows.
- `verification-rows` carry the verdicts and notes filled in from
  Steps 3/4/5. Same field schema, same `objective-banner` and
  `audit-events` resolution, same required markers.

Then print:

```
○ Evaluation report opened: .spades/evaluations/<plan-id>-<date>-report.html
○ Verdict (proposed): <PASS|PARTIAL|FAIL>. Confirm or override below.
```

Both pages now sit side by side — the pre-start plan and the
proposed-verdict report — so the human can compare them.

### Step 5.6 — Confirm the verdict (the gate)

With the report visible, ask via `AskUserQuestion`:

1. **Confirm `<derived-verdict>`** — accept verdict and rationale.
2. **Override to PASS / PARTIAL / FAIL** — offer only the two the
   derivation didn't produce.
3. **Edit rationale** — keep the verdict, capture new text free-form.

On any override or edit, apply it and re-render (page 2 in HTML, the
table in CLI), then **loop back to this question**. Never advance
until the human picks *Confirm*.

The human owns the final verdict in every routing mode — including
`ai`, where AI proposed it. This step is the gate.

## Write the Verdict (fan-out dispatch)

Apply `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`. Spawn
these **in parallel in a single message** (`subagent_type:
general-purpose`):

| Sub-agent | Resource owned | Returns |
|-----------|---------------|---------|
| `worker-file-plan-evaluate` | `.spades/plans/P-<…>.<ext>` — set frontmatter (PASS: keep `status: evaluating`; PARTIAL: roll back to `delivering` so `/spades:do` can resume, recording gaps in the audit line; FAIL: `status: rejected`) and append `- YYYY-MM-DD: Evaluation — verdict: <PASS\|PARTIAL\|FAIL>. Notes: <…>.` | `{ status: ok }` |
| `worker-file-scope-evaluate` *(only on a Scope rollup)* | `.spades/scopes/S-<slug>.<ext>` — roll up per `FRAMEWORK.md § Hierarchy → Scope status rollup` and append an audit entry. Skip when no rollup is required. | `{ status: ok }` |
| `worker-linear-evaluate` *(only when `backend: linear`)* | Linear — `record_evaluation(plan_id, verdict, notes)`: post the report as a sub-issue comment, update sub-issue status. Includes the Layer-2 freshness probe. | `{ status: ok }` |

No back-write. Collect results per § Sub-agent Dispatch's failure
semantics:

- **All ok** → record dispatch mode, continue to After Verdict.
- **`worker-file-plan-evaluate` failed** → abort with the error.
- **`worker-file-scope-evaluate` failed** → surface; the verdict is
  recorded but the Scope rollup needs a manual patch.
- **`worker-linear-evaluate` failed** → keep local files
  (canonical), surface, offer retry. Do **not** block.

When `backend: local`, only the file sub-agent(s) dispatch.

## After Verdict

**PASS**
```
✓ Plan evaluated: P-rag-pipeline-lookup-3HyD
✓ Verdict:        PASS
✓ Status:         evaluating (ready for /spades:ship)

Next:
  /spades:ship P-rag-pipeline-lookup-3HyD   — release the deliverable
```

**PARTIAL**
```
⚠ Plan evaluated: P-rag-pipeline-lookup-3HyD
⚠ Verdict:        PARTIAL — criterion 2 needs work
⚠ Status:         delivering (returning to /spades:do)

Next:
  /spades:do P-rag-pipeline-lookup-3HyD   — apply the fixes
```

**FAIL**
```
✗ Plan evaluated: P-rag-pipeline-lookup-3HyD
✗ Verdict:        FAIL — approach was wrong
✗ Status:         rejected

Next:
  /spades:plan S-add-ai-helper-bot   — re-plan with lessons learned
  /spades:scope S-add-ai-helper-bot  — re-scope if the problem was misunderstood
```

## Scope-Level Evaluation

When the target is a Scope, evaluate every Plan under it. The
Scope's verdict is the floor of the individual verdicts: any FAIL →
FAIL; any PARTIAL with no FAIL → PARTIAL; all PASS → PASS.
