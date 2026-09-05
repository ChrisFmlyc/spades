# Ship driver — `scm: local-git`

The local-git driver for `/spades:ship` Branch A (`deliverable_type:
code`). A resource file, not a skill: `/spades:ship` reads it when
`.spades/config` has `scm: local-git`, follows it, and takes control
back at Step 4.

Local git is a single-phase SCM: there is no review layer in front
of it. Ship pushes when a remote is configured, records the branch
commit as the shipment reference, and the Plan reaches `shipped` in
this run.

## 1. Verify the Scope worktree

Resolve the Scope branch through `/repo:newbranch --resume <branch>` per
`docs/FRAMEWORK.md § Scope Worktrees`. Use its returned directory. A
mismatched branch requires returning to the recorded worktree, not publishing
whichever checkout happens to be current.

## 2. Commit approved pending records

Follow `docs/FRAMEWORK.md § Carry-Forward → Commit contents`. Inspect the
complete index, include authorised pending records, and preserve excluded
staged/unstaged changes. Existing committed work is already part of this
branch's PR and needs no additional inclusion question. Unknown uncommitted
work needs the human's decision before adding it.

If approved records remain, commit them through `/repo:branch` with
`chore(spades): record audit artefacts for <scope_id>`.

## 3. Push when a remote exists

```bash
git remote -v
```

With a remote — the one named by `.spades/config`'s
`local_git.remote:` (default `origin`):

```bash
git push -u <remote> <branch>
```

Without one, report *"No remote configured — recording the local
commit as the shipment reference."* and continue.

## 4. Capture the reference

```bash
git rev-parse HEAD
git log -1 --format='%h %s'
```

## 5. Record and return

Append to the Plan's audit trail:

```markdown
- YYYY-MM-DD: Shipped (local-git). Branch: <branch>. Commit: <sha>.
  Pushed to: <remote>/<branch>.    # only when pushed
```

Return to `/spades:ship` Step 4, which sets `status: shipped` and
runs the Scope rollup.

## Edge cases

- **No remote, but the human expected a push** — suggest
  `git remote add origin <url>` or `local_git.remote:` in
  `.spades/config`, then re-run.
- **Push fails** (auth, network, protected branch) — show the exact
  error; the Plan stays at `shipping` and the run is repeated once
  the cause is fixed.
