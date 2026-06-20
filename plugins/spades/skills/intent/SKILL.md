---
name: intent
description: Create or maintain INTENT.md, the project's durable statement of intent — the problem it solves, who it serves, what it does, what success looks like, and its non-goals. Use when someone says "set up INTENT.md", "capture our project intent", "what is this project for", "update the intent doc", "review our non-goals", or when INTENT.md is missing, still an unfilled template, or flagged stale. The human composes the intent; this skill structures and probes but never authors it.
version: 4.3.0
---

# SPADES Intent

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. **`INTENT.md`
itself stays at the repo root as human-authored Markdown — it is
not auto-converted to HTML in either mode.** In HTML mode, after
writing/refreshing `INTENT.md` the skill renders a *transient*
preview via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/intent/template.html` to
`.spades/.tmp/intent.html` and auto-opens it via OPEN_CMD so the
human can review the refreshed intent in the same B-style format
they review other artefacts. In CLI mode, no preview is rendered;
the human reads `INTENT.md` directly. The Socratic facilitate-never-author
flow is identical between modes.

You are helping a human create or maintain `INTENT.md` — the durable
statement of why a project exists. `INTENT.md` is a root reference document,
peer to `ARCHITECTURE.md`. It changes rarely. It is the backdrop every Scope
is measured against: when a Scope or Plan drifts away from the project's
purpose, `INTENT.md` is what makes that visible.

## The Core Rule: Facilitate, Never Author

**The human owns the intent. You structure it. You never invent it.**

This is the single non-negotiable rule of this skill. SPADES's whole model is
"humans own the edges — intent and verification" (see `AGENTS.md`). Project
intent is the most human-owned thing in the entire framework. If an AI quietly
writes it, the document becomes a fiction and every downstream check built on
it is checking against that fiction.

Concretely:

- **You MAY** ask questions, reflect answers back, propose *structure*,
  suggest *wording* for something the human has already expressed, and — in
  Create mode — offer an explicitly-labelled *draft starting point* inferred
  from the repo (README, docs) for the human to accept, reject, or rewrite.
- **You MUST NOT** write a section the human has not supplied or confirmed;
  present inferred content as established fact; invent non-goals, success
  criteria, audiences, or claims the human did not state; or save `INTENT.md`
  before the human has seen and approved every section.
- **Silence is not consent.** Every section — especially every draft you
  propose — must be actively confirmed by the human before it lands in the
  file. "Looks fine, moving on" is confirmation; no answer is not.

If you ever find yourself typing intent content the human did not say, stop
and ask them instead.

## What INTENT.md Is — and Is Not

`INTENT.md` owns **why** the project exists and **for whom**. It does not own
**how** it is built — that is `ARCHITECTURE.md`. Keep the boundary crisp:

- Problem, users, what it does (in product terms), success, non-goals,
  maturity → `INTENT.md`.
- Tech stack, infrastructure, data flow, patterns → `ARCHITECTURE.md`.

`INTENT.md` is **not** a strategy document. It does not hold OKRs, quarterly
goals, or a roadmap — those are volatile and live in the tracker. `INTENT.md`
is the *durable* layer underneath them: it should still be true a year from
now. If a section reads like it will expire in 90 days, it belongs in an OKR,
not here.

This skill is distinct from its neighbours, deliberately:

- It is **not** `/spades:scope`. A Scope defines one unit of work and becomes a
  tracker issue that flows through the loop and then closes. `INTENT.md` is one
  durable document, edited in place, that never closes.
- It is **not** `/spades:learn`. Learnings are many small immutable retrospective
  entries. `INTENT.md` is a single living document about the project's purpose.

See `examples/example-intent.md` (or `.spades/examples/example-intent.md` in a
consumer repo) for a worked example.

## Inline INTENT.md Template

When this skill needs to scaffold a fresh `INTENT.md`, use exactly this
shape — never copy from an external template file:

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

Leave the placeholder comments in place if the human picks "start
blank" — they're the prompts that walk them through filling each
section.

## Where INTENT.md Lives

`INTENT.md` lives at the **repository root**, alongside `ARCHITECTURE.md`. This
skill reads and writes `./INTENT.md` in the current project. It is a plain
Markdown file with a small YAML frontmatter block (`last_reviewed`).

## Modes

Determine the mode by inspecting `./INTENT.md`:

- **No `INTENT.md`** → **Create mode**.
- **`INTENT.md` exists but is still an unfilled template** — it contains two or
  more `<!-- Describe … -->` / `<!-- List … -->` style markers → **Create
  mode** (you are filling the scaffolded template in place).
- **`INTENT.md` exists and is filled in** → **Edit mode**.

If the human's request is ambiguous (e.g. a filled `INTENT.md` exists but they
said "set up our intent doc"), confirm the mode with `AskUserQuestion` rather
than guessing.

### Create Mode

Walk the human through all six sections from scratch (or fill the scaffolded
template). Before starting, offer — via `AskUserQuestion` — to draft a starting
point inferred from the repo's README and docs:

- *Draft a starting point from the README, then I correct it*
- *Start blank — I'll describe it myself*

If they choose the draft, read the README and any obvious docs, propose a
draft **per section, clearly labelled as an inference you need them to
correct**, and treat their corrections as the real content. If they choose
blank, ask about each section directly.

### Edit Mode

The human wants to refine an existing `INTENT.md`, or a SPADES skill flagged it
(staleness nudge from `/spades:plan`, or an update suggestion from
`/spades:evaluate`). Use `AskUserQuestion` to scope the edit:

- *Refresh `last_reviewed` only — the content is still accurate*
- *Revise specific sections*
- *Full review pass — walk every section*

For "revise specific sections", ask which. For a full pass, walk all six.
Show the current content of each section before discussing changes.

## Conversational Style

This is an interactive, guided conversation — not a form, and not a document
you write for them.

1. **One section at a time.** Ask, listen, reflect back, confirm, move on.
   Never dump all six sections at once.
2. **Probe vague answers.** "It helps the security team" is not enough — who
   on the team, doing what, and what is unacceptable without the project?
3. **Suggest sharper wording, not new substance.** If the human's point is
   sound but loosely worded, offer a tighter phrasing of *their* point — and
   let them accept or reject it.
4. **Be a sparring partner on the non-goals.** This is the section humans
   under-invest in. Push for specifics (see below).
5. **Reflect and confirm before moving on.** After each section, show what you
   captured and let the human correct it.
6. **Match ceremony to the work.** A first-time Create for a serious project
   deserves a real conversation; a `last_reviewed` refresh is two lines.

## The Six Sections

`INTENT.md` has exactly six sections. The set is a locked schema — do not add,
drop, or rename them. Guide the human through each:

### 1. Problem
What pain, friction, or gap does this project exist to address, and for whom?
Push for the concrete situation that is unacceptable without the project.

### 2. Users
Who is this for? The primary audiences or personas and what each needs. It is
also worth naming who it is explicitly *not* for.

### 3. What it does
What the project does in **product terms** — capabilities framed as outcomes
for the users above. Not a technical description; implementation belongs in
`ARCHITECTURE.md`.

### 4. Success
What success looks like as **outcomes, not features**. What signals would show
the project is achieving its purpose? Push back on feature lists here.

### 5. Non-goals
**The load-bearing section.** What the project deliberately will *not* do.
This is the project-level boundary that `/spades:review`'s `scope-guardian`
checks Scopes and Plans against — a vague non-goal cannot catch drift.

Good: "Argus does not take automated remediation action on devices — it
informs human decisions; it never quarantines, patches, or disables a device."

Bad: "We won't over-engineer it."

Push for explicit, checkable statements: "we will never X", "Y is out of scope
until Z". If the human cannot name any non-goals, that is itself worth
probing — almost every project has them.

### 6. Maturity
The current stage — prototype, in production, maintenance, sunsetting — in a
sentence or two. Where the project genuinely is today.

## The `last_reviewed` Field

`INTENT.md` carries a `last_reviewed: YYYY-MM-DD` field in its YAML
frontmatter. Whenever this skill finishes a Create or a meaningful Edit —
including a "still accurate" review pass with no content change — set
`last_reviewed` to **today's date**. That date is what `/spades:plan` reads to
decide whether to surface a staleness reminder; keeping it honest is the point
of the field.

## Decision Prompts (AskUserQuestion)

Intent **content** is open-ended composition and stays free-form — never force
a problem statement or a non-goal into a fixed-option list. But the **fixed
decisions** this skill makes along the way use `AskUserQuestion` (per
`docs/FRAMEWORK.md` § "Asking the Human"):

- **Mode confirmation** when Create vs Edit is ambiguous.
- **Create-mode start** — *Draft a starting point from the README* / *Start
  blank*.
- **Edit-mode scope** — *Refresh `last_reviewed` only* / *Revise specific
  sections* / *Full review pass*.

## Writing the File

### Write the file(s)

Write `./INTENT.md` only after the human has reviewed every section in play:

- **Create mode** — write the full file: the `last_reviewed` frontmatter, a
  short `# Project Intent` heading, and the six `##` sections with the human's
  confirmed content. Remove any template fill markers.
