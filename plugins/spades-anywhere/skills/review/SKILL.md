---
name: review
description: Get an independent second opinion on a SPADES Scope, Plan, or both. Spawns a PANEL of four persona subagents in parallel (scope-guardian, architecture-strategist, security-lens, adversarial-reviewer), merges their structured findings, and presents a single tiered report. Use when someone says "second opinion", "outside view", "review this", "challenge this", or when offered during /spades-anywhere:approve. Non-blocking — informs the human but never gates shipping.
version: 0.4.0
---

# /spades-anywhere:review

You are coordinating an independent multi-persona review. The value
of a panel is genuine independence across distinct concerns: each
persona sees the same structured summary and is primed to care
about a different aspect. The report is a second opinion — it
informs the human and gates nothing.

Read `docs/FRAMEWORK.md` § Freshness, § Target Resolution,
§ Sub-agent Dispatch, and § Output Format before running.
**Report shaping lives in
[`reference/report-format.md`](reference/report-format.md)**; read
it when you reach § Presenting the report.

### Output format

- **Both modes** — `.spades-anywhere/reviews/<target>-<date>.md`,
  the complete record.
- **CLI mode** — the tiered digest prints to the terminal.
- **HTML mode** — additionally
  `.spades-anywhere/reviews/<target>-<date>.html` from
  `${CLAUDE_PLUGIN_ROOT}/skills/review/template.html`, auto-opened;
  the terminal gets the three-line brief. One review surface per
  mode.

## Pre-Flight

1. **Freshness.** The rule applies in the local-backend-in-git
   scenario (`docs/FRAMEWORK.md § Freshness`); elsewhere there is
   nothing to compare against:

   ```bash
   git rev-parse --is-inside-work-tree 2>/dev/null && \
     git fetch origin --quiet && git rev-list --count main..origin/main
   ```

   No git repo, or `0` → continue. Non-zero → abort: *"Local `main`
   is N commits behind `origin/main`. Sync (`git pull`, or
   `/repo:sync` with the `repo` plugin) then re-invoke
   `/spades-anywhere:review`."*
2. **Config.** Read `.spades-anywhere/config` for `project:`,
   `backend:`, `review_format:`; missing → `/spades-anywhere:setup`.
3. **Resolve the mode and target.** Both named → honour directly. A
   Scope or Plan already in session context → one confirm (*Use
   <ID> — <title>?*). Bare invocation → `docs/FRAMEWORK.md § Target
   Resolution`: artefact type via `AskUserQuestion` (*Scope review*
   / *Plan review* / *Full review*); candidates per the status filter
   (Scopes in any active phase; Plans in `draft`, `approved`,
   `delivering`, `evaluating`); a picker of up to three plus
   *Describe a different one*; echo the resolved target. Zero
   candidates → `/spades-anywhere:scope <title>`. Full review takes
   the Plan and reads its parent Scope from `scope:`.

## Modes

| Mode | Context | The panel examines |
|---|---|---|
| Scope review | Scope only | Premises, acceptance-criteria completeness, whether the work is defined well enough to plan |
| Plan review | Plan exists | Gaps, overcomplexity, feasibility, risk to people and money, strategic miscalibration |
| Full review | Both | The pair together |

## Gathering context

Assemble one structured summary from the local `.md` files (the
canonical record for both backends). Every persona gets the same
summary and no conversation history.

- **Scope review** — Statement of Intent; every acceptance
  criterion; constraints (the Scope's plus `INTENT.md` and
  `ARCHITECTURE.md`); dependencies; risks; out of scope; project
  context from `INTENT.md`.
- **Plan review** — the full Plan (tasks, approach, risks, posture
  per task); project context; constraints from `INTENT.md`,
  `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`.
- **Full review** — all of the above.

Over 30KB combined, truncate the Plan (keeping task titles and
approach summaries) rather than dropping Scope fields.

## The panel

| Persona | Focus |
|---|---|
| `review-scope-guardian` | Scope completeness, testability, Plan→Scope traceability; gold-plating and proportionality |
| `review-architecture-strategist` | Conflicts with `ARCHITECTURE.md` / `PATTERNS.md` / `ANTI-PATTERNS.md` — the operating model, not a tech stack |
| `review-security-lens` | Personal data, money, access, commitments, safety |
| `review-adversarial-reviewer` | The strongest attack on the Plan; second-order and compounding cost |

