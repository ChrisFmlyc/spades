---
name: review
description: Get an independent second opinion on a SPADES Scope, Plan, or both. Spawns a PANEL of four persona subagents in parallel (scope-guardian, architecture-strategist, security-lens, adversarial-reviewer), merges their structured findings, and presents a single tiered report. Use when someone says "second opinion", "outside view", "review this", "challenge this", or when offered during /spades:approve. Non-blocking — informs the human but never gates shipping.
version: 3.6.1
---

# SPADES Review — Persona Panel Second Opinion

You are coordinating an independent multi-persona review. The value
of a panel comes from **genuine independence across distinct
concerns** — each persona sees the same structured summary but is
primed to care about a different aspect. A generalist reviewer
collapses a review into the most obvious concern; a panel surfaces
four perspectives and merges them.

This is a **second opinion**. It never gates approval or delivery.
The human decides what to act on.

**Report shaping lives in
[`reference/report-format.md`](reference/report-format.md)** — the
envelope schema, dispatch banner, tiered digest, and persisted
report. Read it when you reach "Presenting the Report".

### Output format

Honours `review_format:` per `docs/FRAMEWORK.md § Output Format →
Universal rule`. In **both** modes write the tiered report to
`.spades/reviews/<target>-<date>.md` — the AI-readable source of
truth. In **CLI mode** the inline digest also prints to the terminal.
In **HTML mode** the digest is *not* printed; render via
`${CLAUDE_PLUGIN_ROOT}/skills/review/template.html`, write
`.spades/reviews/<target>-<date>.html`, and auto-open it.

Panel dispatch and merge logic are identical between modes. HTML is
additive on the filesystem (the `.md` always exists) and strictly
alternative on the review surface — digest in the terminal **or** in
the browser, never both.

## Pre-Flight

### Step 1 — Freshness check (mandatory)

This skill spawns four read-across subagents that read the local
filesystem. A stale `main` produces stale findings — every persona
flags issues that already shipped.

```bash
git fetch origin --quiet && git rev-list --count main..origin/main
```

- `0` → fresh, continue.
- Non-zero → abort: *"Local `main` is N commits behind
  `origin/main`. Run `/repo:sync` then re-invoke `/spades:review`.
  Spawning a panel against stale code wastes reviewer cycles and
  produces false findings."* Do not proceed.

This is Layer 2 of `FRAMEWORK.md § Freshness` — the panel never runs
against stale state.

### Step 2 — Config + backend

Read `.spades/config` for the active project; missing → suggest
`/spades:setup` and abort, since review needs Scope/Plan context.

Scope and Plan content comes from the active backend via
`FRAMEWORK.md § Backend Interface`; the report itself always lands
locally under `.spades/reviews/`.

## Modes and target

Three modes by available context:

| Mode | Context | What the panel does |
|---|---|---|
| **Scope review** | Scope only, no Plan | Challenges premises, acceptance-criteria completeness, whether the work is defined well enough to plan |
| **Plan review** | Plan exists | Gaps, overcomplexity, feasibility risk, security, strategic miscalibration |
| **Full review** | Both — the default when offered during `/spades:approve` | Reviews them as a pair |

### Quick paths

1. Invoked from inside `/spades:approve` → **Full Review** on the
   Plan and Scope already in context.
2. Invocation names both mode and target (`/spades:review scope
   S-add-ai-helper-bot`) → honour it directly.
3. A Plan or Scope is already in session context → surface it as the
   default via one confirm prompt (`Use <ID> — <title>?`), still
   allowing a different pick.

### Bare invocation

Run **Target Resolution** per `FRAMEWORK.md § Target Resolution`:

1. **Artefact type** via `AskUserQuestion` — *Scope review* / *Plan
   review* / *Full review*.
2. **Candidates** per the per-skill status filter: Scope review →
   Scopes in any active phase (`scoped`, `planning`, `delivering`,
   `evaluating`, `shipping`); Plan/Full review → Plans in `draft`,
   `approved`, `delivering`, `evaluating`, most-recently-updated
   first.
