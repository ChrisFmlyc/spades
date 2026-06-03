# SPADES Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-3.2.2-green.svg)](.claude-plugin/marketplace.json)
[![Claude Code](https://img.shields.io/badge/Claude_Code-marketplace-blueviolet.svg)](https://claude.ai/code)

A human–AI operating model for getting work done — coding and
non-coding. SPADES is a six-phase loop (**S**cope → **P**lan →
**A**pprove → **D**o → **E**valuate → **S**hip) with explicit
human gates, an audit-trail-first artefact shape, and pluggable
backends.

This repo ships **two plugins** from the same marketplace. Install
one, both, or either:

| Plugin | For | What it does |
|--------|-----|--------------|
| [`spades`](./plugins/spades) | Coding harnesses — Claude Code, Codex CLI, Gemini CLI, Cursor, Aider, Cline | SPADES for engineering work. 16 skills, 5 agents, Linear / local backends, opt-in HTML mode, sub-agent fan-out. |
| [`spades-anywhere`](./plugins/spades-anywhere) | Non-coding agents — Claude Projects/Desktop, ChatGPT, Gemini, web/mobile | Same loop adapted for real-world human work (plan a party, prep a trip, run a hiring round). 14 skills, 5 agents, no SCM, no PR lifecycle. |

The framework is markdown-only — no bash, no external runtime,
no per-vendor tooling. Plugins are portable; only the *install
mechanism* varies by harness.

---

## Install — `spades` (for coding harnesses)

### Claude Code *(native one-command install)*

```text
/plugin marketplace add ChrisFmlyc/spades
/plugin install spades@spades-framework
```

Restart Claude Code so the slash commands register. Run
`/spades:setup` in any repo you want to adopt SPADES in.

The marketplace ships both plugins — install `spades-anywhere`
the same way if you want the sister plugin alongside (see below).

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

## Install — `spades-anywhere` (for chat surfaces)

### Claude Projects *(recommended — closest to native)*

1. Go to <https://claude.ai/projects> → **New Project**.
2. Name it (e.g. `SPADES Anywhere`).
3. **Custom instructions** — paste the content of
   [`plugins/spades-anywhere/AGENTS.md`](./plugins/spades-anywhere/AGENTS.md).
4. **Knowledge** — upload
   [`plugins/spades-anywhere/docs/FRAMEWORK.md`](./plugins/spades-anywhere/docs/FRAMEWORK.md)
   and the individual `SKILL.md` files for the skills you'll use.
   Claude Projects accepts PDF, DOCX, CSV, TXT, HTML, ODT, RTF,
   EPUB (up to 30MB each; unlimited files within context window —
   see [docs](https://support.claude.com/en/articles/9519177)).
5. Open a chat in that Project and start with
   `/spades-anywhere:setup`. Claude recognises the skill name from
   the attached files and runs the setup flow.

### ChatGPT — Custom GPT

1. Go to <https://chatgpt.com/create>.
2. Click **Configure**.
3. **Instructions** — paste the content of
   [`plugins/spades-anywhere/AGENTS.md`](./plugins/spades-anywhere/AGENTS.md).
4. **Knowledge** — upload up to 20 files (512MB each). Start with
   `docs/FRAMEWORK.md` and the `SKILL.md` files for the skills
   you'll use.
5. Save. Use the GPT for SPADES-anywhere work. The GPT falls back
   to numbered-choice prompts and `degraded` sub-agent dispatch
   automatically (ChatGPT lacks Claude Code's `AskUserQuestion`
   and `Agent` tool calls — the framework's dispatch-mode triplet
   handles the absence).

### Google Gemini Gems

1. Go to <https://gemini.google.com/>.
2. **Explore Gems** → **New Gem**.
3. **Instructions** — paste the content of
   [`plugins/spades-anywhere/AGENTS.md`](./plugins/spades-anywhere/AGENTS.md).
4. **Knowledge** — upload up to 10 reference files. **Bonus**:
   Gems connect to Google Drive — keep your `SKILL.md` and
   `FRAMEWORK.md` in a Drive folder and the Gem auto-syncs on
   plugin updates instead of needing re-upload.
5. Save the Gem and use it for SPADES-anywhere work.

### Other chat surfaces *(Perplexity Spaces, Microsoft Copilot, Mistral Le Chat, etc.)*

Manual fallback — paste
[`plugins/spades-anywhere/AGENTS.md`](./plugins/spades-anywhere/AGENTS.md)
into whatever "custom instructions" / "system prompt" / "persona"
surface the product offers, and attach `docs/FRAMEWORK.md` plus
the relevant `SKILL.md` files however the product accepts
knowledge / reference content.

The framework already gracefully degrades on surfaces with fewer
primitives — sub-agent fan-out → `degraded` mode, auto-open
browser → skipped, fixed-option questions → numbered prompts.
Every gate and skill still works because the framework is
markdown-only with no runtime tool dependency.

---

## Update

| Surface | Command |
|---------|---------|
| Claude Code | `/plugin marketplace update spades-framework` then `/plugin update spades@spades-framework` (or `spades-anywhere@spades-framework`) |
| Codex CLI | `cd ~/.spades-source && git pull` |
| Gemini CLI | `gemini extensions update spades` (or `git pull` in the clone) |
| Claude Projects / ChatGPT GPT / Gemini Gems | `git pull` locally, then re-upload changed `docs/FRAMEWORK.md` and `SKILL.md` files (or, for Gems, just `git push` to the Drive folder you wired in) |

## Uninstall

| Surface | Command / Action |
|---------|------------------|
| Claude Code | `/plugin uninstall spades@spades-framework` then `/plugin marketplace remove spades-framework` |
| Codex CLI | `rm ~/.agents/skills/spades-*` and `rm -rf ~/.spades-source` |
| Gemini CLI | `gemini extensions uninstall spades` |
| Claude Projects / ChatGPT GPT / Gemini Gems | Delete the Project / Custom GPT / Gem from the respective product UI |

---

## Caveats — what works today vs what's aspirational

Only **Claude Code** has a native one-command install. Codex CLI
and Gemini CLI accept the plugin's content through their own
primitives (Skills, Extensions) — install works, but the skill
prose references Claude-Code tool names (`AskUserQuestion`,
`Agent`) that those harnesses don't have; the dispatch-mode
triplet in `FRAMEWORK.md § Sub-agent Dispatch` handles the
absence gracefully (sub-agent → sequential → degraded). Chat
surfaces (Claude Projects, ChatGPT, Gemini) accept the plugin as
**instructions + knowledge files** — manual setup, but every gate
and skill works because the framework is markdown-only with no
runtime tool dependency.

The framework is **deliberately harness-agnostic at the contract
level** — six phases, gates, audit trail, artefact shape, Linear /
local backend, HTML / CLI mode, sub-agent fan-out. The
*translation* between contract and any given harness's specific
tools is where the surfaces differ.

---

## Repository layout

```text
spades/
├── AGENTS.md                            # maintainer-facing parity rule (NOT installed downstream)
├── .claude-plugin/marketplace.json      # marketplace manifest (both plugins)
├── .github/workflows/lint.yml           # CI lint jobs
└── plugins/
    ├── spades/                          # the SPADES plugin (coding)
    │   ├── .claude-plugin/plugin.json
    │   ├── AGENTS.md                    # consumer-facing operating rules
    │   ├── docs/FRAMEWORK.md            # canonical framework reference
    │   ├── skills/<name>/SKILL.md       # 16 skills (HTML-rendering skills also ship template.html)
    │   ├── agents/<name>.md             # 5 agents (4 reviewer personas + 1 researcher)
    │   ├── examples/                    # worked Scope / Plan / Intent examples
    │   ├── scripts/lint/                # CI lints (Python 3.11 stdlib + bash)
    │   ├── tests/                       # planted-fixture self-tests
    │   ├── ARCHITECTURE.md              # plugin's own architecture (dogfooding)
    │   └── CHANGELOG.md
    └── spades-anywhere/                 # sister plugin (non-coding)
        └── (same shape, minus close/quick, minus SCM)
```

`AGENTS.md` is the cross-vendor convention honoured by Claude
Code, Codex CLI, Cursor, Aider, Cline, and others. SPADES
deliberately does not ship a `CLAUDE.md` or any other per-vendor
variant.

The repo-root `AGENTS.md` is a **maintainer** file — it carries
the parity rule between the two plugins. It is not installed in
consumer repos. Each plugin's own `AGENTS.md` (under
`plugins/<plugin>/AGENTS.md`) is the consumer-facing one.

---

## License

MIT. See [LICENSE](./LICENSE).
