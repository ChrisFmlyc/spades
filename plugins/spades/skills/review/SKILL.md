---
name: review
description: Get an independent second opinion on a SPADES Scope, Plan, or both. Spawns a PANEL of four persona subagents in parallel (scope-guardian, architecture-strategist, security-lens, adversarial-reviewer), merges their structured findings, and presents a single tiered report. Use when someone says "second opinion", "outside view", "review this", "challenge this", or when offered during /spades:approve. Non-blocking — informs the human but never gates shipping.
version: 3.3.0
---

## Pre-Flight

### Step 1 — Freshness check (mandatory)

Per `docs/FRAMEWORK.md` § Freshness and `AGENTS.md` § Freshness
Before Read-Across, this skill spawns four read-across subagents
that read the local filesystem. A stale local `main` will produce
stale findings — every persona will flag issues that have already
shipped.

Verify before spawning the panel:

```bash
git fetch origin --quiet && git rev-list --count main..origin/main
```

- Returns `0` → fresh. Continue.
- Non-zero → abort with the message: *"Local `main` is N commits
  behind `origin/main`. Run `/repo:sync` then re-invoke
  `/spades:review`. Spawning a panel against stale code wastes
  reviewer cycles and produces false findings."* Do not proceed.

This is the Layer 2 enforcement of the freshness rule — the panel
never runs against stale state.

### Step 2 — Config + backend

Read `.spades/config` for the active project. If the file is missing,
suggest `/spades:setup` and abort — review needs Scope/Plan context to
review.

`/spades:review` reads from the active backend (via the contract in
`docs/FRAMEWORK.md` § Backend Interface) for Scope and Plan content,
but the review report itself always lands locally at
`.spades/reviews/<slug>-<date>.md`.

# SPADES Review — Persona Panel Second Opinion

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML) → Universal
rule`. In **both** modes, write the tiered report to
`.spades/reviews/<target>-<date>.md` — this is the AI-readable
source of truth and the canonical record. In **CLI mode** the
inline panel digest also prints to the terminal (the
human's only review surface). In **HTML mode**, *instead* of
printing the digest, render via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/review/template.html` — sidebar
verdict roll-up, persona-card grid, and severity-tab findings —
and write `.spades/reviews/<target>-<date>.html` for the human's
view, then auto-open. The four-persona panel dispatch and merge
logic are identical between modes; HTML mode is additive on the
file system (the `.md` always exists; the `.html` is added) and
strictly alternative on the human's review surface (digest in
the terminal OR digest rendered in the browser, never both).

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
`/spades:approve`. The panel reviews them as a pair.

## Determining the Mode and Target

Two pieces of information are needed: the **mode** (Scope / Plan /
Full review) and the **target** (which Scope or Plan).

### Quick paths (no interactive flow needed)

1. If invoked from inside `/spades:approve`, default to **Full
   Review** on the Plan and Scope `/spades:approve` is operating on
   — both are already in context.
2. If the human invocation explicitly names both mode AND target
   (e.g. `/spades:review scope S-add-ai-helper-bot` or `/spades:review
   plan P-rag-pipeline-lookup-3HyD`), honour it directly.
3. If a Plan or Scope is already in conversation context from the
   current session (e.g. mid-`/spades:plan`), surface it as the
   default via a single confirm prompt — `Use <ID> — <title>?` — but
   still let the human pick a different one.

### Bare-invocation flow

If `/spades:review` is invoked with no argument and no Scope/Plan in
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
   empty, suggest `/spades:scope <title>` and stop.
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
the conversation, extract it. If a plan file exists in `.spades/plans/`,
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
| `review-architecture-strategist`          | Conflicts with ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md         |
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

The merge turns four separate findings lists into one ranked report. It
has two jobs: surface **convergence** — where independent personas
landed on the same concern — and rank what remains.

### Convergence: cluster by underlying concern

Read every finding across all four lists and group those that describe
the **same underlying concern** — the same risk, gap, or weakness —
even when the personas filed them under different `category` values or
worded them differently. Each such group collapses to a **single
finding**: keep whichever states the concern most sharply (prefer a
`high`-confidence finding over a `low` one) and add an `also_flagged_by`
array naming the other personas that raised it.
Findings that describe **distinct concerns stay separate**, even if
their `category` or wording happens to coincide.

