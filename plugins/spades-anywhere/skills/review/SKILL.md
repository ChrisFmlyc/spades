---
name: review
description: Get an independent second opinion on a SPADES Scope, Plan, or both. Spawns a PANEL of four persona subagents in parallel (scope-guardian, architecture-strategist, security-lens, adversarial-reviewer), merges their structured findings, and presents a single tiered report. Use when someone says "second opinion", "outside view", "review this", "challenge this", or when offered during /spades-anywhere:approve. Non-blocking — informs the human but never gates shipping.
version: 0.3.0
---

## Pre-Flight

### Step 1 — Freshness check (mandatory)

Per `docs/FRAMEWORK.md` § Freshness (the canonical contract for
this plugin; the sister `spades` plugin documents the same rule
under `AGENTS.md` § Freshness Before Read-Across), this skill spawns
four read-across subagents that read the local filesystem. A stale
local `main` will produce stale findings — every persona will flag
issues that have already shipped.

Verify before spawning the panel:

Only applies when the consumer is in the local-backend + git
scenario (see `docs/FRAMEWORK.md § Freshness`). In Linear-backend or
no-git local scenarios (the common `spades-anywhere` case), this
probe is a no-op.

```bash
git rev-parse --is-inside-work-tree 2>/dev/null && \
  git fetch origin --quiet && git rev-list --count main..origin/main
```

- No git repo, or returns `0` → fresh. Continue.
- Returns non-zero → abort with the message: *"Local `main` is N
  commits behind `origin/main`. Sync (e.g. `git pull` or
  `/repo:sync` if you have the `repo` plugin) then re-invoke
  `/spades-anywhere:review`. Spawning a panel against stale state
  wastes reviewer cycles and produces false findings."* Do not
  proceed.

This is the Layer 2 enforcement of the freshness rule — the panel
never runs against stale state.

### Step 2 — Config + backend

Read `.spades-anywhere/config` for the active project. If the file is missing,
suggest `/spades-anywhere:setup` and abort — review needs Scope/Plan context to
review.

`/spades-anywhere:review` reads from the active backend (via the contract in
`docs/FRAMEWORK.md` § Backend Interface) for Scope and Plan content,
but the review report itself always lands locally at
`.spades-anywhere/reviews/<slug>-<date>.md`.

# SPADES Review — Persona Panel Second Opinion

### Output format

