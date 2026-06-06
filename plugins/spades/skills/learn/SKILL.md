---
name: learn
description: Capture a learning from completed work and store it under .spades/learnings/ so future Plans can reference it. Use when someone says "capture a learning", "record what we learned", "log this learning", "we should remember this", or after an Evaluate phase reveals something worth carrying forward. Also use with `--refresh` to archive stale or contradictory learnings.
version: 3.2.0
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
       `{{spades.public_safe}}`.
     - The frontmatter YAML block also goes verbatim into the
       `<script type="application/yaml" id="spades-frontmatter">` tag.
     - `<!-- SPADES-BLOCK:tags-items -->` — repeated once per tag.
       Per-item: `{{block.tag}}`.
     - `<!-- SPADES-BLOCK:related-items -->` — repeated once per
       related-link bullet. Per-item: `{{block.text}}`,
       `{{block.href|}}`.
     - `<!-- SPADES-BLOCK:audit-events -->` — repeated once per
       audit entry in both the visible timeline and the
       `<script type="application/yaml" id="spades-audit-trail">`
       YAML block. Per-item: `{{block.date}}`, `{{block.desc}}`.
     - The prose body sections (`What we learned`, `Why it matters
       for future work`, etc.) are direct
       `{{spades.<section>_html}}` substitutions, not repeating
       blocks.
   - If `public_safe: true` → write `.spades/learnings/YYYY-MM-DD-<slug>.html`.
   - If `public_safe: false` → write `.spades/learnings/private/YYYY-MM-DD-<slug>.html`.
   - Auto-open via OPEN_CMD
     (`docs/FRAMEWORK.md § OPEN_CMD detection prelude`). Print the
     file path with "open this in your browser" if `OPEN_CMD` is
     empty.
   - The `.md` written above is unchanged — both files coexist.
5. **Ship the learning metadata.** Public learnings get an
   auto-managed bookkeeping PR (mirroring `/spades:close`'s flow)
   so they don't leave the worktree dirty. Private learnings live
   under the gitignored `.spades/learnings/private/` directory and
   skip this step entirely.

   - `public_safe: false` → write the file under
     `.spades/learnings/private/` per Step 4 and exit with the
     reminder: *"`private/` is gitignored — nothing to commit. Share
     the file manually if you want a teammate to see it."*
   - `public_safe: true` → proceed with the **ship flow** below.

   ### 5.1 Preconditions (public only)

   **Critical: run this check BEFORE Step 4 writes the file.**
   Writing the file first and then discovering you can't ship it
   leaves the worktree dirty, which is exactly the failure this
   step is here to prevent. Re-order if necessary: classify in
   Step 3, check preconditions here, then return to Step 4 to write.

   1. `git rev-parse --abbrev-ref HEAD` — must be `main` (or the
      detected default branch). If not, abort **before** writing:

      > *Refusing to run — you're on `<branch>`. `/spades:learn`
      > ships its metadata via its own PR off `main`, like
      > `/spades:close`. Switch to `main` first
      > (`git switch main`) then re-run `/spades:learn`.*

   2. `git status --porcelain` — must be empty. If not, abort
      **before** writing:

      > *Refusing to run — uncommitted changes on `<branch>`:*
      > *`<list>`. Commit, stash, or discard them first, then
      > re-run `/spades:learn`.*

   3. When `.spades/config` has `scm: github`: confirm `gh
      auth status` succeeds and `git remote` returns at least one
      remote. If not, surface the failure and abort.

   ### 5.2 Choose the branch name

   Pattern: `chore/learn-<YYYY-MM-DD>-<slug>` where `<slug>` is
   the same one used in the file name. The full branch name MUST
   match the `/repo:branch` regex:

   ```
   ^(feat|fix|chore|docs|refactor|rnd|hotfix)/[a-z0-9]([a-z0-9-]{0,48}[a-z0-9])?$
   ```

   Slug cap: with `learn-` (6) + date (10) + `-` (1) = 17 chars of
   fixed prefix in the slug portion, leaving 33 chars for the
   learning slug. Truncate at the last hyphen ≤ 33 chars if longer.

   If a local branch with that name already exists (a previous
   `/spades:learn` run aborted mid-flight), abort with:

   > *Bookkeeping branch `<name>` already exists from a previous
   > run. Either merge its PR on GitHub then re-run `/spades:learn`,
   > or delete it (`git branch -D <name>`) and re-run.*

   ### 5.3 Create the branch

   ```bash
   git switch -c <bookkeeping-branch>
   ```

   ### 5.4 Write the file (Step 4 happens here)

   You're now on the bookkeeping branch off clean `main`. Execute
   Step 4 (write the `.md` for CLI mode, or `.html` for HTML mode)
   exactly as written. The file write is the same in both modes —
   only the branch context changed.

   ### 5.5 Stage + commit

   ```bash
   git add .spades/learnings/<file>
   git commit -m "$(cat <<'EOF'
   chore(spades): record learning — <title>

   Captures the learning at .spades/learnings/<file> for future
   /spades:plan runs to surface. No code changes — pure audit
   trail. Area: <area>. Tags: <tag1>, <tag2>, ….

   See .spades/learnings/<file> for the full content.
   EOF
   )"
   ```

   ### 5.6 Push + open the bookkeeping PR

   Branch by `scm:` from `.spades/config`:

   - **`scm: github`** —

     ```bash
     git push -u origin <bookkeeping-branch>
     gh pr create --title "chore(spades): record learning — <title>" --body "$(cat <<'EOF'
     ## Summary

     Bookkeeping commit — records a SPADES learning so future
     `/spades:plan` runs can surface it.

     ## Linked artefacts

     - Learning: `.spades/learnings/<file>`
     - Area:     `<area>`
     - Tags:     `<tag1>, <tag2>, ...`
     - Scope:    `<scope_ref>`     # omit if not set
     - Plan:     `<plan_ref>`      # omit if not set

     ## Files touched

     - `.spades/learnings/<file>` — new learning record.

     No code changes. Pure audit trail.
     EOF
     )"
     ```

     Capture the PR URL. Print it prominently:

     ```
     ○ Learning PR opened: <pr-url>
     ○ Merge it on GitHub — squash recommended — then return here.
     ```

   - **`scm: local-git`** — push to the configured remote if any,
     otherwise commit-only. Skip the PR + skip Step 5.7's wait:

     ```bash
     git push -u origin <bookkeeping-branch>   # only if a remote is configured
     ```

     Print: *"pushed `<branch>` to `origin`; learning recorded
     without a PR (scm: local-git)."* Then jump straight to
     Step 5.8 cleanup. If no remote is configured, print *"learning
     committed locally on `<branch>`; no remote configured so
     nothing was pushed."* and exit without the cleanup (the human
     owns merge to main themselves).

   ### 5.7 Wait for the human to confirm the merge (scm: github only)

   Ask via `AskUserQuestion`:

   > *Has the learning PR been merged?*
   >
   > - **Yes — learning PR is merged.** Continue with cleanup.
   > - **Not yet — exit, I'll merge it and clean up myself.**

   If **Not yet** → exit cleanly. The learning PR stays open. After
   the human merges it on GitHub, the recovery path is to run
   `/repo:sync` (cleans up the merged branch); no need to re-run
   `/spades:learn`.

   ### 5.8 Post-merge cleanup

   After the human confirms the PR is merged:

   ```bash
   git checkout main
   git pull --ff-only
   git branch -D <bookkeeping-branch>
   git status --porcelain
   ```

   If `git status --porcelain` surfaces anything, print it but
   don't abort — the learning has been recorded; the human can
   tidy any residue.

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
