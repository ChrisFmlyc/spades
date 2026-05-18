---
name: spade-update
description: Check for and install SPADE framework updates. Use when someone says "update spade", "upgrade spade", "check for updates", "is spade up to date", or wants to pull the latest version of the framework and reinstall skills. Also handles per-version consumer-repo migrations through v1.7.0, including fragment marker re-stamping and INTENT.md scaffolding.
---

# SPADE Update

You are updating the SPADE framework to the latest version.

## Process

1. Run the following using the Bash tool to see what is new:

```bash
cd ~/.spade && git fetch origin && git log --oneline HEAD..origin/main
```

2. If there are new commits, show them and ask the human via
   **`AskUserQuestion`** (per `docs/FRAMEWORK.md` § "Asking the Human")
   with options *Pull updates* / *Skip*.

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

### v1.2.0 → v1.3.0 upgrade

**Fragment content changes in v1.3.0** — the consumer
`CLAUDE-section.md` fragment gains a `/spade-research` row in its
skill table. This means consumers must re-stamp their fragment block,
unlike v1.1.1 → v1.2.0 (which was version-pin-only).

The release ships:

- **A new skill `/spade-research`** — an Opus 4.7 subagent for
  landscape research with read-only tools (`Read`, `Grep`, `Glob`,
  `WebSearch`, `WebFetch`). Returns a structured findings document;
  optionally posts to a Linear parent issue with explicit human
  consent.
- **A new framework convention "Asking the Human"** — every SPADE
  skill that asks a fixed-option decision now uses Claude Code's
  structured `AskUserQuestion` tool rather than free-form prose.
  Skills retrofitted: `/spade-scope` (decision prompts only),
  `/spade-approve`, `/spade-evaluate`, `/spade-quick`, `/spade-learn`,
  `/spade-update`, `/spade-onboard`. The convention is documented in
  `docs/FRAMEWORK.md` § "Asking the Human". This is a **user-visible
  UX change**: prompts that previously read as plain text now appear
  as numbered choice lists.

**Consumer migration steps:**

In the consumer repo's working directory, run the same
`spade-marker-replace` recipe as v1.0.0 → v1.1.0 with `1.3.0`:

```bash
~/.spade/bin/spade-marker-replace \
  "$PWD/CLAUDE.md" \
  ~/.spade/fragments/CLAUDE-section.md \
  1.3.0

~/.spade/bin/spade-marker-replace \
  "$PWD/AGENTS.md" \
  ~/.spade/fragments/AGENTS-section.md \
  1.3.0

printf 'spade_version=1.3.0\n' > "$PWD/.spade/version"
```

The `AGENTS.md` re-stamp is optional in v1.3.0 — fragment content for
AGENTS-section did not change, so the helper will only re-stamp the
START marker version (idempotent, harmless to skip if you prefer).
The `CLAUDE.md` re-stamp **is** required for consumers to see the
`/spade-research` row in their skill table.

After the migration, suggest a commit:

```bash
git add CLAUDE.md AGENTS.md .spade/version
git commit -m "Update SPADE fragments to v1.3.0"
```

If the helper exits with code 2 or 3, **stop** and surface the error
to the human — same posture as the v1.0.0 → v1.1.0 recipe.

### v1.3.x → v1.6.0 upgrade

**Fragment content is unchanged in v1.6.0.** The release adds a new
HTML-rendering capability (`bin/spade-render` + `render/template.html`
+ `render/spade.css`) and updates `/spade-scope` and `/spade-plan` to
append a `View in browser: file://...` terminal link after every
local write. None of this changes the consumer fragments injected
into `AGENTS.md` / `CLAUDE.md`.

(Releases v1.4 and v1.5 are scoped in this repo but not yet shipped at
the time of v1.6 publication. Consumers upgrading from v1.3.x jump
directly to v1.6.0; once v1.4 and v1.5 ship, this section will be
re-paragraphed as `v1.5.x → v1.6.0`.)

Consumers **do not need** to re-stamp their fragment blocks for v1.6.0.
A consumer on v1.3.x who runs `/spade-update` to pull the framework
and re-run `~/.spade/setup` gets the updated skills globally; the
per-repo version pin can optionally be bumped to match:

```bash
printf 'spade_version=1.6.0\n' > "$PWD/.spade/version"
git add .spade/version
git commit -m "Pin .spade/version to 1.6.0"
```

If consumers prefer, they can re-stamp the marker block via the same
`spade-marker-replace` recipe with `1.6.0` in place of the prior
version — idempotent, content unchanged.

**Pandoc presence check.** `/spade-update` should probe for `pandoc`
after the framework pull and report its status to the human:

```bash
if command -v pandoc >/dev/null 2>&1; then
  echo "pandoc: $(pandoc --version | head -1) — HTML rendering enabled"
else
  echo "pandoc: not installed — HTML rendering will be skipped on every"
  echo "  scope/plan write until you install it:"
  echo "  brew install pandoc | apt install pandoc | winget install pandoc"
fi
```

This is informational only; the upgrade itself does not require
pandoc and **does not bulk-render historical** `.spade/scopes/*.md`
or `.spade/plans/*.md`. Existing files are rendered lazily on next
write only.

If the helper exits with code 2 or 3 during the fragment re-stamp,
**stop** and surface the error to the human — same posture as the
v1.0.0 → v1.1.0 recipe.

### v1.6.0 → v1.6.1 upgrade

**Fragment content is unchanged in v1.6.1.** The release is a patch:
it fixes `spade-render` on Pandoc 3.x (the v1.6.0 `render/template.html`
called non-existent Pandoc partials and failed with exit 3), gives the
rendered HTML an editorial redesign, repurposes the render lint from an
XSS/CSP scan into a render smoke test, and promotes the `/spade-scope`
render-and-link step to a mandatory closing step. Nothing that gets
injected into consumer `AGENTS.md` / `CLAUDE.md` moves.

