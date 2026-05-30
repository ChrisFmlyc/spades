# Ship driver — `scm: local-git`

This file is the local-git driver for `/spades:ship`. SKILL.md loads
it when `.spades/config` has `scm: local-git` and the Plan being
shipped is `deliverable_type: code`. It is not a skill on its own — it
has no frontmatter and is not invoked directly. Read it from SKILL.md,
follow the steps below, then return.

Single-phase. No PR system in front of `local-git`. Ship's job is just
to push (if a remote exists) and record the latest commit on the
branch as the shipment reference. Plan transitions to `shipped`
directly — there is no resume path.

## 1. Verify on the right branch

- `git rev-parse --abbrev-ref HEAD` — current branch
- If on `main` / `master`: error. `/spades:do` should have created a
  feature branch. Abort and suggest the human verifies what happened.
- Read the Plan's audit trail. Find the `Do phase started — branch:`
  line. If the current branch doesn't match, warn via
  `AskUserQuestion`:
  - *Use the current branch anyway (overrides the audit-trail branch)*
  - *Switch to the recorded branch and continue*
  - *Abort*

## 2. Pre-push checks

- Are there uncommitted changes? Surface them; ask via
  `AskUserQuestion` whether to commit (with a follow-up free-form
  message), stash, or discard before recording the shipment.
- Does the branch include commits that don't belong to this Plan? If
  so, surface them; ask whether to rebase / split or proceed.

## 3. Push (if a remote is configured)

```bash
git remote -v
```

- If a remote is configured (read the configured one from
  `.spades/config`'s `local_git.remote:` field, default `origin`):

  ```bash
  git push -u <remote> <branch>
  ```

  Record the push in the audit trail (with remote name + branch).
- If no remote is configured: skip the push, surface *"No remote
  configured — recording the local commit as the shipment reference."*
  in the report.

## 4. Capture the shipment reference

```bash
git rev-parse HEAD          # current commit SHA on the branch
git log -1 --format='%h %s' # short SHA + subject for the audit trail
```

## 5. Record and exit (single-phase)

Append to the Plan's audit trail:

```markdown
- YYYY-MM-DD: Shipped (local-git). Branch: <branch>. Commit: <sha>.
  Pushed to: <remote>/<branch>.    # omit this line if no remote
```

Plan → `status: shipped` directly. **Return to SKILL.md Step 3** to
finalise. No second phase, no resume.

## Edge cases (local-git-specific)

- **No remote and the human expected a push.** Surface the missing
  remote, suggest `git remote add origin <url>` (or set
  `local_git.remote:` in `.spades/config`), and re-run.
- **Push fails (auth, network, protected branch).** Show the exact
  error. The Plan stays in `shipping` — re-run after the human fixes
  the underlying cause. Do NOT mark the Plan shipped on a failed
  push.
