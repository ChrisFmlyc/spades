# Extending SPADES with a New SCM Driver

SPADES v2.3 ships two SCM (source-code-management) drivers:
**GitHub** (via the `gh` CLI) and **local-git** (no remote PR
system). Any source code host with a CLI or API — GitLab,
Bitbucket, Codeberg, Gitea, Azure Repos, AWS CodeCommit — can host
SPADES code deliverables if a driver is written against the
contract below.

This file is the contract. Adding an SCM means extending
`docs/FRAMEWORK.md` and `/spades:setup` + `/spades:ship` with a new
branch — not writing a binary or runtime plugin.

## What an SCM driver is

A driver is a section of prose telling Claude:

1. How to **probe** that the SCM tool is installed and authenticated
   (the equivalent of `gh auth status` for GitHub).
2. How to **install + authenticate** if the probe fails — packaged
   install commands per OS, OAuth/PAT flow, verification step.
3. How to **publish work** for a `deliverable_type: code` Plan —
   the per-driver Ship flow.
4. How to **record the shipment** in the Plan's audit trail.

It is not a binary or a runtime plugin. SPADES skills are pure
Markdown; a driver lives as branches in the relevant SKILL.md files.

## Contract drivers must satisfy

### 1. Probe

A driver MUST define a probe command that:

- Returns success when the SCM tool is installed, authenticated,
  and reachable from the current shell.
- Returns failure otherwise.

Example (GitHub): `gh auth status` (zero exit → reachable).

`/spades:setup`'s SCM-selection step calls the probe. On failure,
the install guide runs instead of aborting.

### 2. Install guide

If the probe fails, the driver MUST present a per-OS install path
plus an auth step. Cover at minimum:

- macOS (Homebrew or equivalent native package manager)
- Linux (apt and dnf/yum at minimum; flatpak/snap if applicable)
- Windows (winget or choco)
- An auth step (OAuth via browser is strongly preferred over token
  paste — fewer credentials in shell history)
- A verification step the human runs after install + auth

The install guide format should mirror the existing Linear-MCP
guide in `skills/setup/SKILL.md` (numbered steps, concrete commands
per OS, "resume `/spades:setup`" at the end).

### 3. Ship flow

`/spades:ship`'s Branch A (`deliverable_type: code`) routes by
`scm:`. The driver MUST define one of two flow shapes:

#### Two-phase (PR / MR systems)

For SCMs with a review-and-merge layer (GitHub, GitLab, Bitbucket):

- **Phase 1 (fresh):**
  1. Verify the branch the Plan recorded in its audit trail.
  2. Pre-push checks.
  3. Push to the configured remote.
  4. Create the PR/MR via the CLI (e.g. `glab mr create`,
     `bb pr create`).
  5. Record `PR opened: <URL>` (or `MR opened: <URL>`) in the
     audit trail.
  6. Exit; Plan stays `status: shipping`.
- **Phase 2 (resume after merge):**
  1. Step 0 detects the resume via the `PR opened:` marker.
  2. Query the PR/MR state via the CLI (e.g. `glab mr view`,
     `gh pr view`).
  3. On merged: capture the merge SHA, append `Shipped. PR/MR:
     <URL>. Merge: <sha>` to the audit trail, mark Plan `shipped`.
  4. On still-open: report state, offer wait or abort.

#### Single-phase (no PR system)

For SCMs that don't gate via review (local-git is the canonical
example):

- Verify branch + pre-push checks.
- Push to remote if configured.
- Capture the current branch commit SHA.
- Append `Shipped (<scm-name>). Branch: <branch>. Commit: <sha>` to
  the audit trail.
- Plan → `status: shipped` directly. No second invocation needed.

### 4. Audit-trail format

The driver MUST use these markers so `/spades:ship`'s Step 0 can
detect resume state:

- Two-phase drivers: `PR opened: <URL>` (or `MR opened: <URL>`)
  marks Phase 1 complete. `Shipped. … Merge: <sha>` marks Phase 2
  complete.
- Single-phase drivers: `Shipped (<scm-name>). Commit: <sha>` is
  enough.

The `Shipped` marker MUST be present whenever the Plan transitions
to `status: shipped`. `/spades:status` and `/spades:list` rely on
this for the shipped-vs-shipping distinction.

## Adding a GitLab driver — worked example

Sketch of what `scm: gitlab` would require:

### 1. Extend `.spades/config`

Add a `gitlab:` block:

```yaml
scm: gitlab
gitlab:
  remote: origin
  host: gitlab.com    # or self-hosted GitLab URL
```

### 2. Document the probe

The GitLab CLI is `glab`. Probe:

```bash
glab auth status
```

### 3. Document the install guide

- macOS: `brew install glab`
- Linux (apt): see <https://gitlab.com/gitlab-org/cli> for the apt
  repo, then `sudo apt install glab`
- Windows: `winget install --id GitLab.cli`

Auth: `glab auth login` — browser flow preferred.

Verify: `glab auth status`.

### 4. Add the Ship branch

`/spades:ship`'s Branch A gains a sub-branch `A.gitlab` mirroring
`A.github`'s two-phase shape but using `glab mr create` and
`glab mr view`. Use `MR opened:` instead of `PR opened:` in the
audit trail to be honest about the SCM's vocabulary; Step 0 detects
both `PR opened:` and `MR opened:` as resume markers.

### 5. Update AGENTS.md + the setup fragment

Add `scm: gitlab` to the SCM list under Phase 6 (Ship) so consumer
repos see GitLab is supported.

### 6. Bump versions

Per `AGENTS.md` § Versioning: bump `ship` (minor — additive
sub-branch), bump `setup` (minor — new SCM option in the install
guide), bump the plugin (minor).

## Things a driver author should resist

- **Don't invent new SCM phases.** SPADES has one Ship phase, two
  flow shapes (single-phase, two-phase). A "review pending" or
  "approval-required" intermediate state isn't part of the
  framework — that lives inside the SCM's own UI.
- **Don't reshape the audit-trail markers.** Step 0's resume
  detection relies on `PR opened:` / `MR opened:` and `Shipped`.
  Pick one of those for your driver; don't invent a third.
- **Don't store credentials in `.spades/config`.** Tokens, SSH keys,
  API URLs with embedded auth — none of that belongs in the SPADES
  config. The SCM CLI's own credential store (`gh auth`,
  `glab auth`, OS keychain) handles authentication.
- **Don't bypass the branch-name regex.** `/repo:branch` enforces
  the prefix list and slug grammar; SPADES code-deliverable Plans
  use that regex too. Don't define a driver-specific naming scheme.
