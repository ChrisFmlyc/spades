# AGENTS.md — Repo Maintainer Operating Rules

> **This file is for *maintainers* of the SPADES framework — the
> people working in this repo.** It is NOT the consumer-facing
> `AGENTS.md`; that lives at `plugins/spades/AGENTS.md` and travels
> with the plugin install.

## One plugin, one repo

This repo ships the `spades` plugin from the `spades-framework`
marketplace, for coding harnesses (Claude Code, Cursor, and the
like) — work that ends in a PR. Everything a consumer needs is under
`plugins/spades/`: the operating rules (`AGENTS.md`), the framework
contract (`docs/FRAMEWORK.md`), the skills, the agents, the lints,
and the plugin's own dogfooded `.spades/` state.

## Where the rules live

- **Operating rules for agents working in a consumer repo** —
  `plugins/spades/AGENTS.md`. Read it before changing any skill;
  the skills are written against it.
- **Framework contracts** (phases, hierarchy, ID format, backends,
  output format, sub-agent dispatch, freshness) —
  `plugins/spades/docs/FRAMEWORK.md`. A skill references a
  contract rather than restating it.
- **Versioning and the release gate** — `plugins/spades/AGENTS.md`
  § Versioning. Every PR bumps the plugin version; a skill or
  `AGENTS.md` bumps its own version only when its content changes.

## Marketplace version

`.claude-plugin/marketplace.json` carries the plugin version twice —
`metadata.version` and the `spades` entry's `version` — and both
match `plugins/spades/.claude-plugin/plugin.json` and
`plugins/spades/.spades/version`. The release gate checks all four.

## Writing skills

A skill is written green-field: the correct behaviour, stated once,
in positive terms. When a fix is needed, refine the instruction so it
is right rather than appending a prohibition or the history of the
fix. The `description` is the only text an agent sees before it
decides to load the skill, so it says what the skill does and when
to use it, in third person, key use case first.
