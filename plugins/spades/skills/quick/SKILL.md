---
name: quick
description: Fast-track path for trivial work — tiny bug fixes, one-line tweaks, config nudges, docs typos, and other changes too small for the full SPADES loop. Use when someone says "just fix this small thing", "quick tweak", "one-line change", "typo fix", "rename this variable", or when you would otherwise invoke /spades:scope for a change that clearly meets every gate criterion below. Do NOT use for anything touching architecture, auth, schemas, public APIs, or requiring more than one focused commit.
version: 2.0.1
---

## Pre-Flight

Read `.spades/config` for the active backend and project. If missing,
abort and suggest `/spades:setup`.

# SPADES Quick — Fast-Track Path for Small Work

You are delivering a trivial change through the SPADES fast-track path.
The full loop (Scope → Plan → Approve → Do → Evaluate → Ship) is
friction theatre for a typo fix or a one-line config tweak.
`/spades:quick` compresses it into four steps —
**Identify → Fix → Verify → PR** — where the PR description is the
audit artefact and there are no separate Scope or Plan records.

This path is a privilege, not a default. If *any* gate criterion below
fails, stop and run `/spades:scope` for the full loop instead. The gate
exists so fast-track does not slowly swallow the framework.

## Conversational Style

Fast-track should feel fast but not reckless.

1. **Confirm the gate explicitly.** Do not silently decide the work is
   trivial. Walk the gate criteria with the human, even briefly. If one
   criterion is ambiguous, flag it and ask — don't assume.
2. **Be willing to bail.** If anything feels bigger than it first looked
   (scope creep mid-fix, an unexpected test failure exposing a deeper
   issue), stop and recommend falling back to `/spades:scope`. The cost
   of restarting is low; the cost of a fast-track change that should
   have had a Scope is high.
3. **Keep the human in the loop on classification.** Ask which `type:*`
   label applies if it's not obvious.
4. **Do not monologue.** One sentence per step update is enough.

## The Gate — ALL must be true

Walk through each of these before writing any code. If any one fails,
stop and invoke `/spades:scope` instead.

1. **Single concern.** One bug, one tweak, one touch-up. Not "fix bug
   and also clean up a bit while I'm there."
2. **≤ 50 lines of code changed total.** Soft cap. Hard stop above ~100.
   If you're not sure, bail.
3. **One file, or one tight cluster in one module.** Not spread across
   unrelated files.
4. **No new dependencies.** `package.json`, `pyproject.toml`, `go.mod`,
   `Cargo.toml`, `Gemfile`, and equivalents must remain untouched.
5. **No schema or migration changes.** No touching database schemas,
   migration files, data-layer models, or anything that would require
   a data backfill.
6. **No architectural changes.** No new patterns, no new abstractions,
   no moving code between layers, no new top-level directories.
7. **No security-sensitive code.** No auth, crypto, secrets handling,
   session management, permission checks, or input validation on a
   trust boundary.
8. **No public API or interface changes.** Nothing that breaks a caller
   elsewhere in the codebase or downstream.
9. **Revertible as one commit.** A single `git revert` should undo the
   entire change cleanly.
10. **Existing tests cover the area.** Or a trivial extension of an
    existing test is enough. If you'd need to build new test scaffolding,
    the change is not fast-track.

### Gate failure

If any criterion fails, stop immediately and tell the human:

> This doesn't fit the fast-track gate because [specific criterion].
> Running `/spades:scope` for the full loop is the right call here.

Do not attempt to "partially" fast-track by skipping just one rule.
The gate is all-or-nothing.

## Classification

Every quick-path change gets a `type:*` label. Pick the closest match:

- **`type:bug`** — fixing incorrect behaviour
- **`type:tweak`** — small behaviour or UX adjustment that isn't strictly a bug
- **`type:chore`** — maintenance, version bumps (non-breaking), housekeeping
- **`type:docs`** — documentation, comments, README updates
- **`type:refactor`** — rename, extract, inline, or similar non-behavioural change

If the work is ambiguous between two types, ask the human via
**`AskUserQuestion`** (per `docs/FRAMEWORK.md` § "Asking the Human")
listing the candidate types as options. This is a closed-set
decision; don't ask in free-form prose.

Similarly, if the gate-check produces an ambiguous "is this trivial
enough" judgement that the human needs to call, prompt via
`AskUserQuestion` with options *Continue on quick path* /
*Fall back to /spades:scope*.

## Workflow

### 1. Identify

- Read the bug report, ticket, or user description.
- Walk the gate criteria out loud. Confirm each one. If any fail, bail.
- Classify with a `type:*` label.
- If there's a Linear issue, note its ID. If not, ask whether to create
  one or whether the PR alone is sufficient audit trail (for extremely
  trivial things like a typo in a comment, the PR may be enough; for
  anything touching behaviour, create a Linear issue).

