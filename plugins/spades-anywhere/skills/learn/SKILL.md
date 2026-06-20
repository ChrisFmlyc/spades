---
name: learn
description: Capture a learning from completed work and store it under .spades-anywhere/learnings/ so future Plans can reference it. Use when someone says "capture a learning", "record what we learned", "log this learning", "we should remember this", or after an Evaluate phase reveals something worth carrying forward. Also use with `--refresh` to archive stale or contradictory learnings.
version: 0.1.2
---

# SPADES-anywhere Learn

## Pre-Flight

Read `.spades-anywhere/config` to confirm the active project (used as the
default `scope_ref` resolver below). If `.spades-anywhere/config` is missing,
`/spades-anywhere:learn` still runs — learnings are local-only — but suggest
`/spades-anywhere:setup` if the human intends to use SPADES properly.

Learnings live under `.spades-anywhere/learnings/` regardless of backend. This
skill makes **no backend MCP calls**.

### Output format

This skill honours `review_format:` from
`.spades-anywhere/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML) → Universal
rule`. In **both** modes, write the learning as
`.spades-anywhere/learnings/YYYY-MM-DD-<slug>.md` — this is the
AI-readable source of truth and the canonical record. In HTML
mode, **additionally** render via the sibling
`${CLAUDE_PLUGIN_ROOT}/skills/learn/template.html` and write the
`.html` companion at the equivalent path for the human's view,
then auto-open. HTML mode is additive — the `.md` always
exists; the `.html` is added in HTML mode.

