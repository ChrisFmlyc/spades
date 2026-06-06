---
name: do
description: Mark a Plan as delivering and restate its parent Scope's acceptance criteria back to the human, then stand down. In spades-anywhere, "Do" is not autonomous work — it's a marker that says "human is now doing the work" plus a reminder of what 'done' looks like. Use after `/spades-anywhere:approve` has run, when someone says "do this", "start this plan", "I'm going to work on this now", or when a Plan is in status `approved`. There is no AI-autonomous branch — only `delivery: human` (default) and `delivery: hybrid` (AI assists with research / drafts / structure; the human acts).
version: 0.1.2
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
4. **Verify ancestors active** per `docs/FRAMEWORK.md § Target
   Resolution → Parent-status precondition`. If the parent Scope is
   `abandoned`, or its parent Project is `abandoned` / `archived`,
   abort hard with the canonical error shape. No override.
5. **Verify status.** The Plan must be `status: approved` or
   `status: delivering`. If `draft`, abort and suggest
   `/spades-anywhere:approve` first.
6. **Verify dependencies.** Read every plan listed in the Plan's
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
7. **Open the artefact (HTML mode only).** When `review_format:
   html`, run the OPEN_CMD prelude and open the Plan's `.html`.
   **In HTML mode the open `.html` (and the linked Scope's `.html`)
   IS the review surface — do NOT also paste / summarise / restate
   the Plan body or the Scope's acceptance criteria list to the
   CLI; the human has the browser tabs.** Step 2.B prints only a
   one-line conversational pointer; all the acceptance-criteria
   detail lives in the open `.html`. Short conversational text
   (delivery-routing acknowledgement, "Plan marked delivering"
   status, error messages) stays CLI as today. In CLI mode,
   summarise inline as today (Step 2.A restates ACs inline). See
   `docs/FRAMEWORK.md § Output Format → What counts as review-form
   text` for the canonical line.

## Step 1 — Update Status

Before updating status, capture a light one-line description (the
"what are you about to do" line) via `AskUserQuestion`:

- *Type a brief description (one line)*
- *Skip — proceed without a description*

For *Type*, follow up with a free-form prompt: *"Brief description
(one line) — e.g. 'drafting interview questions for round 1'."*
Capture the reply verbatim (≤140 chars; truncate with `…` if longer).
Skip is fine — the routing clause alone is enough to start.

Move the Plan to `status: delivering` and `updated: <today>`.

Append a single combined start-line to the Plan's
`## Audit Trail` (mirrors Approve / Evaluate's one-line-per-phase
pattern; matches the sister `spades` plugin's grammar):

```markdown
- YYYY-MM-DD: Do phase started — routing: <human|hybrid>[ — "<description>"].
```

`spades-anywhere` has no feature branches, so there is no
`, branch: …` clause to append. Omit the ` — "<description>"`
clause when the human skipped the description.

Also update the parent Scope's status to `delivering` if it isn't
already.

When `backend: linear`, mirror the status changes (sub-issue →
"Delivering", parent Issue → "Delivering").

## Step 2 — Restate the acceptance criteria (branch on `review_format`)

This is the value-adding part of the skill. The acceptance-criteria
list is **review-form content** — long, structured, meant to be
read and absorbed. Per
`docs/FRAMEWORK.md § Output Format → What counts as review-form
text`, it goes through the mode-selected surface, not both.

### Step 2.A — CLI mode (`review_format: cli`)

Read the parent Scope's `## Acceptance Criteria` section and
present each criterion back to the human, plainly, in the
terminal:

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

### Step 2.B — HTML mode (`review_format: html`)

The human already has the Scope's `.html` open from Step 6. **Do
NOT also paste the acceptance criteria list to the CLI** — that's
review-form content duplicated. Print a one-line conversational
pointer only:

```
You're now doing the work — the open Scope tab shows what 'done'
looks like. Run /spades-anywhere:evaluate P-<id> when ready.
```

That single sentence + the hand-off pointer are the only CLI
output of Step 2 in HTML mode.

### Both modes

Do NOT ask for an assignee, a cadence, a check-in interval, a
status update plan, or anything else managerial. The human knows
how to do their own life — `spades-anywhere` is a marker, not a
project manager.

## Step 3 — Branch on `delivery:`

If the Plan's frontmatter has `delivery: ai` (legacy or hand-edited
state), abort immediately with this one-line message and stop:

> `spades-anywhere` has no AI-autonomous branch. Re-run
> `/spades-anywhere:approve P-…` and pick **Human** or **Hybrid**.

Do not mark the Plan `delivering`. Do not touch any other state.
The human re-routes via Approve and re-invokes `/spades-anywhere:do`.

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
