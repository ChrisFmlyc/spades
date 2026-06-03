# spades-anywhere

SPADES for non-coding agents. Same six-phase loop, same artefact
shape, same Linear / local backends, same HTML mode — adapted for
real-world human tasks rather than code work. Runs in Claude
Desktop, ChatGPT, the Claude web app, and mobile clients.

## What it's for

You're not always at a coding harness. You scope and plan on the
train, the human does the actual work, you evaluate from your phone,
and the "ship" is a confirmation walk through your project's
success criteria with evidence captured.

Examples of what `spades-anywhere` is good for:

- Plan a birthday party for your partner — scope success, plan tasks,
  host the party, evaluate against "everyone had a good time" and
  "the cake didn't melt", ship with photos + thank-you notes.
- Run a hiring round — scope what you're hiring for, plan stages,
  do the interviews, evaluate candidates against the scope,
  ship with the signed offer.
- Prep for a trip — scope the trip's intent, plan packing /
  bookings / errands, do them, evaluate readiness, ship with a
  "ready to fly" checklist.
- Write a book chapter — scope the chapter, plan sections, draft
  them, evaluate against the scope, ship the polished chapter.

## What it's NOT for

- Code work. Use the sister plugin
  [`spades`](https://github.com/ChrisFmlyc/spades) for anything
  that ends in a PR. `spades-anywhere` deliberately has no SCM
  driver, no branch creation, no PR lifecycle.
- High-frequency micro-tasks. The framework's six-phase loop has
  fixed overhead. For "remember to text Mum" you don't need a
  scope record. Use a note app.

## Install

```text
/plugin marketplace add ChrisFmlyc/spades
/plugin install spades-anywhere@spades-framework
```

The marketplace also ships the sister plugin `spades` (for coding
work). They're independent — install one, both, or either.

## The six phases

```
SCOPE   → PLAN   → APPROVE → DO     → EVALUATE → SHIP
```

- **Scope** (human-owned) — what's the outcome and how do we know
  we got it (acceptance criteria)?
- **Plan** (AI drafts, human reviews) — break the outcome into
  tasks with a posture per task (discover-first / outline-first /
  decide-first / iterate / straight-through).
- **Approve** (human gate) — is the plan good? Route delivery
  human or hybrid (AI assists with drafts / research / structure;
  the human acts).
- **Do** (human acts) — the AI restates acceptance criteria back
  to the human ("here's what 'done' looks like") and stands down.
  No assignee tracking, no cadence — Do is a marker, not a project
  manager.
- **Evaluate** (human verdict) — walk the scope's acceptance
  criteria, mark each met / partial / not met, aggregate to
  PASS / PARTIAL / FAIL. If not PASS, route back to Do and keep
  going.
- **Ship** (confirmation walk) — walk the project's `INTENT.md`
  success criteria (broader than this scope's local ACs), capture
  evidence per criterion, mark shipped.

See `docs/FRAMEWORK.md` for the full contract.

## See also

- [`spades`](../spades/) — the sister plugin for coding work.
- Root [`AGENTS.md`](../../AGENTS.md) (maintainer-facing) — the
  parity rule between the two plugins.