### 2. Fix

- Create a quick-path branch: `spades-quick/<issue-id>-<slug>` (or
  `spades-quick/<slug>` if there's no Linear issue).
- Make the change in a **single commit**. If you find yourself wanting
  a second commit, that's a signal the work is bigger than fast-track
  allows — stop and re-evaluate the gate.
- Do not refactor nearby code "while you're there". That's out of scope.

### 3. Verify

- Run the existing test suite. It must pass.
- If the change is behavioural, extend an existing test or add one small
  assertion. If that would require new test scaffolding, you failed the
  gate — bail.
- If the change is visible (UI, output format, CLI help text), manually
  verify it in the relevant environment and record what you checked.

### 4. PR

- Open a pull request using the template below.
- The PR description **is the audit artefact**. There is no separate
  Plan document, no sub-issue, no evaluation comment. The PR carries
  everything a future reader needs.
- On the Linear issue (if one exists): add the labels, post the PR URL
  as a comment, move the status to "In Review". Do not mark Done — the
  human owns that transition.

## PR Description Template

```markdown
**Type:** <bug | tweak | chore | docs | refactor>
**SPADES path:** quick
**Linear:** <S-fix-broken-form or "none — trivial">

## What
<One-sentence description of the change.>

## Why
<One-sentence reason, or the text of the linked issue.>

## Change
<One short paragraph describing what changed and how.>

## Verification
- [ ] Existing tests pass (`<command you ran>`)
- [ ] Manually verified: <what you checked, or "N/A — non-behavioural">

## Gate check
- [x] Single concern
- [x] ≤ 50 LoC changed
- [x] Scoped to one file / tight cluster
- [x] No new dependencies
- [x] No schema or migration changes
- [x] No architectural changes
- [x] No security-sensitive code touched
- [x] No public API changes
- [x] Revertible as one commit
- [x] Existing tests cover the area

---
*Delivered via `/spades:quick` — fast-track path for trivial changes.*
```

Every gate-check box must be ticked. If you can't tick one, you failed
the gate and should not have reached this step.

## Backend Integration

### When `backend: linear`

When there's a Linear issue:

1. Apply labels:
   - `spades:quick`
   - One of `type:bug`, `type:tweak`, `type:chore`, `type:docs`, `type:refactor`
   - `ai-delivered` or `human-delivery`
2. Update status: Todo → In Progress → In Review.
3. Post the PR URL as a comment.
4. **Do NOT create sub-issues.** The Linear issue is the whole unit of
   work on the quick path. Do not attach a Plan document.
5. **Do NOT mark the issue Done.** The human does that after reviewing
   and merging the PR.

If no Linear issue exists, the PR itself is the audit trail.

### When `backend: local`

There is no separate Scope or Plan file. The PR description is the
canonical record.

Optionally, append a one-line note to the active project's
`.spades/projects/<slug>.md` under an `## Audit Trail` heading:

```markdown
- YYYY-MM-DD: quick-path fix — <type> — PR <url>
```

This gives `/spades:list` and `/spades:status` something to surface
when asked about quick-path work.

## When the Gate Changes Mid-Flight

If you're partway through delivering a fast-track change and discover
that the change is actually bigger than the gate allows (a "simple" bug
fix that now needs two files, or a "tiny" tweak that exposes a schema
issue), **stop immediately**:

1. Do not commit what you have.
2. Explain to the human what you found and which gate criterion now fails.
3. Recommend falling back to `/spades:scope` for a proper Scope + Plan.
4. If the human agrees, the in-progress work can be discarded or carried
   into a proper Scope — but not fast-tracked.

It is not a failure to bail out. It is the gate working correctly.

## What `/spades:quick` is NOT for

- Incident response (use the full loop, ceremony is cheap during an incident)
- First-pass work on a new feature, even a small one
- Anything touching ARCHITECTURE.md or PATTERNS.md
- Anything a human reviewer would want to discuss before it lands
- "Several small changes bundled together" — if there are several,
  write a Scope and use delivery bundles on the full loop

## Relationship to the Full Loop

`/spades:quick` exists because full-loop ceremony for trivial work is
wasteful. It is *not* a replacement for the full loop, and it is *not*
the default. The defaults remain:

- **Non-trivial work** → `/spades:scope` → `/spades:plan` → `/spades:approve`
  → deliver → `/spades:evaluate`
- **Trivial work meeting every gate criterion** → `/spades:quick`

When in doubt, use the full loop. The cost of full-loop ceremony on
work that could have been fast-track is a few minutes of friction. The
cost of fast-tracking work that should have had a Scope is a broken
audit trail and, eventually, a broken framework.
