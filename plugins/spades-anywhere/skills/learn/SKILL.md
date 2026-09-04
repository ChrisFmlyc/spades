---
name: learn
description: Capture a learning from completed work and store it under .spades-anywhere/learnings/ so future Plans can reference it. Use when someone says "capture a learning", "record what we learned", "log this learning", "we should remember this", or after an Evaluate phase reveals something worth carrying forward. Also use with `--refresh` to archive stale or contradictory learnings.
version: 0.3.0
---

# /spades-anywhere:learn

Each pass of the loop should strengthen the next. This skill
captures what a pass taught as a structured entry under
`.spades-anywhere/learnings/`, where `/spades-anywhere:plan`
surfaces it the next time a related Scope comes through.

Learnings are local for both backends; this skill makes no backend
calls.

Read `docs/FRAMEWORK.md` § .spades-anywhere/ Local Layout (the
learning schema), § Asking the Human, and § Output Format before
running.

### Output format

- **Both modes** — `.spades-anywhere/learnings/YYYY-MM-DD-<slug>.md`
  (or `private/` beneath it), the canonical record.
- **HTML mode** — additionally the `.html` companion at the same
  path from `${CLAUDE_PLUGIN_ROOT}/skills/learn/template.html`,
  auto-opened as the review surface; iteration is a targeted `.md`
  edit plus a re-render.
- **CLI mode** — the draft is pasted for correction before the
  write.

## Pre-Flight

Read `.spades-anywhere/config` for `project:` and `review_format:`.
A missing config still runs the skill; mention
`/spades-anywhere:setup` for the rest of the loop.

## Two modes

| Mode | When |
|---|---|
| capture (default) | After Evaluate, or any time during delivery, when something is worth remembering. |
| `--refresh` | Periodic housekeeping (quarterly at most): archive stale entries, resolve contradictions. |

One learning per run.

## Storage

```
.spades-anywhere/learnings/YYYY-MM-DD-<short-slug>.md          # public-safe
.spades-anywhere/learnings/private/YYYY-MM-DD-<short-slug>.md  # private
```

```yaml
---
title: One-line summary of what was learned
area: scope | plan | approve | do | evaluate | ship | other
tags: [tag1, tag2, tag3]
created: YYYY-MM-DD
status: active
public_safe: true
scope_ref: S-plan-birthday-party        # optional
plan_ref: P-book-the-venue-3HyD         # optional
---
```

```markdown
## What we learned

One paragraph. Specific: "the venue needs the final headcount ten
days out, and we gave it five", not "book earlier".

## Why it matters for future work

How this changes the next Plan; what future Scopes should account
for.
```

## Capture flow

1. **Read the context.** A Scope or Plan ID becomes `scope_ref` /
   `plan_ref`; a named area pre-fills `area`.
2. **Draft the whole learning** from the conversation so far. CLI
   mode: paste it for correction. HTML mode: continue to Step 4.
3. **Classify** via `AskUserQuestion`: **Public-safe** / **Private**
   (names people, finances, addresses, health, or anything else
   that should stay out of a shared store; in doubt, private) /
   **Skip**.
4. **Write.** Choose a slug that reads well. Write the `.md` at the
   public or private path. In HTML mode render the `.html` from the
   template per `docs/FRAMEWORK.md § Output Format → HTML rendering`:
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
   ○ .spades-anywhere/learnings/YYYY-MM-DD-<slug>.html opened in browser
   Next: /spades-anywhere:status — see what else is in flight
   ```

   CLI mode: the write confirmation, the learning body once, the
   same `Next:` line. Remind the human to save the file to their
   knowledge store; a private learning's brief names the private
   path.

## Refresh flow (`--refresh`)

1. **Flag contradictions first.** Scan pairs of active learnings
   whose tag sets have Jaccard similarity ≥ 0.5 (`|A ∩ B| / |A ∪ B|`
   over case-insensitive, de-duplicated tags) and whose titles
   appear to contradict. Surface qualifying pairs for the human.
2. **List active learnings older than 180 days** (private on
   request).
3. **Per candidate** show title, age, and body, then ask: **Keep
   active** / **Archive** (`status: archived`; skipped by
   `/spades-anywhere:plan`) / **Delete** (factually wrong entries
   only; archive when uncertain).

Every archive, delete, and contradiction resolution is the human's
explicit choice.

## Quality check

- [ ] The title reads well out of context.
- [ ] `area` is the most applicable bucket.
- [ ] `tags` name the domain, the pattern, and the problem class.
- [ ] "What we learned" is specific.
- [ ] "Why it matters" says what someone does differently next time.
- [ ] A private learning is under `private/`.