3. **Picker** — up to 3 candidates plus *Describe a different one*.
   Empty set → suggest `/spades:scope <title>` and stop.
4. **Fuzzy-match** any free-form description against the set.
5. **Echo** the resolved target before continuing.

For Full Review the Plan is the picked target; the parent Scope is
read from its `scope:` frontmatter.

## Gathering context

Assemble a structured summary before spawning. Every persona gets the
same summary and **no conversation history**.

- **Scope review** — Statement of Intent; Acceptance Criteria (full
  list); Architectural Constraints (Scope + ARCHITECTURE.md);
  Dependencies; Risks / Unknowns; Out of Scope; brief project
  context.
- **Plan review** — full Plan (tasks, approach, risks, bundles,
  per-task execution posture); project context; architecture
  constraints from ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md
  (personas read these themselves if needed).
- **Full review** — all of the above.

Fetch from Linear via MCP where that's the backend, extract from
conversation where present, read `.spades/plans/` where a file
exists.

**Truncation rule:** over 30KB combined, truncate the Plan (keeping
task titles and approach summaries) rather than dropping Scope
fields. Personas need the full Scope to review traceability.

## The panel

| Persona | Focus |
|---|---|
| `review-scope-guardian` | Scope completeness, testability, Plan→Scope traceability; gold-plating / proportionality (absorbed remit) |
| `review-architecture-strategist` | Conflicts with ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md |
| `review-security-lens` | Auth, injection, secrets, supply chain, IAM, data sensitivity |
| `review-adversarial-reviewer` | Strongest attack on the Plan — what fails and why; second-order / compounding cost (absorbed remit) |

The panel was five personas through v1.x; M-994 folded
`yagni-simplicity`'s remit into the scope guardian and the
adversarial reviewer. See `FRAMEWORK.md § Multi-persona Review`.

These agents ship under `agents/` and are auto-loaded by name — spawn
via the Agent tool with `subagent_type: review-scope-guardian` and
similar. Do **not** Read their files; the runtime loads them. Each
defines its focus, severity rubric, and output contract.

## Spawning the panel

**Spawn all four in parallel where the runtime supports it,
otherwise sequentially.** Parallel is a performance nicety, not a
correctness requirement — the merge doesn't care.

Each call gets the same self-contained prompt:

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

The *"Think hard"* line is intentional — the panel should use maximum
reasoning effort, since it is meant to be the strongest independent
view available.

**Scope Review mode — suppress Plan-only findings.** Append this to
every persona prompt, right after the output-contract sentence:

> This is a Scope Review — no Plan exists yet. Do not emit findings
> that assume a Plan: no `Task N` references, no bundle-count or
> task-count findings, no Plan-traceability findings. Review the Scope
> on its own terms — intent clarity, acceptance-criteria testability,
> premises, dependencies, and risks.

The persona files lean Plan-oriented in their rubric examples; this
keeps a Scope-only review from referencing a Plan that doesn't exist.
Do not append it for Plan or Full Review.

Without parallel spawning, run the four sequentially in this order:
scope-guardian, architecture-strategist, security-lens,
adversarial-reviewer. **Never skip a persona to save time** — a
reduced panel collapses back toward generalist.

### Dispatch mode

Record the mode during spawning. The banner names it verbatim so a
consumer can tell a real panel from a simulated one:

| Value | When |
|---|---|
| `subagent-dispatch` | The runtime spawns persona agents as **independent contexts** and you spawned all four **in parallel**. |
| `sequential-inproc` | Isolated contexts available but only one at a time; you ran four sequentially, still one context per persona. |
| `degraded` | No isolated-context path; you simulated personas by re-prompting a single context with each priming. A fallback, not a panel. |

Try `subagent-dispatch` first; fall back to `sequential-inproc` if
parallel spawning is unsupported; fall back to `degraded` only when
no isolated-context path exists.

**Degrading is allowed. Concealing that you degraded is not.**
Consumers whose audit trails cite "multi-persona review" must be able
to tell which mode produced a report. The `degraded` value is
load-bearing — it says one model wore four prompt hats.