- **Edit mode** — apply the confirmed changes and update `last_reviewed`.
  Preserve sections the human did not touch.

**In HTML mode (`review_format: html`), also write a persistent
`.spades/intent.html` alongside `INTENT.md`.** Use the same
template the transient preview uses
(`${CLAUDE_PLUGIN_ROOT}/skills/intent/template.html`) with the
same placeholder substitutions described under "Transient HTML
preview" below — the only difference is the destination path and
lifecycle:

- `.spades/intent.html` is **persistent** (tracked, committed
  alongside `INTENT.md`). It is the human's steady-state view of
  the project's intent.
- `.spades/.tmp/intent.html` (covered below) is **transient**
  (`.tmp/` is gitignored). It exists only for the in-flight edit
  review and is recreated each time `/spades:intent` runs.

Both files use the same template content; they just live in
different places for different jobs. In CLI mode, `.spades/intent.html`
is NOT written — only `INTENT.md` exists.

There is no Linear step — `INTENT.md` is a committed root
document, not a tracker artefact.

### HTML mode — parallel render dispatch

**Read `review_format:` from `.spades/config`.** When
`review_format: html`, after the `INTENT.md` write succeeds,
dispatch **two** `worker-html-intent` sub-agents in parallel per
`docs/FRAMEWORK.md § worker-html-* — parallel HTML rendering`:

