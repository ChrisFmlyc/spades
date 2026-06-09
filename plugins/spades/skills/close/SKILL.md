---
name: close
description: The single conversational entry point for closing out a Plan, Scope, or Project. Asks the human what they're doing — finalise as shipped/done/archived (the happy path), reject (Plans only), or abandon (Scopes and Projects only). Always asks before acting; flags `--reject "reason"` and `--abandon "reason"` are optional power-user shortcuts that skip the menu but still capture a reason. Use whenever someone says "close this", "close P-…", "close S-…", "we're not doing this", "abandon this scope", "reject this plan", "this PR got closed without merging" — the skill figures out which flow applies.
version: 4.3.1
---

# /spades:close

You are the close-out entry point. The human tells you what to
close; **you ask them what kind of close it is** — pass, reject, or
abandon — and you do the right thing based on the target type and
their answer.

Four close flows live in this skill:

1. **Pass** (happy path) — finalise the artefact's lifecycle.
   - Plan → `status: shipped` (requires merged PR + bookkeeping
     commit; same machinery as the prior version of this skill).
   - Scope → `status: done` (only when every child Plan is
     terminal; mixed-terminal rollup applies).
   - Project → `status: archived` (graceful sunset).
   - Quick item → `status: shipped` (requires merged PR;
     lightweight — no bookkeeping commit, no Scope rollup).
2. **Reject** — Plan rollback. Plan → `status: rejected`. Applies
   to Plans in any non-terminal status (`approved`, `delivering`,
   `evaluating`, `shipping`). A Plan in `draft` doesn't need
   rejection — the menu offers *"leave in draft (no-op)"* instead.
   Requires a reason.
3. **Abandon** — terminal walk-away on a container. Scope or
   Project → `status: abandoned`. Plans cannot be abandoned (they
   are attempts, not initiatives — see `docs/FRAMEWORK.md §
   Terminal States`). Requires a reason.
4. **Drop** — quick-item bail. Quick item whose PR was closed
   without merging → delete the marker file. Quick items have no
   `rejected` / `abandoned` terminal status (per the framework's
   deliberate non-goal); the marker file is just removed. No
   reason required — git history records the delete if anyone
   wants the trace.

Read `docs/FRAMEWORK.md` § Target Resolution and § Terminal States
before running.

## Conversational Entry

**Step 0 — Detect the target.**

- If the human passed an explicit ID, resolve it by prefix:
  `P-<slug>-<suffix>` → Plan; `S-<slug>` → Scope; `Q-<slug>-<suffix>`
  → Quick item; bare slug that matches a
  `.spades/projects/<slug>.md` → Project.
- If no ID was passed, ask via `AskUserQuestion`:
  - *Plan* → run the Plan picker (status filter: `approved`,
    `delivering`, `evaluating`, `shipping`).
  - *Scope* → run the Scope picker (status filter: any non-terminal).
  - *Quick item* → run the Quick-item picker (glob
    `.spades/quick/Q-*.md`, status filter: `shipping`).
  - *Project* → run the Project picker (status filter: `active`).