## Collecting the findings

Each persona returns a prose summary then a JSON block labelled
`spades-findings`. Parse each and collect into one list.

If a block is invalid (LLMs occasionally emit trailing commas),
present that persona's prose verbatim and note the parse failure.
**Do not auto-repair malformed JSON** — "persona X returned malformed
JSON" is more useful than silent data corruption.

## Merging: convergence and sort

The merge turns four lists into one ranked report. Two jobs: surface
**convergence**, then rank what remains.

### Convergence

Group findings that describe the **same underlying concern** — the
same risk, gap, or weakness — even when filed under different
`category` values or worded differently. Each group collapses to a
**single finding**: keep whichever states it most sharply (prefer
`high` confidence over `low`) and add an `also_flagged_by` array
naming the other personas. Findings describing **distinct concerns
stay separate**, even if category or wording coincide.

Convergence is the panel's strongest signal — "three of four
personas independently flagged this" outweighs any lone finding.
Detecting it is a judgement made by reading the findings, **not a
mechanical key match**: each persona file defines a *disjoint*
`category` enum, so a `(category, message)` key can never fire across
personas. Personas staying in distinct lanes is the deliberate design
that stops the panel collapsing into four restatements of one
concern; it is not the same as personas never converging.

Be conservative. If two findings are *related* but not the *same
concern* — a security worry about an auth boundary and an adversarial
worry about a different failure mode on the same task — keep both. A
false merge hides a finding; a missed merge only costs an annotation.

### Sort

Severity first: `blocking` > `major` > `minor`. Within a bucket, a
longer `also_flagged_by` array comes first. **`confidence` is not a
sort key** — it is a display-only `high | low` annotation. There is
no `severity × confidence` arithmetic, and `nit` is no longer a
severity.

### No merge-side filter

There is no confidence filter at merge time. Every persona already
self-caps at three primary findings (plus a reserved-slot finding for
the scope guardian and adversarial reviewer), so filtering happens at
generation time. The merge keeps everything; volume is controlled at
presentation by the tiered digest, never by dropping findings here.

### Worked example

Four personas file six findings on the same Plan:

| Persona | Severity | Category | Concern |
|---|---|---|---|
| security-lens | major | `trust-boundary` | Task 2's webhook trusts a caller-supplied signature header unverified |
| adversarial-reviewer | major | `hidden-assumption` | Plan assumes the webhook caller is authenticated upstream; if wrong, Task 2 processes forged events |
| architecture-strategist | major | `patterns-drift` | Task 2's handler bypasses the request-validation middleware PATTERNS.md mandates |
| scope-guardian | minor | `acceptance-criteria` | Criterion 3 ("events are handled") states no success condition |
| adversarial-reviewer | minor | `integration-blind-spot` | No retry or backoff for the downstream call in Task 4 |
| scope-guardian | minor | `gold-plating` | Task 5 adds a config flag for an export format the Scope never mentions |

Merges to **four** findings:

1. The first three describe **one concern** — Task 2 trusts an
   unverified caller — despite three different categories. Keep one
   (all `major`), set `also_flagged_by: ["adversarial-reviewer",
   "architecture-strategist"]`.
2. The untestable criterion is distinct; stands alone.
3. The missing retry is distinct — **not** merged with 1 even though
   both came from adversarial-reviewer. Convergence is about the
   concern, not the persona.
4. The gold-plating finding is the reserved-slot absorbed remit;
   distinct, stands alone.

Nothing is dropped. Sorted: finding 1 (`major`, `also_flagged_by`
length 2), then the three `minor` findings in no significant order.
Envelope records `findings_total: 4`.

## Presenting the report

**Read [`reference/report-format.md`](reference/report-format.md) and
follow it.** It owns the envelope, the banner and its three-point
agreement check, the tiered inline digest (both normal and degraded
shapes), and the persisted `.md` / `.html` writes.

A run produces two artefacts: a **tiered inline digest** (leads with
signal, fits a screen) and a **full persisted report** (the complete
audit record). The report file MUST be written before the digest
prints.

