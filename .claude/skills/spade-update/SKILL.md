---
name: spade-update
description: Check for and install SPADE framework updates. Use when someone says "update spade", "upgrade spade", "check for updates", "is spade up to date", or wants to pull the latest version of the framework and reinstall skills. Also handles the v1.0.0 → v1.1.0 fragment marker migration in consumer repos.
---

# SPADE Update

You are updating the SPADE framework to the latest version.

## Process

1. Run the following using the Bash tool to see what is new:

```bash
cd ~/.spade && git fetch origin && git log --oneline HEAD..origin/main
```

2. If there are new commits, show them and ask if the human wants to
   update.

3. If the human confirms (or did not need to be asked), run:

```bash
cd ~/.spade && git pull && ~/.spade/setup
```

4. Clear the update check cache so the next skill invocation sees a
   fresh state:

```bash
rm -f ~/.spade/.state/last-update-check
```

5. Report what was updated:
   - How many commits were pulled
   - Which skills were reinstalled
   - Any new skills that were added
   - Any new persona subagents under `.claude/agents/` (these exist in
     v1.1.0+)

## Consumer-repo migration: v1.0.0 → v1.1.0

When the global install moves from v1.0.0 to v1.1.0, consumer repos
keep their previously-injected fragment blocks at v1.0.0. Those blocks
need refreshing. Do this **per consumer repo** — the global update in
step 3 above does not touch consumer repos.

In the consumer repo's working directory, run:

```bash
# Refresh the SPADE-wrapped sections in AGENTS.md and CLAUDE.md from
# v1.0.0 to v1.1.0 using Bundle A's idempotent marker-replace helper.
~/.spade/bin/spade-marker-replace \
  "$PWD/AGENTS.md" \
  ~/.spade/fragments/AGENTS-section.md \
  1.1.0

~/.spade/bin/spade-marker-replace \
  "$PWD/CLAUDE.md" \
  ~/.spade/fragments/CLAUDE-section.md \
  1.1.0

# Update the per-repo version pin.
printf 'spade_version=1.1.0\n' > "$PWD/.spade/version"
```

The helper contract (from Bundle A) handles v1.0.0 → v1.1.0 cleanly:

| Existing state                          | Helper behaviour                                                   |
|-----------------------------------------|--------------------------------------------------------------------|
| v1.0.0 marker pair present              | Replace block in place, re-stamp START marker to v1.1.0            |
| No markers                              | Append new v1.1.0 block at end                                     |
| Mismatched / duplicate markers          | Exit 2 or 3; no modification — stop and ask the human to resolve   |

Running the migration twice produces an unchanged file on the second
run. That is tested by
`tests/onboard-idempotency.sh` (15 assertions including the v1.0.0 →
v1.1.0 re-stamp path).

If the helper exits with code 2 or 3, **stop** and surface the error
to the human. Do not try to auto-fix the file — malformed markers
usually signal hand-editing that the human should review.

After the migration, suggest a commit:

```bash
git add AGENTS.md CLAUDE.md .spade/version
git commit -m "Update SPADE fragments to v1.1.0"
```

## What is new in v1.1.0 (for the human)

When reporting a successful update, cover the new surface the consumer
gets access to:

- **`/spade-learn`** — capture learnings that future Plans will surface
  automatically. See `.claude/skills/spade-learn/SKILL.md`.
- **Multi-persona `/spade-review`** — five persona subagents replace
  the single-generalist reviewer. Invoke exactly as before; the panel
  runs in parallel and merges findings.
- **Execution posture** in Plan templates — every task now declares
  one of `test-first`, `characterization-first`, `refactor-first`,
  `spike`, `straight-through`.
- **CI lint suite** — `./scripts/lint/run-all.sh` runs five checks the
  framework uses on itself. Consumers can opt in by copying the
  workflow.

## If already up to date

If `git log HEAD..origin/main` shows no commits, tell the human:

```
SPADE is up to date (v1.1.0).
```

Read the current framework version from `~/.spade/.spade/version`
rather than hard-coding it here — the value moves with every release.

## If ~/.spade does not exist

Tell the human SPADE is not installed and show the install command:

```bash
git clone https://github.com/m-kopa/spade-framework.git ~/.spade
~/.spade/setup
```

## If ~/.spade is not a git repo

This can happen if the directory was created manually or corrupted.
Suggest a fresh install:

```bash
rm -rf ~/.spade
git clone https://github.com/m-kopa/spade-framework.git ~/.spade
~/.spade/setup
```

Warn the human before running `rm -rf` and get explicit confirmation.
