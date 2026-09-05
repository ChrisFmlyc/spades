---
name: quick
description: Fast-track path for trivial work — tiny bug fixes, one-line tweaks, config nudges, docs typos, and other changes too small for the full SPADES loop. Use when someone says "just fix this small thing", "quick tweak", "one-line change", "typo fix", "rename this variable", or when you would otherwise invoke /spades:scope for a change that clearly meets every gate criterion below. Work that touches architecture, auth, schemas, or public APIs, or needs more than one focused commit, takes the full loop via /spades:scope.
version: 2.4.1
---

# /spades:quick

You are delivering a trivial change through the fast-track path.
The full loop is the wrong shape for a typo or a one-line config
nudge; `/spades:quick` compresses it into **Identify → Fix → Verify →
Publish**, with a quick-item marker file as the audit record and no
Scope or Plan.

The path is a privilege gated by ten criteria. Every criterion
passes or the work goes to `/spades:scope`. When in doubt, the full
loop costs minutes; a fast-tracked change that needed a Scope costs
the audit trail.

Read `docs/FRAMEWORK.md` § Fast-Track Path, § ID Format, and
§ Carry-Forward of SPADES-Owned Artefacts before running.

## Pre-Flight

Read `.spades/config` for `backend:`, `scm:`, and `project:`; a
missing config points at `/spades:setup`.

## The gate — all ten must hold

Walk each criterion with the human before writing any code. An
ambiguous criterion is asked, not assumed, via `AskUserQuestion`:
**Continue on the quick path** / **Fall back to /spades:scope**.

1. **Single concern.** One bug, one tweak, one touch-up.
2. **≤ 50 lines changed** (soft cap; hard stop around 100).
3. **One file, or a tight cluster in one module.**
4. **No new dependencies** — package manifests untouched.
5. **No schema, migration, or data-layer changes.**
6. **No architectural changes** — no new patterns, abstractions,
   layers, or top-level directories.
7. **No security-sensitive code** — auth, crypto, secrets, sessions,
   permissions, trust-boundary validation.
8. **No public API or interface changes.**
9. **Revertible as one commit.**
10. **Existing tests cover the area** — a trivial extension is fine;
    new scaffolding is not.

When a criterion fails:

> This doesn't fit the fast-track gate because <criterion>. Running
> `/spades:scope` for the full loop is the right call here.

The gate also holds mid-flight. A "simple" fix that grows a second
file or exposes a schema issue stops immediately, uncommitted; the
human hears which criterion now fails, and the work carries into a
proper Scope. Bailing out is the gate working.

## Classification

Every quick item carries a `type`: `bug` (incorrect behaviour),
`tweak` (small behaviour or UX adjustment), `chore` (maintenance,
non-breaking bumps), `docs`, or `refactor` (rename, extract, inline).
When two fit, ask via `AskUserQuestion`.

## Workflow

### 1. Identify

Read the report or description, walk the gate aloud, classify, and
mint the ID: `Q-<slug>-<suffix>`, slug from the one-line title
(Scope slug rules, ≤50 characters), suffix a random 4-character
base62 string collision-checked against `.spades/quick/`.

With `backend: linear`, note an existing Linear issue's ID, or ask
whether to create one — a comment-typo fix is fine with the marker
alone; anything behavioural gets an issue.

### 2. Fix

Invoke `/repo:newbranch` with the quick item's description and configured
remote. Use the returned branch and worktree for the fix, verification,
marker and PR. Naming and default-branch preparation belong to that skill.
On resume, use the marker's recorded branch through `--resume` and resolve
pre-existing uncommitted work before inclusion.

Make the approved fix and marker in a single commit, following
`docs/FRAMEWORK.md § Carry-Forward → Commit contents`. Existing commits on
this branch need no inclusion question; inspect the complete proposed
commit and preserve excluded staged/unstaged changes.

Nearby code stays as it is; tidying "while you're there" is a
second concern.

### 3. Verify

Run the existing test suite. A behavioural change extends an
existing test or adds one small assertion. A visible change (UI,
output format, CLI help) is checked by hand in the relevant
environment, and what was checked is recorded.