Consumers **do not need** to re-stamp their fragment blocks for v1.6.1.
A consumer on v1.6.0 who runs `/spade-update` to pull the framework and
re-run `~/.spade/setup` gets the updated skills and renderer globally;
bump the per-repo pin to match:

```bash
printf 'spade_version=1.6.1\n' > "$PWD/.spade/version"
git add .spade/version
git commit -m "Pin .spade/version to 1.6.1"
```

The pandoc presence check from the v1.3.x → v1.6.0 recipe still applies.
If the helper exits with code 2 or 3 during a fragment re-stamp,
**stop** and surface the error to the human.

### v1.6.1 → v1.7.0 upgrade

**Fragment content changes in v1.7.0** — the consumer `CLAUDE-section.md`
fragment gains a `/spade-intent` row in its skill table. Consumers must
re-stamp their `CLAUDE.md` fragment block, as with v1.2.0 → v1.3.0.

The release ships:

- **A new root document `INTENT.md`** — the project's durable statement of
  intent (problem, users, what it does, success, non-goals, maturity). It is
  a reference document peer to `ARCHITECTURE.md`; the SPADE loop reads it to
  keep Scopes aligned with the project's purpose.
- **A new skill `/spade-intent`** — an interactive, human-composed /
  AI-structured conversation that creates or maintains `INTENT.md`.

**Consumer migration steps**, in the consumer repo's working directory:

1. Scaffold `INTENT.md` if the repo does not already have one —
   create-if-absent, never overwrite an existing file:

   ```bash
   [ -f "$PWD/INTENT.md" ] || cp ~/.spade/templates/INTENT.md "$PWD/INTENT.md"
   ```

   Then tell the human to run `/spade-intent` to fill it in. Do **not**
   AI-author its content — project intent is human-owned.

2. Re-stamp the fragment blocks and bump the version pin:

   ```bash
   ~/.spade/bin/spade-marker-replace \
     "$PWD/CLAUDE.md" \
     ~/.spade/fragments/CLAUDE-section.md \
     1.7.0

   ~/.spade/bin/spade-marker-replace \
     "$PWD/AGENTS.md" \
     ~/.spade/fragments/AGENTS-section.md \
     1.7.0

   printf 'spade_version=1.7.0\n' > "$PWD/.spade/version"
   ```

   The `CLAUDE.md` re-stamp **is** required — it adds the `/spade-intent`
   row to the consumer's skill table. The `AGENTS.md` re-stamp is optional
   (AGENTS-section content did not change in v1.7.0); the helper will only
   re-stamp the START marker version.

3. Migrate `.spade/config` to carry an explicit operating mode. v1.7
   (M-879) makes the canonical store — tracker or local files — a
   per-repo `mode:` setting rather than a framework default; see
   `docs/FRAMEWORK.md` § Operating Modes.

   Read the existing `.spade/config`. If it already has a `mode:`
   line, this step is a **no-op** — leave the file untouched and
   report it as already migrated. If it has **no** `mode:` line:

   - Derive the value **once** via the § Mode Resolver auto-detect
     rule: probe with a `list_teams` MCP call (try/skip, 5-second
     timeout); resolve `linear` if it returns a team set containing
     the config's `linear.team_id`, otherwise resolve `local`.
   - Insert the `mode:` line into `.spade/config`, written inside a
     delimited SPADE marker block so re-running the migration is
     detectable and idempotent — extend the existing
     `spade-marker-replace` mechanism the skill already uses for
     consumer-file writes (per the M-323 learning
     `.spade/learnings/2026-04-22-onboarding-must-be-idempotent.md`).
     **Never blind-append** the line.
   - The mode is chosen at **upgrade time** and persisted. Later
     skill runs read it directly and never re-derive it. Record in
     the change summary that the choice was made during this upgrade.

   The migration is **idempotent**: a config that already has `mode:`
   is left exactly as-is on a re-run, and the marker block guarantees
   a second run produces an unchanged file.

   **Existing `.spade/plans/*` files are grandfathered** — this step
   never rewrites, migrates, or deletes them. The local Plan archives
   stay readable as written; only `.spade/config` gains the `mode:`
   line.

After the migration, suggest a commit:

```bash
git add CLAUDE.md AGENTS.md INTENT.md .spade/config .spade/version
git commit -m "Update SPADE to v1.7.0; scaffold INTENT.md; set mode"
```

Print a summary of what the migration changed, for example:

```
v1.6.1 → v1.7.0 migration:
  ✓ CLAUDE.md fragment re-stamped to v1.7.0
  ✓ AGENTS.md START marker re-stamped to v1.7.0
  ✓ INTENT.md scaffolded (template — fill with /spade-intent)
  ✓ .spade/config — mode: local added (auto-detected at upgrade time)
  ! .spade/plans/* left untouched (grandfathered)
```

If `.spade/config` already carried a `mode:` line, the summary line
reads `! .spade/config already has mode: <value>, skipped` instead.

The pandoc presence check from the v1.3.x → v1.6.0 recipe still applies.
If the helper exits with code 2 or 3 during a fragment re-stamp, **stop**
and surface the error to the human — same posture as the v1.0.0 → v1.1.0
recipe.

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

Warn the human before running `rm -rf` and ask for explicit
confirmation via **`AskUserQuestion`** (per `docs/FRAMEWORK.md` §
"Asking the Human") with options *Confirm — wipe and reinstall* /
*Cancel*. Free-form "y/n?" prose is not acceptable here — the
command is destructive and the structured prompt makes the choice
unambiguous.
