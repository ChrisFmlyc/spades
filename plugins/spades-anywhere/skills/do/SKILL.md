---
name: do
description: Mark a Plan as delivering and restate its parent Scope's acceptance criteria back to the human, then stand down. In spades-anywhere, "Do" is not autonomous work — it's a marker that says "human is now doing the work" plus a reminder of what 'done' looks like. Use after `/spades-anywhere:approve` has run, when someone says "do this", "start this plan", "I'm going to work on this now", or when a Plan is in status `approved`. Routing is `delivery: human` (default) or `delivery: hybrid` (AI assists with research / drafts / structure; the human acts).
version: 0.2.0
---

# /spades-anywhere:do

You are marking a Plan as in progress. The human does the work —
hosts the party, runs the interview, writes the chapter — and this
skill does three things around them:

1. Marks the Plan `delivering`.
2. Restates the parent Scope's acceptance criteria so the human
   knows what done looks like.
3. Under `delivery: hybrid`, offers help on the tasks routed `ai` —
   a draft, a research summary, an outline, a decision frame — which
   the human reviews and applies.

Then it stands down. The human runs `/spades-anywhere:evaluate` when
they want to check progress; the Do → Evaluate loop runs until PASS.
The skill takes no assignee, cadence, or check-in duties.

Read `docs/FRAMEWORK.md` § Target Resolution, § Execution Posture,
and § Output Format before running.

### Output format

The Plan and Scope are read from their `.md` files. HTML mode opens
the Plan's and the Scope's existing `.html` via the OPEN_CMD
prelude; the Scope page is where the acceptance criteria live, so
Step 2 prints a one-line pointer instead of the list. CLI mode
restates the criteria inline. After the audit-trail write in HTML
mode, re-render the Plan's `.html`.

## Pre-Flight

1. **Confirm setup and active project.**
2. **Read `backend:` and `review_format:`.**
3. **Resolve the target Plan** per `docs/FRAMEWORK.md § Target
   Resolution` — status filter `approved`, `delivering` (a re-run is
   "remind me what I'm doing"); zero candidates →
   `/spades-anywhere:approve P-…`.
4. **Read the Plan and its parent Scope.**
5. **Verify ancestors active**; hard abort on an `abandoned` Scope or
   an `abandoned` / `archived` Project.
6. **Verify status.** `approved` → fresh run. `delivering` → resume
   (Step 4). `draft` → `/spades-anywhere:approve` first. `shipped`
   → say so and point at `/spades-anywhere:status`.
7. **Verify routing.** `delivery:` is `human` or `hybrid`; anything
   else is sent back to `/spades-anywhere:approve`.
8. **Verify dependencies.** A `rejected` dependency is a hard abort
   with a pointer to `/spades-anywhere:plan` for that ancestor
   (`docs/FRAMEWORK.md § Plan rejection — no cascade`). A dependency
   not yet `shipped` → `AskUserQuestion`: **Wait** / **Proceed
   anyway** (recorded in the audit trail).
9. **Open the review surface** per § Output format.

## Step 1 — Mark delivering

Capture an optional one-line description via `AskUserQuestion`:
**Type a brief description** (free-form, ≤140 characters) / **Skip**.

Set `status: delivering`, `updated: <today>`, and append:

```markdown
- YYYY-MM-DD: Do phase started — routing: <human|hybrid>[ — "<description>"].
```

Set the parent Scope to `delivering` if it is not already. With
`backend: linear`, move the sub-issue and parent Issue to their
`delivering` states.

## Step 2 — Restate what done looks like

**CLI mode:**

```
You're now doing the work. Here's what 'done' looks like:

  [ ] <criterion 1>
  [ ] <criterion 2>
  [ ] <criterion 3>

When you're ready to check progress, run:
  /spades-anywhere:evaluate P-<id>

A PARTIAL verdict routes you back here to keep going.
```

**HTML mode** — the open Scope page carries the list:

```
You're now doing the work — the open Scope tab shows what 'done'
looks like. Run /spades-anywhere:evaluate P-<id> when ready.
```

## Step 3 — Route

### `delivery: human`

Steps 1–2 were the whole job:

```
✓ Plan in progress: P-host-birthday-party-3HyD
✓ Routing:          human
✓ Status:           delivering

Run /spades-anywhere:evaluate P-… when ready to check progress.
```

### `delivery: hybrid`

Walk the Plan's tasks by their `Routing:` bullet (written by
`/spades-anywhere:approve`). `human` tasks are the human's. For each
`ai` task, ask via `AskUserQuestion`: **Help with this task now** —
produce the draft, outline, research, or decision frame the task's
posture calls for / **Skip for now**. The AI produces material; the
human applies it and takes any real-world action. After the tasks
the human picked, restate the criteria (Step 2) and stand down.

## Step 4 — Resume

On a Plan already `delivering`: read the audit trail, restate the
criteria (Step 2), list any remaining `ai` tasks for a hybrid Plan
and offer help, and stand down. The audit trail is the source of
truth; a resumed Plan picks up rather than restarting.

## Edge cases

- **No tasks declared** → back to `/spades-anywhere:plan`.
- **The human reports mid-Do that the Plan is wrong** → stop and
  surface the discrepancy; revise via `/spades-anywhere:plan` and
  `/spades-anywhere:approve`, or record a documented deviation.
- **Approval revoked mid-delivery** → `status: rejected`, a
  rejection note in the audit trail, and ask the human how to clean
  up.
