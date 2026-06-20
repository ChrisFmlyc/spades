---
name: learn
description: Capture a learning from completed work and store it under .spades/learnings/ so future Plans can reference it. Use when someone says "capture a learning", "record what we learned", "log this learning", "we should remember this", or after an Evaluate phase reveals something worth carrying forward. Also use with `--refresh` to archive stale or contradictory learnings.
version: 4.2.0
---

# SPADES Learn

## Pre-Flight

Read `.spades/config` to confirm the active project (used as the
default `scope_ref` resolver below). If `.spades/config` is missing,
`/spades:learn` still runs — learnings are local-only — but suggest
`/spades:setup` if the human intends to use SPADES properly.

Learnings live under `.spades/learnings/` regardless of backend. This
skill makes **no backend MCP calls**.

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML) → Universal
rule`. In **both** modes, write the learning as
`.spades/learnings/YYYY-MM-DD-<slug>.md` — this is the
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
Markdown entry under `.spades/learnings/` so `/spades:plan` can surface it
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
.spades/learnings/YYYY-MM-DD-<short-slug>.md          # public-safe
.spades/learnings/private/YYYY-MM-DD-<short-slug>.md  # NOT committed
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
   - *Public-safe — commit to .spades/learnings/*
   - *Private — write to .spades/learnings/private/ (gitignored)*
   - *Skip — don't capture*
   Public-safe learnings are OK to land in a public fork of this repo.
   Private learnings name internal systems, customers, credentials
   paths, security details, or anything else that should not leak. When
   in doubt, route to `private/` — downgrading later is cheap.
4. **Confirm and write.** After the human approves the draft (in CLI
   mode) or after Step 3 classification completes (in HTML mode —
   there is no pre-write CLI draft to approve), **read `review_format:`
   from `.spades/config` and branch.** Step 4 MUST write a file before
   exiting — never finish with the draft pasted to the CLI only, **and
   in HTML mode never paste the learning body to the CLI for human
   approval before this step writes the file**. The file IS the review
   surface in HTML mode (see § Output format above).

   Choose a short, hyphenated slug that reads well (e.g.
   `onboarding-must-be-idempotent`, not `learn-1`). The slug is the
   same across both formats; only the extension and rendering differ.

   ##### Write the canonical `.md` (both modes)

   - If `public_safe: true` → write `.spades/learnings/YYYY-MM-DD-<slug>.md`.
   - If `public_safe: false` → write `.spades/learnings/private/YYYY-MM-DD-<slug>.md`.

   ##### Dispatch `worker-html-learning` in parallel (HTML mode only)

   When `review_format: html`, dispatch the `.html` render via
   `worker-html-learning` per
   `docs/FRAMEWORK.md § worker-html-* — parallel HTML rendering`
   in the same wave as the `.md` write (so the main agent never
   blocks on template I/O). No inline render.

   Worker inputs:

   - `template_path`:
     `${CLAUDE_PLUGIN_ROOT}/skills/learn/template.html`
   - `output_path`:
     `.spades/learnings/YYYY-MM-DD-<slug>.html` (public) or
     `.spades/learnings/private/YYYY-MM-DD-<slug>.html` (private)
   - `frontmatter`: `{ id, title, area, status, created,
     public_safe, project }` — `project` is optional (the active
     project slug, for the rail). Also embedded verbatim as the
     YAML in the `<script id="spades-frontmatter">` tag.
   - `blocks`:
     - `objective-banner` — 0 or 1 item per
       `docs/FRAMEWORK.md § Objective banner`. Pass the project's
       sole `open` Objective `{ id, title }` when EXACTLY ONE
       exists in `.spades/objectives/`, else `[]`.
     - `tags-items` — one per tag. Field: `tag`.
     - `related-items` — one per related-link bullet. Fields:
       `text, href`.
     - `audit-events` — one per audit entry. Fields:
       `date, desc`.
   - `prose_sections`: `{ what_we_learned_html, why_it_matters_html, ... }`

   Required template markers:
   `<!-- SPADES-BLOCK:objective-banner -->`,
   `<!-- SPADES-BLOCK:tags-items -->`,
   `<!-- SPADES-BLOCK:related-items -->`,
   `<!-- SPADES-BLOCK:audit-events -->`.
5. **End-of-skill brief.** Branch on `review_format:`:

   **HTML mode** — 3 lines, no body dump:

   ```
   ✓ Learning captured: YYYY-MM-DD-<slug>.md
   ○ .spades/learnings/YYYY-MM-DD-<slug>.html opened in browser
   Next: /spades:status — see what else is in flight
   ```

   **CLI mode** — confirm the write, then print the assembled
   learning body once as the review surface:

   ```
   ✓ Learning captured: YYYY-MM-DD-<slug>.md

   <contents of the learning .md>

   Next: /spades:status — see what else is in flight
   ```

   Private learnings (`public_safe: false`) live under the
   gitignored `.spades/learnings/private/` directory; the brief
   notes the private path in place of the public one.

## Refresh flow (`--refresh`)

Learnings decay. Technology shifts, the team changes approach, or two
entries end up contradicting each other. The refresh mode is a
human-gated housekeeping pass.

1. **List active learnings older than 180 days.** Use `find
   .spades/learnings -name '*.md' -not -path '*/private/*'` (plus private
   if the human asks) and cross-reference `created:` dates against
   today. Entries older than 180 days with `status: active` are
   candidates.
2. **For each candidate**, present the title, age, and body, then ask:
   - *Keep active* — it still holds; no change.
   - *Archive* — flip `status: active` to `status: archived`. Archived
     entries stay on disk for audit but are skipped by `/spades:plan`.
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
- [ ] If private: the file is written under `.spades/learnings/private/`,
      not the public directory.

## Why this matters

The biggest failure mode of AI-assisted delivery is that each task is
treated as isolated. The same mistakes get made repeatedly because the
knowledge from Evaluate doesn't reach the next Plan. Capturing a
learning is a 60-second act that can save hours of rework in three
months' time. The refresh mode keeps the store from rotting.

See `docs/FRAMEWORK.md#learnings` for the full rationale and how
`/spades:plan` consumes learnings.
