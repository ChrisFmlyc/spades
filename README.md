# SPADES Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.11.0-green.svg)](.claude-plugin/marketplace.json)
[![Claude Code](https://img.shields.io/badge/Claude_Code-marketplace-blueviolet.svg)](https://claude.ai/code)

This repository is a [Claude Code plugin marketplace](https://docs.claude.com/en/docs/claude-code/plugins).
It currently ships one plugin — **SPADES** — a human–AI operating
model for engineering teams. Future plugins can join under
`plugins/<name>/`.

## What's in here

| Plugin | Description |
|--------|-------------|
| [`spades`](./plugins/spades) | Scope → Plan → Approve → Do → Evaluate → Ship. Six-phase loop over a Project layer, with pluggable backends (Linear MCP, local filesystem, extensible to any MCP-backed tracker). 15 plugin-namespaced skills, four reviewer-persona subagents, one researcher subagent. Pure Markdown — no bash, no external setup. |

## Install

In Claude Code:

```text
/plugin marketplace add ChrisFmlyc/spades
/plugin install spades@spades-framework
```

Restart Claude Code so the slash commands register. After install,
`/spades:setup`, `/spades:newproject`, `/spades:scope`, `/spades:plan`,
`/spades:approve`, `/spades:do`, `/spades:evaluate`, `/spades:ship`,
and the supporting skills (`review`, `learn`, `research`, `list`,
`status`, `intent`, `quick`) are available.

Start with `/spades:setup` in any repo you want to adopt SPADES in.

## Update

```text
/plugin marketplace update spades-framework
/plugin update spades@spades-framework
```

## Uninstall

```text
/plugin uninstall spades@spades-framework
/plugin marketplace remove spades-framework
```

## Repository layout

```text
spades/
├── .claude-plugin/
│   └── marketplace.json            # marketplace manifest (registers each plugin)
├── .github/workflows/lint.yml      # CI lint jobs
└── plugins/
    └── spades/                     # the SPADES plugin
        ├── .claude-plugin/plugin.json
        ├── skills/<name>/SKILL.md  # 15 skills
        ├── agents/<name>.md        # 5 subagents (4 reviewers + researcher)
        ├── docs/
        │   ├── FRAMEWORK.md        # canonical framework reference
        │   └── EXTENDING-BACKENDS.md
        ├── examples/               # worked Scope / Plan / Intent examples + fixtures
        ├── scripts/lint/           # CI lints (Python 3.11 stdlib + bash)
        ├── tests/                  # planted-fixture self-tests for the lint suite
        ├── ARCHITECTURE.md         # plugin's own architecture (dogfooding)
        ├── AGENTS.md               # canonical SPADES agent rules (cross-vendor)
        └── CHANGELOG.md
```

Each plugin follows the standard Claude Code plugin layout, so its
skills are portable to any agent environment that understands the
`SKILL.md` format.

`AGENTS.md` is the only operating-rules file SPADES writes into
consumer repos — it's the cross-vendor convention honoured by Claude
Code, Cursor, Codex, Aider, and others. SPADES deliberately does not
ship a `CLAUDE.md` or any other per-vendor variant.

## License

MIT. See [LICENSE](./LICENSE).
