---
name: learn
description: Capture a learning from completed work and store it under .spades/learnings/ so future Plans can reference it. Use when someone says "capture a learning", "record what we learned", "log this learning", "we should remember this", or after an Evaluate phase reveals something worth carrying forward. Also use with `--refresh` to archive stale or contradictory learnings.
version: 4.5.0
---

# /spades:learn

Each pass of the loop should strengthen the next. This skill
captures what a pass taught as a structured entry under
`.spades/learnings/`, where `/spades:plan` surfaces it the next time
a related Scope comes through.

Learnings are local for both backends; this skill makes no backend
calls.

Read `docs/FRAMEWORK.md` § .spades/ Local Layout (the learning
schema), § Asking the Human, and § Output Format before running.

### Output format

- **Both modes** — `.spades/learnings/YYYY-MM-DD-<slug>.md` (or
  `private/` beneath it), the canonical record.
- **HTML mode** — additionally the `.html` companion at the same
  path, rendered from `${CLAUDE_PLUGIN_ROOT}/skills/learn/template.html`
  by `worker-html-learning` and auto-opened as the review surface;
  iteration is a targeted `.md` edit plus a re-render.
- **CLI mode** — the draft is pasted to the terminal for correction
  before the write.

## Pre-Flight

Read `.spades/config` for `project:` (the default `scope_ref`
resolver) and `review_format:`. A missing config still runs the
skill; mention `/spades:setup` for the rest of the loop.

## Two modes

| Mode | When |
|---|---|
| capture (default) | After Evaluate, or any time during delivery, when something is worth remembering for future work. |
| `--refresh` | Periodic housekeeping (quarterly at most): archive stale entries, resolve contradictions. |

One learning per run. Three lessons are three runs.

## Storage

```
.spades/learnings/YYYY-MM-DD-<short-slug>.md          # public-safe
.spades/learnings/private/YYYY-MM-DD-<short-slug>.md  # gitignored
```

```yaml
---
title: One-line summary of what was learned
area: scope | plan | approve | do | evaluate | ship | other
tags: [tag1, tag2, tag3]
created: YYYY-MM-DD
status: active
public_safe: true
scope_ref: S-add-ai-helper-bot          # optional
plan_ref: P-rag-pipeline-lookup-3HyD    # optional
---
```

```markdown
## What we learned

One paragraph. Specific: "X has property Y that bit us because Z",
not "be more careful with X".

## Why it matters for future work

How this changes the next Plan; what future Scopes should account
for. Link code, docs, or prior issues where helpful.
```

## Capture flow

1. **Read the context.** A Scope or Plan ID in the request becomes
   `scope_ref` / `plan_ref`; a file path or area pre-fills `area`.
2. **Draft the whole learning** from the conversation so far — one
   draft beats eight questions. CLI mode: paste it for correction.
   HTML mode: continue to Step 4, which writes it and opens the page.
3. **Classify** via `AskUserQuestion`:
   - **Public-safe — commit to `.spades/learnings/`** — fine in a
     public fork.
   - **Private — `.spades/learnings/private/`** — names internal
     systems, customers, credential paths, security detail. In
     doubt, private; downgrading later is cheap.
   - **Skip — don't capture.**
4. **Write.** Choose a slug that reads well
   (`onboarding-must-be-idempotent`). Write the `.md` at the public
   or private path. In HTML mode dispatch `worker-html-learning` in
   the same wave per `docs/FRAMEWORK.md § worker-html-*`:
   - `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/learn/template.html`
   - `output_path`: the `.md` path with `.html`
   - `frontmatter`: `{ id, title, area, status, created,
     public_safe, project }`, embedded verbatim in
     `<script id="spades-frontmatter">`; `project` optional
   - `blocks`:
     - `objective-banner` — the project's sole `open` Objective
       `{ id, title }` when exactly one exists, else `[]`
     - `tags-items` — one per tag. Field: `tag`.
     - `related-items` — one per related link. Fields: `text, href`.
     - `audit-events` — one per audit entry. Fields: `date, desc`.
   - `prose_sections`: `{ what_we_learned_html, why_it_matters_html }`

   Required markers: `objective-banner`, `tags-items`,
   `related-items`, `audit-events`.
5. **Brief.**

   HTML mode:

   ```
   ✓ Learning captured: YYYY-MM-DD-<slug>.md
   ○ .spades/learnings/YYYY-MM-DD-<slug>.html opened in browser
   Next: /spades:status — see what else is in flight
   ```

   CLI mode: the write confirmation, the learning body once, the
   same `Next:` line. A private learning's brief names the private
   path.

## After capture — the Lead it implies

A learning is a diagnosis; often it implies a prescription — a
specific change to this project — and that belongs on the Leads
board. Invoke **`/spades:leads --from learn --learning <path>`**.
The scout returns nothing when the learning's action is "remember
this when planning", which is the correct outcome; budget one. A
Lead born this way carries `learning_ref:` and sorts to the top of
the board as evidence-backed. A Leads failure is a warning; the
learning is already written. Skipped when `leads: off`.

## Refresh flow (`--refresh`)

Learnings decay: technology shifts, the team changes approach, two
entries contradict. Refresh is a human-gated housekeeping pass.

1. **Flag contradictions first.** Scan pairs of active learnings
   whose tag sets have Jaccard similarity ≥ 0.5 (`|A ∩ B| / |A ∪ B|`
   over case-insensitive, de-duplicated tags) and whose titles
   appear to contradict ("prefer X over Y" and "prefer Y over X").
   Surface qualifying pairs for the human to resolve.
2. **List active learnings older than 180 days** (`find
   .spades/learnings -name '*.md' -not -path '*/private/*'`, plus
   private on request), cross-referencing `created:`.
3. **Per candidate** show title, age, and body, then ask: **Keep
   active** / **Archive** (`status: archived`; stays on disk,
   skipped by `/spades:plan`) / **Delete** (factually wrong entries
   only; archive when uncertain).

Every archive, delete, and contradiction resolution is the human's
explicit choice.

## Quality check

- [ ] The title reads well out of context.
- [ ] `area` is the most applicable bucket.
- [ ] `tags` name the technology, the pattern, and the problem class
      — future Plans match on them.
- [ ] "What we learned" is specific.
- [ ] "Why it matters" says what someone does differently next time.
- [ ] A private learning is under `private/`.
