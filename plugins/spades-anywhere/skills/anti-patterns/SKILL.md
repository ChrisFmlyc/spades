---
name: anti-patterns
description: Create or maintain ANTI-PATTERNS.md, the project's durable list of things the team DELIBERATELY AVOIDS in how this work is run — process anti-patterns, communication anti-patterns, tool anti-patterns, and other "we won't do X" rules. Use when someone says "set up ANTI-PATTERNS.md", "document what we don't do", "we should ban X", "we deliberately avoid Y", "what's forbidden here", "add an anti-pattern", "update the anti-patterns doc", "what shouldn't we do", or when ANTI-PATTERNS.md is missing, still an unfilled template, or flagged stale by /spades-anywhere:plan, /spades-anywhere:approve, or /spades-anywhere:review. Also use proactively after a Plan rejection that traces to an unwritten prohibition. The human composes the prohibitions; this skill structures and probes but never authors it. SKIP when the human's intent is per-Plan risk capture (use the Plan's Risks & Assumptions section instead) or when documenting an APPROVED pattern (use /spades-anywhere:patterns).
version: 1.2.0
---

# /spades-anywhere:anti-patterns

You are helping a human create or maintain `ANTI-PATTERNS.md` — the
durable list of ways of working the team has explicitly decided
against. A root reference document, peer to `INTENT.md`,
`ARCHITECTURE.md`, and `PATTERNS.md`, and the prohibition layer
`/spades-anywhere:plan` and `/spades-anywhere:review` cross-check
Plans against: a Plan proposing a forbidden practice is a blocking
finding.

Read `docs/FRAMEWORK.md` § Asking the Human and § Output Format
before running.

### Output format

- **Both modes** — `ANTI-PATTERNS.md` at the root of the knowledge
  store, the canonical record.
- **HTML mode** — additionally two renders from
  `${CLAUDE_PLUGIN_ROOT}/skills/anti-patterns/template.html`: a
  persistent `.spades-anywhere/anti-patterns.html` and a transient
  `.spades-anywhere/.tmp/anti-patterns.html` opened as the review
  surface.
- **CLI mode** — the assembled document prints once in the brief.

A root document; no backend mirror.

## The core rule: facilitate, never author

Anti-patterns are the team's prohibitions, usually born from a real
incident, a hard trade-off, or a principle. Capture them clearly.
You may ask, reflect back, suggest sharper wording, and, in Create
mode, offer a small, high-confidence draft from shared context
(retro notes, post-mortems, prior debriefs). Every rule lands only
after the human confirms it. A generic rule the team would shrug at
dilutes the file and produces false positives in review, so a
prohibition the team has not decided on is a question rather than
a line.

## What `ANTI-PATTERNS.md` is

It owns **deliberate prohibitions** — "we don't do Y", the dual of
`PATTERNS.md`'s "we do X". How the work is structured is
`ARCHITECTURE.md`; why it exists is `INTENT.md`. A good entry reads
as a rule with a reason: *"We never start interviews without a
calibrated scorecard (decided after the Q2 round, where two
candidates were rejected on incomparable grounds)."*

## Inline template

The scaffold `/spades-anywhere:setup` writes and Create mode fills.
Exactly this shape:

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

The placeholder comments stay when the human starts blank. Each ban
is a discrete item — a short title, why it is banned, what to do
instead — so the renderer can card and count them.

## Modes

Inspect `./ANTI-PATTERNS.md`: **Missing** → Create; **unfilled** →
Create in place; **filled** → Edit. Confirm via `AskUserQuestion`
when ambiguous.

**Create.** Offer via `AskUserQuestion`: **Draft a starting point
from what's already shared, then I correct it** / **Start blank**.
Propose few, high-confidence rules and let the human add the rest.

**Edit.** Read the existing file first, then scope via
`AskUserQuestion`: **Refresh `last_reviewed` only** / **Revise
specific sections** / **Add a new prohibition** (in the human's own
wording) / **Full review pass**.

## Conversational style

One section or one rule at a time. Probe for the reason — with no
incident, trade-off, or principle behind it, a rule is an opinion
and stays out. Suggest sharper wording: vague rules cannot catch
drift. Capture the reason inline. Five sharp bans beat fifty vague
ones.

## The four sections

A locked schema.

1. **Process** — steps or sequences the team avoids, with reasons.
2. **Communication** — patterns the team avoids, with reasons.
3. **Tools & Resources** — tools or usage the team avoids, with
   reasons.
4. **Other Bans** — anything else, each with a one-line reason.

## `last_reviewed`

Set to today's date on every Create and every meaningful Edit.

## Writing the file

Write `./ANTI-PATTERNS.md` once the human has confirmed every rule
in play.

**HTML mode** — after the write, render twice from the template per
`docs/FRAMEWORK.md § Output Format → HTML rendering`, identical
inputs, different paths: `.spades-anywhere/anti-patterns.html`
(persistent) and `.spades-anywhere/.tmp/anti-patterns.html`
(transient, opened).

- `frontmatter`: `{ project_slug, last_reviewed, rendered_at,
  plugin_version }`
- `ban_count` *(scalar)*: total bans across the four sections
- `blocks`:
  - `process-bans`, `communication-bans`, `tools-bans`,
    `other-bans-bans` — one card per ban under the matching
    section. Fields: `title, why_html, instead_html`.
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`.

Required markers: the four `*-bans` blocks.

## Brief

**HTML mode:**

```
✓ ANTI-PATTERNS.md written (last reviewed YYYY-MM-DD)
○ .spades-anywhere/anti-patterns.html opened in browser
Next: /spades-anywhere:scope <title>
```

**CLI mode:** the write confirmation, the assembled
`ANTI-PATTERNS.md` once, the same `Next:` line. Remind the human to
save the file to their knowledge store.