## Cross-model synthesis

Add your synthesis as coordinator — but only what changes a decision:

- **Disagreements** — findings you think are wrong, mis-severity, or
  missing context the panel didn't have (conversation history, prior
  human decisions). State what you think and why.
- **Tension points** — genuine conflicts for the human to resolve,
  stated neutrally rather than picking a side.

**Do not enumerate findings you agree with** — agreement needs no
airtime; collapse it to one line. No disagreements and no tensions
means that line is the whole synthesis.

```
CROSS-MODEL SYNTHESIS:

Agreement: <one line — e.g. "No disagreements; I second the panel.">
Disagreements: <findings with reasoning — omit this line if none>
Tension points (for the human to resolve — omit if none):

  TENSION: <topic>
  Panel says:    X
  My view:       Y
  Context the panel didn't have: Z
```

This appears in both the inline digest and the persisted report.

## User decision

Ask via `AskUserQuestion`:

```
The panel review is above. What would you like to do?

A) **Act on specific findings** — name which ones to address (by
   severity, persona, or message).
B) **Continue as-is** — review noted, proceed without changes.
C) **Discuss further** — work through tension points before deciding.
```

**Non-blocking.** The human can acknowledge and move on; the panel
never gates approval or delivery.

## End-of-skill brief

**HTML mode** — 3 lines, no body dump (the tab IS the surface):

```
✓ Review report: .spades/reviews/<target>-<date>.md
○ .spades/reviews/<target>-<date>.html opened in browser
Next: /spades:approve P-<id>   — apply or override findings
```

**CLI mode** — confirm the write, then print the merged report once:

```
✓ Review report: .spades/reviews/<target>-<date>.md

<merged report body>

Next: /spades:approve P-<id>   — apply or override findings
```

## After the brief — record Leads from unactioned findings

The panel's non-blocking findings are already Lead-shaped: specific,
out of scope for the Plan under review, and blocking nothing. Today
they die in the report. Record them instead.

Once the brief is printed, invoke
**`/spades:leads --from review --report <path-to-the-report.md>`**.

- **Non-blocking findings only.** Anything the human is about to act
  on at `/spades:approve` is not a Lead — it is the work.
- Budget is five. The panel is already ranked, so the scout is mostly
  filtering and de-duplicating rather than judging afresh.
- **Never ask.** Never block: the review report stands on its own.
- Skipped entirely when `leads: off` in `.spades/config`.

## Relationship with /spades:approve

`/spades:approve` does not invoke this skill inline. The human runs
each separately: `/spades:review` runs the panel, writes the report,
and exits; `/spades:approve` then reads that report (if present) as
extra context for its checklist before asking for routing.

The panel supplements the approval checklist. It never replaces any
part of it.

## What this skill must never do

- **Gate shipping.** The panel is informational — no authority to
  reject a Plan or block delivery.
- **Auto-apply findings.** Never rewrite a Scope or Plan from
  findings without explicit human instruction.
- **Claim "panel" or "multi-persona" in degraded output.** Use
  `SINGLE-CONTEXT SIMULATION (degraded)` and describe the run
  accurately. This is the load-bearing honesty rule the whole
  dispatch-mode machinery exists to enforce; breaking it
  retroactively falsifies every audit trail citing the report.
- **Omit the banner or envelope** — required on every invocation,
  *especially* a degraded one. Without them a report is
  indistinguishable from pre-v1.1.1 output and tooling misreads it.
- **Suppress a blocking finding, or skip the persisted report.** The
  digest tiers `major` and `minor`; it never tiers `blocking`. The
  file is written on every run, `degraded` included.
- **Leak conversation context into persona prompts.** Each persona
  sees only the structured summary. Passing "the primary agent thinks
  X" defeats the independence.
- **Summarise a persona's prose in your own words.** Verbatim only.
- **Run during fast-track (`/spades:quick`).** Too small to warrant a
  panel; suggest the full loop instead.
- **Skip personas to save time.** Four or none.
- **Repair malformed JSON.** Report the parse failure; do not guess.
