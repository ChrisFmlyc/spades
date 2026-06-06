---
name: anti-patterns
description: Create or maintain ANTI-PATTERNS.md, the project's durable list of things the codebase DELIBERATELY AVOIDS — runtime dependencies, hidden state, premature abstraction, and any other "we won't do X" rules. Use when someone says "set up ANTI-PATTERNS.md", "document what we don't do", "we should ban X", "we deliberately avoid Y", "what's forbidden here", "add an anti-pattern", "update the anti-patterns doc", "what shouldn't we do", or when ANTI-PATTERNS.md is missing, still an unfilled template, or flagged stale by /spades:plan, /spades:approve, or /spades:review. Also use proactively after a Plan rejection that traces to an unwritten prohibition. The human composes the prohibitions; this skill structures and probes but never authors it. SKIP when the human's intent is per-Plan risk capture (use the Plan's Risks & Assumptions section instead) or when documenting an APPROVED pattern (use /spades:patterns).
version: 1.0.0
---

# SPADES Anti-Patterns

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`.
**`ANTI-PATTERNS.md` itself stays at the repo root as
human-authored Markdown — it is not auto-converted to HTML in
either mode.** In HTML mode, after writing/refreshing
`ANTI-PATTERNS.md` the skill renders a persistent summary at
`.spades/anti-patterns.html` via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/anti-patterns/template.html`, and
a transient preview at `.spades/.tmp/anti-patterns.html` during
the edit flow. In CLI mode, no preview is rendered. The Socratic
facilitate-never-author flow is identical between modes.

You are helping a human create or maintain `ANTI-PATTERNS.md` —
the durable list of things the codebase deliberately avoids.
`ANTI-PATTERNS.md` is a root reference document, peer to
`INTENT.md`, `ARCHITECTURE.md`, and `PATTERNS.md`. It changes
infrequently. It is the load-bearing prohibition layer that
`/spades:plan` and `/spades:review` (architecture-strategist
persona) cross-check against: when a Plan would introduce a
forbidden technique, `ANTI-PATTERNS.md` is what makes that
visible.

## The Core Rule: Facilitate, Never Author

**The human owns the anti-patterns. You structure them. You
never invent them.**

Same non-negotiable rule as `/spades:intent`,
`/spades:architecture`, `/spades:patterns`. Anti-patterns are
*the team's prohibitions* — usually born from real incidents,
bad past experiences, or principled philosophy. The AI's job is
to capture them clearly; it must not invent prohibitions the
team has not decided on.

Concretely:

- **You MAY** ask questions, reflect answers back, propose
  *structure*, suggest *wording* for a prohibition the human
  has already expressed, and — in Create mode — offer an
  explicitly-labelled *draft starting point* inferred from the
  repo (lint configs, ANTI-PATTERN-style comments, PR history)
  for the human to accept, reject, or rewrite.
- **You MUST NOT** invent prohibitions the human did not state;
  bring in generic "best practice" anti-patterns from outside
  this codebase as if the team had decided them; or save
  `ANTI-PATTERNS.md` before the human has reviewed every rule.
- **Silence is not consent.**

If you ever find yourself typing an anti-pattern the human did
not say, stop and ask them instead.

### Why this rule matters most for anti-patterns

Anti-patterns are easy to over-generate. The internet is full of
"don't do X" rules, and an AI can plausibly suggest many. **Resist.**
A useful ANTI-PATTERNS.md captures rules *this team has actually
decided on*, ideally tied to a real incident or a deliberate
trade-off. Generic anti-patterns the team would shrug at are
worse than nothing — they dilute the file's signal and the
architecture-strategist persona will start flagging false
positives in `/spades:review`.

## What ANTI-PATTERNS.md Is — and Is Not

`ANTI-PATTERNS.md` owns **deliberate prohibitions** — things the
team has decided not to do. It does NOT own:

- **Why** the project exists / for whom → `INTENT.md`.
- **How** the system is built → `ARCHITECTURE.md`.
- **Approved patterns** → `PATTERNS.md`. (The dual: PATTERNS is
  "we do X"; ANTI-PATTERNS is "we don't do Y".)
- **Style minutiae enforceable by a formatter** — those live in
  Prettier / Black / etc.
- **General-purpose engineering bad practices** — only the ones
  *this team has explicitly decided to ban* belong here.

This skill is distinct from its neighbours:

- It is **not** `/spades:patterns`. Patterns express affirmative
  conventions; anti-patterns express prohibitions. Both inform
  Plan-review.
- A good anti-pattern reads like a rule with a reason: *"No
  runtime dependency on PyYAML — stdlib-only Markdown lint
  (decided 2024-Q4 after the Python 3.13 PyYAML wheels broke
  CI)."*

## Inline ANTI-PATTERNS.md Template

When this skill needs to scaffold a fresh `ANTI-PATTERNS.md`,
use exactly this shape:

```markdown
---
last_reviewed: YYYY-MM-DD
---

# Anti-Patterns

## Runtime Dependencies

<!-- Specific dependencies the team has decided not to add at
     runtime. Include the reason (CI breakage, security audit
     failure, footprint, license incompatibility). -->

## Hidden State

<!-- Patterns that create implicit state the rest of the
     codebase has to know about. Examples: singletons, global
     module-level config, thread-local context. Capture which
     ones are banned and why. -->

## Premature Abstraction

<!-- When to NOT abstract. "Three similar lines are fine;
     don't extract until N=4" — that style of explicit rule.
     Better to copy code than to ship the wrong abstraction. -->

## Other Bans

<!-- Anything else the team has explicitly decided to avoid.
     Each entry: the rule, then a one-line reason. -->
```

Leave the placeholder comments in place if the human picks
"start blank".

## Where ANTI-PATTERNS.md Lives

`ANTI-PATTERNS.md` lives at the **repository root**, alongside
`INTENT.md`, `ARCHITECTURE.md`, `PATTERNS.md`. This skill reads
and writes `./ANTI-PATTERNS.md` in the current project. It is a
plain Markdown file with a small YAML frontmatter block
(`last_reviewed`).

## Modes

Determine the mode by inspecting `./ANTI-PATTERNS.md`:

- **No file** → **Create mode**.
- **File exists but is still an unfilled template** (two or more
  `<!-- … -->` placeholder markers) → **Create mode** (filling
  the scaffolded template in place).
- **File exists and is filled in** → **Edit mode**.

If ambiguous, confirm via `AskUserQuestion`.

### Create Mode

Walk the human through all four sections from scratch. Before
starting, offer — via `AskUserQuestion` — to draft a starting
point inferred from the repo's `eslint.config.js`, `pyproject.toml`
`[tool.ruff]`, golangci-lint config, README, or any explicit
"don't do X" comments scattered in the codebase:

- *Draft a starting point inferred from the repo, then I correct it*
- *Start blank — I'll describe it myself*

If they choose the draft, surface what you found and let the
human reject any inferred anti-pattern they don't actually
follow. **Be especially conservative here — propose few,
high-confidence anti-patterns; let the human add the rest.**

### Edit Mode

The human wants to refine an existing `ANTI-PATTERNS.md`. Use
`AskUserQuestion` to scope the edit:

- *Refresh `last_reviewed` only — the rules are still accurate*
- *Revise specific sections*
- *Add a new prohibition* — free-form follow-up; loop in the
  human's exact wording
- *Full review pass — walk every rule*

**Always read the existing file first** — preserve what's there;
never rewrite from scratch.

## Conversational Style

1. **One section / one rule at a time.** Don't flood the human
   with proposed bans.
2. **Probe for the reason.** *"Why does this team ban X?"* If
   there's no concrete answer (a past incident, a hard
   trade-off, a principle), the rule probably shouldn't be in
   `ANTI-PATTERNS.md` — it's an opinion, not a team decision.
