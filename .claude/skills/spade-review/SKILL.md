---
name: spade-review
description: Get an independent second opinion on a SPADE Scope, Plan, or both. Spawns a PANEL of five persona subagents in parallel (scope-guardian, architecture-strategist, security-lens, yagni-simplicity, adversarial-reviewer), merges their structured findings, and presents a single deduplicated report. Use when someone says "second opinion", "outside view", "review this", "challenge this", or when offered during /spade-approve. Non-blocking — informs the human but never gates shipping.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using the
Bash tool and show the output to the user if it is non-empty. If the script
does not exist or fails, skip silently and continue with the skill.

## Project Config

Read `.spade/config` in the current project directory. This file specifies
which Linear team, project, and default assignee to use. Use these values
for all Linear operations. If the file doesn't exist, ask the human which
team and project to use, or suggest running `/spade-onboard` first.

# SPADE Review — Persona Panel Second Opinion

You are coordinating an independent multi-persona review of SPADE work.
The value of a panel review comes from **genuine independence across
distinct concerns** — each persona sees the same structured summary but
is primed to care about a different aspect. A generalist reviewer
collapses a review into the most obvious concern; a persona panel
surfaces five distinct perspectives and merges the findings.

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
`/spade-approve`. The panel reviews them as a pair.

## Determining the Mode

1. If the human explicitly names the mode, use it.
2. If invoked during `/spade-approve`, default to **Full Review**.
3. If a Plan exists in context (conversation or `.spade/plans/`), use
   **Full Review**.
4. If only a Scope exists (Linear issue or conversation), use
   **Scope Review**.
5. If only a Plan exists with no clear Scope, use **Plan Review**.

## Gathering Context

Before spawning the panel, assemble a structured summary. Every persona
subagent gets the same summary — no conversation history.

### For Scope Review, gather:

- **Statement of Intent** — the what and why
- **Acceptance Criteria** — the full list
- **Architectural Constraints** — from the Scope and ARCHITECTURE.md
- **Dependencies** — what must be in place
- **Risks / Unknowns** — what the scoper flagged
- **Out of Scope** — the boundaries
- **Project context** — brief description of the project (from
  ARCHITECTURE.md or repo structure)

### For Plan Review, gather:

- **Plan content** — the full plan (tasks, approach, risks, bundles,
  execution posture per task)
- **Project context**
- **Architecture constraints** — from ARCHITECTURE.md, PATTERNS.md,
  ANTI-PATTERNS.md (personas read these themselves if needed).

### For Full Review, gather all of the above.

If any of this context comes from Linear, fetch it via MCP. If it is in
the conversation, extract it. If a plan file exists in `.spade/plans/`,
read it.

**Truncation rule:** If the combined context exceeds 30KB, truncate the
Plan content (keeping task titles and approach summaries) rather than
dropping Scope fields. Personas need the full Scope to review
traceability.

## The Panel

Five persona subagents, each defined under `.claude/agents/`:

| Persona file                                    | Focus                                                                   |
|-------------------------------------------------|-------------------------------------------------------------------------|
| `spade-review-scope-guardian`                   | Scope completeness, testability, Plan→Scope traceability                |
| `spade-review-architecture-strategist`          | Conflicts with ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md         |
| `spade-review-security-lens`                    | Auth, injection, secrets, supply chain, IAM, data sensitivity           |
| `spade-review-yagni-simplicity`                 | Over-engineering, premature abstraction, bundle/task proportionality    |
| `spade-review-adversarial-reviewer`             | Strongest attack on the Plan — what will fail and why                   |

Read `.claude/agents/spade-review-*.md` in the framework install
(`~/.spade/.claude/agents/` if installed globally, or `.claude/agents/`
in the consumer repo if the consumer has vendored them). Each file
defines the persona's focus, the severity rubric, and the output
contract.

## Spawning the Panel

**Spawn all five personas in parallel where the runtime supports it;
otherwise sequentially.** Parallel is a performance nicety, not a
correctness requirement — the merge logic doesn't care.

In Claude Code, use the `Task` tool (or the persona-specific
`subagent_type`) to spawn each persona. Each call gets the same
self-contained prompt:

```
You are reviewing a SPADE {mode} as the {persona} on a multi-persona
panel. Think hard and reason carefully before responding. Follow the
output contract in your persona file exactly — prose summary first,
then a JSON code block labelled `spade-findings` with strictly
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

The five persona files are written generically and several lean
Plan-oriented in their rubric examples; this line keeps a Scope-only
review from producing findings that reference a Plan that does not
exist. Do not append it for Plan Review or Full Review.

If the runtime does not support parallel Task spawns, run the five
sequentially in this order: scope-guardian, architecture-strategist,
security-lens, yagni-simplicity, adversarial-reviewer. Never skip a
persona to save time — a three-persona review collapses back toward
generalist.

### Dispatch-mode determination (v1.1.1)

Record the **dispatch mode** during spawning. It is one of exactly three
values; the banner in the report header names it verbatim so a consumer
can distinguish a real panel from a simulated one:

| Value                  | When to record                                                                                                            |
|------------------------|---------------------------------------------------------------------------------------------------------------------------|
| `subagent-dispatch`    | The runtime supports spawning `.claude/agents/*.md` (or equivalent) as **independent subagent contexts**, and you spawned all five personas **in parallel** as separate contexts. |
| `sequential-inproc`    | The runtime supports spawning personas in **isolated contexts** but only one at a time. You ran the five sequentially, still as separate contexts per persona. |
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
five prompt hats, not five independent contexts.

## Collecting the Findings

Each persona returns a short prose summary followed by a JSON code
block labelled `spade-findings`. Parse each block and collect all
findings into a single list.

If a persona's JSON block is invalid (rare; LLMs occasionally emit
trailing commas), present its prose summary verbatim and note the
parse failure alongside the report. Do not attempt to auto-repair
malformed JSON — showing the human "persona X returned malformed JSON"
is more useful than risking silent data corruption.

## Merging: Convergence and Sort

The merge turns five separate findings lists into one ranked report. It
has two jobs: surface **convergence** — where independent personas
landed on the same concern — and rank what remains.

### Convergence: cluster by underlying concern

Read every finding across all five lists and group those that describe
the **same underlying concern** — the same risk, gap, or weakness —
even when the personas filed them under different `category` values or
worded them differently. Each such group collapses to a **single
finding**: keep the one with the highest `confidence` and add an
`also_flagged_by` array naming the other personas that raised it.
Findings that describe **distinct concerns stay separate**, even if
their `category` or wording happens to coincide.

Convergence is the panel's strongest signal: "four of five personas
independently flagged this" is worth far more than any lone finding.
Detecting it is a judgement the coordinator makes by reading the
findings — not a mechanical key match.

> **Why this is a judgement, not a dedupe key.** Earlier versions
> deduped on `(category, first 100 characters of message)`. That key
> can never fire across personas: each persona file defines a
> **disjoint** `category` enum — scope-guardian emits `traceability`,
> security-lens emits `auth`, yagni-simplicity emits `gold-plating`,
> and so on, with no value shared between any two personas. Two
> personas therefore can never produce the same key, and the
> `also_flagged_by` array was unreachable. Keep the distinction clear:
> personas using **distinct categories** is *staying in lane* — the
> deliberate design that stops the panel collapsing into five
> restatements of one concern. That is not the same as personas never
> **converging**. Two personas in different lanes routinely see the
> same underlying risk from different angles; convergence detection is
> what makes that visible.

Be conservative when clustering. If two findings are *related* but not
the *same concern* — say, a security-lens worry about an auth boundary
and an adversarial-reviewer worry about a different failure mode on the
same task — keep them separate and let both stand. A false merge hides
a finding; a missed merge only costs a convergence annotation.

### Sort

**Sort** by severity × confidence, descending. Severity order:
`blocking` > `major` > `minor` > `nit`. Within a severity bucket,
higher confidence comes first.

### Confidence filter

Findings with confidence below 0.3 are filtered out before
presentation — they are below the calibration rubric each persona is
told to respect. Log the count of filtered findings so the human sees
"3 low-confidence findings hidden" rather than silent loss.

### Worked example

Five findings arrive from three personas (refs omitted for brevity):

```json
[
  {"persona": "security-lens", "severity": "major", "confidence": 0.78,
   "category": "trust-boundary",
   "message": "Task 2's webhook handler trusts the caller-supplied signature header without verifying it against the shared secret."},
  {"persona": "adversarial-reviewer", "severity": "major", "confidence": 0.70,
   "category": "hidden-assumption",
   "message": "The Plan assumes the webhook caller is already authenticated upstream; if that assumption is wrong, Task 2 processes forged events."},
  {"persona": "scope-guardian", "severity": "minor", "confidence": 0.60,
   "category": "acceptance-criteria",
   "message": "Acceptance criterion 3 ('events are handled') states no success condition and is not testable."},
  {"persona": "adversarial-reviewer", "severity": "minor", "confidence": 0.55,
   "category": "integration-blind-spot",
   "message": "No retry or backoff is described for the downstream call in Task 4."},
  {"persona": "yagni-simplicity", "severity": "nit", "confidence": 0.20,
   "category": "speculation",
   "message": "The config struct carries an unused 'region' field."}
]
```

The merge produces **three** findings, with one hidden:

1. The **security-lens** and **adversarial-reviewer** findings describe
   the *same underlying concern* — the webhook trusts an unverified
   caller — even though they were filed under different categories
   (`trust-boundary` vs `hidden-assumption`). They converge into one
   finding: keep the higher-confidence security-lens finding (0.78) and
   set `also_flagged_by: ["adversarial-reviewer"]`.
2. The **scope-guardian** finding is a *distinct concern* (an
   untestable criterion) — it stays on its own.
3. The second **adversarial-reviewer** finding is also *distinct* (a
   missing retry path on a different task). It stays separate and is
   **not** merged with finding 1, even though both came from
   adversarial-reviewer — convergence is about the concern, not the
   persona.
4. The **yagni-simplicity** finding is dropped by the confidence filter
   (0.20 < 0.3) and reported as "1 low-confidence finding hidden".

Sorted, the merged report is: finding 1 (`major`, 0.78) → finding 2
(`minor`, 0.60) → finding 3 (`minor`, 0.55). The envelope records
`findings_total: 3` and `findings_filtered_low_confidence: 1`.

## Report envelope (v1.1.1)

The merged report carries a top-level envelope so downstream tooling
can parse the report without inspecting the Markdown prose. The
envelope appears as a `json` code block immediately after the banner
(see Presenting the Report below) and MUST be valid JSON.

```json
{
  "schema_version": "1.1.1",
  "dispatch_mode": "subagent-dispatch",
  "personas_spawned": 5,
  "personas_completed": 5,
  "findings_total": 0,
  "findings_filtered_low_confidence": 0
}
```

Required fields:

- `schema_version` — the string `"1.1.1"` for this contract. A consumer
  that encounters a different version knows to fall back to prose
  parsing or flag the mismatch.
- `dispatch_mode` — one of `subagent-dispatch`, `sequential-inproc`,
  `degraded`. Same value as the banner line.
- `personas_spawned` — integer count of personas actually invoked.
  Always `5` under v1.1.1.
- `personas_completed` — the number of personas whose `spade-findings`
  block parsed successfully. Count them; do not estimate. If a
  persona's JSON block failed to parse, its prose still shows in the
  report but it does NOT increment this counter.
- `findings_total` — the number of findings in the merged report:
  literally the length of the final merged list, counted after
  convergence merging and the confidence filter. Do not estimate.
- `findings_filtered_low_confidence` — the number of findings dropped
  by the confidence filter (confidence below 0.3). Count them as they
  are dropped; do not estimate.

Per-persona findings keep the schema they had in v1.1 (Bundle E) — this
envelope is a wrapper, not a change to finding shape. If a future
version changes per-persona finding shape, bump `schema_version`.

## Presenting the Report

The report begins with a **dispatch-mode banner** (the value you
recorded during spawning) and the **report envelope** JSON. The section
title depends on dispatch mode:

- When `dispatch_mode` is `subagent-dispatch` or `sequential-inproc`,
  the title is `PANEL SECOND OPINION`.
- When `dispatch_mode` is `degraded`, the title is
  `SINGLE-CONTEXT SIMULATION (degraded)`. You MUST NOT use the words
  "panel" or "multi-persona" anywhere in a degraded report's header or
  framing prose — see "What This Skill Must Never Do" below.

Shape when dispatch mode is `subagent-dispatch` (or `sequential-inproc`):

```
Dispatch mode: subagent-dispatch

```json
{"schema_version":"1.1.1","dispatch_mode":"subagent-dispatch",
 "personas_spawned":5,"personas_completed":5,
 "findings_total":4,"findings_filtered_low_confidence":3}
```

PANEL SECOND OPINION
════════════════════════════════════════════════════════════

Summary from each persona (their own words, verbatim):

  scope-guardian:           <prose summary>
  architecture-strategist:  <prose summary>
  security-lens:            <prose summary>
  yagni-simplicity:         <prose summary>
  adversarial-reviewer:     <prose summary>

Merged findings (sorted by severity × confidence):

  [blocking, 0.95] architecture-strategist — <message>
    refs: ANTI-PATTERNS.md#..., Plan Task 4
  [major,    0.85] yagni-simplicity — <message>
    refs: Plan Task 3
    also_flagged_by: [adversarial-reviewer]
  ...

Hidden: 3 finding(s) below 0.3 confidence threshold.

════════════════════════════════════════════════════════════
```

Shape when dispatch mode is `degraded`:

```
Dispatch mode: degraded

```json
{"schema_version":"1.1.1","dispatch_mode":"degraded",
 "personas_spawned":5,"personas_completed":5,
 "findings_total":4,"findings_filtered_low_confidence":3}
```

SINGLE-CONTEXT SIMULATION (degraded)
════════════════════════════════════════════════════════════

This report was produced by re-prompting a single model context with
each persona's priming in turn — it is NOT a multi-context review.
Consumers relying on independence between reviewers should treat
findings as lower-confidence than the headline severity suggests.

Summary from each persona-prompted run (verbatim):

  scope-guardian:           <prose summary>
  ...

Merged findings (sorted by severity × confidence):

  ...

Hidden: N finding(s) below 0.3 confidence threshold.

════════════════════════════════════════════════════════════
```

The banner line (`Dispatch mode: <value>`) is ALWAYS the first line of
output, before any prose, the envelope JSON, or the section title.
This is so a `head -n 1` or a regex scan of the top-of-report surfaces
the mode without needing to parse the envelope.

**Never summarise a persona's prose in your own words.** The whole
point is that the human sees each independent view unfiltered. The
merge only applies to the JSON findings — the prose summaries are
always shown verbatim.

## Cross-Model Synthesis

After presenting the merged panel output, add your own synthesis as
the coordinating agent. For each finding you disagree with, state what
you think differently and why — include context the panel did not have
(conversation history, prior human decisions, and so on). Flag
genuine tensions neutrally rather than picking a side:

```
CROSS-MODEL SYNTHESIS:

Where I agree: <list of findings you second>
Where I disagree: <findings with reasoning>
Tension points (for the human to resolve):

  TENSION: <topic>
  Panel says:    X
  My view:       Y
  Context the panel didn't have: Z
```

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

## Integration with /spade-approve

When invoked from `/spade-approve`:

1. `/spade-approve` presents the approval checklist with its own
   assessments.
2. Before asking for the approval decision, it offers:
   "Want a panel review from an independent perspective?"
3. If the human says yes, `/spade-approve` invokes this skill.
4. After the merged report, synthesis, and user decision,
   `/spade-approve` resumes with the approval decision.

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
- **Leak conversation context into persona prompts.** Each persona
  sees only the structured summary. Passing "primary agent thinks X"
  into the persona prompt defeats the independence.
- **Summarise a persona's prose in your own words.** Verbatim only.
- **Run during fast-track (`/spade-quick`).** Fast-track work is too
  small to warrant a panel review. If someone asks for a review on a
  quick-path item, suggest the full loop instead.
- **Skip personas to save time.** Five personas or none. A reduced
  panel collapses back toward generalist and loses the coverage
  guarantee.
- **Repair malformed JSON from a persona.** Report the parse failure;
  do not guess.
