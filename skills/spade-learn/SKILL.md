---
name: spade-learn
description: Capture a learning from completed work and store it under .spade/learnings/ so future Plans can reference it. Use when someone says "capture a learning", "record what we learned", "log this learning", "we should remember this", or after an Evaluate phase reveals something worth carrying forward. Also use with `--refresh` to archive stale or contradictory learnings.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using the
Bash tool and show the output to the user if it is non-empty. If the script
does not exist or fails, skip silently and continue with the skill.

## Project Config

Read `.spade/config` in the current project directory. If the file doesn't
exist, `/spade-learn` can still run — learnings are local-only by default —
but suggest running `/spade-onboard` if the human intends to track learnings
alongside Linear work.

## Mode Resolution

Before any tracker call or local-file access, resolve the operating mode
**once** per `docs/FRAMEWORK.md` § Mode Resolver:

- Read `mode:` from `.spade/config`. An explicit value (`linear`,
  `local`, or `hybrid`) wins immediately.
- If `mode:` is absent, auto-detect: probe with a `list_teams` MCP call
  (try/skip, 5-second timeout). Resolve `linear` if it returns a team
  set containing `linear.team_id`; otherwise resolve `local`.
- Failure policy: an explicit `mode` with a configured `team_id` and a
  failing probe is a **fail-loud abort**; an absent `mode` with a
  failing probe **degrades quietly to `local`**.

Do not embed the resolver algorithm — it is single-sourced in
FRAMEWORK.md. The resolved mode governs every tracker-vs-local branch in
this skill:

- **`linear`** — the tracker is canonical; operate against Linear MCP.
- **`local`** — `.spade/` files are canonical; make **zero Linear MCP
  calls**; read and write the paths in FRAMEWORK.md § Local Layout.
- **`hybrid`** — the tracker is canonical; after a successful tracker
  write, mirror to `.spade/` best-effort per FRAMEWORK.md § Hybrid Mode.

In practice `/spade-learn` captures learnings to `.spade/learnings/`
regardless of the resolved mode and makes **no Linear MCP calls in any
mode**. The resolver is wired here for consistency with the other eight
skills, so that a future tracker-backed learnings index would already
be gated.

# SPADE Learn

Each pass of the SPADE loop should produce knowledge that strengthens the
next pass. Without a place to capture it, that knowledge vanishes into PR
descriptions and Evaluate comments. This skill captures it as a structured
Markdown entry under `.spade/learnings/` so `/spade-plan` can surface it
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
.spade/learnings/YYYY-MM-DD-<short-slug>.md          # public-safe
.spade/learnings/private/YYYY-MM-DD-<short-slug>.md  # NOT committed
```

With this frontmatter (flat YAML, one key per line — no nested structures):

```yaml
---
title: One-line summary of what was learned
area: onboarding | planning | delivery | review | other
tags: comma, separated, keywords
created: YYYY-MM-DD
status: active
public_safe: true
scope_ref: LIN-123     # optional; include if the learning came out of a specific Scope
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

1. **Read the context.** If the current Linear issue is provided in the
   user's message or conversation (e.g. "capture a learning from M-324"),
   capture it as `scope_ref`. `.spade/config` holds project-level
   metadata (Linear team, project, default assignee) and does **not**
   carry a per-issue identifier, so don't look there for `scope_ref`. If
   the user referenced a specific file path or area of the codebase, use
   that to pre-fill the `area` field.
2. **Propose a draft.** Don't ask eight questions in a row — draft a
   complete learning based on the conversation so far and present it for
   the human to correct. Use the frontmatter + body format above.
3. **Classify public-safe.** Ask via **`AskUserQuestion`** (per
   `docs/FRAMEWORK.md` § "Asking the Human") with three options:
   - *Public-safe — commit to .spade/learnings/*
   - *Private — write to .spade/learnings/private/ (gitignored)*
   - *Skip — don't capture*
   Public-safe learnings are OK to land in a public fork of this repo.
   Private learnings name internal systems, customers, credentials
   paths, security details, or anything else that should not leak. When
   in doubt, route to `private/` — downgrading later is cheap.
4. **Confirm and write.** After the human approves the draft:
   - If `public_safe: true` → write to `.spade/learnings/YYYY-MM-DD-<slug>.md`.
   - If `public_safe: false` → write to `.spade/learnings/private/YYYY-MM-DD-<slug>.md`.
   - Choose a short, hyphenated slug that reads well (e.g.
     `onboarding-must-be-idempotent`, not `learn-1`).
5. **Suggest a commit.** For public learnings, commit alongside the
   work that produced the learning where possible. For private
   learnings, remind the human that `private/` is gitignored — no
   commit needed, but they can share the file manually if wanted.

## Refresh flow (`--refresh`)

Learnings decay. Technology shifts, the team changes approach, or two
entries end up contradicting each other. The refresh mode is a
human-gated housekeeping pass.

1. **List active learnings older than 180 days.** Use `find
   .spade/learnings -name '*.md' -not -path '*/private/*'` (plus private
   if the human asks) and cross-reference `created:` dates against
   today. Entries older than 180 days with `status: active` are
   candidates.
2. **For each candidate**, present the title, age, and body, then ask:
   - *Keep active* — it still holds; no change.
   - *Archive* — flip `status: active` to `status: archived`. Archived
     entries stay on disk for audit but are skipped by `/spade-plan`.
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
   gate in the full SPADE loop. The refresh mode is a tool for the
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
- [ ] If private: the file is written under `.spade/learnings/private/`,
      not the public directory.

## Why this matters

The biggest failure mode of AI-assisted delivery is that each task is
treated as isolated. The same mistakes get made repeatedly because the
knowledge from Evaluate doesn't reach the next Plan. Capturing a
learning is a 60-second act that can save hours of rework in three
months' time. The refresh mode keeps the store from rotting.

See `docs/FRAMEWORK.md#learnings` for the full rationale and how
`/spade-plan` consumes learnings.