### 4. Publish — by `scm:`

**`scm: github`** — open the PR with the template below, write the
marker at `status: shipping` with `pr_url`, and print one line:
*"PR opened. Run `/spades:close Q-<id>` after it merges to
finalise."* `/spades:close` verifies the merge with `gh pr view`,
flips the marker to `shipped`, and appends `- YYYY-MM-DD: Shipped
(github). PR: <url>. Merge: <sha>. Merged by: <login>.`

**`scm: local-git`** — push the branch when a remote is configured
(`local_git.remote:`, default `origin`), then write the marker at
`status: shipped` with `- YYYY-MM-DD: Shipped (local-git). Branch:
<name>. Commit: <sha>.` as its last audit line. Single-phase; there
is nothing to close.

#### PR description (github)

```markdown
**Type:** <bug | tweak | chore | docs | refactor>
**SPADES path:** quick
**Quick item:** Q-<slug>-<suffix>
**Linear:** <issue-id, or "none">

## What
<one sentence>

## Why
<one sentence, or the linked issue's text>

## Change
<one short paragraph>

## Verification
- [ ] Existing tests pass (`<command>`)
- [ ] Manually verified: <what, or "N/A — non-behavioural">

## Gate check
- [x] Single concern
- [x] ≤ 50 LoC changed
- [x] One file / tight cluster
- [x] No new dependencies
- [x] No schema or migration changes
- [x] No architectural changes
- [x] No security-sensitive code
- [x] No public API changes
- [x] Revertible as one commit
- [x] Existing tests cover the area

---
*Delivered via `/spades:quick`.*
```

Every box is ticked; an unticked box is a gate failure, which
belongs in Step 1.

## The marker file

`.spades/quick/Q-<slug>-<suffix>.md` is the canonical record for
both backends — what `/spades:evaluate`, `/spades:list`,
`/spades:status`, and `/spades:close` read. With `backend: linear`
the Linear issue mirrors it.

```yaml
---
id: Q-fix-broken-form-4nKr
id_suffix: 4nKr
project: <project-slug>
title: "<one-line title>"
type: bug | tweak | chore | docs | refactor
status: shipping | shipped        # github opens at shipping; local-git writes shipped
pr_url: <url>                     # github only
branch: <branch returned by /repo:newbranch>
linear_issue_id: <id>             # backend: linear only
delivery: ai | human
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

```markdown
# <title>

## What
<one sentence>

## Why
<one sentence or linked issue text>

## Change
<one short paragraph>

## Gate Check (retrospective)
- [x] Single concern
- [x] ≤ 50 LoC changed
- [x] One file / tight cluster
- [x] No new dependencies
- [x] No schema or migration changes
- [x] No architectural changes
- [x] No security-sensitive code
- [x] No public API changes
- [x] Revertible as one commit
- [x] Existing tests cover the area

## Audit Trail
- YYYY-MM-DD: Quick-path opened. Type: <type>. Branch: <name>. Delivery: <ai|human>.[ PR: <url>.]
```

`status: shipped` always means the change is on `main` (github) or
recorded as the shipment commit (local-git). A quick item that is
started and dropped has its marker deleted; git history keeps the
trace, and there is no terminal status to set.

### `backend: linear`

Alongside the marker, on the Linear issue: apply `spades:quick`, the
`type:<value>` label, and `ai-delivered` or `human-delivery`; move
the issue Todo → In Progress → In Review; post the PR URL as a
comment; record the issue ID in `linear_issue_id:`. The issue is the
whole unit of work — no sub-issues, no Plan document. In Review →
Done is `/spades:close Q-<id>`'s transition after the merge (with
`scm: local-git`, move it to Done here).

## Where the quick path stops

Incident response, first-pass work on a feature, anything touching
`ARCHITECTURE.md` or `PATTERNS.md`, anything a reviewer would want
to discuss before it lands, and bundles of several small changes all
take the full loop: `/spades:scope` → `/spades:plan` →
`/spades:approve` → `/spades:deliver` → `/spades:evaluate` →
`/spades:ship`.