- **Persistent**: `output_path = .spades/intent.html` (committed
  alongside `INTENT.md`).
- **Transient**: `output_path = .spades/.tmp/intent.html` (the
  in-flight preview; gitignored).

Both workers take the same inputs (identical content, different
output paths):

- `template_path`:
  `${CLAUDE_PLUGIN_ROOT}/skills/intent/template.html`
- `frontmatter`: `{ project_slug, last_reviewed, rendered_at,
  plugin_version, maturity_stage }`
- `users_count` *(scalar)*: the number of `users-items`. Drives the deck.
- `non_goals_count` *(scalar)*: the number of `non-goals-items`. Drives
  the deck.
- `blocks`:
  - `users-items` — one per bullet under `## Users`. Field: `html`.
  - `non-goals-items` — one per bullet under `## Non-goals`. Field: `html`.
  - `objective-banner` — 0 or 1 item, fields `{ id, title }`, per
    `docs/FRAMEWORK.md § Objective banner`. For this project-level
    doc, pass the project's sole `open` Objective when EXACTLY ONE
    exists (scan `.spades/objectives/*.md` for the active project);
    else pass `[]`.
- `prose_sections`: `{ problem_html, what_it_does_html,
  success_html, maturity_html }`

Required template markers:
`<!-- SPADES-BLOCK:users-items -->`,
`<!-- SPADES-BLOCK:non-goals-items -->`.

The transient render is the in-flight preview the human reviews
during the Socratic walk; the persistent render is the
committed steady-state view. Two workers, one wave, fully
parallel.

**In HTML mode the open `.html` preview IS the review surface — do
NOT also paste / summarise the assembled INTENT body to the CLI;
the human has the browser tab.** The Socratic interview's
conversational back-and-forth (the per-section probing questions,
the human's free-form answers, the per-section confirmations) all
stay CLI as today — those are conversational. What must NOT go to
the CLI in HTML mode is the *assembled INTENT document* shown for
review. See `docs/FRAMEWORK.md § Output Format → What counts as
review-form text` for the canonical line.

`INTENT.md` itself stays Markdown in both modes — only the transient
preview is HTML, and only in HTML mode. In CLI mode this step is
skipped entirely; the human reads `INTENT.md` from disk if they
want to review the final assembled document.

## End-of-Skill Brief

The skill must terminate with a brief that confirms the write and
points at follow-up commands. Branch on `review_format:`:

**HTML mode** — 3 lines, no body dump (the browser tab IS the
review surface):

```
✓ INTENT.md written (last reviewed YYYY-MM-DD)
○ .spades/intent.html opened in browser
Next: /spades:architecture · /spades:scope <title>
```

**CLI mode** — confirm the write, then print the assembled
`INTENT.md` body once as the review surface (this is the only
data dump and it happens here):

```
✓ INTENT.md written (last reviewed YYYY-MM-DD)

<contents of INTENT.md>

Next: /spades:architecture · /spades:scope <title>
```

## Quality Checks

Before finishing, verify:

- [ ] All six sections are present and filled — no template markers remain.
- [ ] Every section's content came from the human, not from you.
- [ ] Non-goals are specific and checkable, not platitudes.
- [ ] Success is stated as outcomes, not a feature list.
- [ ] Nothing in `INTENT.md` duplicates `ARCHITECTURE.md` (how) or reads like a
      quarterly OKR (volatile).
- [ ] `last_reviewed` is set to today's date.

## What This Skill Must Never Do

- **Author intent.** You do not decide what the project is for. Ever.
- **Present inference as fact.** A draft from the README is a proposal the
  human must correct, and you must say so.
- **Save `INTENT.md` without section-by-section human confirmation.**
- **Invent non-goals, users, or success criteria** to fill a silent section —
  ask the human instead.
- **Add, drop, or rename sections** — the six-section schema is locked.
- **Render or file anything** — `INTENT.md` is a plain root document.
