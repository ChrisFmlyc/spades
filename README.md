# SPADES Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-5.21.0-green.svg)](.claude-plugin/marketplace.json)
[![Claude Code](https://img.shields.io/badge/Claude_Code-marketplace-blueviolet.svg)](https://claude.ai/code)

A human–AI operating model for engineering work. SPADES is a
six-phase loop (**S**cope → **P**lan → **A**pprove → **D**o →
**E**valuate → **S**hip) with explicit human gates, an
audit-trail-first artefact shape, and pluggable backends.

This repo ships the [`spades`](./plugins/spades) plugin for coding
harnesses — Claude Code, Codex CLI, Gemini CLI, Cursor, Aider,
Cline. 22 skills, 5 agents, Linear / local backends, opt-in HTML
mode, sub-agent fan-out.

The framework is markdown-only — no bash, no external runtime,
no per-vendor tooling. Plugins are portable; only the *install
mechanism* varies by harness.

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

Caveats: Codex's slash-command syntax and tool names differ from
Claude Code's (`AskUserQuestion`, `Agent`); skills work but
sub-agent fan-out drops to `sequential-inproc` or `degraded` mode
per [`FRAMEWORK.md § Sub-agent Dispatch`](./plugins/spades/docs/FRAMEWORK.md).

### Google Gemini CLI *(Extensions)*

[Gemini CLI Extensions](https://geminicli.com/extensions/) can be
installed from a GitHub URL:

```bash
gemini extensions install https://github.com/ChrisFmlyc/spades
```

If the extension manifest needs additional metadata not yet
present in this repo, fall back to the clone-and-paste approach
below: clone the repo, copy
[`plugins/spades/AGENTS.md`](./plugins/spades/AGENTS.md) into each
project, and Gemini CLI honours the operating rules at task time.

### Other coding harnesses *(Cursor, Aider, Cline, Copilot Workspace, etc.)*

No native plugin install. Manual fallback:

```bash
git clone https://github.com/ChrisFmlyc/spades.git
```

Paste [`plugins/spades/AGENTS.md`](./plugins/spades/AGENTS.md)'s
content into your harness's instructions surface (`.cursorrules`
for Cursor, `.aiderrc` for Aider, `Rules` for Cline, etc.). The
framework's contracts live in
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
| Gemini CLI | `gemini extensions update spades` (or `git pull` in the clone) |

## Uninstall

| Surface | Command / Action |
|---------|------------------|
| Claude Code | `/plugin uninstall spades@spades-framework` then `/plugin marketplace remove spades-framework` |
| Codex CLI | `rm ~/.agents/skills/spades-*` and `rm -rf ~/.spades-source` |
| Gemini CLI | `gemini extensions uninstall spades` |

---

## Caveats — what works today vs what's aspirational

Only **Claude Code** has a native one-command install. Codex CLI
and Gemini CLI accept the plugin's content through their own
primitives (Skills, Extensions) — install works, but the skill
prose references Claude-Code tool names (`AskUserQuestion`,
`Agent`) that those harnesses don't have; the dispatch-mode
triplet in `FRAMEWORK.md § Sub-agent Dispatch` handles the
absence gracefully (sub-agent → sequential → degraded). Every gate
and skill still works because the framework is markdown-only with
no runtime tool dependency.

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
        ├── skills/<name>/SKILL.md       # 22 skills (HTML-rendering skills also ship template.html)
        ├── agents/<name>.md             # 5 agents (4 reviewer personas + 1 researcher)
        ├── examples/                    # worked Scope / Plan / Intent examples
        ├── scripts/lint/                # CI lints (TypeScript on Node + bash)
        ├── tests/                       # planted-fixture self-tests
        ├── ARCHITECTURE.md              # plugin's own architecture (dogfooding)
        └── CHANGELOG.md
```

`AGENTS.md` is the cross-vendor convention honoured by Claude
Code, Codex CLI, Cursor, Aider, Cline, and others. SPADES
deliberately does not ship a `CLAUDE.md` or any other per-vendor
variant.

The repo-root `AGENTS.md` is a **maintainer** file and is not
installed in consumer repos. `plugins/spades/AGENTS.md` is the
consumer-facing one.

---

## License

MIT. See [LICENSE](./LICENSE).
