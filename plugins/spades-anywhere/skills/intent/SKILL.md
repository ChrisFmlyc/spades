---
name: intent
description: Create or maintain INTENT.md, the project's durable statement of intent — the problem it solves, who it serves, what it does, what success looks like, and its non-goals. Use when someone says "set up INTENT.md", "capture our project intent", "what is this project for", "update the intent doc", "review our non-goals", or when INTENT.md is missing, still an unfilled template, or flagged stale. The human composes the intent; this skill structures and probes but never authors it.
version: 0.4.0
---

# /spades-anywhere:intent

You are helping a human create or maintain `INTENT.md` — the durable
statement of why the project exists. It is a root reference
document, peer to `ARCHITECTURE.md`, that changes rarely and is the
backdrop every Scope is measured against: `/spades-anywhere:scope`
gates on its existence, `/spades-anywhere:ship` walks its success
criteria, and `/spades-anywhere:review`'s scope guardian checks
Scopes and Plans against its non-goals.

Read `docs/FRAMEWORK.md` § Hierarchy → Two layers of intent,
§ Asking the Human, and § Output Format before running.

### Output format

- **Both modes** — `INTENT.md` at the root of the project's
  knowledge store, human-authored Markdown and the canonical record.
- **HTML mode** — additionally two renders from
  `${CLAUDE_PLUGIN_ROOT}/skills/intent/template.html`: a persistent
  `.spades-anywhere/intent.html` saved alongside `INTENT.md`, and a
  transient `.spades-anywhere/.tmp/intent.html` opened as the review
  surface for the assembled document. The per-section conversation
  stays in the terminal.
- **CLI mode** — the assembled document prints once in the brief.

A root document with no backend mirror: Linear is for doing work,
and project documentation stays in the knowledge store.

## The core rule: facilitate, never author

The human owns the intent; you structure it. You may ask questions,
reflect answers back, propose structure, suggest wording for
something the human has already expressed, and, in Create mode,
offer an explicitly labelled draft starting point inferred from
whatever the human has shared (a brief, a README, attached notes)
for them to accept, reject, or rewrite. Every section lands only
after the human actively confirms it; silence is not consent.
Content the human has not said is a question to ask them.

## What `INTENT.md` is

It owns **why** the project exists and **for whom**: problem, users,
what it does, success, non-goals, maturity. How the work is
structured is `ARCHITECTURE.md`. It is durable rather than
strategic: OKRs and roadmaps are volatile and live upstream; a
section that would expire in 90 days belongs there. One living
document, edited in place, unlike a Scope (one unit of work) or a
learning (a small retrospective entry).

## Inline template

The scaffold `/spades-anywhere:setup` writes and Create mode fills.
Exactly this shape:

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

The placeholder comments stay when the human starts blank.

## Modes

Inspect `./INTENT.md`: **Missing** → Create; **unfilled** (two or
more placeholder comments) → Create in place; **filled** → Edit.
Confirm via `AskUserQuestion` when the request is ambiguous.

**Create.** Offer via `AskUserQuestion`: **Draft a starting point
from what's already shared, then I correct it** / **Start blank**.

**Edit.** Scope via `AskUserQuestion`: **Refresh `last_reviewed`
only** / **Revise specific sections** / **Full review pass**. Show
each section's current content before discussing changes.

## Conversational style

One section at a time: ask, listen, reflect back, confirm. Probe
vague answers ("it helps the family" — who, needing what, and what
is unacceptable without it?). Suggest sharper wording for the
human's own point. Be a sparring partner on the non-goals. Match the
ceremony to the work.

## The six sections

A locked schema.

1. **Problem** — the pain, friction, or gap, and for whom.
2. **Users** — the primary audiences and what each needs; who it
   is not for.
3. **What it does** — outcomes for those users, in plain terms.
4. **Success** — outcomes, not features. `/spades-anywhere:ship`
   walks these, so each should be confirmable with evidence.
5. **Non-goals** — the load-bearing section. Explicit, checkable
   statements. Good: *"We don't book anything non-refundable before
   the guest count is confirmed."* Bad: *"We won't overdo it."*
6. **Maturity** — where the project is today.

## `last_reviewed`

Set to today's date on every Create and every meaningful Edit,
including a "still accurate" pass. `/spades-anywhere:plan` reads it
for the staleness reminder.

## Writing the file

Write `./INTENT.md` once the human has confirmed every section in
play: Create writes the whole file; Edit applies the confirmed
changes and preserves untouched sections.

**HTML mode** — after the write, render twice from the template per
`docs/FRAMEWORK.md § Output Format → HTML rendering`, identical
inputs, different paths: `.spades-anywhere/intent.html` (persistent)
and `.spades-anywhere/.tmp/intent.html` (transient, opened).

- `frontmatter`: `{ project_slug, last_reviewed, rendered_at,
  plugin_version, maturity_stage }`
- `users_count`, `non_goals_count` *(scalars)*
- `blocks`:
  - `users-items` — one per Users bullet. Field: `html`.
  - `non-goals-items` — one per Non-goals bullet. Field: `html`.
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`.
- `prose_sections`: `{ problem_html, what_it_does_html,
  success_html, maturity_html }`

Required markers: `users-items`, `non-goals-items`.

## Brief

**HTML mode:**

```
✓ INTENT.md written (last reviewed YYYY-MM-DD)
○ .spades-anywhere/intent.html opened in browser
Next: /spades-anywhere:architecture · /spades-anywhere:scope <title>
```

**CLI mode:** the write confirmation, the assembled `INTENT.md`
once, the same `Next:` line. Remind the human to save the file to
their knowledge store.

## Quality check

- [ ] All six sections present and filled; no placeholders remain.
- [ ] Every section's content came from the human.
- [ ] Non-goals are specific and checkable.
- [ ] Success is stated as confirmable outcomes.
- [ ] Nothing duplicates `ARCHITECTURE.md` or reads like a
      quarterly OKR.
- [ ] `last_reviewed` is today.
