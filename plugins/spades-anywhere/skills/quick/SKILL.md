---
name: quick
description: Fast-track path for trivial human work in spades-anywhere — tiny errands, one-off actions, quick artefact tweaks, single-message communications that don't warrant a Scope. Use when someone says "just do this small thing", "quick errand", "one-off task", "tiny tweak to the doc", or when you would otherwise invoke /spades-anywhere:scope for a change that clearly meets every gate criterion below. Work that touches project intent, coordinates several people, commits money over the threshold, or needs evaluation against acceptance criteria takes the full loop via /spades-anywhere:scope.
version: 0.3.0
---

# /spades-anywhere:quick

You are opening a trivial unit of human work through the fast-track
path. The full loop is the wrong shape for one email, one booking,
or one typo in a doc; `/spades-anywhere:quick` compresses it into
**Identify → Declare → Open the marker**, with a quick-item marker
file as the audit record and no Scope or Plan.

The marker opens at `status: shipping` — the intent is declared and
the human has not yet acted. When they come back with evidence,
`/spades-anywhere:close Q-<id>` fills in what happened and flips the
marker to `shipped`. Like `/spades-anywhere:do`, this skill is a
marker plus a restatement of done; the human owns the doing.

The path is a privilege gated by ten criteria. Every criterion
passes or the work goes to `/spades-anywhere:scope`.

Read `docs/FRAMEWORK.md` § ID Format → Quick-item ID before running.

## Pre-Flight

Read `.spades-anywhere/config` for `backend:` and `project:`; a
missing config points at `/spades-anywhere:setup`.

## The gate — all ten must hold

Walk each criterion with the human before anything is written. An
ambiguous criterion is asked via `AskUserQuestion`: **Continue on
the quick path** / **Fall back to /spades-anywhere:scope**.

1. **Single concrete action.** One errand, one email, one tweak.
2. **≤ 30 minutes of human time** (soft cap; hard stop around 60).
3. **One artefact or one recipient.**
4. **No new external commitment** — no new contract, vendor, or
   financial obligation over the project's stated threshold.
5. **No project-intent shift** — the action doesn't change what the
   project is for.
6. **No coordination across multiple people.** One message to one
   person is fine; chairing a four-way thread is not.
7. **No irreversible commitment.** A cancellable test booking is
   fine; a non-refundable payment is not.
8. **No new dependency on external state** — no "waiting for X to
   reply".
9. **Revertible** — undoing it is cheap.
10. **No verification against project success criteria.** Work that
    would move an `INTENT.md` criterion deserves a Scope.

When a criterion fails:

> This doesn't fit the fast-track gate because <criterion>. Running
> `/spades-anywhere:scope` for the full loop is the right call here.

The gate holds mid-flight too. An action that grows (the one email
becomes a thread) stops before any marker is written; the human
hears which criterion now fails, and the work carries into a Scope.

## Classification

Every quick item carries a `type`: `bug` (fixing something wrong —
a typo, an incorrect detail), `tweak` (a small adjustment), `chore`
(filing, archiving, scheduling), `docs` (a written record), or
`errand` (a one-off real-world action: book, buy, send, confirm).
When two fit, ask via `AskUserQuestion`.

## Workflow

### 1. Identify

Hear the ask, walk the gate aloud, classify, and mint the ID
`Q-<slug>-<suffix>` (slug from the action, ≤50 characters; a random
4-character base62 suffix collision-checked against
`.spades-anywhere/quick/`). With `backend: linear`, note an existing
issue's ID or ask whether to create one; for the most trivial items
the marker alone is enough.

### 2. Declare

Make the contract explicit before the human leaves:

- **The action** in one line — what, to which artefact or
  recipient, by when.
- **What done looks like** — the evidence they will bring back (a
  URL, a file path, a one-line attestation, a message ID). The
  standard is that future-you can tell what happened from the
  evidence alone.

Nothing else is captured — no cadence, no check-in, no reminder.

### 3. Open the marker

Write `.spades-anywhere/quick/Q-<slug>-<suffix>.md` at `status:
shipping`, with the **Action taken** and **Evidence** sections as
`<filled in at close>` placeholders. Confirm in one line: *"Marker
opened. Run `/spades-anywhere:close Q-<id>` with evidence when
done."*

## The marker file

The canonical record for both backends — what
`/spades-anywhere:evaluate`, `/spades-anywhere:list`,
`/spades-anywhere:status`, and `/spades-anywhere:close` read. With
`backend: linear` the issue mirrors it.

```yaml
---
id: Q-book-venue-deposit-7Mqz
id_suffix: 7Mqz
project: <project-slug>
title: "<one-line title>"
type: bug | tweak | chore | docs | errand
status: shipping                 # /spades-anywhere:close Q-<id> flips to shipped with evidence
evidence_ref: <filled-in-at-close>
linear_issue_id: <id>            # backend: linear
delivery: human
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

```markdown
# <title>

## What
<one sentence>

## Why
<one sentence or linked context>

## Action to take
<one short paragraph — the action the human is about to take>

## Action taken
<filled in at close>

## Evidence
<filled in at close>

## Gate Check (prospective)
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
- YYYY-MM-DD: Quick-path opened. Type: <type>. Action: <one-line restatement>.
```

At close the placeholders are filled, the Gate Check heading becomes
`(retrospective)` and is re-validated against what happened, and a
`Shipped` line in the canonical ship grammar is appended. A quick
item that is started and dropped has its marker deleted; there is
no terminal status to set.

### `backend: linear`

Alongside the marker, on the issue: apply `spades:quick`,
`type:<value>`, and `human-delivery`; move it Todo → In Progress;
comment *"Quick-path opened. Action: `<restatement>`."*; record the
issue ID in `linear_issue_id:`. The issue is the whole unit of work
— no sub-issues. In Progress → Done is `/spades-anywhere:close
Q-<id>`'s transition, after the evidence is in.

## Where the quick path stops

Decisions that affect project intent, first-pass work on a new
initiative, anything touching `INTENT.md`, `ARCHITECTURE.md`, or
`PATTERNS.md`, anything that warrants a confirmation walk against
INTENT, and bundles of several small things all take the full loop:
`/spades-anywhere:scope` → `plan` → `approve` → the human acts →
`evaluate` → `ship` → `close`.
