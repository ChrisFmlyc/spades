---
name: evaluate
description: Check delivered work against a Plan's parent Scope acceptance criteria. Returns PASS / PARTIAL / FAIL. Human-only verdict — no test execution, no automated checks. Use after `/spades-anywhere:do` has marked a Plan as delivering and the human has done the work, when someone says "evaluate this", "check if this is done", "verify the work", or when a Plan is in status `delivering` or `evaluating`. If not PASS, this skill routes the work back to `/spades-anywhere:do` and the human keeps going.
version: 0.6.0
---

# /spades-anywhere:evaluate

You are running the Evaluate gate. The human walks the Scope's
acceptance criteria one by one and judges each *met / partial / not
met*; the verdicts aggregate to PASS / PARTIAL / FAIL, and the human
owns the result. For human work a first pass is often PARTIAL: the
skill routes back to `/spades-anywhere:do` on anything below PASS,
and the loop runs until PASS.

Read `docs/FRAMEWORK.md` § Hierarchy, § Target Resolution, § Asking
the Human, § Audit Trail, and § Output Format before running.

### Output format

Two review surfaces in both modes: the locked verification plan
before the walk (Step 1) and the report after (Step 4). The verdict
lives as audit-trail lines on the Plan's `.md`.

- **CLI mode** — the table printed in each step is the surface,
  anchored by a one-line pointer.
- **HTML mode** — each surface is a page rendered from
  `${CLAUDE_PLUGIN_ROOT}/skills/evaluate/template.html` into
  `.spades-anywhere/evaluations/` and auto-opened; the terminal gets
  a one-line nudge. `{{spades.mode}}` (`plan` | `report`) sets the
  page's brand, heading, tagline, and title. The evaluator is
  always `human`. This skill opens its own two pages only.

## Pre-Flight

1. **Confirm setup and active project.**
2. **Read `backend:` and `review_format:`.**
3. **Resolve the target** per `docs/FRAMEWORK.md § Target
   Resolution` — a Plan, a Scope (whole-scope evaluation), or a
   Quick item.
   - **ID passed** — `P-…` → Plan; `S-…` → Scope; `Q-…` → § Quick
     path.
   - **Bare invocation** — `AskUserQuestion`: *One plan*
     (`delivering` / `evaluating`), *Whole scope* (`evaluating`),
     *Quick item* (markers without an `Evaluate — verdict:` line).
   - **Zero candidates** — no Plans → `/spades-anywhere:do P-…`; no
     Scopes → keep delivering; no Quick items →
     `/spades-anywhere:quick`.
4. **Read the target** — Plan plus parent Scope, or Scope plus every
   Plan — from the `.md` files.
5. **Verify ancestors active**; hard abort on an `abandoned` Scope or
   an `abandoned` / `archived` Project. Quick items sit outside the
   hierarchy.
6. **Verify the Plan has been through Do.** `approved` →
   `/spades-anywhere:do P-…` first; evaluating undelivered work is
   meaningless.
7. **Append** `- YYYY-MM-DD: Evaluation started — routing: human.`

## Step 1 — Present the locked verification plan

One row per acceptance criterion, each verified by the human.

**CLI mode** — print one anchor and continue:

```
○ Verification plan locked — I'll walk each criterion next.
```

**HTML mode — page 1.** Render from the template per
`docs/FRAMEWORK.md § Output Format → HTML rendering`:

- `output_path`:
  `.spades-anywhere/evaluations/<plan_id_lower>-<YYYY-MM-DD>-plan.html`
  (create the directory when missing)
- `frontmatter`: `{ mode: "plan", brand_label: "Verification Plan",
  h1_prefix: "Verification plan", page_title: "Verification",
  tagline: "What we're about to walk through. One row per
  acceptance criterion. After you answer each, the completed report
  appears as page 2.", verdict: "PENDING", verdict_class:
  "pending", verdict_summary_html: "<p>Walk-through not started
  yet. The completed report appears once you've answered each
  criterion.</p>", pass_count: 0, partial_count: 0, fail_count: 0,
  plan_id, plan_title, scope_id, scope_title, project, evaluated,
  evaluator: "human", plugin_version }`