Convergence is the panel's strongest signal: "three of four personas
independently flagged this" is worth far more than any lone finding.
Detecting it is a judgement the coordinator makes by reading the
findings — not a mechanical key match.

> **Why this is a judgement, not a dedupe key.** Earlier versions
> deduped on `(category, first 100 characters of message)`. That key
> can never fire across personas: each persona file defines a
> **disjoint** `category` enum — scope-guardian emits `traceability`,
> security-lens emits `auth`, adversarial-reviewer emits
> `hidden-assumption`, and so on, with no value shared between any two
> personas. Two personas therefore can never produce the same key, and
> the `also_flagged_by` array was unreachable. Keep the distinction
> clear: personas using **distinct categories** is *staying in lane* —
> the deliberate design that stops the panel collapsing into four
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

**Sort** by severity, then by convergence. Severity order:
`blocking` > `major` > `minor`. Within a severity bucket, a finding
with a longer `also_flagged_by` array — more personas independently
converged on it — comes first. `confidence` is **not** a sort key: it
is a display-only `high | low` annotation (see the persona files).
There is no `severity × confidence` arithmetic, and `nit` is no longer
a severity.

### No merge-side filter

There is no confidence filter at merge time. Under v1.1 the merge
dropped findings with `confidence` below `0.3`; `confidence` is now a
coarse `high | low` flag, not a float, and every persona already
self-caps at three primary findings (plus, for the scope guardian and
adversarial reviewer, one reserved-slot finding) — the filtering moved
to generation time. The merge keeps every finding each persona emits;
volume is controlled at presentation time by the tiered report (see
"Presenting the Report"), not by dropping findings here.

### Worked example

Six findings arrive from four personas (refs omitted for brevity):

```json
[
  {"persona": "security-lens", "severity": "major", "confidence": "high",
   "category": "trust-boundary",
   "message": "Task 2's webhook handler trusts the caller-supplied signature header without verifying it against the shared secret."},
  {"persona": "adversarial-reviewer", "severity": "major", "confidence": "high",
   "category": "hidden-assumption",
   "message": "The Plan assumes the webhook caller is already authenticated upstream; if that assumption is wrong, Task 2 processes forged events."},
  {"persona": "architecture-strategist", "severity": "major", "confidence": "low",
   "category": "patterns-drift",
   "message": "Task 2's handler bypasses the shared request-validation middleware PATTERNS.md mandates."},
  {"persona": "scope-guardian", "severity": "minor", "confidence": "high",
   "category": "acceptance-criteria",
   "message": "Acceptance criterion 3 ('events are handled') states no success condition and is not testable."},
  {"persona": "adversarial-reviewer", "severity": "minor", "confidence": "high",
   "category": "integration-blind-spot",
   "message": "No retry or backoff is described for the downstream call in Task 4."},
  {"persona": "scope-guardian", "severity": "minor", "confidence": "low",
   "category": "gold-plating",
   "message": "Task 5 adds a config flag for an export format the Scope does not mention."}
]
```

The merge produces **four** findings:

1. The **security-lens**, **adversarial-reviewer**, and
   **architecture-strategist** findings all describe the *same
   underlying concern* — Task 2's webhook trusts an unverified caller —
   even though they were filed under three different categories
   (`trust-boundary`, `hidden-assumption`, `patterns-drift`). They
   converge into one finding: keep one of the three (all `major`) and
   set `also_flagged_by: ["adversarial-reviewer", "architecture-strategist"]`.
2. The **scope-guardian** `acceptance-criteria` finding is a *distinct
   concern* (an untestable criterion) — it stays on its own.
3. The second **adversarial-reviewer** finding is also *distinct* (a
   missing retry path on a different task). It stays separate and is
   **not** merged with finding 1, even though both came from
   adversarial-reviewer — convergence is about the concern, not the
   persona.
4. The **scope-guardian** `gold-plating` finding is the reserved-slot
   absorbed-remit finding — a *distinct concern*, so it stays on its
   own.

Nothing is dropped: there is no merge-side confidence filter.