3. **Suggest sharper wording.** A vague rule ("no over-engineering")
   can't catch drift. A specific one ("no abstractions before
   N=4 callsites") can.
4. **Capture the reason inline.** Each rule should be one
   sentence + a one-line reason. Future maintainers (and
   `/spades:review`) need to know *why* the rule exists.
5. **Bias toward fewer, sharper rules.** Five well-articulated
   anti-patterns beat fifty vague ones.

## The Four Sections

`ANTI-PATTERNS.md` has exactly four sections. Locked schema.

### 1. Runtime Dependencies
Specific dependencies the team has decided not to add at
runtime. The reason matters: CI breakage, security audit
failure, footprint, license incompatibility, transitive bloat.

### 2. Hidden State
Patterns that create implicit state. Singletons, global
module-level config, thread-local context. Be explicit about
which patterns are banned and why this codebase cares.

### 3. Premature Abstraction
When to NOT abstract. Concrete rules like *"three similar lines
are fine; don't extract until N=4"* — explicit thresholds, not
vague exhortations.

### 4. Other Bans
Anything else the team has explicitly decided to avoid. Each
entry: the rule, then a one-line reason.

## The `last_reviewed` Field

`ANTI-PATTERNS.md` carries a `last_reviewed: YYYY-MM-DD` field in
its YAML frontmatter. Set to today's date on every Create or
meaningful Edit.

## Decision Prompts (AskUserQuestion)

- **Mode confirmation** when Create vs Edit is ambiguous.
- **Create-mode start** — *Draft inferred from the repo* /
  *Start blank*.
- **Edit-mode scope** — *Refresh `last_reviewed` only* /
  *Revise specific sections* / *Add a new prohibition* /
  *Full review pass*.

## Writing the File

Write `./ANTI-PATTERNS.md` only after the human has reviewed
every rule in play:

- **Create mode** — write the full file: the `last_reviewed`
  frontmatter, a short `# Anti-Patterns` heading, and the four
  `##` sections with the human's confirmed content. Remove any
  template fill markers.
- **Edit mode** — apply the confirmed changes and update
  `last_reviewed`. Preserve sections the human did not touch.

**In HTML mode, also write a persistent
`.spades/anti-patterns.html` alongside `ANTI-PATTERNS.md`.** Use
the same template the transient preview uses. In CLI mode,
`.spades/anti-patterns.html` is NOT written.

Then confirm what changed and remind the human that
`ANTI-PATTERNS.md` is a living document the SPADES loop reads.

There is no Linear step.

### Transient HTML preview (HTML mode only)

When `review_format: html`, during/after the walk:

**You MUST render via the bundled `template.html`. Do NOT
hand-roll the HTML.**

1. Read the template at
   `${CLAUDE_PLUGIN_ROOT}/skills/anti-patterns/template.html`.
2. Validate it contains the placeholders listed below; if any
   are missing, abort.
3. Substitute:
   - `{{spades.project_slug}}`, `{{spades.last_reviewed}}`,
     `{{spades.rendered_at}}`, `{{spades.plugin_version}}`.
   - Prose sections via direct substitutions:
     `{{spades.runtime_deps_html}}`,
     `{{spades.hidden_state_html}}`,
     `{{spades.premature_abstraction_html}}`,
     `{{spades.other_bans_html}}`.
4. Write to `.spades/.tmp/anti-patterns.html`.
5. Auto-open via the OPEN_CMD prelude.

In HTML mode the open `.html` preview IS the review surface
during the walk — the Socratic conversation stays CLI; the
*assembled ANTI-PATTERNS document* shown for review must be
HTML.

`ANTI-PATTERNS.md` itself stays Markdown in both modes — only the
preview is HTML.