- `blocks`:
  - `objective-banner` — 0 or 1 item `{ id, title }` per
    `docs/FRAMEWORK.md § Objective banner`, from the parent Scope's
    `strategy_link`; else `[]`.
  - `verification-rows` — one per criterion. Fields: `step` (the
    criterion as a concrete check — "Confirm the venue was set up on
    time"), `criterion_ref` (`C1`, …), `verifier` (`Human`),
    `verifier_class` (`human`), `method` (`Eyes-on` until the human
    names one), `verdict` (`PENDING`), `verdict_class` (`pending`),
    `notes` (empty).
  - `audit-events` — Plan audit entries whose `desc` contains
    `Evaluation`. Fields: `date, desc`.

Required markers: `verification-rows`, `audit-events`. Then:

```
○ Verification plan opened: .spades-anywhere/evaluations/<plan-id>-<date>-plan.html
○ I'll walk you through each row next.
```

## Step 2 — Walk the criteria

For each criterion in turn, `AskUserQuestion`: *"Criterion <N>:
'<text>'. How did this turn out?"*

- **Met** — optionally a one-line note (evidence, how confirmed).
- **Partial** — a one-line note on what is missing.
- **Not met** — a one-line note on why (blocked, out of time, scope
  changed, deprioritised).
- **Defer — come back later** — for criteria with delayed
  verification ("guests reported a good time" needs a few days).
  Recorded as `deferred`, counted as partial.

Free-form follow-up after each is welcome ("met, but the cake was a
different flavour") and lands in the note. Record each `(criterion,
verdict, note)` in the audit trail as you go.

A criterion whose text no longer matches what was done is recorded
as `not met` with the explanation; the Scope is revised via
`/spades-anywhere:scope` (Edit mode) before re-evaluating rather
than the criterion being reworded to fit.

## Step 3 — Aggregate and confirm

Derive: every criterion met → **PASS**; at least one met and at
least one partial or not met (or deferred) → **PARTIAL**; every
criterion not met → **FAIL**.

Confirm via `AskUserQuestion`:

- **PASS** — proceed to `/spades-anywhere:ship`
- **PARTIAL** — back to `/spades-anywhere:do`
- **FAIL — the approach was wrong** — back to
  `/spades-anywhere:plan` (or `/spades-anywhere:scope`)
- **FAIL — keep as-is, mark rejected** — `status: rejected`

The derivation is a proposal; the human can pick a different verdict
when context (schedule pressure, new information) outweighs the
mechanical count. Then capture a rationale free-form: *"In a
sentence or two, why this verdict? What should the next reader take
away?"*

## Step 4 — Present the report

**CLI mode** — print the table of rows with verdicts and notes, then:

```
✓ Evaluation report above — verdict: <PASS|PARTIAL|FAIL>. The Plan's audit-trail line records the same verdict.
```

**HTML mode — page 2.** Same template, `output_path` ending
`-report.html`, `mode: "report"`, `brand_label: "Evaluation
Report"`, `h1_prefix: "Evaluation report"`, `page_title:
"Evaluation"`, `tagline: "All verdicts confirmed. The Plan's
audit-trail line is the authoritative record; this report is your
rich view."`, the verdict and `verdict_class` (`pass` / `partial` /
`fail`), the rationale as `verdict_summary_html`, and the counts from
the rows. `verification-rows` carry `method` from the human's note,
`verdict` (`PASS` / `PARTIAL` / `FAIL` / `NA` for deferred) with the
matching class, and `notes`. Then:

```
○ Evaluation report opened: .spades-anywhere/evaluations/<plan-id>-<date>-report.html
```

The human saves both pages to their knowledge store on their own
cadence.

## Step 5 — Write the verdict (fan-out)