Sorted by severity, then convergence: finding 1 (`major`,
`also_flagged_by` length 2) → then the three `minor` findings (2, 3,
4), whose order among themselves is not significant — `confidence` is
a display annotation, not a tiebreak. The envelope records
`findings_total: 4`.

## Report envelope (v2.0.0)

The merged report carries a top-level envelope so downstream tooling
can parse the report without inspecting the Markdown prose. The
envelope appears as a `json` code block immediately after the banner
(see Presenting the Report below) and MUST be valid JSON.

```json
{
  "schema_version": "2.0.0",
  "dispatch_mode": "subagent-dispatch",
  "personas_spawned": 4,
  "personas_completed": 4,
  "findings_total": 0
}
```

Required fields:

- `schema_version` — the string `"2.0.0"` for this contract. A consumer
  that encounters a different version knows to fall back to prose
  parsing or flag the mismatch. `2.0.0` is the M-994 redesign: four
  personas, `nit` removed from `severity`, `confidence` recast to a
  `high | low` string, no merge-side confidence filter. This is the
  **report-envelope** contract version — it is independent of the
  framework's `.spades/version` and of the fragment-marker mechanism
  `/spades:setup` uses to refresh consumer files on plugin upgrade.
- `dispatch_mode` — one of `subagent-dispatch`, `sequential-inproc`,
  `degraded`. Same value as the banner line.
- `personas_spawned` — integer count of personas actually invoked.
  Always `4` under v2.0.0.
- `personas_completed` — the number of personas whose `spades-findings`
  block parsed successfully. Count them; do not estimate. If a
  persona's JSON block failed to parse, its prose still shows in the
  report but it does NOT increment this counter.
- `findings_total` — the number of findings in the merged report:
  literally the length of the final merged list, counted after
  convergence merging. Do not estimate.

The v1.1 envelope carried a sixth field,
`findings_filtered_low_confidence`, counting findings dropped by the
merge-side confidence filter. v2.0.0 removes both the filter and the
field — `confidence` is no longer a float, and the per-persona caps
moved filtering to generation time.

Per-persona finding shape changed in v2.0.0: `severity` lost the `nit`
value and `confidence` became a `high | low` string. If a future
version changes finding shape again, bump `schema_version`.

## Presenting the Report

A panel run produces two artefacts: a **tiered inline report** written
to the terminal, and a **full report** persisted to a file. The inline
report is a digest — it leads with the signal and fits on a screen; the
full report is the complete audit record.

### The dispatch-mode banner and envelope

Both artefacts begin with a **dispatch-mode banner** (the value you
recorded during spawning) and the **report envelope** JSON. The banner
line (`Dispatch mode: <value>`) is ALWAYS the first line of output,
before any prose, the envelope JSON, or the section title — so a
`head -n 1` or a regex scan of the top-of-report surfaces the mode
without parsing the envelope.

The section title depends on dispatch mode:

- When `dispatch_mode` is `subagent-dispatch` or `sequential-inproc`,
  the title is `PANEL SECOND OPINION`.
- When `dispatch_mode` is `degraded`, the title is
  `SINGLE-CONTEXT SIMULATION (degraded)`. You MUST NOT use the words
  "panel" or "multi-persona" anywhere in a degraded report's header or
  framing prose — see "What This Skill Must Never Do" below.

**Degraded-detection check.** The dispatch mode is asserted in three
places that MUST agree: the banner's first line, the envelope's
`dispatch_mode` field, and the section title (`PANEL SECOND OPINION`
for a real panel; `SINGLE-CONTEXT SIMULATION (degraded)` for a degraded
run). A reader — or a downstream tool — confirms a run was a genuine
multi-context panel by checking that all three agree and none say
`degraded`. If the three disagree, the report is malformed. This
three-point agreement is the stated check that a degraded run can never
be silently presented as a panel; it holds in the inline report and the
persisted file alike.

### The tiered inline report (CLI mode)

**Read `review_format:` from `.spades/config` and branch.** In CLI
mode this digest IS the human's review surface and prints to the
terminal in full. In HTML mode the digest is *not* printed inline —
the rendered `.html` (written under "The persisted full report"
below) is the human's review surface, and the terminal gets only a
short `✓ Review written: <path>` line plus any conversational text.
Both modes still write the canonical `.md`; the digest content is
identical between surfaces — only where it renders differs.

