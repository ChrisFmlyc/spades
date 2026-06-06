---
name: quick
description: Fast-track path for trivial human work in spades-anywhere — tiny errands, one-off actions, quick artefact tweaks, single-message communications that don't warrant a Scope. Use when someone says "just do this small thing", "quick errand", "one-off task", "tiny tweak to the doc", or when you would otherwise invoke /spades-anywhere:scope for a change that clearly meets every gate criterion below. Do NOT use for anything touching project intent, multi-step coordination, financial commitment over a threshold, or work that needs evaluation against acceptance criteria.
version: 0.1.0
---

## Pre-Flight

Read `.spades-anywhere/config` for the active backend and project. If
missing, abort and suggest `/spades-anywhere:setup`.

# SPADES-Anywhere Quick — Fast-Track Path for Small Human Work

You are delivering a trivial unit of human work through the
spades-anywhere fast-track path. The full loop (Scope → Plan →
Approve → Do → Evaluate → Ship → Close) is friction theatre for
sending one email, booking one slot, or fixing one typo in a doc.
`/spades-anywhere:quick` compresses it into four steps —
**Identify → Act → Verify → Record** — where the quick-item
marker file is the audit artefact and there is no separate Scope
or Plan.

This path mirrors the sister `spades` plugin's `/spades:quick`
in process; the gate criteria differ because human work isn't
measured in lines of code.

This path is a privilege, not a default. If *any* gate criterion below
fails, stop and run `/spades-anywhere:scope` for the full loop instead.
The gate exists so fast-track does not slowly swallow the framework.

## Conversational Style

Fast-track should feel fast but not reckless.

1. **Confirm the gate explicitly.** Do not silently decide the work is
   trivial. Walk the gate criteria with the human, even briefly. If one
   criterion is ambiguous, flag it and ask — don't assume.
2. **Be willing to bail.** If anything feels bigger than it first looked
   (the "one email" turns into a chain, the "tiny doc tweak" reveals a
   structural problem), stop and recommend falling back to
   `/spades-anywhere:scope`. The cost of restarting is low; the cost of
   a fast-track action that should have had a Scope is a broken audit
   trail.
3. **Keep the human in the loop on classification.** Ask which `type:*`
   label applies if it's not obvious.
4. **Do not monologue.** One sentence per step update is enough.

## The Gate — ALL must be true

Walk through each of these before acting. If any one fails, stop and
invoke `/spades-anywhere:scope` instead.

1. **Single concrete action.** One errand, one email, one tweak. Not
   "send the email and also follow up with three people."
2. **≤ 30 minutes of human time.** Soft cap. Hard stop above ~60 min.
   If you're not sure, bail.
3. **One artefact or one recipient.** Not spread across multiple
   documents, multiple people, or multiple systems.
4. **No new external commitment.** No new contracts, no new vendor
   relationships, no new financial obligations over the project's
   stated threshold (see `INTENT.md` § Non-Goals or Constraints).
5. **No project-intent shift.** The action does not change what the
   project is *for*. (If it does, you need a Scope.)
6. **No coordination across multiple people.** A single message to a
   single person is fine; chairing a four-way thread is not.
7. **No irreversible commitment.** A "test booking" you can cancel is
   fine; a non-refundable payment is not.
8. **No new dependency on external state.** No "waiting for X to
   reply" or "depends on the supplier confirming". Quick items are
   self-contained.
9. **Revertible.** If the action turns out wrong, undoing it is cheap
   (re-send a correction email, edit the doc back).
10. **No verification against project success criteria.** Quick items
    do not run through `INTENT.md` confirmation — they are too small
    to move project-level criteria. If the work *would* move an INTENT
    criterion, it deserves a Scope.

### Gate failure

If any criterion fails, stop immediately and tell the human:

> This doesn't fit the fast-track gate because [specific criterion].
> Running `/spades-anywhere:scope` for the full loop is the right
> call here.

Do not attempt to "partially" fast-track by skipping just one rule.
The gate is all-or-nothing.

## Classification

Every quick-path item gets a `type:*` label. Pick the closest match:

- **`type:bug`** — fixing something that's wrong (a typo, an incorrect
  detail, an oversight)
- **`type:tweak`** — small adjustment that isn't strictly a fix
- **`type:chore`** — administrative or maintenance task (filing,
  archiving, scheduling)
- **`type:docs`** — adding or amending a written record (note,
  document, comment, summary)
- **`type:errand`** — one-off real-world action (book, buy, send,
  confirm)

If the work is ambiguous between two types, ask the human via
`AskUserQuestion` listing the candidate types as options.

## Workflow

### 1. Identify

- Hear what the human wants done.
- Walk the gate criteria out loud. Confirm each one. If any fail, bail.
- Classify with a `type:*` label.
- If there's a Linear issue, note its ID. If not, decide whether to
  create one (for traceability) or skip Linear entirely (for the most
  trivial things, the marker file alone is enough).

### 2. Act

The human does the thing. `/spades-anywhere:quick` is **not** an
autonomous action skill — like every other anywhere skill, the AI
stands down and the human acts. The AI's job here is to:

- Restate what the human is about to do (one line) so they're clear.
- Capture the evidence reference they'll bring back ("photo of
  receipt", "forwarded email", "screenshot of the booking").

If the action turns out to be bigger than the gate allowed,
**stop immediately** — bail to `/spades-anywhere:scope`.

### 3. Verify

- Confirm the action completed.
- Capture evidence: a URL, a file path, a one-line attestation, a
  forwarded message ID. Light is fine; the standard is "future-me
  can tell what happened from this evidence alone".

### 4. Record

Write the quick-item marker file. The marker file is the audit
artefact.

## Backend Integration

Quick-path work creates a **quick-item marker file** under the active
project. The file is the local-canonical record — it's what
`/spades-anywhere:evaluate`, `/spades-anywhere:list`, and
`/spades-anywhere:status` find when they look for quick-path work.
The marker exists for **both backends**; when `backend: linear`, the
Linear issue carries the labels and status as a mirror, but the
local file is authoritative.

### The marker file

Path: `.spades-anywhere/quick/Q-<slug>-<4-char-suffix>.md`

- `<slug>` is derived from the action description. Same slug rules
  as Scope IDs (lowercase, `[a-z0-9-]`, ≤ 50 chars).
- `<4-char-suffix>` is a base62 random suffix.

Frontmatter:

```yaml
---
id: Q-book-venue-deposit-7Mqz
id_suffix: 7Mqz
project: <project-slug>
title: "<one-line title>"
type: bug | tweak | chore | docs | errand
status: shipped                # quick items reach shipped on completion
evidence_ref: <url-or-path-or-attestation>
linear_issue_id: <id>          # only when backend: linear
delivery: human                # always human in spades-anywhere
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

Body:

```markdown
# <title>

## What
<one sentence>

## Why
<one sentence or linked context>

## Action taken
<one short paragraph — what the human did>

## Evidence
- <evidence ref 1>
- <evidence ref 2 — optional>

## Gate Check (retrospective)
- [x] Single concrete action
- [x] ≤ 30 min of human time
- [x] One artefact or one recipient
- [x] No new external commitment
- [x] No project-intent shift
- [x] No coordination across multiple people
- [x] No irreversible commitment
- [x] No new dependency on external state
- [x] Revertible
- [x] No verification against project success criteria

## Audit Trail
- YYYY-MM-DD: Quick-path opened. Type: <type>.
- YYYY-MM-DD: Quick-path completed. Evidence: <ref>.
```

### When `backend: linear`

In addition to writing the marker file:

1. Apply labels on the Linear issue:
   - `spades:quick`
   - One of `type:bug`, `type:tweak`, `type:chore`, `type:docs`, `type:errand`
   - `human-delivery` (always — spades-anywhere has no AI-delivered branch)
2. Update issue status: Todo → In Progress → Done (quick items are
   single-action; they reach Done as soon as the marker file is
   written).
3. Post a comment on the Linear issue with the evidence reference.
4. Record the Linear issue ID in the marker file's `linear_issue_id:`
   frontmatter field.
5. **Do NOT create sub-issues.** The Linear issue is the whole unit
   of work on the quick path. Do not attach a Plan document.

If no Linear issue exists, the marker file alone is the audit trail.

### When `backend: local`

Just the marker file. `linear_issue_id:` is omitted (or left as `null`).

## When the Gate Changes Mid-Flight

If you're partway through a fast-track item and discover the work is
actually bigger than the gate allows (the "single email" became a
thread; the "doc tweak" exposed a structural problem),
**stop immediately**:

1. Do not record a quick-item marker.
2. Explain to the human what you found and which gate criterion now
   fails.
3. Recommend falling back to `/spades-anywhere:scope` for a proper
   Scope + Plan.
4. If the human agrees, the in-progress work can be carried into a
   proper Scope — but not fast-tracked.

It is not a failure to bail out. It is the gate working correctly.

## What `/spades-anywhere:quick` is NOT for

- Decisions that affect project intent (use the full loop)
- First-pass work on a new initiative, even a small one
- Anything touching `ARCHITECTURE.md`, `PATTERNS.md`, or `INTENT.md`
- Anything where you'd want a confirmation walk against INTENT
  success criteria
- "Several small things bundled together" — if there are several,
  write a Scope

## Relationship to the Full Loop

`/spades-anywhere:quick` exists because full-loop ceremony for
trivial work is wasteful. It is *not* a replacement for the full
loop, and it is *not* the default. The defaults remain:

- **Non-trivial work** → `/spades-anywhere:scope` →
  `/spades-anywhere:plan` → `/spades-anywhere:approve` → human acts
  → `/spades-anywhere:evaluate` → `/spades-anywhere:ship` →
  `/spades-anywhere:close`
- **Trivial human work meeting every gate criterion** →
  `/spades-anywhere:quick`

When in doubt, use the full loop. The cost of full-loop ceremony on
work that could have been fast-track is a few minutes of friction.
The cost of fast-tracking work that should have had a Scope is a
broken audit trail and, eventually, a broken framework.
