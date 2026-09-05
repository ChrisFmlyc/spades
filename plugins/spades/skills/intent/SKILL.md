---
name: intent
description: Create or maintain INTENT.md, the project's durable statement of intent — the problem it solves, who it serves, what it does, what success looks like, and its non-goals. Use when someone says "set up INTENT.md", "capture our project intent", "what is this project for", "update the intent doc", "review our non-goals", or when INTENT.md is missing, still an unfilled template, or flagged stale. The human composes the intent; this skill structures and probes but never authors it.
version: 4.4.1
---

# /spades:intent

You are helping a human create or maintain `INTENT.md` — the durable
statement of why the project exists. It is a root reference
document, peer to `ARCHITECTURE.md`, that changes rarely and is the
backdrop every Scope is measured against: `/spades:scope` gates on
its existence, `/spades:plan` reads its `last_reviewed`, and
`/spades:review`'s scope guardian checks Scopes and Plans against
its non-goals.

Read `docs/FRAMEWORK.md` § Hierarchy → Two layers of intent,
§ Asking the Human, and § Output Format before running.

### Output format

- **Both modes** — `INTENT.md` at the repo root, human-authored
  Markdown and the canonical record.
- **HTML mode** — additionally two renders from
  `${CLAUDE_PLUGIN_ROOT}/skills/intent/template.html`: a persistent
  `.spades/intent.html` committed alongside `INTENT.md`, and a
  transient `.spades/.tmp/intent.html` opened as the review surface
  for the assembled document during the walk. The per-section
  conversation stays in the terminal; the assembled document is
  reviewed on the page.
- **CLI mode** — the assembled document prints once in the brief.

`INTENT.md` is a committed root document, so there is no backend
mirror.

## The core rule: facilitate, never author

The human owns the intent; you structure it. Project intent is the
most human-owned thing in the framework — SPADES's model is that
humans own the edges, intent and verification — and a document the
AI wrote quietly is a fiction every downstream check would measure
against.

You may ask questions, reflect answers back, propose structure,
suggest wording for something the human has already expressed, and,
in Create mode, offer an explicitly labelled draft starting point
inferred from the README and docs for the human to accept, reject,
or rewrite. Every section lands in the file only after the human
has actively confirmed it — "looks fine, moving on" is confirmation;
silence is not. Content the human has not said is a question to ask
them, not a line to type.

## What `INTENT.md` is

It owns **why** the project exists and **for whom**: problem, users,
what it does in product terms, success, non-goals, maturity. `How`
it is built is `ARCHITECTURE.md`. It is durable rather than
strategic — OKRs, quarterly goals, and roadmaps are volatile and
live in the tracker; a section that would expire in 90 days belongs
there. It differs from a Scope (one unit of work that flows through
the loop and closes) and from learnings (many small retrospective
entries): one living document, edited in place.

See `examples/example-intent.md` for a worked example.

## Inline template

The scaffold `/spades:setup` writes and Create mode fills. Exactly
this shape:

```markdown
---
last_reviewed: YYYY-MM-DD
---

# Project Intent

## Problem

<!-- Describe the pain, friction, or gap this project exists to address,
     and for whom. Be concrete — what specific situation is unacceptable
     without the project? -->

## Users

<!-- Primary audiences or personas, and what each needs. Also worth
     naming who this is explicitly NOT for. -->

## What it does

<!-- Capabilities framed as outcomes for the users above. Product terms,
     not implementation. -->

## Success

<!-- Outcomes, not features. What signals show this project is achieving
     its purpose? Push back on feature lists here. -->

## Non-goals

<!-- The load-bearing section. What this project deliberately will NOT
     do. Explicit, checkable statements: "we will never X", "Y is out of
     scope until Z". A vague non-goal cannot catch drift. -->

## Maturity

<!-- The current stage — prototype, in production, maintenance,
     sunsetting — in a sentence or two. -->
```

The placeholder comments stay when the human starts blank; they are
the prompts for each section.

## Modes

Inspect `./INTENT.md`:

- **Missing** → Create.
- **Present but unfilled** (two or more placeholder comments) →
  Create, filling the scaffold in place.
