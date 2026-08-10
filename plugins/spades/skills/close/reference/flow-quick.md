# Flow — Quick item close

Reached from `SKILL.md` Step 0 when the target is a Quick item
(`Q-<slug>-<suffix>`). There is no Step 1 menu — the action is
unambiguous: verify the PR merged and flip the marker to `shipped`,
offering *Drop* only when the PR is confirmed closed unmerged.

**No bookkeeping PR, no Scope rollup, no Linear sub-issue
handling.** Quick items are deliberately lightweight
(`FRAMEWORK.md § Fast-Track Path`) and are leaf nodes — they have no
parents in the audit-trail sense. SKILL.md's B1–B7 machinery does
not apply here.

## Contents

- Q1 — Pre-flight
- Q2 — Probe the PR state (two outcome classes; the Update PR
  sub-flow)
- Q3 — Flip to shipped
- Q4 — Drop
- Q5 — Linear mirror and confirm

## Q1 — Pre-flight

1. **Setup + active project.** Read `.spades/config`; abort
   otherwise.
2. **Read the marker** at `.spades/quick/<Q-id>.md`. Capture `id`,
   `pr_url`, `branch`, `linear_issue_id`, `status`. Refuse if
   `status: shipped`: *"Quick item `<Q-id>` is already `shipped`.
   Terminal means terminal."*
3. **Confirm `scm: github`.** Otherwise the merge probe doesn't
   apply — abort:

   > *`/spades:close Q-<id>` is meaningful for `scm: github`.
   > Local-git quick items reach shipped inside `/spades:quick`
   > itself (single-phase). Nothing to close out.*

   (Future SCM drivers may extend this; see
   `docs/EXTENDING-SCM.md`.)
4. **HTML mode** — run the OPEN_CMD prelude and open
   `.spades/quick/<Q-id>.html` if it exists. CLI mode — print the
   marker's title and `pr_url` inline.

## Q2 — Probe the PR state

Parse the PR number from `pr_url` and query:

```bash
gh pr view <n> --json state,mergeCommit,mergedAt,mergedBy
```

The probe has **two outcome classes**; distinguish them before
branching on `state`. **A failed probe is not the same signal as a
non-merged PR and must never reach Drop** — Drop deletes the marker,
and on a transiently-failed lookup that would destroy the canonical
record of work that may have shipped.

### Outcome A — probe failure

`gh` exits non-zero, JSON parse fails, or a required field is
missing (`state` null/absent, or `mergeCommit.oid` missing when
`state: MERGED`). **Abort cleanly; do NOT offer Drop:**

> *Couldn't query PR `<pr_url>` — `gh` returned an error or
> incomplete data. Re-run `/spades:close Q-<id>` after fixing the
> underlying issue (check `gh auth status`, network, GitHub rate
> limit). The marker is untouched at `status: shipping`.*

### Outcome B — probe succeeded

- **`MERGED`** → Q3.
- **`OPEN`** → `AskUserQuestion`: *Wait — exit and come back later*
  (recommended) / *Drop the quick item*. Wait → exit cleanly.
  Drop → Q4.
- **`CLOSED`** (unmerged) → the PR is dead, but the work may have
  shipped under a different one (force-replace: original closed,
  replacement opened on another branch and merged). Surface that
  possibility **before** offering Drop. `AskUserQuestion`:
  - *Update PR — the work shipped under a different PR* → the
    sub-flow below.
  - *Drop the quick item* → Q4 (the work is genuinely gone).
  - *Cancel* → exit without changes.

### Update PR sub-flow

**The marker is read-only until the probe against the replacement
URL succeeds.** This validate-before-write contract is what lets
Outcome A's abort message truthfully promise *"the marker is
untouched"*.

1. Prompt free-form for the replacement PR URL.
2. **Validate before touching the marker:**
   - Must parse as a GitHub PR URL under the **same `owner/repo`** as
     the current `pr_url`. Otherwise re-prompt: *"Replacement must be
     a PR under `<owner>/<repo>` — try again or pick Cancel."*
   - Must **not** be byte-equal to the current `pr_url`. Otherwise
     re-prompt: *"That's the same URL — paste a different
     replacement, or pick Cancel."*
3. **Probe the replacement inline** with the same `gh pr view` call.
   Do **not** rewrite `pr_url` before this completes.
   - **Probe failure** → the marker is still untouched. Offer
     *Try a different URL* (re-enter at step 1) / *Cancel*:

     > *Couldn't reach `<new-url>` — `gh` returned an error or
     > incomplete data. The marker is untouched at
     > `status: shipping`. Try a different URL, or Cancel and re-run
     > `/spades:close Q-<id>` later.*

     Drop is deliberately **not** offered here. The human reaches it
     by cancelling and re-running, where Drop acts against the
     original probe-confirmed CLOSED PR.
   - **Probe success** → rewrite `pr_url` to the replacement (the
     first marker write in this sub-flow), then dispatch on the new
     `state` exactly as above: `MERGED` → Q3; `OPEN` → Wait/Drop;
     `CLOSED` → re-enter this CLOSED handler. The marker now records
     the URL we have evidence for; the original survives in the
     `PR opened:` audit line written by `/spades:quick`.

## Q3 — Flip to shipped

In `.spades/quick/<Q-id>.md`:

- Frontmatter `status: shipping` → `shipped`; `updated: <today>`.
- Append to `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: Shipped (github). PR: <pr_url>. Merge: <merge-sha>. Merged by: <login>.
  ```

  The grammar matches the canonical Plan-close `Shipped` line so
  every `Shipped` entry across the framework parses the same way.

In HTML mode, if `.spades/quick/<Q-id>.html` exists, re-render it
via the bundled template (or append the same audit line to it). The
marker is the source of truth; the HTML is the human-readable
mirror.

## Q4 — Drop (PR closed without merging)

Delete `.spades/quick/<Q-id>.md` and its `.html` companion if
present. Git history records the delete; no other audit entry is
needed. **Capture `linear_issue_id` before deleting** — Q5 needs it.

> *`Q-<id>` dropped. PR was closed without merging; marker deleted.
> Git history records the trace.*

## Q5 — Linear mirror and confirm

When `backend: linear` and `linear_issue_id` was present:

- **After Q3** — move the issue In Review → `Done`. Comment:
  *"Merged via `/spades:close Q-<id>`. Merge: `<merge-sha>` by
  `<login>`."*
- **After Q4** — move it In Review → `Cancelled` (or `Backlog`, if
  the team uses that for not-done-not-failed). Comment: *"Quick item
  dropped — PR closed without merging."*

Confirm with one CLI line (in HTML mode the marker's `.html` is
already updated):

- Flip: `✓ Q-<id> shipped. Merge: <merge-sha>.`
- Drop: `✓ Q-<id> dropped.`
