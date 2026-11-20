# Extending SPADES with a New SCM Driver

SPADES ships three SCM (source-code-management) drivers: **GitHub**
(via the `gh` CLI), **GitLab** (via the `glab` CLI, on gitlab.com or a
self-managed instance) and **local-git** (no remote review system).
`docs/FRAMEWORK.md § SCM Drivers` lists them and the commands each
operation runs. Any other source code host with a CLI or API —
Bitbucket, Codeberg, Gitea, Azure Repos, AWS CodeCommit — can host
SPADES code deliverables if a driver is written against the contract
below.

This file is the contract. Adding an SCM means extending
`docs/FRAMEWORK.md` and the skills that publish code with a new
branch — not writing a binary or runtime plugin.

## What an SCM driver is

A driver is a section of prose telling Claude:

1. How to **probe** that the SCM tool is installed and authenticated
   (the equivalent of `gh auth status` for GitHub).
2. How to **install + authenticate** if the probe fails — packaged
   install commands per OS, the CLI's login, verification step.
3. How to **publish work** for a `deliverable_type: code` Plan —
   the per-driver Ship flow.
4. How to **record the shipment** in the Plan's audit trail.

The relevant skills select and read the driver's bundled Markdown
instructions.

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
- An auth step covering the ways the host's CLI and git can sign in —
  a browser (OAuth) login, a personal access token, SSH keys — with the
  human choosing. A token is entered at the CLI's prompt or on stdin,
  not on the command line, so it stays out of shell history.
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
  1. Resolve the Scope delivery worktree and verify its branch.
  2. Pre-push checks.
  3. Push to the configured remote.
  4. Open or reuse the Scope's shared PR/MR via the CLI
     (e.g. `glab mr create`, `bb pr create`) after all participating
     code Plans have a confirmed PASS.
  5. Record `PR opened: <URL>` (or `MR opened: <URL>`) in every
     participating Plan's audit trail.
  6. Exit; participating Plans stay `status: shipping`.
- **Phase 2 (finalise after merge)** — performed by
  `/spades:close P-<id>`, which lands the marker on `main` through
  a bookkeeping PR:
  1. `/spades:ship`, re-invoked on a `shipping` Plan with a
     `PR opened:` or `MR opened:` marker, reports the PR state and points at
     `/spades:close`.
  2. Close queries the PR/MR state via the CLI (e.g. `glab mr view`,
     `gh pr view`).
  3. On merged: capture the merge SHA, append `Shipped (<scm-name>).
     PR: <URL>. Merge: <sha>. Merged by: <login>.` (`MR:` where the
     host calls it a merge request) to each participating Plan's
     audit trail,
     mark those Plans `shipped`, apply the Scope roll-up checks,
     and commit via the bookkeeping PR.
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
  marks Phase 1 complete. `Shipped (<scm-name>). … Merge: <sha>.`
  marks Phase 2 complete.
- Single-phase drivers: `Shipped (<scm-name>). Commit: <sha>` is
  enough.

The `Shipped` marker MUST be present whenever the Plan transitions
to `status: shipped`. `/spades:status` and `/spades:list` rely on
this for the shipped-vs-shipping distinction.

## Adding a driver — the touchpoints

The GitLab driver is the reference two-phase implementation; read it
alongside this list. A new two-phase driver (`scm: bitbucket`, say)
touches:

1. **`.spades/config`** — a `<scm>:` block with `remote:` (default
   `origin`), documented in `docs/FRAMEWORK.md § .spades/config
   schema`, plus whatever the CLI needs to address the repository
   exactly. Neither `gh` nor `glab` follows the configured remote, so
   every command names the repository: the GitHub driver reads it from
   the remote's URL and passes it as `-R`, and the GitLab block records
   `host` and `project`. The GitLab block also lists `review_bots`, because
   GitLab marks no account as a bot.
2. **`docs/FRAMEWORK.md § SCM Drivers`** — a column in the
   review-request and issue operation tables, the `review_state`
   field mapping (state, merge SHA, merged by, merged at, head SHA),
   and a row in § The `Shipped` marker.
3. **`/spades:setup` Step 2** — an option, the probe, and the
   install + auth guide below; Step 7 writes the config block.
4. **`/spades:ship`** — a driver file `skills/ship/scm-<name>.md`
   mirroring `scm-github.md` / `scm-gitlab.md`, and its route in
   Step 3 A.
5. **`/spades:close`** and **`/spades:quick`** — they call the
   operations by name, so they need only the new `Shipped` line and
   any host wording (where to merge or re-open).
6. **`/spades:leads`** — an issue mirror row, its worker, and a
   `<scm>_issue:` field, when the host has issues.
7. **`/spades:loop`** — the host's thread sweep, merge readiness,
   deploy and FINISHED probes in `skills/loop/reference/`, and how
   review bots are handled when `/codereview:loop` doesn't support the
   host.
