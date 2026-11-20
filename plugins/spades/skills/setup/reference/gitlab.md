# Setup — the GitLab driver

`/spades:setup` Step 2 reads this file when the human chooses GitLab. It
returns three values for Step 7's `gitlab:` block — `host`, `project` and
`review_bots` — and stops with a remediation the human runs when a check
fails. Every check below runs again on the next `/spades:setup`.

Skills read the block verbatim. A GitLab project can live on gitlab.com or a
self-managed instance, in nested groups (`group/sub/project`), and the host
and path recorded here are the ones every GitLab command and check uses.

## 1. Host and project path from the remote

The remote is GitLab's remote as Step 2 resolves it. Read its URL with
`git remote get-url <remote>`. An HTTPS URL can carry `user:password@` before
the host: show any URL with that part replaced by `***@`.

- `https://[user[:password]@]<host>[:<port>]/<path>[.git]` — the host is
  what follows `://` and any `…@`, up to the first `/`, keeping a `:<port>`:
  the API is served on that port too.
- `ssh://[user@]<host>[:<port>]/<path>[.git]` — the host up to the first `:`
  or `/`; an SSH port says nothing about the web host, so drop it.
- `[user@]<host>:<path>[.git]` (the scp-style SSH form).
- An SSH host can be an alias from `~/.ssh/config`. Check it against
  `^[A-Za-z0-9._-]+$`, then resolve it with
  `ssh -G '<alias>' | awk '$1 == "hostname" { print $2 }'`.
  `altssh.gitlab.com` (gitlab.com's SSH-over-443 host) is `gitlab.com`.

The path is everything after the host (and port), without a leading `/` or a
trailing `.git`. It must match `^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)+$`. Any
other URL form (`http://`, `git://`, `file://`, a local path) stops setup:
name the form, not the URL.

## 2. `glab` and `jq`

```bash
command -v glab && command -v jq && glab auth status --hostname <host>
```

A non-zero exit means not ready. The GitLab probes in `/spades:loop` and
`/spades:close` pipe `glab api` output to `jq`, so both tools are required.
Give the human the steps for what is missing, then re-run `/spades:setup`:

1. **Install `glab`** — macOS: `brew install glab`. Windows:
   `winget install glab.glab`. Linux, as root: `dnf install glab` on Fedora;
   `apt install glab` on Debian and Ubuntu releases that package it. Where
   `apt` or `dnf` finds no `glab` package, the `.deb` or `.rpm` from
   <https://gitlab.com/gitlab-org/cli/-/releases> installs instead, and
   `brew install glab` works on any distribution. Other package managers are
   listed at
   <https://gitlab.com/gitlab-org/cli/-/blob/main/docs/installation_options.md>.
   **Install `jq`** — macOS: `brew install jq`. Windows:
   `winget install jqlang.jq`. Linux, as root: `apt install jq` on Debian and
   Ubuntu; `dnf install jq` on Fedora and RHEL.
2. **Sign in**, as the human, with whichever method they use:
   `! glab auth login --hostname <host>` offers a browser (OAuth) login or a
   token. A token needs the `api` and `write_repository` scopes. On a
   self-managed instance a browser login needs an OAuth application for
   `glab`, registered by an administrator, with its ID saved by
   `glab config set client_id <application-id> --host <host>`.
3. **Git** reaches the remote over SSH or HTTPS, with whatever credential
   git already uses there. For an HTTPS remote,
   `--setup-git-credential-helper` on the login lets git use `glab`'s
   login instead.
4. **Verify** with `glab auth status --hostname <host>`.

## 3. The project is visible

```bash
glab api --hostname <host> "projects/<path with each / written as %2F>" \
  | jq -r '[.id, .path_with_namespace, .default_branch] | @tsv'
```

`path_with_namespace` must equal the path from § 1, ignoring case; record
`gitlab.project` as GitLab spells it. GitLab answers 404 both for a project
that doesn't exist and for one this login cannot see, so a 404 reads: *"GitLab
has no project at `<host>/<path>` that `<username>` can see — check the remote
URL and the signed-in account (`glab auth status --hostname <host>`)."* A
GitLab served under a path prefix (`https://<host>/gitlab/…`) shows up here as
a 404 too; SPADES needs the instance at the root of its host.

## 4. Git can reach the remote

`glab` uses the GitLab API and git uses its own credential, and GitLab
enforces SAML single sign-on on them separately: the API can work while every
push fails. Check git directly:

```bash
git ls-remote --heads <remote> >/dev/null
```

On failure, show git's `remote:` lines and its `fatal:` line with any
`user:password@` replaced by `***@`, and the cause they show:

- **`Cannot find valid SSO session. Please login via your group's SSO at
  <url>`** — the group enforces SSO for git and the human's last SSO sign-in
  is more than a day old. They open `<url>` in a browser, sign in, and re-run
  `/spades:setup`. Over HTTPS, git may be offering a stored credential
  other than the one the human just refreshed; this tries `glab`'s login
  for one command:
  `git -c credential.helper= -c 'credential.helper=!glab auth git-credential' ls-remote --heads <remote>`.
- **`The project you were looking for could not be found or you don't have
  permission to view it`** — the § 3 wording.
- **Anything else** — show it as it is.

## 5. Review bots

GitLab marks no account as a review bot. `/codereview:loop` answers and
resolves threads only from the accounts listed here; every other author is a
person, whose threads pause `/spades:loop`.

Ask, multi-select: *"Which review bots post on `<project>`'s merge requests?"*
— **CodeRabbit**, **Greptile**, **GitLab Duo**, **None**. A bot typed under
*Other* uses the `generic` adapter. GitLab Duo always posts as `GitLabDuo`.
Ask in conversation for each other chosen bot's GitLab username — the
account its notes appear under on a reviewed MR, which the installer chose
(often `CodeRabbit`, or a project or group bot user named
`project_<id>_bot_…` or `group_<id>_bot_…`).

Check each username against `^[A-Za-z0-9._-]+$`, then that GitLab knows it:

```bash
glab api --hostname <host> "users?username=<username>" | jq 'length'
```

`1` → record it. `0` → show the username back and ask again.

| Choice | Entry |
|---|---|
| CodeRabbit | `{username: <answer>, kind: coderabbit}` |
| Greptile | `{username: <answer>, kind: greptile}` |
| GitLab Duo | `{username: GitLabDuo, kind: duo}` |
| Other | `{username: <answer>, kind: generic}` |
| None | `review_bots: []` |

Return `host`, `project` and `review_bots` to Step 7.
