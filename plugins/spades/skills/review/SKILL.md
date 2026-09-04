---
name: review
description: Get an independent second opinion on a SPADES Scope, Plan, or both. Spawns a PANEL of four persona subagents in parallel (scope-guardian, architecture-strategist, security-lens, adversarial-reviewer), merges their structured findings, and presents a single tiered report. Use when someone says "second opinion", "outside view", "review this", "challenge this", or when offered during /spades:approve. Non-blocking — informs the human but never gates shipping.
version: 3.8.0
---

# /spades:review

You are coordinating an independent multi-persona review. The value
of a panel is genuine independence across distinct concerns: each
persona sees the same structured summary and is primed to care about
a different aspect. The report is a second opinion — it informs the
human and gates nothing.

Read `docs/FRAMEWORK.md` § Freshness, § Target Resolution,
§ Sub-agent Dispatch, and § Output Format before running.
**Report shaping lives in
[`reference/report-format.md`](reference/report-format.md)** — the
envelope, banner, tiered digest, and persisted report; read it when
you reach § Presenting the report.

### Output format

- **Both modes** — `.spades/reviews/<target>-<date>.md`, the
  complete record.
- **CLI mode** — the tiered digest prints to the terminal.
- **HTML mode** — additionally `.spades/reviews/<target>-<date>.html`
  from `${CLAUDE_PLUGIN_ROOT}/skills/review/template.html` via
  `worker-html-review`, auto-opened; the terminal gets the
  three-line brief. One review surface per mode.

## Pre-Flight

1. **Freshness.** Four read-across sub-agents read the local
   filesystem, so:

   ```bash
   git fetch origin --quiet && git rev-list --count main..origin/main
   ```

   `0` → continue. Non-zero → abort: *"Local `main` is N commits
   behind `origin/main`. Run `/repo:sync` then re-invoke
   `/spades:review`."*
2. **Config.** Read `.spades/config` for `project:`, `backend:`, and
   `review_format:`; missing → `/spades:setup`.
3. **Resolve the mode and target.**
   - Both named (`/spades:review scope S-…`, `/spades:review plan
     P-…`) → honour directly.
   - A Scope or Plan already in session context → offer it as the
     default via one confirm (*Use <ID> — <title>?*).
   - Bare invocation → `docs/FRAMEWORK.md § Target Resolution`:
     artefact type via `AskUserQuestion` (*Scope review* / *Plan
     review* / *Full review*); candidates per the status filter
     (Scopes in any active phase; Plans in `draft`, `approved`,
     `delivering`, `evaluating`, most recently updated first); a
     picker of up to three plus *Describe a different one*; echo the
     resolved target. Zero candidates → suggest `/spades:scope
     <title>`.

   Full review takes the Plan as target and reads its parent Scope
   from `scope:`.

## Modes

| Mode | Context | The panel examines |
|---|---|---|
| Scope review | Scope only | Premises, acceptance-criteria completeness, whether the work is defined well enough to plan |
| Plan review | Plan exists | Gaps, overcomplexity, feasibility, security, strategic miscalibration |
| Full review | Both | The pair together |

## Gathering context

Assemble one structured summary from the local `.md` files (the
canonical record for both backends). Every persona gets the same
summary and no conversation history.

- **Scope review** — Statement of Intent; every acceptance
  criterion; architectural constraints (Scope plus
  `ARCHITECTURE.md`); dependencies; risks; out of scope; brief
  project context from `INTENT.md`.
- **Plan review** — the full Plan (tasks, approach, risks, posture
  per task); project context; constraints from `ARCHITECTURE.md`,
  `PATTERNS.md`, `ANTI-PATTERNS.md`.
- **Full review** — all of the above.

Over 30KB combined, truncate the Plan (keeping task titles and
approach summaries) rather than dropping Scope fields; personas need
the whole Scope for traceability.

## The panel

| Persona | Focus |
|---|---|
| `review-scope-guardian` | Scope completeness, testability, Plan→Scope traceability; gold-plating and proportionality |
| `review-architecture-strategist` | Conflicts with `ARCHITECTURE.md` / `PATTERNS.md` / `ANTI-PATTERNS.md` |
| `review-security-lens` | Auth, injection, secrets, supply chain, IAM, data sensitivity |
| `review-adversarial-reviewer` | The strongest attack on the Plan; second-order and compounding cost |

The agents ship under `agents/` and are loaded by name: spawn via
the Agent tool with `subagent_type: review-scope-guardian` and so
on. Each defines its focus, severity rubric, and output contract.

## Spawning

Spawn all four in parallel; sequentially where the runtime only
supports one at a time (scope-guardian, architecture-strategist,
security-lens, adversarial-reviewer). Four run or none; a reduced
panel collapses toward a generalist. Each gets the same
self-contained prompt:

```
You are reviewing a SPADES {mode} as the {persona} on a multi-persona
panel. Think hard and reason carefully before responding. Follow the
output contract in your persona file exactly — prose summary first,
then a JSON code block labelled `spades-findings` with strictly
schema-matching finding objects.

PROJECT CONTEXT:
{project_context}

SCOPE:
{scope_content}                 # omit for Plan-only reviews

PLAN:
{plan_content}                  # omit for Scope-only reviews

ARCHITECTURE CONSTRAINTS:
{architecture_constraints}      # ARCHITECTURE / PATTERNS / ANTI-PATTERNS
```

For a **Scope review**, append after the output-contract sentence:

> This is a Scope Review — no Plan exists yet. Review the Scope on
> its own terms — intent clarity, acceptance-criteria testability,
> premises, dependencies, and risks — and emit no finding that
> assumes a Plan (no `Task N` references, no task-count or
> Plan-traceability findings).

### Dispatch mode

Record which mode ran; the banner names it so a reader can tell a
real panel from a simulated one:

| Value | When |
|---|---|
| `subagent-dispatch` | Four independent contexts, spawned in parallel. |
| `sequential-inproc` | Four independent contexts, one at a time. |
| `degraded` | No isolated-context path; one context re-prompted with each persona's priming. A fallback, reported as one. |

Try `subagent-dispatch`, then `sequential-inproc`, then `degraded`.

## Collecting

Each persona returns a prose summary then a `spades-findings` JSON
block. Parse and collect. An invalid block (a trailing comma, say)
is reported as a parse failure with that persona's prose shown
verbatim; the JSON is not repaired.

## Merging

### Convergence

Group findings that describe the same underlying concern — the same
risk, gap, or weakness — even under different `category` values or
wording. Each group collapses to one finding: keep the sharpest
statement (prefer `high` confidence) and add `also_flagged_by`
naming the other personas. Distinct concerns stay separate even
when category or wording coincide.

Convergence is the panel's strongest signal. It is a judgement made
by reading: each persona's `category` enum is disjoint by design, so
a mechanical key match can never fire across personas. Be
conservative: two related findings about different failure modes on
the same task stay separate. A false merge hides a finding; a missed
merge costs an annotation.

### Sort

Severity first (`blocking` > `major` > `minor`); within a bucket, a
longer `also_flagged_by` first. `confidence` is a display-only
`high | low` annotation. There is no merge-side filter: every
persona self-caps at three primary findings (plus a reserved slot
for the scope guardian and adversarial reviewer), so volume is
controlled at generation and at presentation, never by dropping.

### Worked example

Six findings on one Plan:

| Persona | Severity | Category | Concern |
|---|---|---|---|
| security-lens | major | `trust-boundary` | Task 2's webhook trusts a caller-supplied signature header unverified |
| adversarial-reviewer | major | `hidden-assumption` | Plan assumes the caller is authenticated upstream; if wrong, Task 2 processes forged events |
| architecture-strategist | major | `patterns-drift` | Task 2's handler bypasses the request-validation middleware PATTERNS.md mandates |
| scope-guardian | minor | `acceptance-criteria` | Criterion 3 ("events are handled") states no success condition |
| adversarial-reviewer | minor | `integration-blind-spot` | No retry or backoff for the downstream call in Task 4 |
| scope-guardian | minor | `gold-plating` | Task 5 adds a config flag for an export format the Scope never mentions |

Merges to four: the first three are one concern (Task 2 trusts an
unverified caller) despite three categories — keep one, `also_flagged_by:
["adversarial-reviewer", "architecture-strategist"]`; the other
three are distinct, including the retry finding, which shares a
persona with finding 1 but not a concern. `findings_total: 4`.

## Presenting the report

**Read [`reference/report-format.md`](reference/report-format.md) and
follow it.** A run produces the tiered digest and the full persisted
report; the report file is written before the digest prints.

## Cross-model synthesis

Add only what changes a decision:

- **Disagreements** — findings you think are wrong or mis-graded,
  or that lack context the panel didn't have.
- **Tension points** — genuine conflicts for the human to resolve,
  stated neutrally.

```
CROSS-MODEL SYNTHESIS:

Agreement: <one line — e.g. "No disagreements; I second the panel.">
Disagreements: <findings with reasoning — omit when none>
Tension points (for the human to resolve — omit when none):

  TENSION: <topic>
  Panel says:    X
  My view:       Y
  Context the panel didn't have: Z
```

The synthesis appears in both the digest and the persisted report.

## Human decision — `AskUserQuestion`

- **Act on specific findings** — by severity, persona, or message.
- **Continue as-is** — noted, proceed without changes.
- **Discuss further** — work through the tension points.

The human decides what to act on; findings are applied to a Scope or
Plan only on their instruction.

## Brief

**HTML mode:**

```
✓ Review report: .spades/reviews/<target>-<date>.md
○ .spades/reviews/<target>-<date>.html opened in browser
Next: /spades:approve P-<id>   — apply or override findings
```

**CLI mode:** the write confirmation, the merged digest once, then
the same `Next:` line.

## With `/spades:approve`

The human runs each separately: this skill writes the report and
exits; `/spades:approve` reads it as extra context for the
checklist. The panel supplements the checklist and replaces none of
it. Fast-track work (`/spades:quick`) is too small for a panel; a
review request on a quick item is a signal to use the full loop.