**HTML mode is review-via-file, not review-via-CLI.** Do NOT paste
the learning body to the CLI for the human's approval before Step 4
writes the file. The file IS the review surface. Step 4 writes a
working draft and auto-opens it; the human reviews in the browser.
To iterate, apply targeted edits to the file (the human reloads to
see changes) — never re-paste a new full draft to the CLI. In CLI
mode the existing draft-then-paste workflow (Step 2: "Propose a
draft") is fine.

Each pass of the SPADES loop should produce knowledge that strengthens the
next pass. Without a place to capture it, that knowledge vanishes into PR
descriptions and Evaluate comments. This skill captures it as a structured
Markdown entry under `.spades-anywhere/learnings/` so `/spades-anywhere:plan` can surface it
the next time a related Scope comes through.

## Two modes

| Mode                    | When to use                                                                                                           |
|-------------------------|-----------------------------------------------------------------------------------------------------------------------|
| capture (default)       | After Evaluate, or anytime during delivery, when the team notices something worth remembering for future work.        |
| `--refresh`             | Periodic (quarterly at most) housekeeping: archive stale entries, resolve contradictions, keep the store high-signal. |

Always capture one learning at a time. If someone describes three lessons,
run the skill three times and record them separately.

## Storage format

Each learning is a Markdown file at:

```
.spades-anywhere/learnings/YYYY-MM-DD-<short-slug>.md          # public-safe
.spades-anywhere/learnings/private/YYYY-MM-DD-<short-slug>.md  # NOT committed
```

With this frontmatter (flat YAML, one key per line — no nested structures):

```yaml
---
title: One-line summary of what was learned
area: scope | plan | approve | do | evaluate | ship | other
tags: [tag1, tag2, tag3]
created: YYYY-MM-DD
status: active
public_safe: true
scope_ref: S-add-ai-helper-bot     # optional; the Scope this learning came from
plan_ref: P-rag-pipeline-lookup-3HyD   # optional; specific Plan if applicable
---
```

Body has two suggested sections:

```markdown
## What we learned

One paragraph describing the observation or insight. Be specific. "We
should be more careful with X" is not a learning — "X has property Y
that bit us because Z" is.

## Why it matters for future work

How this should change the next Plan. What patterns does it imply?
What should future Scopes or Plans account for? Link to relevant code,
docs, or prior issues where helpful.
```

## Capture flow

When invoked in the default mode:

1. **Read the context.** If a Scope or Plan ID is named in the user's
   message ("capture a learning from S-add-ai-helper-bot" or "from
   P-rag-pipeline-lookup-3HyD"), capture it as `scope_ref` / `plan_ref`.
   If the user referenced a specific file path or area of the codebase,
   use that to pre-fill the `area` field.
2. **Propose a draft.** Don't ask eight questions in a row — draft a
   complete learning based on the conversation so far. In **CLI mode**
   present the draft inline to the terminal for the human to correct.
   In **HTML mode** skip the CLI paste — proceed directly to Step 4,
   which writes the file as a working draft and auto-opens it; the
   human reviews in the browser. Use the frontmatter + body format
   above.
3. **Classify public-safe.** Ask via **`AskUserQuestion`** (per
   `docs/FRAMEWORK.md` § "Asking the Human") with three options:
   - *Public-safe — commit to .spades-anywhere/learnings/*
   - *Private — write to .spades-anywhere/learnings/private/ (gitignored)*
   - *Skip — don't capture*
   Public-safe learnings are OK to land in a public fork of this repo.
   Private learnings name internal systems, customers, credentials
   paths, security details, or anything else that should not leak. When
   in doubt, route to `private/` — downgrading later is cheap.
4. **Confirm and write.** After the human approves the draft (in CLI
   mode) or after Step 3 classification completes (in HTML mode —
   there is no pre-write CLI draft to approve), **read `review_format:`
   from `.spades-anywhere/config` and branch.** Step 4 MUST write a file before
   exiting — never finish with the draft pasted to the CLI only, **and
   in HTML mode never paste the learning body to the CLI for human
   approval before this step writes the file**. The file IS the review
   surface in HTML mode (see § Output format above).

   Choose a short, hyphenated slug that reads well (e.g.
   `onboarding-must-be-idempotent`, not `learn-1`). The slug is the
   same across both formats; only the extension and rendering differ.

   ##### Write the canonical `.md` (both modes)

   - If `public_safe: true` → write `.spades-anywhere/learnings/YYYY-MM-DD-<slug>.md`.
   - If `public_safe: false` → write `.spades-anywhere/learnings/private/YYYY-MM-DD-<slug>.md`.

   ##### Additionally render the HTML (HTML mode only)

   When `review_format: html`, after the `.md` above is written,
   render the HTML companion file. The `.md` is unchanged; the
   `.html` is **additive**.


   **You MUST render via the bundled `template.html`. Do NOT
   hand-roll the HTML.** Validate the template exists and the named
   blocks below match the markers in the actual file before
   substituting; abort and surface any mismatch. See
   `docs/FRAMEWORK.md § Output Format → HTML rendering: validate
   and use the bundled template` for the canonical rule.

   - Read the template at
     `${CLAUDE_PLUGIN_ROOT}/skills/learn/template.html`.
   - Validate it contains the block markers listed below; if any
     are missing, abort.
   - Substitute placeholders per `docs/FRAMEWORK.md § Output
     Format`:
     - Frontmatter values fill `{{spades.id}}`, `{{spades.title}}`,
       `{{spades.area}}`, `{{spades.status}}`, `{{spades.created}}`,
       `{{spades.public_safe}}`, `{{spades.project}}` (optional —
       the active project slug, for the rail).
     - The frontmatter YAML block also goes verbatim into the
       `<script type="application/yaml" id="spades-frontmatter">` tag.
     - `<!-- SPADES-BLOCK:objective-banner -->` — 0 or 1 item per
       `docs/FRAMEWORK.md § Objective banner`. Pass the project's
       sole `open` Objective `{{block.id}}`, `{{block.title}}` when
       EXACTLY ONE exists in `.spades-anywhere/objectives/`, else
       `[]`.
     - `<!-- SPADES-BLOCK:tags-items -->` — repeated once per tag.
       Per-item: `{{block.tag}}`.
     - `<!-- SPADES-BLOCK:related-items -->` — repeated once per
       related-link bullet. Per-item: `{{block.text}}`,
       `{{block.href|}}`.
     - `<!-- SPADES-BLOCK:audit-events -->` — repeated once per
       audit entry in both the visible timeline and the
       `<script type="application/yaml" id="spades-audit-trail">`
       YAML block. Per-item: `{{block.date}}`, `{{block.desc}}`.
     - The prose body sections are direct
       `{{spades.<section>_html}}` substitutions, not repeating
       blocks.
   - If `public_safe: true` → write `.spades-anywhere/learnings/YYYY-MM-DD-<slug>.html`.
   - If `public_safe: false` → write `.spades-anywhere/learnings/private/YYYY-MM-DD-<slug>.html`.
   - Auto-open via OPEN_CMD
     (`docs/FRAMEWORK.md § OPEN_CMD detection prelude`). Print the
     file path with "open this in your browser" if `OPEN_CMD` is
     empty.
   - The `.md` written above is unchanged — both files coexist.
5. **Suggest a commit.** For public learnings, commit alongside the
   work that produced the learning where possible. For private
   learnings, remind the human that `private/` is gitignored — no
   commit needed, but they can share the file manually if wanted.

## Refresh flow (`--refresh`)

Learnings decay. Technology shifts, the team changes approach, or two
entries end up contradicting each other. The refresh mode is a
human-gated housekeeping pass.

1. **List active learnings older than 180 days.** Use `find
   .spades-anywhere/learnings -name '*.md' -not -path '*/private/*'` (plus private
   if the human asks) and cross-reference `created:` dates against
   today. Entries older than 180 days with `status: active` are
   candidates.
2. **For each candidate**, present the title, age, and body, then ask:
   - *Keep active* — it still holds; no change.
   - *Archive* — flip `status: active` to `status: archived`. Archived
     entries stay on disk for audit but are skipped by `/spades-anywhere:plan`.
   - *Delete* — remove the file entirely. Only for learnings that
     were factually wrong. Suggest archive instead when uncertain.
3. **Flag contradictions.** Before prompting per-candidate, scan for
   pairs of active learnings whose tag sets show **Jaccard similarity
   ≥ 0.5** and whose titles appear to contradict (e.g. "prefer X over
   Y" and "prefer Y over X"). Jaccard similarity is
   `|A ∩ B| / |A ∪ B|` — the size of the tag intersection divided by
   the size of the tag union, both treated as sets (case-insensitive,
   de-duplicated). This is a symmetric metric: it does not depend on
   which learning is picked as "A". Surface qualifying pairs for the
   human to resolve before doing anything else.
4. **Never silently modify.** Every archive, delete, or contradiction
   resolution requires explicit human approval, just like the Approve
   gate in the full SPADES loop. The refresh mode is a tool for the
   human, not an autonomous agent pass.

## Quality checks for a good learning

Before writing, verify:

- [ ] Title is one line and reads well out of context.
- [ ] `area` is set to the most applicable bucket.
- [ ] `tags` include the *technology*, *pattern*, and *problem class* —
      future agents will grep on these.
- [ ] The body's "What we learned" is specific, not a platitude.
- [ ] The body's "Why it matters for future work" has a concrete
      implication — what would someone do differently next time?
- [ ] If private: the file is written under `.spades-anywhere/learnings/private/`,
      not the public directory.

## Why this matters

The biggest failure mode of AI-assisted delivery is that each task is
treated as isolated. The same mistakes get made repeatedly because the
knowledge from Evaluate doesn't reach the next Plan. Capturing a
learning is a 60-second act that can save hours of rework in three
months' time. The refresh mode keeps the store from rotting.

See `docs/FRAMEWORK.md#learnings` for the full rationale and how
`/spades-anywhere:plan` consumes learnings.