One wave per `docs/FRAMEWORK.md § Sub-agent Dispatch (Fan-Out)`:

| Sub-agent | Resource owned | Returns |
|---|---|---|
| `worker-file-plan-evaluate` | `.spades-anywhere/plans/P-<…>.md` — PASS keeps `status: evaluating`; PARTIAL rolls back to `delivering`; FAIL-replan keeps `evaluating` with a "needs re-plan" note; FAIL-rejected sets `rejected`. Appends `- YYYY-MM-DD: Evaluation — verdict: <verdict>. Criteria: <met/partial/not-met counts>. Notes: <rationale>.` | `{ status: ok }` |
| `worker-file-scope-evaluate` *(Scope rollup only)* | `.spades-anywhere/scopes/S-<…>.md` — `status: evaluating` on the first PASS, plus an audit line | `{ status: ok }` |
| `worker-linear-evaluate` *(`backend: linear`)* | Linear — `record_evaluation(plan_id, verdict, notes)`: the verdict and per-criterion notes as a sub-issue comment, the matching workflow state | `{ status: ok }` |

In HTML mode, re-render the Plan's `.html` after the write. After
the wave: all ok → record the dispatch mode; plan file failed →
abort; scope file failed → surface for a manual patch; Linear failed
→ keep local files, offer a retry.

## After the verdict

```
✓ Plan evaluated: P-host-birthday-party-3HyD
✓ Verdict:        PASS (3/3 criteria met)
✓ Status:         evaluating (ready for /spades-anywhere:ship)

Next:
  /spades-anywhere:ship P-host-birthday-party-3HyD   — confirm against INTENT success criteria
```

```
⚠ Plan evaluated: P-host-birthday-party-3HyD
⚠ Verdict:        PARTIAL (2 met, 1 partial)
⚠ Note:           Photographer didn't show; phone-camera photos instead
⚠ Status:         delivering (returning to /spades-anywhere:do)

Next:
  /spades-anywhere:do P-host-birthday-party-3HyD   — keep going on the partial criterion
```

```
✗ Plan evaluated: P-host-birthday-party-3HyD
✗ Verdict:        FAIL — the approach was wrong
✗ Status:         evaluating

Next:
  /spades-anywhere:plan S-plan-birthday-party   — re-plan with what you learned
  /spades-anywhere:scope S-plan-birthday-party  — re-scope if the problem was misunderstood
```

A rejected FAIL reads `Status: rejected` and suggests revisiting the
parent Scope.

## Scope-level evaluation

For a Scope target, evaluate every Plan in turn and surface the
matrix (Plan, verdict, notes). The Scope's verdict is the floor:
any FAIL → FAIL; any PARTIAL → PARTIAL; all PASS → PASS.

## Quick path

Reached for a `Q-…` target, or with `backend: linear` an issue
labelled `spades:quick`. The marker is the whole record; the check
is against the recorded action.

1. **Read the marker** `.spades-anywhere/quick/<Q-id>.md`: `type`,
   `evidence_ref`, `delivery`, and the Gate Check.
2. **Verify the action and evidence** — did the human do what the
   marker says, and is the evidence reachable or corroborated?
3. **Re-walk the gate** against what happened.
4. **Verdict** via `AskUserQuestion`: **PASS** / **PARTIAL** (a small
   follow-up) / **FAIL** (the gate was violated; the work belongs
   in a Scope).
5. **On PARTIAL, route the follow-up** via a second
   `AskUserQuestion`: **Update this marker** (`update-marker` — add
   the missing evidence and re-run) / **Open a new quick item**
   (`new-quick` — reference this Q-id in the new Why) / **Re-route
   through the full loop** (`full-loop` — `/spades-anywhere:scope`).
   Print the exact next command.
6. **Append** `- YYYY-MM-DD: Evaluate — verdict: <verdict>.
   <rationale>.[ Follow-up: <route>.]`, and with `backend: linear`
   post the same line as a comment on the issue.
