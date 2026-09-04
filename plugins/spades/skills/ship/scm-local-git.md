# Ship driver — `scm: local-git`

The local-git driver for `/spades:ship` Branch A (`deliverable_type:
code`). A resource file, not a skill: `/spades:ship` reads it when
`.spades/config` has `scm: local-git`, follows it, and takes control
back at Step 4.

Local git is a single-phase SCM: there is no review layer in front
of it. Ship pushes when a remote is configured, records the branch
commit as the shipment reference, and the Plan reaches `shipped` in
this run.

## 1. Verify the branch

```bash
git rev-parse --abbrev-ref HEAD
```

- On `main` / `master` → abort; `/spades:do` creates the feature
  branch, so the human checks what happened.
- Compare with the `Do phase started — … branch:` line in the Plan's
  audit trail. On a mismatch ask via `AskUserQuestion`: **Use the
  current branch anyway** / **Switch to the recorded branch and
  continue** / **Abort**.

## 2. Pre-push sweep

Per `docs/FRAMEWORK.md § Carry-Forward of SPADES-Owned Artefacts`:

```bash
git add -- .spades AGENTS.md INTENT.md ARCHITECTURE.md PATTERNS.md ANTI-PATTERNS.md 2>/dev/null || true
```

If anything was staged:

```bash
git commit -m "chore(spades): carry forward audit artefacts for <plan_id>"
```

Uncommitted files outside the allowlist stay the human's work in
progress and are named in one line. Commits that don't belong to
this Plan are surfaced for the human to decide on.

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