8. **`AGENTS.md`** and **`skills/setup/reference/agents-md-block.md`**
   — the SCM list under Phase 6 (Ship).
9. **Tests** — tag every command snippet with
   `<!-- scm-test: <name> -->` and add recorded-output cases under
   `tests/fixtures/scm/` for `scripts/test/scm-snippets.sh`, including
   the host's failure cases.
10. **Versions** — per `AGENTS.md` § Versioning, every changed skill
   and the plugin bump (additive: minor), plus `agents_version`.

The GitLab driver's probe, install guide and vocabulary, as a model:

- **Probe:** `glab auth status --hostname <host>` (non-zero exit → not
  ready), then `git ls-remote` on the remote, because SAML SSO can block
  git while the API works.
- **Install:** `brew install glab`; `winget install glab.glab`; the
  Linux packages in glab's installation options; and `jq`.
- **Auth:** `glab auth login --hostname <host>` — a browser login (on a
  self-managed instance, after `glab config set client_id <id> --host
  <host>` for its OAuth application) or a token with the `api` and
  `write_repository` scopes. Git uses SSH or HTTPS as the remote does;
  `--setup-git-credential-helper` lets an HTTPS remote use `glab`'s
  login. Verify with `glab auth status --hostname <host>`.
- **Vocabulary:** `MR opened:` instead of `PR opened:`, and
  `Shipped (gitlab). MR: …`; ship's resume step and close's picker
  detect both markers.

## GitLab compared with GitHub

The GitLab driver does everything the GitHub one does. Where GitLab
works differently, the driver does this:

| Area | GitHub | GitLab, and what the driver does |
|---|---|---|
| Choosing the repository | `gh` picks its own; commands pass `-R` with the repository read from `github.remote`'s URL | `glab` picks its own; commands name `gitlab.host` and `gitlab.project`, recorded at setup |
| Review bots | `[bot]` accounts | No bot flag on notes; only `gitlab.review_bots` count, matched by user ID, with an adapter per bot kind for "review finished" |
| A finished review | A review object | Notes only; CodeRabbit's commit status, Greptile's summary naming the head commit, or the newest discussion settling |
| Changes requested | A review state | A reviewer state; on Premium and above it blocks merging until approved, removed or bypassed |
| Merge SHA | `mergeCommit.oid` | `merge_commit_sha`, `squash_commit_sha` or `sha` by merge method; checked to be on the default branch |
| Merging | `gh pr merge --squash` | `--auto-merge=false --sha`; a project that forbids squashing pauses; a merge train is joined with auto-merge and polled |
| CI | Check runs | Pipelines and commit statuses; a bot's `external` pipeline doesn't count; a zero-job failure is linted for its errors |
| Draft | Bots skip drafts by default; `gh pr create` opens a ready PR | Bots skip draft MRs, and a `Draft:` title makes one; Ship never opens one |
| Push rejections | Rulesets, push protection (`GH013`, `GH009`) | Push rules (`remote: GitLab: …`), which can name commits older than the change |
| SAML SSO | The credential is authorised per organisation | Enforced on git and not the API: `glab` works while pushes fail, until the human signs in through SSO |
| Missing or hidden | 404 | 404 for both, reported as "not found, or not visible" |
| Issue close reason | `--reason` | None; a comment records it |
| Deployments | Filter by SHA | No SHA filter; recent deployments are matched, per environment |
| Closing issues | On merge | On merge into the default branch, while the project's auto-close setting is on |

A GitLab instance served under a path prefix (`https://host/gitlab/…`)
is not supported.

## Changing a flow

Every driver runs the same flows, so a change to one driver's flow is
checked against the others in the same PR (the repo-root `AGENTS.md`,
§ SCM drivers move together). Where each flow lives:

| Flow | Files | Per-driver part |
|---|---|---|
| Setup | `skills/setup/SKILL.md` Steps 2 and 7 | the option, probe, install guide and config block |
| Operation commands | `docs/FRAMEWORK.md § SCM Drivers` | a column per review host; local-git has none |
| Ship | `skills/ship/SKILL.md` Step 3 A | `scm-local-git.md`, `scm-github.md`, `scm-gitlab.md` |
| Quick | `skills/quick/SKILL.md` | a publish paragraph per driver |
| Close | `skills/close/SKILL.md`, `skills/close/reference/flow-*.md` | the `Shipped` line and the PR/MR URL check |
| Evaluate | `skills/evaluate/SKILL.md` | the shipped-state check |
| Loop | `skills/loop/SKILL.md`, `skills/loop/reference/*.md` | a section per review host; local-git doesn't run the loop |
| Leads | `skills/leads/SKILL.md` | an issue mirror per host with issues |
| Branch, PR, review bots | the `repo` and `codereview` plugins | a GitHub and a GitLab path in each skill |

Read the row for the flow you changed and open each driver's part.
Make the matching change where the step exists; where it doesn't, say
so in the PR description.

## Preserve the SCM contract

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