This skill honours `review_format:` from
`.spades-anywhere/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML) → Universal
rule`. In **both** modes, write the tiered report to
`.spades-anywhere/reviews/<target>-<date>.md` — this is the
AI-readable source of truth and the canonical record. In **CLI
mode** the inline panel digest also prints to the terminal (the
human's only review surface). In **HTML mode**, *instead* of
printing the digest, render via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/review/template.html` — sidebar
verdict roll-up, persona-card grid, and severity-tab findings —
and write `.spades-anywhere/reviews/<target>-<date>.html` for
the human's view, then auto-open. The four-persona panel
dispatch and merge logic are identical between modes; HTML mode
is additive on the file system (the `.md` always exists; the
`.html` is added) and strictly alternative on the human's
review surface (digest in the terminal OR digest rendered in
the browser, never both).

You are coordinating an independent multi-persona review of SPADES work.
The value of a panel review comes from **genuine independence across
distinct concerns** — each persona sees the same structured summary but
is primed to care about a different aspect. A generalist reviewer
collapses a review into the most obvious concern; a persona panel
surfaces four distinct perspectives and merges the findings.

This is a **second opinion**. It never gates approval or delivery — the
report is advisory. The human decides what to act on.

## When This Skill Is Used

Three modes depending on what context exists:

### 1. Scope Review (before planning)

Only a Scope exists; no Plan yet. The panel challenges premises,
acceptance criteria completeness, and whether the work is well-defined
enough for planning.

### 2. Plan Review (after planning)

A Plan exists and the human wants an independent technical review
before approval. The panel looks for gaps, overcomplexity, feasibility
risks, security concerns, and strategic miscalibration.

### 3. Full Review (Scope + Plan together)

Both artefacts available — the default when invoked during
`/spades-anywhere:approve`. The panel reviews them as a pair.

## Determining the Mode and Target

Two pieces of information are needed: the **mode** (Scope / Plan /
Full review) and the **target** (which Scope or Plan).

### Quick paths (no interactive flow needed)

1. If invoked from inside `/spades-anywhere:approve`, default to **Full
   Review** on the Plan and Scope `/spades-anywhere:approve` is operating on
   — both are already in context.
2. If the human invocation explicitly names both mode AND target
   (e.g. `/spades-anywhere:review scope S-add-ai-helper-bot` or `/spades-anywhere:review
   plan P-rag-pipeline-lookup-3HyD`), honour it directly.
3. If a Plan or Scope is already in conversation context from the
   current session (e.g. mid-`/spades-anywhere:plan`), surface it as the
   default via a single confirm prompt — `Use <ID> — <title>?` — but
   still let the human pick a different one.

### Bare-invocation flow

If `/spades-anywhere:review` is invoked with no argument and no Scope/Plan in
context, run **Target Resolution** per `docs/FRAMEWORK.md` § Target
Resolution:

1. **Step 1 (artefact type).** Ask via `AskUserQuestion`:
   - *Scope review* — review the outcome record (premises,
     acceptance criteria, constraints)
   - *Plan review* — review one Plan in detail
   - *Full review* — review a Plan together with its parent Scope
2. **Step 2 (list candidates).** Per the per-skill status filter in
   FRAMEWORK.md § Target Resolution:
   - **Scope review** → list Scopes for the active project in any
     active phase (`scoped`, `planning`, `delivering`,
     `evaluating`, `shipping`).
   - **Plan review** / **Full review** → list Plans for the active
     project in `draft`, `approved`, `delivering`, or `evaluating`
     status. Most-recently-updated first.
3. **Step 3 (picker).** Present up to 3 candidates plus a
   *Describe a different one* fallback. If the candidate set is
   empty, suggest `/spades-anywhere:scope <title>` and stop.
4. **Step 4 (fuzzy-match if needed).** Resolve any free-form
   description against the candidate set.
5. **Step 5 (echo).** Briefly confirm the resolved target before
   continuing.

For **Full Review**, the Plan is the picked target; the parent
Scope is read automatically from the Plan's `scope:` frontmatter.

## Gathering Context

Before spawning the panel, assemble a structured summary. Every persona
subagent gets the same summary — no conversation history.

### For Scope Review, gather:

- **Statement of Intent** — the what and why
- **Acceptance Criteria** — the full list
- **Constraints** — from the Scope and INTENT.md
- **Dependencies** — what must be in place
- **Risks / Unknowns** — what the scoper flagged
- **Out of Scope** — the boundaries
- **Project context** — brief description of the project (from
  INTENT.md or repo structure)

### For Plan Review, gather:

- **Plan content** — the full plan (tasks, approach, risks, bundles,
  execution posture per task)
- **Project context**
- **Constraints** — from INTENT.md (project intent and success
  criteria) and the Scope's `Constraints` section (budget, schedule,
  stakeholders, tools); personas read these themselves if needed.

### For Full Review, gather all of the above.

If any of this context comes from Linear, fetch it via MCP. If it is in
the conversation, extract it. If a plan file exists in `.spades-anywhere/plans/`,
read it.

**Truncation rule:** If the combined context exceeds 30KB, truncate the
Plan content (keeping task titles and approach summaries) rather than
dropping Scope fields. Personas need the full Scope to review
traceability.

## The Panel

Four persona subagents, each defined by a bundled `review-*` agent:

| Persona file                                    | Focus                                                                   |
|-------------------------------------------------|-------------------------------------------------------------------------|
| `review-scope-guardian`                   | Scope completeness, testability, Plan→Scope traceability; gold-plating / proportionality (absorbed remit) |
| `review-architecture-strategist`          | Conflicts with INTENT.md         |
| `review-security-lens`                    | Auth, injection, secrets, supply chain, IAM, data sensitivity           |
| `review-adversarial-reviewer`             | Strongest attack on the Plan — what will fail and why; second-order / compounding cost (absorbed remit) |

The panel was five personas through v1.1–v1.x; M-994 folded the
`yagni-simplicity` persona's remit into the scope guardian (gold-plating
and proportionality) and the adversarial reviewer (second-order and
compounding cost), and the panel is now four. See `docs/FRAMEWORK.md`
§Multi-persona Review for the rationale.

The four reviewer-persona agents are bundled with the SPADES plugin
under `agents/` and are auto-loaded by Claude Code by name — you spawn
them via the Agent tool with `subagent_type: review-scope-guardian`
(and similar). You do not Read their files directly; the runtime
loads them. Each persona file defines the persona's focus, the
severity rubric, and the output contract.

## Spawning the Panel

**Spawn all four personas in parallel where the runtime supports it;
otherwise sequentially.** Parallel is a performance nicety, not a
correctness requirement — the merge logic doesn't care.

In Claude Code, use the `Task` tool (or the persona-specific
`subagent_type`) to spawn each persona. Each call gets the same
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

CONSTRAINTS:
{constraints}                   # INTENT.md success criteria + Scope's `Constraints` section (budget, schedule, stakeholders, tools)
```

The `Think hard and reason carefully before responding` line is
intentional — each persona should use maximum reasoning effort since
the panel is meant to be the strongest independent view available.

### Scope Review mode — suppress Plan-only findings

When the `{mode}` is **Scope Review**, append this line to every
persona prompt, immediately after the output-contract sentence:

> This is a Scope Review — no Plan exists yet. Do not emit findings
> that assume a Plan: no `Task N` references, no bundle-count or
> task-count findings, no Plan-traceability findings. Review the Scope
> on its own terms — intent clarity, acceptance-criteria testability,
> premises, dependencies, and risks.

The four persona files are written generically and several lean
Plan-oriented in their rubric examples; this line keeps a Scope-only
review from producing findings that reference a Plan that does not
exist. Do not append it for Plan Review or Full Review.

If the runtime does not support parallel Task spawns, run the four
sequentially in this order: scope-guardian, architecture-strategist,
security-lens, adversarial-reviewer. Never skip a persona to save
time — a reduced panel collapses back toward generalist.

### Dispatch-mode determination (v1.1.1)

Record the **dispatch mode** during spawning. It is one of exactly three
values; the banner in the report header names it verbatim so a consumer
can distinguish a real panel from a simulated one:

| Value                  | When to record                                                                                                            |
|------------------------|---------------------------------------------------------------------------------------------------------------------------|
| `subagent-dispatch`    | The runtime supports spawning `.claude/agents/*.md` (or equivalent) as **independent subagent contexts**, and you spawned all four personas **in parallel** as separate contexts. |
| `sequential-inproc`    | The runtime supports spawning personas in **isolated contexts** but only one at a time. You ran the four sequentially, still as separate contexts per persona. |
| `degraded`             | No isolated-context path was available and you simulated the personas by re-prompting a single model context with each persona's priming. This is a fallback, not a panel. |

Decision rules at spawn time:

1. **Try `subagent-dispatch` first.** If the runtime accepts parallel
   Task-tool invocations that land in isolated contexts, use it. This is
   the default and strongest path.
2. **Fall back to `sequential-inproc`** if parallel spawning fails or is
   unsupported but isolated per-persona contexts are still possible.
3. **Fall back to `degraded`** only when no isolated-context path is
   available. Never silently degrade — read the next section.

**Degrading is allowed, concealing that you degraded is not.** Consumers
whose audit trails cite "multi-persona review" need to be able to tell
which invocation mode produced a given report. Record the mode honestly
and emit it in the banner (see Report envelope + Presenting the Report
below). The `degraded` value is load-bearing — it tells a downstream
tool that this specific report was generated from one model wearing
four prompt hats, not four independent contexts.

## Collecting the Findings

Each persona returns a short prose summary followed by a JSON code
block labelled `spades-findings`. Parse each block and collect all
findings into a single list.

If a persona's JSON block is invalid (rare; LLMs occasionally emit
trailing commas), present its prose summary verbatim and note the
parse failure alongside the report. Do not attempt to auto-repair
malformed JSON — showing the human "persona X returned malformed JSON"
is more useful than risking silent data corruption.

