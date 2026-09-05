---
name: anti-patterns
description: Create or maintain ANTI-PATTERNS.md, the project's durable list of things the codebase DELIBERATELY AVOIDS — runtime dependencies, hidden state, premature abstraction, and any other "we won't do X" rules. Use when someone says "set up ANTI-PATTERNS.md", "document what we don't do", "we should ban X", "we deliberately avoid Y", "what's forbidden here", "add an anti-pattern", "update the anti-patterns doc", "what shouldn't we do", or when ANTI-PATTERNS.md is missing, still an unfilled template, or flagged stale by /spades:plan, /spades:approve, or /spades:review. Also use proactively after a Plan rejection that traces to an unwritten prohibition. The human composes the prohibitions; this skill structures and probes but never authors it. SKIP when the human's intent is per-Plan risk capture (use the Plan's Risks & Assumptions section instead) or when documenting an APPROVED pattern (use /spades:patterns).
version: 1.5.1
---

# /spades:anti-patterns

You are helping a human create or maintain `ANTI-PATTERNS.md` — the
durable list of things the codebase deliberately avoids. A root
reference document, peer to `INTENT.md`, `ARCHITECTURE.md`, and
`PATTERNS.md`, and the prohibition layer `/spades:plan` and
`/spades:review`'s architecture strategist cross-check Plans
against: a Plan proposing a forbidden technique is a blocking
finding.

Read `docs/FRAMEWORK.md` § Asking the Human and § Output Format
before running.

### Output format

- **Both modes** — `ANTI-PATTERNS.md` at the repo root, the
  canonical record.
- **HTML mode** — additionally two renders from
  `${CLAUDE_PLUGIN_ROOT}/skills/anti-patterns/template.html`: a
  persistent `.spades/anti-patterns.html` and a transient
  `.spades/.tmp/anti-patterns.html` opened as the review surface for
  the assembled document. The per-rule conversation stays in the
  terminal.
- **CLI mode** — the assembled document prints once in the brief.

A committed root document; no backend mirror.

## The core rule: facilitate, never author

Anti-patterns are the team's prohibitions, usually born from a real
incident, a hard trade-off, or a principle. Capture them clearly.
You may ask, reflect back, suggest sharper wording, and, in Create
mode, offer a small, high-confidence draft inferred from lint
configs (`eslint.config.js`, `[tool.ruff]`, golangci-lint), the
README, and explicit "don't do X" comments in the codebase. Every
rule lands only after the human confirms it. The internet is full of
plausible "don't do X" rules; a generic one the team would shrug at
dilutes the file and turns the architecture strategist's findings
into false positives, so a rule the team has not decided on is a
question rather than a line.

## What `ANTI-PATTERNS.md` is

It owns **deliberate prohibitions** — "we don't do Y", the dual of
`PATTERNS.md`'s "we do X". Style enforceable by a formatter belongs
in the formatter config; general engineering bad practice belongs
here only when this team has explicitly banned it. A good entry
reads as a rule with a reason: *"No runtime dependency on PyYAML —
stdlib-only Markdown lint (decided 2024-Q4 after the Python 3.13
PyYAML wheels broke CI)."*

## Inline template

The scaffold `/spades:setup` writes and Create mode fills. Exactly
this shape:

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

The placeholder comments stay when the human starts blank. Each ban
is a discrete item — a short title, why it is banned, what to do
instead — so the renderer can card and count them.

## Modes

Inspect `./ANTI-PATTERNS.md`: **Missing** → Create; **unfilled**
(two or more placeholder comments) → Create in place; **filled** →
Edit. Confirm via `AskUserQuestion` when ambiguous.

**Create.** Offer via `AskUserQuestion`: **Draft a starting point
inferred from the repo, then I correct it** / **Start blank**.
Propose few, high-confidence rules and let the human add the rest.

**Edit.** Read the existing file first, then scope via
`AskUserQuestion`: **Refresh `last_reviewed` only** / **Revise
specific sections** / **Add a new prohibition** (free-form, in the
human's own wording) / **Full review pass**. Untouched sections are
preserved.

## Conversational style

One section or one rule at a time. Probe for the reason — with no
incident, trade-off, or principle behind it, a rule is an opinion
and stays out. Suggest sharper wording: "no over-engineering" cannot
catch drift; "no abstractions before four call sites" can. Capture
the reason inline, one sentence each. Five well-articulated bans
beat fifty vague ones.

## The four sections

A locked schema.

1. **Runtime Dependencies** — specific dependencies the team keeps
   out at runtime, with the reason.
2. **Hidden State** — singletons, module-level config, thread-local
   context: which are banned and why this codebase cares.
3. **Premature Abstraction** — explicit thresholds for when not to
   abstract.
4. **Other Bans** — anything else, each with its one-line reason.

## `last_reviewed`

Set to today's date on every Create and every meaningful Edit.

## Writing the file

Write `./ANTI-PATTERNS.md` once the human has confirmed every rule
in play.

**HTML mode** — after the write, dispatch two
`worker-html-anti-patterns` sub-agents in one wave per
`docs/FRAMEWORK.md § worker-html-*`, shared content and `open_path`, different
`output_path`: `.spades/anti-patterns.html` (persistent) and
`.spades/.tmp/anti-patterns.html` (transient, opened).

- `open_path`: the absolute `.spades/.tmp/anti-patterns.html` path for initial
  presentation when this document is the active task; `null` for refreshes
  or background use. Both workers inherit it per § Review-page ownership.
- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/anti-patterns/template.html`
- `frontmatter`: `{ project_slug, last_reviewed, rendered_at,
  plugin_version }`
- `ban_count` *(scalar)*: total bans across the four sections
- `blocks`:
  - `runtime-deps-bans`, `hidden-state-bans`,
    `premature-abstraction-bans`, `other-bans-bans` — one card per
    ban under the matching section. Fields: `title, why_html,
    instead_html`.
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`.

Required markers: the four `*-bans` blocks.

## Brief

**HTML mode** (report “opened” only from `opened: true`; if opening was
requested but failed, link that selected page for manual opening. With
`open_path: null`, report the write only):

```
✓ ANTI-PATTERNS.md written (last reviewed YYYY-MM-DD)
○ .spades/.tmp/anti-patterns.html opened in browser
Next: /spades:scope <title>
```

**CLI mode:** the write confirmation, the assembled
`ANTI-PATTERNS.md` once, the same `Next:` line.
