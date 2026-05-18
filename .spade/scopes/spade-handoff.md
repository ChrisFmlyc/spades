# Scope: SPADE handoff — spawn a configured CLI agent to deliver an approved Plan

**Status:** Scoped
**Priority:** High

**Intent:** After a Plan is approved, the human can hand delivery off to a
fresh CLI agent — Claude Code or Amp — running in its own terminal window,
so the planning session stays free and delivery runs in a watchable,
separate context with the agent pointed at the Linear Scope and the
repo's SPADE delivery constraints.

**Acceptance Criteria:**
- [ ] **Core spawn.** `/spade-handoff <ISSUE>` spawns the configured CLI
      agent in a new terminal window (iTerm2 default, or Terminal.app),
      cwd at the repo working directory, pre-seeded with a handoff prompt
      that references the Linear Scope URL and a "deliver the approved
      Plan" instruction. If the configured terminal or agent binary is
      missing or unconfigured, it fails with a clear message — never a
      silent no-op.
- [ ] **Data-driven, drift-free invocation.** Both agent modes (`claude`,
      `amp`) are driven by a per-agent command template in `.spade/config`
      — not hard-coded prose branches — so a changed CLI flag is a
      one-line config edit. Neither mode's handoff prompt inlines SPADE
      constraint prose: it points the spawned agent at the repo's
      `AGENTS.md` and architecture docs as the single source of truth
      (the `amp` prompt explicitly instructs Amp to read `AGENTS.md`).
- [ ] **Loop re-entry.** The handoff prompt instructs the delivering
      agent to deliver via the normal SPADE path — one bundle → one
      branch → one PR — so the human observes success via that PR and
      runs `/spade-evaluate` unchanged. The handoff opens no separate
      audit channel.
- [ ] **Worktree-collision guard.** When the spawn directory is the same
      git worktree as the invoking session, `/spade-handoff` requires
      explicit confirmation before proceeding; tested with a same-dir
      fixture.
- [ ] **Injection-safe input.** Linear-sourced content (issue
      identifier, Scope/Plan text) is passed to the spawn as data only —
      via stdin, here-doc, or an argv array — never word-split or
      re-evaluated by the shell or `osascript`; a fixture covers
      injection metacharacters (`"`, `$()`, backticks, `;`).
- [ ] **Autonomy gate.** `autonomous: false` (default) runs the spawned
      agent interactively. `autonomous: true` adds the agent's
      skip-permission flag AND `/spade-handoff` requires an explicit
      interactive confirmation on each invocation before bypass mode
      launches.
- [ ] **No secret exposure.** No credentials are written into the
      handoff prompt, the launcher script, or `.spade/config`; the
      spawned agent obtains Linear access via the consumer's existing
      `.claude/settings.local.json`.
- [ ] **Opt-in config.** `/spade-onboard` writes handoff config (agent,
      autonomy default, per-agent command templates) to the committed
      `.spade/config`, and terminal choice to a gitignored machine-local
      file. With no handoff config present, `/spade-handoff` is dormant —
      it explains it is unconfigured, points to `/spade-onboard`, and
      does nothing else.

**Architectural Constraints:**
- New skill `.claude/skills/spade-handoff/SKILL.md` following existing
  `spade-*` conventions. The skill ships installed but is dormant until
  `/spade-onboard` writes handoff config — no behaviour for consumers
  who never opt in.
- Launcher script: source lives in repo-root `bin/`, installed to
  `~/.spade/bin/` by the repo-root `setup` / `setup.ps1` — the same
  install path SPADE already uses for `spade-render` and
  `spade-update-check`.
- Per-agent invocation is expressed as a command template in
  `.spade/config` (YAML), not prose branching, so adjusting or adding an
  agent is a config edit, not a code change.
- Committed handoff settings live in `.spade/config`; machine-local
  terminal choice lives in a gitignored file.
- macOS-only at runtime (`osascript`/`open`); `/spade-handoff` reports a
  clear "macOS only" message on other platforms. `setup` / `setup.ps1`
  keep parity by both installing the launcher file (inert on Windows).
  Launcher is bash 3.2-safe. No new runtime dependencies.
- The framework spawns and detaches the agent — it does not supervise,
  restart, or track it. No long-lived process is owned by the repo; the
  "no runtime" constraint holds.
- Honor ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md (including: no
  emojis in skill output).

**Dependencies:** None hard. Amp and/or Claude Code CLI must be installed
on the machine running a handoff (runtime, not build). Linear MCP for
reading the Scope.

**Context:**
- Upstream: `/spade-approve` produces the approved Plan; the Linear
  Scope/Plan are the source.
- Downstream: the spawned agent delivers via a normal bundle → branch →
  PR; `/spade-evaluate` checks the result, unchanged by the handoff.
- Related: `/spade-onboard` (config), `/spade-approve` (future
  handoff-link emission).

**Out of Scope:**
- Ghostty (and any terminal beyond iTerm2 / Terminal.app) as a spawn
  target — deferred until the Ghostty spawn recipe is verified against
  the 1.3+ AppleScript window API; a follow-up Scope adds it.
- cmux as a terminal target — no AppleScript dictionary, no
  command-injection CLI; not automatable. Permanent non-goal.
- The clickable-link trigger (custom URL scheme handler / localhost
  daemon) — future; note a localhost daemon would itself conflict with
  the "no runtime" anti-pattern.
- `/spade-approve` auto-emitting the handoff at approval time — future.
- Non-macOS runtime support; agents other than Claude Code and Amp.
- Supervising, monitoring, or reporting on the spawned agent's progress
  — the handoff is detached; observation is via the agent's PR.

**Origin:** Ad-hoc — the framework author's workflow: writes
comprehensive Scopes/Plans, then manually spawns a separate agent to
deliver. Automates a per-loop friction point. Reviewed by
`/spade-review` on 2026-05-18 (panel report:
`.spade/reviews/spade-handoff-2026-05-18.md`); the framework-fit tension
was resolved by making the skill opt-in (dormant until configured), and
the constraint-drift tension by pointing handoff prompts at repo docs
rather than inlining prose.

**Risk / Unknowns:**
- External CLI flag drift: `claude` / `amp` invocation contracts are not
  owned or pinned by SPADE, and there is no integration CI to catch a
  breaking flag rename. Accepted cost — concentrated in the per-agent
  command templates in `.spade/config`, so a fix is a one-line edit.
- Ghostty 1.2.3 on the author's machine lacks the AppleScript window API
  (needs 1.3+) — which is why Ghostty is out of scope for now.
- Amp TUI requires a real TTY — the launcher must spawn the terminal
  first, then run the agent inside it; never via
  `osascript do shell script`.
- macOS-only is a known limitation; `/spade-handoff` degrades to a clear
  message on other platforms.
- The spawned agent must not assume Linear MCP is available — the
  handoff prompt embeds the Scope URL and key content.

**Delivery Preference:** Mostly AI-delivered — shell scripting + a skill
markdown file. The one human bit: verifying the terminal-spawn recipes
on the actual machine.

**Priority:** High — this cycle. Automates a per-loop friction point in
the framework author's own workflow. Not blocking a release.
