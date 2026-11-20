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
  § Versioning. Every PR to the plugin bumps its version; a skill or
  `AGENTS.md` bumps its own version only when its content changes.

## Marketplace version

`.claude-plugin/marketplace.json` carries the plugin version twice —
`metadata.version` and the `spades` entry's `version` — and both
match `plugins/spades/.claude-plugin/plugin.json` and
`plugins/spades/.spades/version`. The release gate checks all four.

## SCM drivers move together

SPADES ships three SCM drivers: `local-git`, `github` and `gitlab`.
Each consumer repo runs one of them, so a flow improved for one host
leaves teams on the others with the old behaviour. A change to how any
driver sets up, ships, closes, merges, sweeps review threads, checks
a deploy or mirrors Leads is weighed for every driver in the same PR:

- Where another driver has the same step, change it to match.
- Where it has no equivalent (local-git has no review threads; GitLab
  issues take no close reason), the PR description names that driver
  and says why it stays as it is.

`plugins/spades/docs/EXTENDING-SCM.md § Changing a flow` maps each flow
to its files. Command snippets tagged `<!-- scm-test: … -->` run against
recorded output in CI (`plugins/spades/scripts/test/scm-snippets.sh`);
a changed flow updates or adds its cases for each driver it touches.
The `repo` and `codereview` plugins that SPADES hands branch, PR and
review work to keep GitHub and GitLab paths side by side under the same
rule, in their own repo.

## Writing skills and agent docs

Every file an agent reads is written green-field, as if fresh, so it
carries its rules at the highest fidelity. That covers skills and
their references, agent definitions, `AGENTS.md`, `docs/`, templates
and READMEs.

- State each rule once, in positive terms, as the correct behaviour,
  in the one place it belongs. Everywhere else, point to it.
- When a rule is wrong, rewrite or delete that line. A wrong "always
  use a VPN" is removed, never answered by a second sentence that
  undoes, softens, overrides or excepts it.
- Write the current behaviour only: no history of fixes ("now", "no
  longer", "previously") and no denial of something nothing asked
  for.
- A condition that belongs to a rule sits inside that rule. Cases
  that differ read as one list or table.
- When two passages disagree, settle which is right and keep only
  that one.
- After an edit, re-read the whole file, and every file that restates
  the same contract, for these faults.

The `description` is the only text an agent sees before it decides
to load a skill, so it says what the skill does and when to use it,
in third person, key use case first.
