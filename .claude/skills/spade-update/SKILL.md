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

After the migration, suggest a commit:

```bash
git add AGENTS.md CLAUDE.md .spade/version
git commit -m "Update SPADE fragments to v1.1.0"
```

### v1.1.0 → v1.1.1 upgrade

**Fragment content is unchanged in v1.1.1.** The release is a
version-pin-only bump that moves `.spade/version` and extends
`/spade-review` and `/spade-plan` skill prose — nothing that gets
injected into consumer `AGENTS.md` / `CLAUDE.md`.

Consumers **do not need** to re-stamp their fragment blocks for
v1.1.1. A consumer on v1.1.0 who runs `/spade-update` to pull the
framework and re-run `~/.spade/setup` already gets the updated skills
globally; the per-repo version pin can optionally be bumped to match:

```bash
printf 'spade_version=1.1.1\n' > "$PWD/.spade/version"
git add .spade/version
git commit -m "Pin .spade/version to 1.1.1"
```

If consumers prefer, they can run the same `spade-marker-replace`
command from the v1.0.0 → v1.1.0 recipe above with `1.1.1` in place
of `1.1.0` — the helper will re-stamp their marker version string
without changing the wrapped content. Both paths are equivalent;
choose based on whether the team wants the marker version to tick
alongside the repo's `.spade/version` pin.

The **underlying re-stamp mechanism** is tested by
`tests/onboard-idempotency.sh` Case 3 on the specific `v1.0.0 → v1.1.0`
transition, and the helper itself is version-agnostic by
implementation — its regex accepts any `X.Y.Z` version string and
re-stamping is idempotent by construction. A dedicated
`v1.1.0 → v1.1.1` fixture is **not** in the test suite: the first real
consumer invocation is the smoke test. If the helper misbehaves on a
real `v1.1.0 → v1.1.1` re-stamp, file a bug and we'll add a
parameterised fixture.

If the helper exits with code 2 or 3, **stop** and surface the error
to the human. Do not try to auto-fix the file — malformed markers
usually signal hand-editing that the human should review.

### v1.1.1 → v1.2.0 upgrade

**Fragment content is unchanged in v1.2.0.** The release is a
version-pin-only bump that introduces a **skill behaviour change** in
`/spade-plan`: from v1.2.0 onward, an approved Plan is stored
canonically in the tracker (Linear) when one is available, and
`.spade/plans/` becomes a fallback for Linear-less environments rather
than a default dual-write. Fragments do not discuss plan storage, so
nothing that gets injected into consumer `AGENTS.md` / `CLAUDE.md`
moves.

Consumers **do not need** to re-stamp their fragment blocks for
v1.2.0. A consumer on v1.1.1 who runs `/spade-update` to pull the
framework and re-run `~/.spade/setup` already gets the updated skills
globally; the per-repo version pin can optionally be bumped to match:

```bash
printf 'spade_version=1.2.0\n' > "$PWD/.spade/version"
git add .spade/version
git commit -m "Pin .spade/version to 1.2.0"
```

If consumers prefer, they can run the same `spade-marker-replace`
command from the v1.0.0 → v1.1.0 recipe with `1.2.0` in place of
`1.1.0` — the helper will re-stamp the marker version string without
changing the wrapped content. Both paths are equivalent; choose based
on whether the team wants the marker version to tick alongside the
repo's `.spade/version` pin.

**Existing `.spade/plans/*.md` files stay untouched.** v1.2.0 is
non-destructive: historical archives are preserved and remain readable
by any skill that needs to fall back to local storage. The framework
does not delete or migrate them; consumers who want to clean up may
do so manually but are not required to.

The first `/spade-plan` invocation after the upgrade exhibits the new
behaviour: if Linear MCP is available and the parent-issue comment
write succeeds, no `.spade/plans/<id>-plan.md` is written. If Linear
is unreachable, fails to accept the Plan, or the Scope has no tracker
parent, the fallback file is written with a banner line marking it as
a fallback artefact.

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

If `git log HEAD..origin/main` shows no commits, tell the human the
framework is already current. **Read the version from
`~/.spade/.spade/version`** — do not hard-code a version literal in
the message; the value moves with every release. Format the message
as `SPADE is up to date (v<version>).` where `<version>` is the
`spade_version=...` value read from that file. If the file is missing
or unreadable, fall back to a plain `SPADE is up to date.` without a
version.

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