- **Present and filled** → Edit.

When the request is ambiguous (a filled file and "set up our intent
doc"), confirm the mode via `AskUserQuestion`.

**Create.** Offer via `AskUserQuestion`: **Draft a starting point
from the README, then I correct it** / **Start blank — I'll describe
it myself**. A draft is proposed per section, labelled as an
inference to correct, and the human's corrections are the content.

**Edit.** Scope the edit via `AskUserQuestion`: **Refresh
`last_reviewed` only** / **Revise specific sections** (ask which) /
**Full review pass**. Show each section's current content before
discussing changes.

## Conversational style

One section at a time: ask, listen, reflect back, confirm, move on.
Probe vague answers ("it helps the security team" — who, doing what,
and what is unacceptable without it?). Suggest sharper wording for
the human's own point. Be a sparring partner on the non-goals, the
section humans under-invest in. Match the ceremony to the work: a
first Create deserves a real conversation; a `last_reviewed`
refresh is two lines.

## The six sections

The set is a locked schema.

1. **Problem** — the pain, friction, or gap, and for whom; the
   concrete situation that is unacceptable without the project.
2. **Users** — the primary audiences and what each needs, and who it
   is explicitly not for.
3. **What it does** — capabilities as outcomes for those users, in
   product terms.
4. **Success** — outcomes, not features: the signals that show the
   project achieving its purpose.
5. **Non-goals** — the load-bearing section. Explicit, checkable
   statements. Good: *"Argus does not take automated remediation
   action on devices — it informs human decisions; it never
   quarantines, patches, or disables a device."* Bad: *"We won't
   over-engineer it."* A human who can name no non-goals is worth
   probing; almost every project has them.
6. **Maturity** — prototype, in production, maintenance, sunsetting.

## `last_reviewed`

Set to today's date on every Create and every meaningful Edit,
including a "still accurate" pass with no content change. It is
what `/spades:plan` reads to decide whether to surface a staleness
reminder.

## Writing the file

Write `./INTENT.md` once the human has confirmed every section in
play: Create writes the whole file (frontmatter, `# Project Intent`,
the six sections, placeholders removed); Edit applies the confirmed
changes and preserves untouched sections.

**HTML mode** — after the write, dispatch two `worker-html-intent`
sub-agents in one wave per `docs/FRAMEWORK.md § worker-html-*`,
shared content and `open_path`, different `output_path`: `.spades/intent.html`
(persistent) and `.spades/.tmp/intent.html` (transient, opened).

- `open_path`: the absolute `.spades/.tmp/intent.html` path for initial
  presentation when this document is the active task; `null` for refreshes
  or background use. Both workers inherit it per § Review-page ownership.
- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/intent/template.html`
- `frontmatter`: `{ project_slug, last_reviewed, rendered_at,
  plugin_version, maturity_stage }`
- `users_count`, `non_goals_count` *(scalars)*: the item counts
- `blocks`:
  - `users-items` — one per Users bullet. Field: `html`.
  - `non-goals-items` — one per Non-goals bullet. Field: `html`.
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`.
- `prose_sections`: `{ problem_html, what_it_does_html,
  success_html, maturity_html }`

Required markers: `users-items`, `non-goals-items`.

## Brief

**HTML mode** (report “opened” only from `opened: true`; if opening was
requested but failed, link that selected page for manual opening. With
`open_path: null`, report the write only):

```
✓ INTENT.md written (last reviewed YYYY-MM-DD)
○ .spades/.tmp/intent.html opened in browser
Next: /spades:architecture · /spades:scope <title>
```

**CLI mode:** the write confirmation, the assembled `INTENT.md`
once, the same `Next:` line.

## Quality check

- [ ] All six sections present and filled; no placeholders remain.
- [ ] Every section's content came from the human.
- [ ] Non-goals are specific and checkable.
- [ ] Success is stated as outcomes.
- [ ] Nothing duplicates `ARCHITECTURE.md` or reads like a
      quarterly OKR.
- [ ] `last_reviewed` is today.
