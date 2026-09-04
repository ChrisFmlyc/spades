# Flow — Quick item close

Reached from `SKILL.md` Step 0 for a `Q-<slug>-<suffix>` target.
There is no menu: the action is to verify the PR merged and flip the
marker to `shipped`, with *Drop* offered once the PR is confirmed
closed unmerged. Quick items are leaf nodes — no bookkeeping PR, no
Scope rollup, no B1–B7.

## Contents

- Q1 — Pre-flight
- Q2 — Probe the PR (two outcome classes; the replacement-PR sub-flow)
- Q3 — Flip to shipped
- Q4 — Drop
- Q5 — Linear mirror and confirm

## Q1 — Pre-flight

1. **Setup and active project** from `.spades/config`.
2. **Read the marker** `.spades/quick/<Q-id>.md`: `id`, `pr_url`,
   `branch`, `linear_issue_id`, `status`. A marker already at
   `shipped` is terminal: *"Quick item `<Q-id>` is already
   `shipped`."*
3. **`scm: github`.** With `scm: local-git` the marker was written
   at `shipped` by `/spades:quick`; there is nothing to close.
4. Print the marker's title and `pr_url`.

## Q2 — Probe the PR

```bash
gh pr view <n> --json state,mergeCommit,mergedAt,mergedBy
```

Two outcome classes. A failed probe and a non-merged PR are
different signals: Drop deletes the canonical record, so it is
offered only on a confirmed `CLOSED`.

**Probe failure** — `gh` error, unparseable JSON, `state` missing, or
`mergeCommit.oid` missing on `MERGED` → abort:

> *Couldn't query PR `<pr_url>`. Check `gh auth status`, network, or
> rate limits, then re-run `/spades:close Q-<id>`. The marker is
> untouched at `status: shipping`.*

**Probe succeeded**:

- **`MERGED`** → Q3.
- **`OPEN`** → `AskUserQuestion`: *Wait — exit and come back later*
  (recommended) / *Drop the quick item* → Q4.
- **`CLOSED`** → the work may have shipped under a replacement PR.
  `AskUserQuestion`: *Update PR — the work shipped under a different
  PR* (sub-flow below) / *Drop the quick item* → Q4 / *Cancel*.

### Replacement-PR sub-flow

The marker stays read-only until the replacement probe succeeds.

1. Prompt free-form for the replacement URL.
2. Validate: a GitHub PR URL under the same `owner/repo` as the
   current `pr_url`, and different from it. Otherwise re-prompt or
   *Cancel*.
3. Probe the replacement with the same `gh pr view` call.
   - **Failure** → *Try a different URL* / *Cancel*, marker untouched.
   - **Success** → write the replacement into `pr_url` (the first
     marker write in this sub-flow) and dispatch on its `state` as
     above. The original URL survives in the `Quick-path opened`
     audit line.

## Q3 — Flip to shipped

In `.spades/quick/<Q-id>.md`: `status: shipped`, `updated:` today,
and append:

```markdown
- YYYY-MM-DD: Shipped (github). PR: <pr_url>. Merge: <merge-sha>. Merged by: <login>.
```

The grammar matches the Plan `Shipped` line, so every `Shipped`
entry parses the same way.

## Q4 — Drop

Capture `linear_issue_id` first (Q5 needs it), then delete
`.spades/quick/<Q-id>.md`. Git history records the delete.

> *`Q-<id>` dropped. PR was closed without merging; marker deleted.*

## Q5 — Linear mirror and confirm

With `backend: linear` and a `linear_issue_id`:

- **After Q3** — issue In Review → Done; comment *"Merged via
  `/spades:close Q-<id>`. Merge: `<merge-sha>` by `<login>`."*
- **After Q4** — issue → Cancelled (or Backlog, per team
  convention); comment *"Quick item dropped — PR closed without
  merging."*

Confirm in one line: `✓ Q-<id> shipped. Merge: <merge-sha>.` or
`✓ Q-<id> dropped.`
