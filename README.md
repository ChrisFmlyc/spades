# SPADES Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-6.10.0-green.svg)](.claude-plugin/marketplace.json)
[![Claude Code](https://img.shields.io/badge/Claude_Code-marketplace-blueviolet.svg)](https://claude.ai/code)

A human–AI operating model for engineering work. SPADES is a
six-phase loop (**S**cope → **P**lan → **A**pprove → **D**eliver →
**E**valuate → **S**hip) with explicit human gates,
records that preserve an audit trail, and pluggable backends.

This repo ships the [`spades`](./plugins/spades) plugin for coding
harnesses — Claude Code, Codex CLI, Gemini CLI, Cursor, Aider,
Cline. 24 skills, 6 agents, Linear / local backends, opt-in HTML
mode, sub-agent fan-out.

Skills describe the workflow in Markdown and use the tools available
in the coding harness. Installation and tool names vary by harness.
The repository also includes HTML templates and CI lint scripts.

---

## Install

### Claude Code *(native one-command install)*

```text
/plugin marketplace add ChrisFmlyc/spades
/plugin install spades@spades-framework
```

Restart Claude Code so the slash commands register. Run
`/spades:setup` in any repo you want to adopt SPADES in.

Plugin docs: <https://code.claude.com/docs/en/discover-plugins>.

### OpenAI Codex CLI *(Skills + AGENTS.md)*

Codex CLI gained [Skills support](https://developers.openai.com/codex/skills)
in December 2025. Skills live under `~/.agents/skills/<name>/SKILL.md`.

```bash
git clone https://github.com/ChrisFmlyc/spades.git ~/.spades-source
mkdir -p ~/.agents/skills
for s in ~/.spades-source/plugins/spades/skills/*/; do
  ln -sfn "$s" "$HOME/.agents/skills/spades-$(basename $s)"
done
```

Codex also reads each project's
[`AGENTS.md`](https://developers.openai.com/codex/guides/agents-md)
before any work. `/spades:setup` scaffolds the AGENTS.md marker
block; once that's in your repo, Codex honours the same operating
rules as Claude Code.

Skills ask the human through Codex's own question tool, per
[`FRAMEWORK.md § Asking the Human`](./plugins/spades/docs/FRAMEWORK.md).
Caveats: Codex's slash-command syntax differs from Claude Code's, and
it has no `Agent` tool, so sub-agent fan-out drops to
`sequential-inproc` or `degraded` mode per
[`FRAMEWORK.md § Sub-agent Dispatch`](./plugins/spades/docs/FRAMEWORK.md).

### Other coding harnesses *(Gemini CLI, Cursor, Aider, Cline, Copilot Workspace, etc.)*

No native plugin install. Manual fallback:

```bash
git clone https://github.com/ChrisFmlyc/spades.git
```

Paste the operating rules `/spades:setup` installs, the fenced block in
[`plugins/spades/skills/setup/reference/agents-md-block.md`](./plugins/spades/skills/setup/reference/agents-md-block.md),
into your harness's instructions surface (`GEMINI.md` for Gemini CLI,
`.cursorrules` for Cursor, `.aiderrc` for Aider, `Rules` for Cline,
etc.). The framework's contracts live in
[`plugins/spades/docs/FRAMEWORK.md`](./plugins/spades/docs/FRAMEWORK.md)
and each skill at
`plugins/spades/skills/<name>/SKILL.md` — load whichever you need
into the harness's context.

---

## Update

| Surface | Command |
|---------|---------|
| Claude Code | `/plugin marketplace update spades-framework` then `/plugin update spades@spades-framework` |
| Codex CLI | `cd ~/.spades-source && git pull` |

## Uninstall

| Surface | Command / Action |
|---------|------------------|
| Claude Code | `/plugin uninstall spades@spades-framework` then `/plugin marketplace remove spades-framework` |
| Codex CLI | `rm ~/.agents/skills/spades-*` and `rm -rf ~/.spades-source` |

---

## Harness compatibility

Only **Claude Code** has a native one-command install. Codex CLI
accepts the plugin's content through its own primitive (Skills).
Skills say *ask* where they need the human, and `FRAMEWORK.md § Asking the Human` maps that to the
harness's question tool where it has one (Claude Code, Codex and
others) and, where it has none, to a question with numbered options in
the final message that the human answers in their next reply.
Sub-agent fan-out names Claude Code's `Agent` tool;
`FRAMEWORK.md § Sub-agent Dispatch` defines the available modes
(`subagent-dispatch` → `sequential-inproc` → `degraded`).
A skill can run only when the harness supplies its required tools;
its contract defines what happens when a capability is missing.

The framework is **deliberately harness-agnostic at the contract
level** — six phases, gates, audit trail, artefact shape, Linear /
local backend, HTML / CLI mode, sub-agent fan-out. The
*translation* between contract and any given harness's specific
tools is where the surfaces differ.

---

## Repository layout

```text
spades/
├── AGENTS.md                            # maintainer-facing rules (NOT installed downstream)
├── .claude-plugin/marketplace.json      # marketplace manifest
├── .github/workflows/lint.yml           # CI lint jobs
└── plugins/
    └── spades/                          # the SPADES plugin
        ├── .claude-plugin/plugin.json
        ├── AGENTS.md                    # consumer-facing operating rules
        ├── docs/FRAMEWORK.md            # canonical framework reference
        ├── skills/<name>/SKILL.md       # 24 skills (HTML-rendering skills also ship template.html)
        ├── agents/<name>.md             # 6 agents (4 reviewer personas, 1 diff reviewer, 1 researcher)
        ├── examples/                    # worked Scope / Plan / Intent examples
        ├── scripts/lint/                # CI lints (TypeScript on Node + bash)
        ├── tests/                       # planted-fixture self-tests
        ├── ARCHITECTURE.md              # plugin's own architecture (dogfooding)
        └── CHANGELOG.md
```

`AGENTS.md` is the cross-vendor convention honoured by Claude
Code, Codex CLI, Cursor, Aider, Cline, and others, and the only
agent-rules file SPADES ships.

The repo-root `AGENTS.md` is a **maintainer** file and is not
installed in consumer repos. `plugins/spades/AGENTS.md` is the
consumer-facing one.

---

## License

MIT. See [LICENSE](./LICENSE).