The inline report shows, in order:

1. The banner and the envelope JSON.
2. The section title.
3. **Persona summaries** — each persona's prose summary, verbatim.
   Never summarise a persona's prose in your own words; the whole point
   is that the human sees each independent view unfiltered.
4. **Convergence** — every merged finding with a non-empty
   `also_flagged_by` array, shown in full. Convergence is the panel's
   strongest signal, so it leads the findings.
5. **Blocking and major findings.** Every `blocking` finding is shown
   in full, always — blocking is never suppressed or collapsed. `major`
   findings then fill an inline budget of roughly 5–7 findings total
   (the convergence and blocking findings already shown count toward
   that budget). `major` findings beyond the budget are not printed
   individually — they collapse to a count line:
   `+N more major finding(s) — see full report`.
6. **Minor findings** never print individually inline. They collapse to
   a single count line: `N minor finding(s) — see full report`.
7. A pointer to the persisted full report: `Full report: <path>`.

Inline shape when dispatch mode is `subagent-dispatch` (or
`sequential-inproc`):

```
Dispatch mode: subagent-dispatch

```json
{"schema_version":"2.0.0","dispatch_mode":"subagent-dispatch",
 "personas_spawned":4,"personas_completed":4,"findings_total":14}
```

PANEL SECOND OPINION
════════════════════════════════════════════════════════════

Summary from each persona (their own words, verbatim):

─── scope-guardian ─────────────────────────────────────────

  <prose summary>

─── architecture-strategist ────────────────────────────────

  <prose summary>

─── security-lens ──────────────────────────────────────────

  <prose summary>

─── adversarial-reviewer ───────────────────────────────────

  <prose summary>

Convergence — independent personas on the same concern:

  [major, also_flagged_by ×2] security-lens — <message>
    refs: Plan Task 2
    also_flagged_by: [adversarial-reviewer, architecture-strategist]

Findings — every blocking in full; major up to the inline budget:

  [blocking] architecture-strategist — <message>
    refs: ANTI-PATTERNS.md#..., Plan Task 4
  [major]    scope-guardian — <message>
    refs: Plan Task 3
  +3 more major finding(s) — see full report.
  9 minor finding(s) — see full report.

Full report: .spades/reviews/s-add-ai-helper-bot-2026-05-17.md

════════════════════════════════════════════════════════════
```

Inline shape when dispatch mode is `degraded`:

```
Dispatch mode: degraded

```json
{"schema_version":"2.0.0","dispatch_mode":"degraded",
 "personas_spawned":4,"personas_completed":4,"findings_total":14}
```

SINGLE-CONTEXT SIMULATION (degraded)
════════════════════════════════════════════════════════════

This report was produced by re-prompting a single model context with
each persona's priming in turn — it is NOT a multi-context review.
Consumers relying on independence between reviewers should treat
findings as lower-confidence than the headline severity suggests.

Summary from each persona-prompted run (verbatim):

─── scope-guardian ─────────────────────────────────────────

  <prose summary>

─── architecture-strategist ────────────────────────────────

  <prose summary>

─── security-lens ──────────────────────────────────────────

  <prose summary>

─── adversarial-reviewer ───────────────────────────────────

  <prose summary>

Convergence — runs that landed on the same concern:

  ...

Findings — every blocking in full; major up to the inline budget:

  ...
  +N more major finding(s) — see full report.
  N minor finding(s) — see full report.

Full report: .spades/reviews/s-add-ai-helper-bot-2026-05-17.md

════════════════════════════════════════════════════════════
```

### The persisted full report

On **every** panel run — `degraded` runs included — write the full
report to a file under `.spades/reviews/`. **Read `review_format:`
from `.spades/config` and branch on the format.** The review MUST
write a file before the inline digest is printed.

#### Write the canonical `.md` (both modes)

- **Path:** `.spades/reviews/<slug>-<date>.md`. `<slug>` is the reviewed
  Scope or Plan's tracker identifier lower-cased (e.g. `s-add-ai-helper-bot`), or a
  short kebab-case slug derived from its title when there is no
  identifier; `<date>` is `YYYY-MM-DD`.