## Merging: Convergence and Sort

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
`category` enum, so a `(category, message)` key can never fire
across personas. Personas staying in distinct lanes is the
deliberate design that stops the panel collapsing into four
restatements of one concern; it is not the same as personas never
converging.

Be conservative. If two findings are *related* but not the *same
concern* — a security worry about an auth boundary and an
adversarial worry about a different failure mode on the same task —
keep both. A false merge hides a finding; a missed merge only costs
an annotation.

### Sort

Severity first: `blocking` > `major` > `minor`. Within a bucket, a
longer `also_flagged_by` array comes first. **`confidence` is not a
sort key** — it is a display-only `high | low` annotation. There is
no `severity × confidence` arithmetic, and `nit` is no longer a
severity.

### No merge-side filter

There is no confidence filter at merge time. Every persona already
self-caps at three primary findings (plus a reserved-slot finding
for the scope guardian and adversarial reviewer), so filtering
happens at generation time. The merge keeps everything; volume is
controlled at presentation by the tiered digest, never by dropping
findings here.

### Worked example

Four personas file six findings on the same Plan:

| Persona | Severity | Category | Concern |
|---|---|---|---|
| security-lens | major | `trust-boundary` | Task 2's webhook trusts a caller-supplied signature header unverified |
| adversarial-reviewer | major | `hidden-assumption` | Plan assumes the caller is authenticated upstream; if wrong, Task 2 processes forged events |
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

