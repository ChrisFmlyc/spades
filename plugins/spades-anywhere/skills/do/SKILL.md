---
name: do
description: Mark a Plan as delivering and restate its parent Scope's acceptance criteria back to the human, then stand down. In spades-anywhere, "Do" is not autonomous work — it's a marker that says "human is now doing the work" plus a reminder of what 'done' looks like. Use after `/spades-anywhere:approve` has run, when someone says "do this", "start this plan", "I'm going to work on this now", or when a Plan is in status `approved`. There is no AI-autonomous branch — only `delivery: human` (default) and `delivery: hybrid` (AI assists with research / drafts / structure; the human acts).
version: 0.1.0
---

# /spades-anywhere:do

You are marking a Plan as in-progress. **You are not doing the
work for the human.** `spades-anywhere` runs in non-coding contexts
where there is no code to generate; the human is the one who
actually does the work (hosts the party, runs the interview,
writes the chapter). This skill's job is:

1. Mark the Plan as `delivering`.
2. Restate the parent Scope's acceptance criteria back so the
   human knows what "done" looks like.
3. For `delivery: hybrid` plans, offer to assist with drafts /
   research / structure where the human asked for help.
4. Stand down. The human goes off and does the thing. They run
   `/spades-anywhere:evaluate` when they want to check progress.

There is **no AI-autonomous branch** in `spades-anywhere`. The
sister `spades` plugin's `delivery: ai` (autonomous code execution
on a feature branch) has no equivalent here. Routing in
`spades-anywhere` is `human` or `hybrid`.

Read `docs/FRAMEWORK.md` § Target Resolution and § Execution
Posture before running.

### Output format

This skill honours `review_format:` from `.spades-anywhere/config`
per `docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. In HTML
mode, auto-open the Plan's existing `.html` file via the OPEN_CMD
prelude at the start so the human can see the Plan they're about
to work on. In CLI mode, summarise inline. The marker behaviour is
identical between modes.

## Pre-Flight

1. **Confirm setup + active project.** Abort otherwise.
2. **Resolve the target Plan** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill's parameters:
   - **Artefact type:** Plan (no type-question needed).
   - **Status filter:** `approved`, `delivering` (so re-run works
     as a "remind me what I'm doing").
   - **Zero-candidate suggestion:** `/spades-anywhere:approve P-…`
     on a draft plan.

   If the human passed a Plan ID, resolve directly; otherwise run
   the interactive picker.
3. **Read the Plan and parent Scope.**
4. **Verify status.** The Plan must be `status: approved` or
   `status: delivering`. If `draft`, abort and suggest
   `/spades-anywhere:approve` first.
5. **Verify dependencies.** Read every plan listed in the Plan's
   `depends_on:` field.
   - If any dependency has `status: rejected`, **abort** with a
     pointer to `/spades-anywhere:plan` for the rejected ancestor.
     Rejections do not cascade silently — the human must
     explicitly replan the rejected ancestor (or mark its
     dependants rejected too) before Do can proceed. See
     `docs/FRAMEWORK.md § Plan Rejection` for the contract.
   - If any dependency is not yet `status: shipped` (still
     `delivering`, `evaluating`, etc.), warn the human:

     > Plan `P-foo-3HyD` depends on `P-bar-28sD`, which is still
     > `delivering`. Do you want to proceed anyway, or wait?

     Offer (via `AskUserQuestion`):
     - **Wait** — abort, suggest finishing the dependency first
     - **Proceed anyway** — record the override in the audit trail
6. **Open the artefact (HTML mode only).** When `review_format:
   html`, run the OPEN_CMD prelude and open the Plan's `.html`.
   In CLI mode, summarise inline.

## Step 1 — Update Status

Move the Plan to `status: delivering` and `updated: <today>`.

Append to the Plan's `## Audit Trail`:

```markdown
- YYYY-MM-DD: Do phase started — routing: <human|hybrid>.
```

Also update the parent Scope's status to `delivering` if it isn't
already.

When `backend: linear`, mirror the status changes (sub-issue →
"Delivering", parent Issue → "Delivering").

## Step 2 — Restate the acceptance criteria

This is the value-adding part of the skill. Read the parent
Scope's `## Acceptance Criteria` section and present each
criterion back to the human, plainly:

```
You're now doing the work. Here's what 'done' looks like:

  [ ] <criterion 1>
  [ ] <criterion 2>
  [ ] <criterion 3>

When you're ready to check progress, run:
  /spades-anywhere:evaluate P-<id>

If you finish without all the criteria met (PARTIAL), this skill
will route you back here to keep going.
```

Do NOT ask for an assignee, a cadence, a check-in interval, a
status update plan, or anything else managerial. The human knows
how to do their own life — `spades-anywhere` is a marker, not a
project manager.

## Step 3 — Branch on `delivery:`

### Branch A: `delivery: human` (default)

The human is doing the work themselves with no AI assistance.
You've already done your job (Steps 1–2). Print the summary and
exit:

```
✓ Plan in progress: P-host-birthday-party-3HyD
✓ Routing:           human
✓ Status:            delivering

Run /spades-anywhere:evaluate P-… when ready to check progress.
```

### Branch B: `delivery: hybrid`

Some sub-tasks can use AI help. Walk each task in the Plan body
and check its per-task `Routing:` field (set by
`/spades-anywhere:approve` during hybrid routing):

- For tasks marked `Routing: human`: do nothing here. The human
  will handle them.
- For tasks marked `Routing: ai`: offer to help. The AI does NOT
  execute the task autonomously; it produces a draft, a research
  summary, a structured outline, or a decision frame — whichever
  the task's posture calls for. The human reviews and applies.

For each `Routing: ai` task, ask the human via `AskUserQuestion`:

- **Help with this task now** — produce the deliverable
  (draft / outline / research / decision frame).
- **Skip for now** — the human will come back to it.

After helping with the AI tasks the human picked, restate the
acceptance criteria again (as Step 2) and exit. The human
continues from there.

## Step 4 — Resume on re-invocation

If `/spades-anywhere:do` is re-invoked on a plan already
`status: delivering`:

1. Read the audit trail to see what happened.
2. Restate the acceptance criteria again as Step 2 (so the human
   has fresh context).
3. For hybrid plans, list remaining `Routing: ai` tasks and offer
   to help with any of them.
4. Stand down.

Never restart a Plan from scratch. The audit trail is the source
of truth for what's already happened.

## Edge cases

- **The Plan has no tasks declared.** Abort and route back to
  `/spades-anywhere:plan` — every Plan should have at least one
  task before Do.
- **The Plan was already shipped.** Abort with: *"Plan already
  shipped — nothing more to do here. Run
  `/spades-anywhere:status` to see what's next, or
  `/spades-anywhere:scope <title>` to start a new piece of work."*
- **The human revokes approval mid-delivery.** Update the Plan to
  `status: rejected`, append a rejection note to the audit trail,
  surface the partial state, and ask the human how to clean up.