- **Collision rule:** if that path already exists — a repeat run of the
  same slug on the same date — append a numeric suffix:
  `<slug>-<date>-2.md`, then `-3`, and so on. Never overwrite an
  existing review file; each run is its own audit record.

#### Dispatch `worker-html-review` in parallel (HTML mode only)

When `review_format: html`, dispatch `worker-html-review` per
`docs/FRAMEWORK.md § worker-html-* — parallel HTML rendering` in
the same wave as the `.md` write. No inline render.

Worker inputs:

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/review/template.html`
- `output_path`: `.spades/reviews/<slug>-<date>.html` (same slug
  + collision rules as the `.md`: `<slug>-<date>-2.html`, etc.)
- `frontmatter`: `{ target_id, target_title, mode (Scope|Plan|Full),
  verdict, date, dispatch_mode }` (also embedded verbatim in
  `<script id="spades-frontmatter">`)
- `blocks`:
  - `persona-cards` — one per persona (4 cards). Fields:
    `persona, summary_html, finding_count`.
  - `findings` — one per merged finding (every severity,
    ungated). Fields: `severity, confidence, category, persona,
    message_html, refs, also_flagged_by`.
  - `convergence-cards` — one per convergence cluster. Fields:
    `label, personas, severity`.
- `prose_sections`: `{ synthesis_html }` (cross-model synthesis).

Required template markers:
`<!-- SPADES-BLOCK:persona-cards -->`,
`<!-- SPADES-BLOCK:findings -->`,
`<!-- SPADES-BLOCK:convergence-cards -->`.

In HTML mode, do NOT print the inline CLI digest — the open
`.html` is the human's review surface. The terminal gets only
the short `✓ Review written: <path>` confirmation + any
conversational text. The full digest lives in the `.html`
(and the same content is in the `.md` for AI / fallback reads).
- **Contents:** the banner, the envelope, the section title, every
  persona's prose summary verbatim, **every** merged finding at every
  severity shown in full (the file is not tiered — it is the complete
  record), and the cross-model synthesis.
- `.spades/reviews/` is gitignored by default; the review file is a
  local audit artefact, not committed output.

Create `.spades/reviews/` lazily on the first write; do not pre-create
it. The inline report's `Full report:` pointer names the file
just written. If the write fails, say so plainly inline
(`Full report: write failed — <reason>`) and continue — a failed
persistence write never aborts the review. **Failure fallback**:
if the `.md` and / or `.html` write failed in HTML mode, the
digest *is* printed to CLI as a backup so the human still sees
the panel output. In CLI mode this is moot — the digest is the
primary display already.

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

## End-of-Skill Brief

**HTML mode** — 3 lines, no body dump (the browser tab IS the
review surface):

```
✓ Review report: .spades/reviews/<target>-<date>.md
○ .spades/reviews/<target>-<date>.html opened in browser
Next: /spades:approve P-<id>   — apply or override findings
```

**CLI mode** — confirm the write, then print the merged report
once as the review surface:

```
✓ Review report: .spades/reviews/<target>-<date>.md

<merged report body>

Next: /spades:approve P-<id>   — apply or override findings
```

## Relationship with /spades:approve

`/spades:approve` no longer invokes `/spades:review` inline. The
human runs each separately:

1. `/spades:review S-<id>` or `/spades:review P-<id>` — runs the
   panel, writes the report, exits.
2. `/spades:approve P-<id>` — reads the existing review report (if
   present) as additional context for the approval checklist, then
   asks for the routing decision.

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
  `.spades/reviews/` on every run, `degraded` runs included. The inline
  digest tiers `major` and `minor`; it never tiers `blocking`.
- **Leak conversation context into persona prompts.** Each persona
  sees only the structured summary. Passing "primary agent thinks X"
  into the persona prompt defeats the independence.
- **Summarise a persona's prose in your own words.** Verbatim only.
- **Run during fast-track (`/spades:quick`).** Fast-track work is too
  small to warrant a panel review. If someone asks for a review on a
  quick-path item, suggest the full loop instead.
- **Skip personas to save time.** Four personas or none. A reduced
  panel collapses back toward generalist and loses the coverage
  guarantee.
- **Repair malformed JSON from a persona.** Report the parse failure;
  do not guess.