## Cross-Model Synthesis

After presenting the merged panel output, add your synthesis as the
coordinating agent — but keep it to what changes a decision. Show only:

- **Disagreements** — findings you think are wrong, mis-severity, or
  miss context the panel did not have (conversation history, prior
  human decisions). State what you think differently and why.
- **Tension points** — genuine conflicts for the human to resolve,
  stated neutrally rather than picking a side.

Do **not** enumerate the findings you agree with — agreement needs no
airtime. Collapse it to a single line. If there are no disagreements
and no tensions, that one line is the whole synthesis.

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

This synthesis appears in both the inline report and the persisted
full report.

## User Decision

After synthesis, ask the human what they want to do via the
AskUserQuestion tool:

```
The panel review is above. What would you like to do?

A) **Act on specific findings** — name which ones to address (by
   severity, persona, or message).
B) **Continue as-is** — review noted, proceed without changes.
C) **Discuss further** — work through tension points before deciding.
```

**Non-blocking.** The human can acknowledge the review and move on.
The panel never gates approval or delivery — it informs.

## Integration with /spades-anywhere:approve

When invoked from `/spades-anywhere:approve`:

1. `/spades-anywhere:approve` presents the approval checklist with its own
   assessments.
2. Before asking for the approval decision, it offers:
   "Want a panel review from an independent perspective?"
3. If the human says yes, `/spades-anywhere:approve` invokes this skill.
4. After the merged report, synthesis, and user decision,
   `/spades-anywhere:approve` resumes with the approval decision.

The panel does NOT replace any part of the approval checklist. It
supplements it.

## What This Skill Must Never Do

- **Gate shipping.** The panel is informational. It does not have
  authority to reject a plan or block delivery.
- **Auto-apply findings.** The human decides what to act on. Never
  rewrite the Scope or Plan based on findings without explicit human
  instruction.
- **Claim "panel" or "multi-persona" in degraded output.** When
  `dispatch_mode` is `degraded`, the coordinator MUST NOT use the
  words "panel" or "multi-persona" in the report title, framing
  prose, or synthesis — those words imply independence that a
  single-context simulation did not have. Use
  `SINGLE-CONTEXT SIMULATION (degraded)` as the title and describe
  the run accurately. This is the load-bearing honesty rule the whole
  dispatch-mode machinery exists to enforce; breaking it retroactively
  falsifies every downstream audit trail that cites the report.
- **Omit the dispatch-mode banner or envelope.** Both are required on
  every invocation, even when dispatch is degraded — *especially*
  when dispatch is degraded. A report without the banner is indistinguishable
  from a pre-v1.1.1 report, and downstream tooling will misread it.
- **Suppress a blocking finding, or skip the persisted report.** Every
  `blocking` finding is shown in full in the inline report — blocking is
  never collapsed to a count line. The full report is written to
  `.spades-anywhere/reviews/` on every run, `degraded` runs included. The inline
  digest tiers `major` and `minor`; it never tiers `blocking`.
- **Leak conversation context into persona prompts.** Each persona
  sees only the structured summary. Passing "primary agent thinks X"
  into the persona prompt defeats the independence.
- **Summarise a persona's prose in your own words.** Verbatim only.
- **Run during fast-track (`/spades-anywhere:quick`).** Fast-track work is too
  small to warrant a panel review. If someone asks for a review on a
  quick-path item, suggest the full loop instead.
- **Skip personas to save time.** Four personas or none. A reduced
  panel collapses back toward generalist and loses the coverage
  guarantee.
- **Repair malformed JSON from a persona.** Report the parse failure;
  do not guess.
