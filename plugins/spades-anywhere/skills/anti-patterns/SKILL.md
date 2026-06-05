---
name: anti-patterns
description: Create or maintain ANTI-PATTERNS.md, the project's durable list of things the team DELIBERATELY AVOIDS in how this work is run — process anti-patterns, communication anti-patterns, tool anti-patterns, and other "we won't do X" rules. Use when someone says "set up ANTI-PATTERNS.md", "document what we don't do", "we should ban X", "update the anti-patterns doc", or when ANTI-PATTERNS.md is missing, still an unfilled template, or flagged stale. The human composes the prohibitions; this skill structures and probes but never authors it.
version: 1.0.0
---

# SPADES-anywhere Anti-Patterns

### Output format

This skill honours `review_format:` from
`.spades-anywhere/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`.
**`ANTI-PATTERNS.md` itself stays at the repo root as
human-authored Markdown.** In HTML mode, after writing/refreshing
`ANTI-PATTERNS.md` the skill renders a persistent summary at
`.spades-anywhere/anti-patterns.html` via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/anti-patterns/template.html`, and
a transient preview at `.spades-anywhere/.tmp/anti-patterns.html`
during the edit flow. In CLI mode, no preview is rendered.

You are helping a human create or maintain `ANTI-PATTERNS.md` —
the durable list of things the team deliberately avoids in how
this work is run. In `spades-anywhere`, anti-patterns are
process-level: ways of working the team has explicitly decided
NOT to use.

`ANTI-PATTERNS.md` is a root reference document, peer to
`INTENT.md`, `ARCHITECTURE.md`, and `PATTERNS.md`. It changes
infrequently. `/spades-anywhere:plan` and
`/spades-anywhere:review` cross-check Plans against it.

## The Core Rule: Facilitate, Never Author

**The human owns the anti-patterns. You structure them. You
never invent them.**

Anti-patterns are usually born from real incidents or principled
philosophy. The AI's job is to capture them clearly; it must
not invent prohibitions the team has not decided on.

- **You MAY** ask, reflect, suggest sharper wording, draft a
  starting point from shared context (retro notes, post-mortems,
  prior debriefs).
- **You MUST NOT** invent prohibitions the human did not state;
  bring in generic "best-practice" anti-patterns from outside;
  save `ANTI-PATTERNS.md` before the human has reviewed every
  rule.

### Why this rule matters most for anti-patterns

A useful ANTI-PATTERNS.md captures rules *this team has actually
decided on*, ideally tied to a real incident or a deliberate
trade-off. Generic anti-patterns the team would shrug at are
worse than nothing — they dilute the file's signal.

## What ANTI-PATTERNS.md Is — and Is Not

`ANTI-PATTERNS.md` owns **deliberate prohibitions**. It does NOT
own:

- **Why** the project exists / for whom → `INTENT.md`.
- **How** the work is structured (stages, etc.) →
  `ARCHITECTURE.md`.
- **Approved process conventions** → `PATTERNS.md`. (The dual:
  PATTERNS is "we do X"; ANTI-PATTERNS is "we don't do Y".)
- **General-purpose bad practices** — only the ones *this team
  has explicitly decided to ban* belong here.

## Inline ANTI-PATTERNS.md Template

```markdown
---
last_reviewed: YYYY-MM-DD
---

# Anti-Patterns

## Process

<!-- Process steps or sequences the team has explicitly decided
     to avoid. "We never start interviews without a calibrated
     scorecard" (decided after Q2 hiring round where two
     candidates were rejected on incomparable grounds). -->

## Communication

<!-- Communication patterns the team has explicitly decided to
     avoid. "We don't make irreversible decisions in a chat
     thread" — capture the rule + the reason. -->

## Tools & Resources

<!-- Tools or resource usage the team has explicitly decided
     against. "We don't track this work in spreadsheets — it
     lives in Notion." Include the reason. -->

## Other Bans

<!-- Anything else the team has explicitly decided to avoid.
     Each entry: the rule, then a one-line reason. -->
```

## Where ANTI-PATTERNS.md Lives

`ANTI-PATTERNS.md` lives at the **repository root** (or
knowledge store root for chat-surface contexts).

## Modes

- **No file** → **Create mode**.
- **Unfilled template** → **Create mode**.
- **Filled and complete** → **Edit mode**.

If ambiguous, confirm via `AskUserQuestion`.

### Create Mode

Walk the human through all four sections. **Be especially
conservative** — propose few, high-confidence anti-patterns;
let the human add the rest.

### Edit Mode

`AskUserQuestion`:

- *Refresh `last_reviewed` only*
- *Revise specific sections*
- *Add a new prohibition*
- *Full review pass*

**Always read the existing file first** — preserve what's there.

## Conversational Style

1. **One section / one rule at a time.**
2. **Probe for the reason.** No concrete reason → probably
   shouldn't be in `ANTI-PATTERNS.md`.
3. **Suggest sharper wording.** Vague rules can't catch drift.
4. **Capture the reason inline.** One sentence + one-line reason.
5. **Bias toward fewer, sharper rules.**

## The Four Sections

`ANTI-PATTERNS.md` has exactly four sections. Locked schema.

### 1. Process
Process steps or sequences the team has explicitly decided to
avoid. Include the reason.

### 2. Communication
Communication patterns the team has explicitly decided to
avoid. Include the reason.

### 3. Tools & Resources
Tools / resource usage explicitly avoided. Include the reason.

### 4. Other Bans
Anything else the team has explicitly decided to avoid.

## The `last_reviewed` Field

Set to today's date on every Create or meaningful Edit.

## Decision Prompts (AskUserQuestion)

- **Mode confirmation** when ambiguous.
- **Create-mode start** — *Draft inferred* / *Start blank*.
- **Edit-mode scope** — *Refresh `last_reviewed` only* /
  *Revise specific sections* / *Add a new prohibition* /
  *Full review pass*.

## Writing the File

Write `./ANTI-PATTERNS.md` only after the human has reviewed
every rule in play.

**In HTML mode, also write a persistent
`.spades-anywhere/anti-patterns.html` alongside
`ANTI-PATTERNS.md`.** In CLI mode, the `.html` is NOT written.

There is **no SCM in spades-anywhere** — the human saves both
files to their chat-surface knowledge store on their own
cadence.

### Transient HTML preview (HTML mode only)

When `review_format: html`, render to
`.spades-anywhere/.tmp/anti-patterns.html`:

**You MUST render via the bundled `template.html`. Do NOT
hand-roll the HTML.**

1. Read the template at
   `${CLAUDE_PLUGIN_ROOT}/skills/anti-patterns/template.html`.
2. Validate placeholders; abort if any missing.
3. Substitute:
   - `{{spades.project_slug}}`, `{{spades.last_reviewed}}`,
     `{{spades.rendered_at}}`, `{{spades.plugin_version}}`.
   - Prose sections: `{{spades.process_html}}`,
     `{{spades.communication_html}}`, `{{spades.tools_html}}`,
     `{{spades.other_bans_html}}`.
4. Write to `.spades-anywhere/.tmp/anti-patterns.html`.
5. Auto-open via the OPEN_CMD prelude.

`ANTI-PATTERNS.md` itself stays Markdown in both modes.
