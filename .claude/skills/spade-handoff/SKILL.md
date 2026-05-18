---
name: spade-handoff
description: Hand an approved SPADE Plan off to a fresh CLI agent (Claude Code or Amp) in a new terminal window, so the planning session stays free and delivery runs in a separate, watchable context. Opt-in — dormant until /spade-onboard writes a handoff: block to .spade/config. Use when someone says "hand this off", "deliver this in Amp", "spawn an agent to deliver", "/spade-handoff <issue>", or wants delivery to run as a detached agent.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using the
Bash tool and show the output to the user if it is non-empty. If the script
does not exist or fails, skip silently and continue with the skill.

## Project Config

Read `.spade/config` in the current project directory. This file specifies
which Linear team, project, and default assignee to use, and — when the
project has opted in — the `handoff:` block this skill needs. If the file
does not exist, tell the human to run `/spade-onboard` first.

# SPADE Handoff

You are handing an approved Plan off to a fresh CLI agent that will
deliver it. The planning session — this one — stays free; delivery runs
in its own terminal window, in a separate context the human can watch.

This skill **spawns and detaches** the delivery agent. It does not
supervise, restart, or track it — the framework owns no long-lived
process. Delivery re-enters the SPADE loop the normal way: the spawned
agent opens a PR, and the human runs `/spade-evaluate` against it.

## Step 1: Dormancy check (opt-in)

`/spade-handoff` is **opt-in**. Read `.spade/config` and look for a
top-level `handoff:` block.

**If there is no `handoff:` block**, the skill is dormant. Tell the
human exactly this, and stop — do nothing else:

> `/spade-handoff` is not configured for this project. Run
> `/spade-onboard` and choose "set up `/spade-handoff`" to enable it.

Do not spawn anything; do not guess a configuration.

**If the `handoff:` block exists**, continue.

## Step 2: Resolve the target issue

The human invokes `/spade-handoff <ISSUE>` (e.g. `/spade-handoff M-1024`).

- If no issue identifier was given, ask for one.
- The issue must be a Scope with an **approved Plan** — Linear status
  `Approval` or `Delivering`. If Linear MCP is available, read the
  issue and confirm the Plan exists (the Plan comment and sub-issues).
  If it is still `Scoped` or `Planning`, stop and tell the human: a
  handoff delivers an *approved* Plan.
- Capture the issue's Linear URL for the handoff prompt. If Linear MCP
  is unavailable, ask the human for the issue URL and a short summary
  of the approved Plan — never assume the spawned agent can reach
  Linear.

## Step 3: Read config and the machine-local terminal

From the `handoff:` block read:

- `agent` — `claude` or `amp`.
- `autonomous` — the default autonomy setting.
- `agents.<agent>` — `command` (the argv array), `prompt_via` (`arg` or
  `stdin`), and `autonomous_flag`.