- If the human gave an ambiguous reference ("close that thing", "the
  newsletter scope"), surface 1–3 best candidates and ask which one.
  Don't guess silently.
- **If the resolved target is a Quick item, skip Step 1 and go
  directly to the Quick Close Flow** — quick items have no menu
  (the action is unambiguous: try to flip to shipped; offer Drop
  only if the PR is closed unmerged).

**Step 1 — Ask what kind of close.**

Read the target's current `status:` first; the menu options are
conditional on that.

For **Plans**:

| Plan status | Menu options |
|---|---|
| `draft` | *Leave in draft (no-op)* / *Reject* |
| `approved` | *Reject* (no pass — Plan hasn't been delivered yet) |
| `delivering` | *Reject* (no pass — Plan hasn't been evaluated) |
| `evaluating` | *Reject* (no pass — Plan hasn't shipped) |
| `shipping` (with `PR opened:` and no `Shipped` line) | *Pass — finalise as shipped (requires merged PR)* / *Reject* |
| `shipped` / `rejected` | abort: *"Plan `<id>` is already `<status>`. Terminal means terminal."* |

For **Scopes**:

| Scope status | Menu options |
|---|---|
| `scoped` / `planning` (no Plans started) | *Abandon* (no pass — nothing to roll up) |
| `delivering` / `evaluating` / `shipping` | *Pass — roll up to done (requires every Plan terminal; mixed-terminal aware)* / *Abandon* |
| `done` / `abandoned` | abort: *"Scope `<id>` is already `<status>`."* |

For **Projects**:

| Project status | Menu options |
|---|---|
| `active` | *Pass — archive (graceful sunset)* / *Abandon* |
| `archived` / `abandoned` | abort: *"Project `<slug>` is already `<status>`."* |

**Step 2 — Capture a reason (Reject / Abandon only).**

If the human picked *Reject* or *Abandon*, follow up with a
free-form prompt: *"Brief reason (one line) — why are you
[rejecting / abandoning]?"* The reason is **required**; pressing
through with an empty string re-prompts with: *"Rejecting /
abandoning needs a reason. The audit trail loses meaning without
one."*

**Step 3 — Route to the matching flow.**

- *Leave in draft (no-op)* → exit cleanly. Print *"Plan `<id>` left
  at `draft`. Run `/spades:approve` when ready."*
- *Pass* on a Plan → continue to **Plan Pass Flow** (the existing
  Pre-Flight + Steps 1–9 below; PR merge verification, bookkeeping
  PR, Scope rollup, Linear mirror).
- *Pass* on a Scope → continue to **Scope Roll-Up Flow** (new; see
  below). Mixed-terminal aware.
- *Pass* on a Project → continue to **Project Archive Flow** (new;
  see below).
- *Reject* on a Plan → continue to **Plan Reject Flow** (new; see
  below).
- *Abandon* on a Scope → continue to **Scope Abandonment Flow**
  (existing; below).
- *Abandon* on a Project → continue to **Project Abandonment Flow**
  (existing; below).
- Quick item (resolved at Step 0) → continue to **Quick Close
  Flow** (no Step 1 menu).

## Power-user Shortcuts

For automation, two flags skip Step 1's menu but still capture a
reason (Step 2):

- `/spades:close P-foo --reject "reason"` — skip to Plan Reject
  Flow. Reason is consumed; no second prompt.
- `/spades:close S-foo --abandon "reason"` — skip to Scope
  Abandonment Flow.
- `/spades:close <project-slug> --abandon "reason"` — skip to
  Project Abandonment Flow.

Invalid flag/target combos abort with a clear message:
- `--abandon` with a Plan ID → *"Plans use `rejected`, not
  `abandoned`. Use `--reject "reason"` instead."*
- `--reject` with a Scope or Project → *"Scopes and Projects use
  `abandoned`, not `rejected`. Use `--abandon "reason"` instead."*
- Either flag with no reason text → *"<flag> needs a reason. Re-run
  with `<flag> "reason text here"`."*

### Output format

This skill honours `review_format:` from `.spades/config` per
`docs/FRAMEWORK.md § Output Format (CLI vs HTML)`. Anywhere this
skill would today print the Plan being closed to the terminal, in
HTML mode auto-open the Plan's existing `.html` file via the
OPEN_CMD prelude. The bookkeeping-PR workflow, sync invocations,
and Linear mirror calls are identical between modes.

## Quick Close Flow

Reached when target is a Quick item (`Q-<slug>-<suffix>`). The
action is to verify the PR has merged and flip the marker to
`status: shipped`. No bookkeeping PR, no Scope rollup, no Linear
sub-issue handling — quick items are deliberately lightweight (see
`docs/FRAMEWORK.md § Fast-Track Path`).

### Pre-Flight

1. **Confirm setup + active project.** Read `.spades/config`. Abort
   otherwise.
2. **Read the marker file** at `.spades/quick/<Q-id>.md`. Capture:
   - `id`, `pr_url`, `branch`, `linear_issue_id`, `status`.
   - Reject if `status: shipped` — already terminal. Print:
     *"Quick item `<Q-id>` is already `shipped`. Terminal means
     terminal."*
3. **Confirm `scm: github`.** If `scm: local-git` (or anything
   else), the merge probe doesn't apply — abort with:

   > *`/spades:close Q-<id>` is meaningful for `scm: github`.
   > Local-git quick items reach shipped inside `/spades:quick`
   > itself (single-phase). Nothing to close out.*

   *(Note: future SCM drivers may extend this; see
   `docs/EXTENDING-SCM.md`.)*
4. **Open the marker (HTML mode only).** When `review_format: html`,
   run the OPEN_CMD prelude and open `.spades/quick/<Q-id>.html` if
   it exists. In CLI mode, print the marker's title and `pr_url`
   inline.

### Step 1 — Probe the PR state

Parse the PR number from `pr_url` (last `/pull/<n>` segment).
Query GitHub:

```bash
gh pr view <n> --json state,mergeCommit,mergedAt,mergedBy
```

The probe has **two outcome classes** — distinguish them before
branching on `state`. A failed probe is NOT the same signal as a
non-merged PR, and must never trigger the Drop path. Drop deletes
the marker; on a transiently-failed lookup that would destroy the
canonical record of work that may have shipped.

**Outcome A — probe failure (auth, network, malformed response).**

If `gh` exits non-zero, JSON parse fails, or any required field is
missing (`state` null or absent, `mergeCommit.oid` missing when
`state: MERGED`), **abort cleanly** — do NOT offer Drop. Print:

> *Couldn't query PR `<pr_url>` — `gh` returned an error or
> incomplete data. Re-run `/spades:close Q-<id>` after fixing the
> underlying issue (check `gh auth status`, network, GitHub rate
> limit). The marker is untouched at `status: shipping`.*

**Outcome B — probe succeeded.** Branch on `state`:

- **`MERGED`** → continue to Step 2 (flip to shipped).
- **`OPEN`** → the PR is still open. Tell the human; ask via
  `AskUserQuestion`:
  - *Wait — exit and come back later* (recommended)
  - *Drop the quick item* (delete marker; quick items have no
    abandoned state, the file is just removed)
  
  On *Wait* → exit cleanly. On *Drop* → continue to Step 3 (drop).
- **`CLOSED`** (closed without merging) → the PR is dead, but the
  work itself may have shipped under a different PR (force-replace
  pattern: original PR closed, replacement PR opened on a different
  branch and merged). Surface that possibility *before* offering
  Drop. Ask via `AskUserQuestion`:
  - *Update PR — the work shipped under a different PR* (see the
    Update PR sub-flow below; the marker's `pr_url` is rewritten
    only after the replacement URL is verified reachable)
  - *Drop the quick item* (delete marker — the work is genuinely
    gone)
  - *Cancel* — exit without changes
  
  On *Update PR* → enter the sub-flow. On *Drop* → continue to
  Step 3. On *Cancel* → exit.

  **Update PR sub-flow.** The marker is read-only until the probe
  against the replacement URL succeeds; this is the validate-before-
  write contract that lets the outer abort message in Outcome A
  truthfully promise *"the marker is untouched"*.
  
  1. Prompt for the replacement PR URL via a free-form follow-up.
  2. Validate the input *before* touching the marker:
     - Must parse as a GitHub PR URL pointing at the same `owner/repo`
       as the current `pr_url`. If not, re-prompt with a short error
       (*"Replacement must be a PR under `<owner>/<repo>` — try again
       or pick Cancel."*).
     - Must NOT be byte-equal to the current `pr_url`. If it is,
       re-prompt with *"That's the same URL — paste a different
       replacement, or pick Cancel."* (No marker write yet.)
  3. **Probe the replacement URL inline** with the same `gh pr view
     <new-n> --json state,mergeCommit,mergedAt,mergedBy` call used in
     Step 1. Do NOT rewrite `pr_url` before this probe completes.
     - **Probe failure on the replacement** (gh non-zero / JSON parse
       error / missing fields) → the marker has not been touched, so
       offer a tailored retry via `AskUserQuestion`:
       - *Try a different URL* — re-enter the sub-flow at step 1.
       - *Cancel* — exit without changes.
       
       Print the tailored message:
       
       > *Couldn't reach `<new-url>` — `gh` returned an error or
       > incomplete data. The marker is untouched at
       > `status: shipping`. Try a different URL, or Cancel and re-run
       > `/spades:close Q-<id>` later.*
       
       Drop is intentionally NOT offered here — the human can return
       to the outer CLOSED menu by Cancelling and re-running the
       skill, where Drop is reachable against the original (probe-
       confirmed CLOSED) PR.
     - **Probe success on the replacement** → rewrite `pr_url` on the
       marker to the replacement URL (this is the first marker write
       in the sub-flow), then dispatch on the new `state` exactly as
       in Step 1: `MERGED` → Step 2; `OPEN` → Wait/Drop menu;
       `CLOSED` → re-enter this outer CLOSED handler (Update PR /
       Drop / Cancel). The marker now records the URL we have
       evidence for; the original URL survives in the audit-trail
       `PR opened:` line written by `/spades:quick`.

### Step 2 — Flip to shipped

Update `.spades/quick/<Q-id>.md`:

- Frontmatter: `status: shipping` → `status: shipped`;
  `updated: <today>`.
- Append to the `## Audit Trail` section:

  ```markdown
  - YYYY-MM-DD: Shipped (github). PR: <pr_url>. Merge: <merge-sha>. Merged by: <login>.
  ```

  The grammar matches the canonical Plan-close Shipped line so
  every `Shipped` audit-trail entry across the framework is
  parseable the same way.

If HTML mode and `.spades/quick/<Q-id>.html` exists, re-render
it via the bundled template (or append the audit-trail line to
the existing HTML, matching the .md). Marker is the
source-of-truth; the HTML is the human-readable mirror.

### Step 3 — Drop (PR closed without merging)

Delete the marker file at `.spades/quick/<Q-id>.md` (and the
`.html` companion if present). Git history records the delete;
no other audit-trail entry is needed.

Print a single confirmation line:

> *`Q-<id>` dropped. PR was closed without merging; marker
> deleted. Git history records the trace.*

### Step 4 — Linear mirror (when `backend: linear`)

If `linear_issue_id` is present in the marker (and the marker
existed before Step 3 deleted it — capture the ID first):

- On Step 2 flip: move the Linear issue from In Review → Done.
  Post a comment: *"Merged via `/spades:close Q-<id>`. Merge:
  `<merge-sha>` by `<login>`."*
- On Step 3 drop: move the Linear issue from In Review → Cancelled
  (or Backlog, if your team uses that for not-done-not-failed).
  Post a comment: *"Quick item dropped — PR closed without
  merging."*

### Step 5 — Confirm

Print one line in CLI mode (HTML mode: the marker's `.html` is
already updated):

- On flip: *`✓ Q-<id> shipped. Merge: <merge-sha>.`*
- On drop: *`✓ Q-<id> dropped.`*

No commit, no PR, no Scope rollup. Quick items are leaf nodes —
they don't have parents in the audit-trail sense.

## Plan Pass Flow — Pre-Flight + Steps 1–9

Reached when target is a Plan in `status: shipping` and the human
picked *Pass* (or invoked bare `/close P-foo` with a merged PR
detected).

### Pre-Flight

**Prerequisite — post-merge git state.** Run `/repo:sync` before
`/spades:close` so the local checkout is on a fast-forwarded `main`
with the merged feature branch deleted. Close enforces branch +
fast-forward state in step 4 below; it does not auto-sync.


1. **Confirm setup + active project.** Read `.spades/config`. Abort
   otherwise.
2. **Confirm `scm: github`.** If `scm: local-git` (or anything else),
   abort with:

   > *`/spades:close` is only meaningful for `scm: github`. Local-git
   > is single-phase — Plans go straight to `shipped` inside
   > `/spades:ship`. Nothing to close out.*

3. **Confirm the `repo` plugin is installed.** Probe:

   ```bash
   [ -d "$HOME/.claude/plugins/cache/ai-skills/repo" ] && echo found || echo missing
   ```

   If `missing`, abort with:

   > *`/spades:close` requires the `repo` plugin from the `ai-skills`
   > marketplace (for `/repo:sync` and `/repo:branch`). Re-run
   > `/spades:setup` — it walks through installing the prerequisite
   > plugins.*

4. **Precondition checks — local state is post-merge-clean.**

   - Current branch:

     ```bash
     git rev-parse --abbrev-ref HEAD
     ```

     Must be `main` (or whatever the default branch is). If not,
     abort with: *"Run `/repo:sync` first — `/spades:close` expects
     to start on `main` after the merged feature branch has been
     cleaned up."*

   - Working tree may be dirty — no precondition check. The sweep
     at Step 3.3 picks up SPADES-owned paths.

   - Local `main` is fast-forwarded to origin:

     ```bash
     git fetch origin --quiet
     git rev-list --count main..origin/main
     ```

     Must return `0`. If not, abort with: *"Local `main` is behind
     `origin/main`. Run `/repo:sync` first."*

   These checks are minimal on purpose. `/spades:close` doesn't
   duplicate `/repo:sync`; it just refuses to run if the
   preconditions `/repo:sync` would have satisfied aren't already
   met.

5. **Resolve the target Plan** per `docs/FRAMEWORK.md` § Target
   Resolution. This skill's parameters:
   - **Artefact type:** Plan (no type-question needed).
   - **Status filter:** `status: shipping` AND audit trail contains a
     `PR opened:` line AND no later `Shipped` line.
   - **Zero-candidate suggestion:** `/spades:ship P-…` to open a ship
     PR for an evaluated Plan first.

   If exactly one candidate matches and the human passed no Plan ID,
   pick it silently and announce. Otherwise, run the interactive
   picker.
6. **Read the Plan and parent Scope.** Capture:
   - `plan_id`, `plan_id_lower` (lowercased), `plan_slug`,
     `scope_id`, `project_slug`.
   - The PR URL from the most recent `PR opened:` line in the Plan's
     audit trail.
7. **Verify ancestors active** per `docs/FRAMEWORK.md § Target
   Resolution → Parent-status precondition`. If the parent Scope is
   `abandoned`, or its parent Project is `abandoned` / `archived`,
   abort hard with the canonical error shape. No override. (The
   Reject and Abandon flows below are exempt — they *create*
   terminal status; only the Pass route is gated.)
8. **Open the artefact (HTML mode only).** Read `review_format:`
   from `.spades/config`. When `review_format: html`, run the
   OPEN_CMD prelude (`docs/FRAMEWORK.md § OPEN_CMD detection
   prelude`) and open the Plan's `.html`. **In HTML mode the open
   `.html` IS the review surface — do NOT also paste / summarise
   the Plan body or audit trail to the CLI; the human has the
   browser tab.** Short conversational text (bookkeeping-PR
   progress, the final `✓ Plan closed …` confirmation, error
   messages) stays CLI as today. In CLI mode, summarise the Plan
   inline as today. See `docs/FRAMEWORK.md § Output Format → What
   counts as review-form text` for the canonical line.

## Step 1 — Verify the ship PR is merged

1. Parse the PR number from the captured URL (last `/pull/<n>`
   segment).
2. Query GitHub:

   ```bash
   gh pr view <n> --json state,mergeCommit,mergedAt,mergedBy
   ```

3. **Probe failure handling.** If `gh` exits non-zero, JSON parse
   fails, or any required field is missing (`state` null or
   absent, `mergeCommit.oid` missing when `state: MERGED`), abort
   cleanly with:

   > *Couldn't query PR `<URL>` — `gh` returned an error or
   > incomplete data. Re-run `/spades:close <plan_id>` after
   > fixing the underlying issue (check `gh auth status`, network,
   > GitHub rate limit). The Plan is untouched at `status:
   > shipping`.*

   The Plan Pass Flow does no destructive writes before Step 2, so
   a probe failure here is purely a re-runnable error — but
   surfacing the remediation explicitly stops humans guessing.

4. **Branch on `state`** (probe succeeded):
   - `MERGED` → capture `mergeCommit.oid` (full SHA),
     `mergedBy.login`, `mergedAt`. Continue.
   - `OPEN` → tell the human the PR is still open. Show CI/review
     status if surfaced by `gh pr view`. Ask via `AskUserQuestion`:
     - *Wait — re-run later (exit, do nothing)*
     - *Abort — exit without changes*
   - `CLOSED` (not merged) → surface the state and exit with a
     pointer to the Reject flow: *"PR `<URL>` is closed without
     merge. The Plan can't pass — re-run as `/spades:close
     <plan_id> --reject "reason"` to mark the Plan rejected, or
     re-open the PR on GitHub to retry the merge."* The skill does
     not silently switch flows; the human picks Reject explicitly.

   On any non-MERGED state, exit before Step 2 — nothing has changed.

## Step 2 — Create the bookkeeping branch

Branch off `main` for the bookkeeping commit (commits on `main`
are forbidden — `/repo:branch` enforces this). Any uncommitted
changes ride onto the new branch; Step 3.3's sweep picks the
paths to stage.

### 2.1 Choose the branch name

The branch name MUST match the `/repo:branch` regex:

```
^(feat|fix|chore|docs|refactor|rnd|hotfix)/[a-z0-9]([a-z0-9-]{0,48}[a-z0-9])?$
```

Strategy:

1. Try `chore/close-<lower(plan_id_without_P_prefix)>`. Example:
   `chore/close-rag-pipeline-lookup-3hyd`.
2. If the slug exceeds 50 chars (chained Plan IDs can run long),
   fall back to `chore/close-<lower(suffix-chain-only)>`. Example:
   `chore/close-9xaz-3hyd-28sd`.
3. If a local branch with that name already exists (a previous
   `/spades:close` run aborted mid-flight), abort with:

   > *Bookkeeping branch `<name>` already exists from a previous
   > run. Either merge its PR on GitHub then re-run `/spades:close`,
   > or delete it (`git branch -D <name>`) and re-run.*

### 2.2 Create the branch

```bash
git switch -c <bookkeeping-branch>
```

## Step 3 — Apply the close-out edits

### 3.1 Edit the Plan file

Locate `.spades/plans/<plan_id>.md` (local mode) — or, for Linear
backend, edit the local mirror under `.spades/plans/` that the other
skills maintain. Update:

- Frontmatter `status:` → `shipped`.
- Frontmatter `updated:` → today's date.
- Append to the `## Audit Trail` section:

  ```markdown
  - YYYY-MM-DD: Shipped (github). PR: <URL>. Merge: <merge-sha>. Merged by: <login>.
  ```

### 3.2 Edit the Scope file (mixed-terminal aware rollup)

Read every sibling Plan under `scope_id` (counting this one as
already `shipped`). Classify each:

- `shipped` — terminal, success.
- `rejected` — terminal, abandoned (a prior explicit decision).
- Anything else (`draft`, `approved`, `delivering`, `evaluating`,
  `shipping`) — still in flight.

Rules:

- **Every sibling is `shipped`** → roll up silently. Update
  `.spades/scopes/<scope_id>.md` frontmatter `status:` → `done`,
  `updated:` → today. Append to the Scope's `## Audit Trail`:
  ```markdown
  - YYYY-MM-DD: All plans shipped. Scope done.
  ```

- **Every sibling is terminal (mix of `shipped` and `rejected`) and at
  least one is `shipped`** → ask the human to acknowledge via
  `AskUserQuestion`, listing the rejected siblings so the
  acknowledgement is informed. If they accept, update the Scope
  frontmatter and append:
  ```markdown
  - YYYY-MM-DD: All plans terminal. Shipped: <n>. Rejected: <m>
    (acknowledged: P-<id-1>, P-<id-2>). Scope done.
  ```
  If they decline, leave the Scope unchanged and record a deferred
  rollup line in the Plan's audit trail.

- **Every sibling is `rejected` (no `shipped`)** → no rollup; the
  Scope didn't ship anything. Surface and stop short of the rollup
  edit. The Plan close-out itself still proceeds.

- **At least one sibling still in flight** → no rollup; leave the
  Scope unchanged — sibling Plans still in flight.

### 3.3 Stage + commit

Sweep SPADES-owned paths, then commit. Allowlist only — never
`git add -A` / `git add .`:

```bash
git add -- .spades AGENTS.md INTENT.md ARCHITECTURE.md PATTERNS.md ANTI-PATTERNS.md 2>/dev/null || true
```

If the sweep added paths beyond the Plan / Scope frontmatter
edits, list them in the commit body:

```bash
git commit -m "$(cat <<'EOF'
chore(spades): close <plan_id>

Records the Shipped marker for <plan_id> on main. Original PR:
<URL>. Squash-merge: <merge-sha> by @<login>.

Scope <scope_id> rolled up to `done`.   # omit if not rolled up

Outstanding bookkeeping swept up:
- <path-1>
- <path-2>
…
# omit the "Outstanding bookkeeping" block if the sweep added nothing
EOF
)"
```

## Step 4 — Open the bookkeeping PR

```bash
git push -u origin <bookkeeping-branch>
```

```bash
gh pr create --title "chore(spades): close <plan_id>" --body "$(cat <<'EOF'
## Summary

Bookkeeping commit — records the SPADES audit trail for <plan_id>
on `main` after its ship PR was squash-merged.

## Linked artefacts

- Plan:        `<plan_id>`
- Scope:       `<scope_id>`
- Ship PR:     <URL>
- Merge SHA:   <merge-sha>
- Merged by:   @<login>

## Files touched

- `.spades/plans/<plan_id>.md` — `status: shipped`, audit entry.
- `.spades/scopes/<scope_id>.md` — `status: done`, audit entry.   # omit if not rolled up
- <swept-path-1>, <swept-path-2>, …                               # omit if nothing swept

No code changes. Pure audit trail (plus any outstanding SPADES
bookkeeping swept up from a dirty worktree).
EOF
)"
```

Capture the bookkeeping PR URL. Print it prominently:

```
○ Bookkeeping PR opened: <bookkeeping-pr-url>
○ Merge it on GitHub — squash recommended — then return here.
```

## Step 5 — Wait for the human to confirm the merge

Ask via `AskUserQuestion`:

> *Has the bookkeeping PR been merged?*
>
> - **Yes — bookkeeping PR is merged.** Continue with cleanup.
> - **Not yet — exit, I'll merge it and re-run `/spades:close`.**

If **Not yet** → exit cleanly. The bookkeeping PR stays open. After
the human merges it on GitHub, the recovery path is to run
`/repo:sync` (cleans up the merged bookkeeping branch) — at that
point the close-out is fully complete; no need to re-run
`/spades:close` unless the human still wants Linear mirroring or a
learning prompt.

## Step 6 — Post-bookkeeping cleanup

After the human confirms the bookkeeping PR is merged:

```bash
git checkout main
git pull --ff-only
git branch -D <bookkeeping-branch>
```

Assert clean:

```bash
git status --porcelain
```

If anything shows, surface it but don't abort — we've done the work,
the human can clean residue.

## Step 7 — Linear mirror (when `backend: linear`)

This step runs only after the bookkeeping commit is on `main` —
Linear is the live source of truth and should never lead the audit
trail.

When `backend: linear`:

- Update the Plan's sub-issue → status `Done`.
- If every sub-issue under the parent Scope's parent Issue is now
  `Done`, update the parent Issue → `Done`.
- Post a comment on the sub-issue:

  > *Shipped. PR: `<URL>` (squash-merge `<merge-sha>` by `@<login>`).
  > Bookkeeping audit: `<bookkeeping-pr-url>`.*

When `backend: local`: nothing to mirror. Local mode's source of
truth is the file on `main`, already updated by Step 4's bookkeeping
merge.

## Step 8 — Suggest a Learning

Same hand-off as `/spades:ship` Step 4. Ask via `AskUserQuestion`:

- **Capture a learning** (recommended) — invokes `/spades:learn`
- **Skip** — no learning this time

If yes, hand off to `/spades:learn` with the plan ID as context. The
learning will be tagged and stored under `.spades/learnings/`.

## Step 9 — Confirm

One-block summary:

```
✓ Ship PR merged:        <URL>  (merge <short-sha> by @<login>)
✓ Bookkeeping PR merged: <bookkeeping-pr-url>
✓ Plan shipped:          <plan_id>
✓ Scope:                 <scope_id> (done — all plans shipped)   # omit "done" line if not rolled up
✓ Linear mirror:         sub-issue Done, parent Issue Done       # omit when backend: local
✓ Working tree:          clean, on main
✓ Status:                shipped

Next:
  /spades:learn                            — capture a learning
  /spades:status                           — see what's still open
```

## Plan Reject Flow

Reached when target is a Plan in `approved`, `delivering`,
`evaluating`, or `shipping`, and the human picked *Reject* (or
invoked `/close P-foo --reject "reason"`). Plans in `draft` use
*"leave in draft (no-op)"* from the menu — no skill action needed.

A reject is a Plan rollback. The Plan stays as a leaf state on its
own track; sibling Plans and the parent Scope are unchanged.

### R1. Pre-Flight
1. **Confirm setup + active project.** Read `.spades/config`. Abort
   otherwise.
2. **Confirm `scm: github`** if the Plan has any audit-trail markers
   from `/spades:do` (a feature branch may exist that needs the
   `/repo` workflow). For `scm: local-git` and no SCM markers,
   skip; the human edits the file directly if they prefer.
3. **Confirm `/repo` plugin + post-merge git state** — same checks
   as the Plan Pass Pre-Flight (clean `main`, fast-forwarded with
   `origin/main`).
4. **Resolve the Plan** and read its current `status:`. Refuse if
   already `shipped` or `rejected`.
5. **If the Plan's audit trail has a `PR opened:` line with no
   later `Shipped`**, query GitHub for the PR state and surface it
   to the human: *"PR `<URL>` is currently `<state>` (open/closed/
   merged). Rejecting will mark the Plan rejected but won't close
   the PR — close it on GitHub if you haven't already."* This is
   purely informational; the rejection proceeds either way.

### R2. Create the bookkeeping branch
- Branch name: `chore/reject-<lower(plan-slug-without-P-prefix)>`,
  truncate to 50 chars; validate against `/repo:branch` regex.
- `git switch -c <bookkeeping-branch>`.

### R3. Edit the Plan file
- Frontmatter `status:` → `rejected`.
- Frontmatter `updated:` → today's date.
- Append to `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: Rejected. Reason: <reason>.
  ```

### R4. Stage + commit + open bookkeeping PR
- `git add .spades/plans/<plan_id>.md`
- Commit message: `chore(spades): reject <plan_id>` with body
  *"Records rejection of Plan `<plan_id>`. Reason: `<reason>`.
  Parent Scope unchanged; sibling Plans unchanged. See
  `docs/FRAMEWORK.md § Plan rejection — no cascade`."*
- Push, open PR with the same content.

### R5. Wait for human merge + cleanup
Same as Plan Pass Steps 5–6 (AskUserQuestion gate; post-merge
cleanup).

### R6. Linear mirror (when `backend: linear`)
- Update sub-issue → `Cancelled` (or team equivalent).
- Apply label `spades:rejected`.
- Comment: *"Rejected. Reason: `<reason>`. Bookkeeping PR: `<URL>`."*

### R7. Confirm
```
✓ Plan rejected:      <plan_id>
✓ Reason:             <reason>
✓ Bookkeeping PR:     <bookkeeping-pr-url>
✓ Linear mirror:      sub-issue Cancelled                    # omit when backend: local
✓ Sibling Plans:      unchanged (no cascade)
✓ Parent Scope:       unchanged

Next:
  /spades:plan S-<scope>     — draft a replacement Plan toward the same goal
  /spades:list               — see what else is active
```

## Scope Roll-Up Flow

Reached when target is a Scope in `delivering`/`evaluating`/
`shipping` and the human picked *Pass*. Uses the same mixed-terminal
rollup logic as the Plan Pass Flow's Step 3.2 — but standalone, so
the human can roll up a Scope explicitly (e.g. after a deferred
acknowledgement, or when child Plans reached terminal states out of
order).

### U1. Pre-Flight
1. **Confirm setup + active project.** Read `.spades/config`.
2. **Confirm `scm: github`** + post-merge git state — same checks.
3. **Resolve the Scope.** Refuse if `status:` is already `done` or
   `abandoned`.
4. **Read every sibling Plan** and classify (per Plan Pass Step 3.2
   rules): `shipped`, `rejected`, or still in flight.
5. **Decide the rollup:**
   - **Every Plan `shipped`** → proceed; rollup is unambiguous.
   - **Mix of `shipped` and `rejected`, ≥1 `shipped`** → prompt the
     human with the rejected siblings list (mixed-terminal ack).
     Proceed on confirmation.
   - **Every Plan `rejected`** → abort: *"Scope `<id>` has no
     shipped Plans. Roll-up to `done` doesn't apply. Use *Abandon*
     instead if you're walking away."*
   - **Any Plan still in flight** → abort: *"Scope `<id>` has Plans
     still in flight (<list>). Wait for them to terminate, or
     abandon the Scope."*

### U2. Create the bookkeeping branch
- Branch name: `chore/rollup-<lower(scope-slug-without-S-prefix)>`.

### U3. Edit the Scope file
- Frontmatter `status:` → `done`.
- Frontmatter `updated:` → today's date.
- Append to `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: All plans terminal. Shipped: <n>. Rejected: <m>[ (acknowledged: P-<id-1>, P-<id-2>)]. Scope done.
  ```

### U4–U7. Commit, PR, wait for merge, mirror, confirm
Same shape as Plan Pass Steps 4–7 with `chore(spades): rollup <S-id>`
commit/PR messaging. Linear mirror updates the parent Issue → Done.

## Project Archive Flow

Reached when target is a Project in `active` and the human picked
*Pass*. Archived is the graceful-sunset terminal state — distinct
from `abandoned` (see `docs/FRAMEWORK.md § Terminal States`).

### V1. Pre-Flight
1. **Confirm setup.** Read `.spades/config`.
2. **Confirm `scm: github`** + post-merge git state.
3. **Resolve the Project** by slug. Refuse if `status:` is already
   `archived` or `abandoned`.
4. **Check active child work.** If any Scope under this Project is
   still in flight (`scoped`/`planning`/`delivering`/`evaluating`/
   `shipping`), surface the list and ask via `AskUserQuestion`:
   - *Proceed anyway — archive the Project; in-flight Scopes stay
     at their current status (no cascade).*
   - *Abort — close the in-flight Scopes first.*

### V2. Create the bookkeeping branch
- Branch name: `chore/archive-project-<project-slug>`.

### V3. Edit the Project file
- Frontmatter `status:` → `archived`.
- Frontmatter `updated:` → today's date.
- Append to the Project's `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: Archived. Project lifecycle complete.[ Active child Scopes at archive: <list>.]
  ```

The reason text is **not required** for Archive (the action is
graceful sunset; the absence of a reason is itself the signal). If
the human wants to record a reason anyway, they can edit the
audit-trail line on the bookkeeping branch.

### V4–V7. Commit, PR, wait for merge, mirror, confirm
Same shape as Scope Abandonment Steps A4–A7, with `chore(spades):
archive <project-slug>` commit/PR messaging. Linear mirror updates
the Linear Project to `Completed` (or equivalent).

## Workflow integration with `/repo:sync`

The intended flow after a `/spades:ship` PR is squash-merged on
GitHub is:

1. `/repo:sync` — cleans up the local checkout (clean `main`,
   delete the merged feature branch).
2. `/spades:close P-<id>` — opens the bookkeeping PR, waits for
   merge confirmation, mirrors to Linear, suggests a learning.

A future enhancement to the `repo` plugin would have `/repo:sync`
auto-detect Plans in `status: shipping` with a `PR opened:` marker
on the just-merged branch and offer to chain into `/spades:close`
automatically. Until that lands, run the two skills in sequence.

## Scope Abandonment Flow

Reached when target is `S-<slug>` and `--abandon "reason"` is set.
See `docs/FRAMEWORK.md § Terminal States` for the contract.

### A1. Pre-Flight
1. **Confirm setup + active project.** Read `.spades/config`. Abort
   otherwise.
2. **Confirm `scm: github`.** If `scm: local-git`, abort with:
   *"`/spades:close --abandon` is only meaningful for `scm: github`.
   For local-git, edit the Scope file directly: set `status:
   abandoned` and append an audit-trail line."* (Symmetry with the
   Plan-close path; local-git is single-phase.)
3. **Confirm `/repo` plugin + post-merge git state** — same checks
   as Steps 3–4 of the Plan-close Pre-Flight (clean `main`, fast-
   forwarded with `origin/main`). Abort with `/repo:sync` pointer if
   any check fails.
4. **Resolve the Scope.** Read `.spades/scopes/<S-id>.md`. Abort if
   missing.
5. **Refuse if already terminal.** If `status:` is already
   `abandoned` or `done`, abort with: *"Scope `<S-id>` is already
   `<status>`. Terminal means terminal."*

### A2. Create the bookkeeping branch
- Branch name: `chore/abandon-<lower(scope-slug-without-S-prefix)>`
  (truncate to 50 chars if needed). Validate against `/repo:branch`
  regex.
- `git switch -c <bookkeeping-branch>`.

### A3. Edit the Scope file
- Frontmatter `status:` → `abandoned`.
- Frontmatter `updated:` → today's date.
- Append to `## Audit Trail`:

  ```markdown
  - YYYY-MM-DD: Abandoned. Reason: <reason>.
  ```

### A4. Stage + commit + open bookkeeping PR
- `git add .spades/scopes/<S-id>.md`
- Commit message: `chore(spades): abandon <S-id>` with body
  *"Records abandonment of Scope `<S-id>`. Reason: `<reason>`. No
  cascade — child Plans retain their current status; see
  `docs/FRAMEWORK.md § Terminal States`."*
- Push, open PR with the same content in the body.
- Print the PR URL prominently.

### A5. Wait for human merge + cleanup
Same as Plan-close Steps 5–6 (AskUserQuestion gate; post-merge
cleanup via `git checkout main && git pull --ff-only && git branch
-D <bookkeeping-branch>`).

### A6. Linear mirror (when `backend: linear`)
- Update parent Issue → status `Cancelled` (or the team's equivalent
  for "abandoned" — fall back to `Canceled`).
- Apply label `spades:abandoned` to the parent Issue.
- Post a comment: *"Abandoned. Reason: `<reason>`. Bookkeeping PR:
  `<URL>`. No cascade — child sub-issues unchanged; see
  `docs/FRAMEWORK.md § Terminal States`."*

### A7. Confirm
```
✓ Scope abandoned:      <S-id>
✓ Reason:               <reason>
✓ Bookkeeping PR merged: <bookkeeping-pr-url>
✓ Linear mirror:        parent Issue Cancelled                 # omit when backend: local
✓ Child Plans:          unchanged (no cascade)
✓ Status:               abandoned

Next:
  /spades:list all     — see abandoned Scopes alongside active
  /spades:status       — review remaining active work
```

## Project Abandonment Flow

Reached when target is `<project-slug>` and `--abandon "reason"` is
set. Identical shape to Scope abandonment with two differences:

1. Target file is `.spades/projects/<project-slug>.md`, not
   `.spades/scopes/<S-id>.md`.
2. Linear mirror updates the Linear *Project* (not an Issue) to
   `Canceled`/`Cancelled`. If the team doesn't have a project-level
   "cancelled" status, apply a `spades:abandoned` label on the
   project and surface the limitation to the human.
3. Branch name: `chore/abandon-project-<project-slug>` (truncate
   to 50 chars if needed).

Pre-Flight, edit, PR, mirror, confirm — all follow the Scope
abandonment shape. The audit-trail line is identical:

```markdown
- YYYY-MM-DD: Abandoned. Reason: <reason>.
```

No cascade to child Scopes (which keep their own statuses). The
project's `abandoned` is the authoritative signal.

## Edge Cases

- **Local state isn't post-merge-clean.** Pre-Flight refuses and
  points at `/repo:sync`. The boundary is deliberate — `/spades:close`
  doesn't duplicate sync logic.
- **Ship PR isn't merged.** Step 1 catches this; the skill exits
  before touching git or files. Re-run after merging.
- **Bookkeeping branch already exists.** Step 2.1 catches this;
  the human picks recovery (merge the PR or delete the branch).
- **Bookkeeping PR can't be merged (branch protection, required
  reviews).** The human merges by hand on GitHub, then selects
  *Yes* on Step 5's prompt. Or selects *Not yet*, fixes the
  protection issue, comes back later.
- **Plan was already shipped on `main`** (e.g. legacy
  `/spades:ship` Step 6 finalised it without the bookkeeping PR).
  The target resolver returns zero candidates; the skill exits
  saying so. The Plan is fine — the audit trail just lives in a
  prior commit.
- **Abandon target is already terminal.** Pre-Flight Step A5 / P5
  catches this; the skill aborts without touching files.
- **`--abandon` passed with a Plan ID.** Target-Type Routing
  catches this; the skill explains that Plans use `rejected` (via
  Approve/Evaluate gates), not `abandoned`.