The agents ship under `agents/` and are loaded by name via the
Agent tool (`subagent_type: review-scope-guardian` and so on). Each
defines its focus, severity rubric, and output contract.

## Spawning

Spawn all four in parallel; sequentially where the runtime only
supports one at a time. Four run or none. Each gets the same
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
{constraints}                   # INTENT success criteria + the Scope's Constraints + ARCHITECTURE / PATTERNS / ANTI-PATTERNS
```

For a **Scope review**, append after the output-contract sentence:

> This is a Scope Review — no Plan exists yet. Review the Scope on
> its own terms — intent clarity, acceptance-criteria testability,
> premises, dependencies, and risks — and emit no finding that
> assumes a Plan.

### Dispatch mode

| Value | When |
|---|---|
| `subagent-dispatch` | Four independent contexts, in parallel. |
| `sequential-inproc` | Four independent contexts, one at a time. |
| `degraded` | One context re-prompted per persona — the common case on chat surfaces without sub-agent dispatch. Reported as such. |

Try them in that order. The banner names the mode so a reader can
tell a real panel from a simulated one.

## Collecting

Parse each persona's `spades-findings` block. An invalid block is
reported as a parse failure with the prose shown verbatim; the JSON
is not repaired.

## Merging

**Convergence.** Group findings that describe the same underlying
concern, even under different `category` values or wording; each
group collapses to the sharpest statement (prefer `high`
confidence) with `also_flagged_by` naming the others. Distinct
concerns stay separate. Convergence is a judgement made by reading
— each persona's `category` enum is disjoint by design. Be
conservative: a false merge hides a finding; a missed merge costs an
annotation.

**Sort.** Severity first (`blocking` > `major` > `minor`); within a
bucket, a longer `also_flagged_by` first. `confidence` is display
only. No merge-side filter: personas self-cap at generation, and
the digest tiers at presentation.

**Worked example.** Six findings on one Plan:

| Persona | Severity | Category | Concern |
|---|---|---|---|
| security-lens | major | `trust-boundary` | Task 2 shares the guest list with a vendor before the vendor contract is signed |
| adversarial-reviewer | major | `hidden-assumption` | Plan assumes the vendor is already vetted; if not, Task 2 leaks personal data |
| architecture-strategist | major | `patterns-drift` | Task 2 skips the "vendor onboarding checklist" PATTERNS.md mandates |
| scope-guardian | minor | `acceptance-criteria` | Criterion 3 ("guests informed") states no success condition |
| adversarial-reviewer | minor | `integration-blind-spot` | No fallback if the caterer cancels in Task 4 |
| scope-guardian | minor | `gold-plating` | Task 5 designs printed menus the Scope never mentions |

Merges to four: the first three are one concern (data shared with
an unvetted vendor) — keep one with `also_flagged_by:
["adversarial-reviewer", "architecture-strategist"]`; the other
three are distinct. `findings_total: 4`.

## Presenting the report

**Read [`reference/report-format.md`](reference/report-format.md) and
follow it.** The report file is written before the digest prints.

## Cross-model synthesis

Add only what changes a decision — disagreements (findings you
think are wrong or mis-graded, or that lack context the panel didn't
have) and tension points for the human to resolve, stated neutrally:

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

## Human decision — `AskUserQuestion`

- **Act on specific findings** — by severity, persona, or message.
- **Continue as-is.**
- **Discuss further.**

Findings are applied to a Scope or Plan only on the human's
instruction.

## Brief

**HTML mode:**

```
✓ Review report: .spades-anywhere/reviews/<target>-<date>.md
○ .spades-anywhere/reviews/<target>-<date>.html opened in browser
Next: /spades-anywhere:approve P-<id>   — apply or override findings
```

**CLI mode:** the write confirmation, the merged digest once, the
same `Next:` line.

## With `/spades-anywhere:approve`

The human runs each separately: this skill writes the report and
exits; `/spades-anywhere:approve` reads it as extra context for the
checklist. Fast-track work (`/spades-anywhere:quick`) is too small
for a panel; a review request on a quick item is a signal to use
the full loop.
