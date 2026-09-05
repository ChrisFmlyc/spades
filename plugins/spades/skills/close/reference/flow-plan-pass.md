# Flow — Plan Pass (finalise as shipped)

Reached from `SKILL.md` Step 3 for a Plan at `status: shipping`
whose human picked *Pass*. This flow verifies a merge it did not
perform, records the `Shipped` marker on `main`, and may roll the
parent Scope up. Everything else is SKILL.md's shared machinery
(**B1–B7**), referenced by name.

## Contents

- P1 — Pre-flight and target resolution
- P2 — Verify the ship PR merged
- P3 — Close-out edits (Plan, Scope rollup)
- P4 — Commit, PR, merge, retention, mirror
- P5 — Confirm

## P1 — Pre-flight

Run **B1**, then resolve the target: artefact type Plan; status
filter `shipping` with a `PR opened:` line and no later `Shipped`
line; zero candidates → suggest `/spades:ship P-…`. A single
candidate with no ID passed is picked and announced.

Read the Plan and parent Scope. Capture `plan_id`, `plan_slug`,
`scope_id`, `project_slug`, and the PR URL from the latest
`PR opened:` line.

## P2 — Verify the ship PR merged

```bash
gh pr view <n> --json state,mergeCommit,mergedAt,mergedBy
```

- **Probe failure** (`gh` error, unparseable JSON, `state` missing,
  or `mergeCommit.oid` missing on `MERGED`) → abort cleanly:
  *"Couldn't query PR `<URL>`. Check `gh auth status`, network, or
  rate limits, then re-run `/spades:close <plan_id>`. The Plan is
  untouched at `status: shipping`."*
- **`MERGED`** → capture `mergeCommit.oid`, `mergedBy.login`,
  `mergedAt`. Continue.
- **`OPEN`** → report it with any CI or review status shown.
  `AskUserQuestion`: *Wait — re-run later* / *Abort*. Both exit
  without changes.
- **`CLOSED`** unmerged → exit with the pointer: *"PR `<URL>` is
  closed without merge. Re-open it on GitHub to retry, or re-run as
  `/spades:close <plan_id> --reject "reason"`."* The human picks the
  flow.

Identify every code Plan in this Scope participating in the same verified
PR. Use the Scope's recorded PR branch and each Plan's `PR opened:` marker;
recover a missing post-push marker from the PR association and approved
records, without claiming unrelated Plans shipped. Then **B2** with the
Scope close-out description and preferred `chore/close-<scope-slug>` name.
One bookkeeping PR records the shared shipment.

## P3 — Close-out edits

### P3.1 — Plan

For each participating code Plan in the bookkeeping worktree, set
`.spades/plans/<plan_id>.md` to `status: shipped`, `updated:` today,
and append:

```markdown
- YYYY-MM-DD: Shipped (github). PR: <pr_url>. Merge: <merge-sha>. Merged by: <login>.
```

### P3.2 — Scope rollup

Read every sibling Plan, counting the verified PR's participating Plans
as `shipped`, and
classify each as `shipped`, `rejected`, or in flight.

| Situation | Action |
|---|---|
| Every sibling `shipped`, acceptance criteria covered | Ask the outcome (P3.3), then Scope `status: done`, `updated:` today, append `- YYYY-MM-DD: All plans shipped. Scope done. Outcome: <O-slug \| none>.` |
| Every sibling `shipped`, criteria left uncovered | Ask first (below). |
| All terminal, mix of `shipped` and `rejected`, ≥1 `shipped` | `AskUserQuestion` listing the rejected siblings. |
| Every sibling `rejected` | No rollup; the Scope shipped nothing. Say so; the Plan's own close-out proceeds. |
| A sibling in flight | No rollup. |

"All Plans terminal" is not "the Scope is done": Plans deferred at
planning and never written leave criteria untouched. Read the
Scope's acceptance criteria and check the shipped Plans cover them.
Where they don't, surface the uncovered criteria via
`AskUserQuestion`:

- **Leave the Scope open** *(recommended)* — append `- YYYY-MM-DD:
  Rollup withheld — <n>/<m> acceptance criteria uncovered: <list>.`
- **Roll up anyway** — record the uncovered criteria in the rollup
  line so the claim traces to a decision.

An accepted mixed-terminal rollup asks the outcome (P3.3) and appends
to the Scope:

```markdown
- YYYY-MM-DD: All plans terminal. Shipped: <n>. Rejected: <m>
  (acknowledged: P-<id-1>, P-<id-2>). Scope done. Outcome: <O-slug | none>.
```

### P3.3 — Outcome

A Scope names the Objective it delivered against exactly once, here,
as it closes. Resolve the project's `open` Objectives via
`list_objectives(status: open)` and ask via `AskUserQuestion`:

- One open Objective → **O-<slug> — <title>** *(Recommended)* /
  **No outcome — not part of a strategy**.
- Several → one option per Objective, plus **No outcome**.
- None → skip the question; the outcome is `none`.

An Objective chosen writes `strategy_link: O-<slug>` into the Scope
frontmatter alongside `status: done`. **No outcome** leaves
`strategy_link:` absent; the audit line records `Outcome: none.` A
Scope outside a strategy is a valid Scope. This question is asked on
roll-up only; the abandon route never asks it.

A declined one leaves the Scope unchanged and appends to the Plan:

```markdown
- YYYY-MM-DD: Scope rollup deferred (mixed-terminal; human declined).
```

## P4 — Commit, PR, merge, retention, mirror

**B3** with:

```
chore(spades): close <plan_id>

Records the Shipped marker for <plan_id> on main. Original PR:
<URL>. Squash-merge: <merge-sha> by @<login>.

Scope <scope_id> rolled up to `done`.   # only when rolled up
```

Then **B4** (body lists the Plan, Scope, ship PR, merge SHA,
merged-by, files touched), **B5**, **B6**, and **B7** with:

- Each participating Plan sub-issue → Done.
- Parent Issue → Done, only when every sub-issue is Done. With an
  outcome chosen at P3.3, add the label `outcome/O-<slug>` (the child
  of the exclusive `outcome` label group `/spades:objective` created)
  to the parent Issue and comment *"Closed against `O-<slug>`."* This
  close is the only write to the parent Issue after its creation.
- Comment on each participating sub-issue: *"Shipped. PR: `<URL>` (squash-merge
  `<merge-sha>` by `@<login>`). Bookkeeping audit:
  `<bookkeeping-pr-url>`."*

## P5 — Confirm

```
✓ Ship PR merged:        <URL>  (merge <short-sha> by @<login>)
✓ Bookkeeping PR merged: <bookkeeping-pr-url>
✓ Plans shipped:         <participating-plan-ids>
✓ Scope:                 <scope_id> (done — all plans shipped)   # when rolled up
✓ Outcome:               O-<slug> — <title>  (or: none)          # when rolled up
✓ Linear mirror:         sub-issue Done, parent Issue Done[, labelled outcome/O-<slug>]   # backend: linear
✓ Working tree:          retained at <worktree-path>
✓ Status:                shipped

Next:
  /spades:learn                            — capture a learning
  /spades:status                           — see what's still open
```

Omit the `/spades:learn` suggestion when the Plan's audit trail
already carries a `Loop — learning captured:` or `Loop — learning
declined.` line; that question was answered before close ran.