Read the terminal choice from `.spade/handoff.local` — the gitignored,
machine-local file. **If `.spade/handoff.local` is missing**, ask the
human via `AskUserQuestion` (per `docs/FRAMEWORK.md` § "Asking the
Human") — *iTerm2* / *Terminal.app* — and write the answer to
`.spade/handoff.local` as `terminal: iterm` or `terminal: terminal`.

## Step 4: Autonomy confirmation

If `autonomous` is `true` — or the human explicitly asks for an
autonomous handoff — the spawned agent runs with its permission checks
bypassed, in a window you are not driving. Before **every** such
handoff, confirm via `AskUserQuestion`:

- *Yes — run autonomously (permission checks bypassed)*
- *No — run interactively instead*

Only on an explicit "yes" do you append the agent's `autonomous_flag`
to its command. The default, and "no", mean interactive — no flag.
Never bypass permissions without a per-invocation yes; the `autonomous`
config value is a default, not standing consent.

## Step 5: Build the handoff prompt

Assemble the prompt the delivering agent receives. It MUST:

- Name the issue and include the Linear Scope URL.
- Instruct the agent to deliver the **approved Plan** for that issue.
- Point the agent at the repo's own `AGENTS.md`, `ARCHITECTURE.md`,
  `PATTERNS.md`, and `ANTI-PATTERNS.md` as the source of delivery
  rules. **Do not inline SPADE constraint prose** into the prompt —
  the repo docs are the single source of truth, and inlining them
  creates a second copy that drifts.
- Instruct delivery via the normal SPADE path: one bundle, one branch,
  one PR; close the bundle's sub-issues from that PR.
- Carry **no credentials** — no tokens, no API keys. The spawned agent
  uses the machine's existing tool configuration.

For the **`amp`** agent the prompt must explicitly say "Read `AGENTS.md`
before starting" — Amp does not auto-load it the way Claude Code loads
`CLAUDE.md`, and Amp cannot call `/spade-*` skills.

A workable template (adapt it; do not inline constraint prose):

> Deliver the approved SPADE Plan for <ISSUE> — <SCOPE_URL>.
> Read AGENTS.md, ARCHITECTURE.md, PATTERNS.md and ANTI-PATTERNS.md in
> this repository first; they define how delivery must be done. Work
> the Plan's bundle on its branch, open one PR, and close the bundle's
> sub-issues from that PR. Do not exceed the approved Plan's scope.

Write the finished prompt to a temporary file (use the Write tool, to a
path under the system temp directory) so it can be piped to the
launcher without shell-quoting it.

## Step 6: Invoke the launcher

`~/.spade/bin/spade-handoff-launch` is the spawn mechanism. It takes
everything as explicit arguments and never parses `.spade/config`
itself — you pass it the values you read in Step 3.

Build the call:

```bash
~/.spade/bin/spade-handoff-launch \
  --terminal <terminal from .spade/handoff.local> \
  --cwd <repo root> \
  --invoked-from <this session's working directory> \
  --prompt-via <agents.<agent>.prompt_via> \
  -- <agents.<agent>.command ...> [<autonomous_flag> only if confirmed in Step 4]
```

Run it with the prompt file on stdin:

```bash
~/.spade/bin/spade-handoff-launch <args ...> < /path/to/prompt-file
```

Handle the launcher's exit codes:

- **0** — the handoff window opened. Go to Step 7.
- **2** — not macOS. Tell the human `/spade-handoff` is macOS-only.
- **3** — the terminal app or agent binary is missing. Relay the
  launcher's message; suggest fixing the install or the `handoff:`
  config in `.spade/config`.
- **4** — worktree collision: `--cwd` is the same git worktree as this
  session, so the delivery agent would share this working tree and
  branch. Confirm via `AskUserQuestion`:
  - *Yes — share this worktree* — re-invoke the launcher with
    `--force-same-worktree` added.
  - *No — cancel the handoff* — stop; suggest the human run the handoff
    from a separate clone or git worktree.
- **1** — usage error: a bug in how this skill built the call. Show the
  launcher's message and stop; do not retry blindly.

## Step 7: Hand back

Once the launcher returns 0, this skill is done. Tell the human:

- Delivery is running in a new terminal window.
- The handoff is detached — this session does not track its progress.
- They observe success via the delivery agent's PR, and run
  `/spade-evaluate <ISSUE>` against it once it is complete.

## What This Skill Must Never Do

- **Run when dormant.** No `handoff:` block in `.spade/config` → print
  the unconfigured message and stop. Never guess a configuration.
- **Bypass permissions without a per-invocation yes.** The `autonomous`
  config value is a default, not standing consent.
- **Inline SPADE constraint prose into the handoff prompt.** Point the
  agent at the repo docs; they are the single source of truth.
- **Put credentials in the prompt, the launcher arguments, or any
  file.** The spawned agent uses the machine's existing configuration.
- **Hand off an unapproved Plan.** The issue must have an approved Plan
  (status `Approval` or `Delivering`).
- **Supervise the spawned agent.** The handoff is detached by design;
  re-entry into the loop is the PR plus `/spade-evaluate`, nothing else.
