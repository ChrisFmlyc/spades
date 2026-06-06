# AGENTS.md — Repo Maintainer Operating Rules

> **This file is for *maintainers* of the SPADES framework — the
> people working in this repo.** It is NOT the consumer-facing
> `AGENTS.md` — those live inside each plugin's directory
> (`plugins/spades/AGENTS.md` and `plugins/spades-anywhere/AGENTS.md`)
> and travel with the plugin install.

## Two plugins, one repo

This repo ships two plugins from the same `spades-framework`
marketplace:

| Plugin | Audience | Plugin dir |
|--------|----------|-----------|
| `spades` | Coding harnesses (Claude Code, Cursor, etc.) — work that ends in a PR | `plugins/spades/` |
| `spades-anywhere` | Non-coding agents (Claude Desktop, ChatGPT, web/mobile) — real-world human tasks | `plugins/spades-anywhere/` |

They share a framework — the six-phase loop, Project / Scope / Plan
/ Task hierarchy, ID format, backend interface (Linear / local),
HTML mode, sub-agent fan-out, freshness-before-read, INTENT gate,
audit-trail format, idempotent setup. They differ in what "Do",
"Evaluate", and "Ship" mean (code work vs human work) and in a few
code-only concerns (SCM driver, branch creation, PR lifecycle).

## The parity rule

**When you change a skill or framework doc in `plugins/spades/`,
evaluate whether the change applies to `plugins/spades-anywhere/`
too.** Most cross-cutting framework changes MUST be ported.
Code-only changes do NOT apply.

When in doubt: port it. Drift between the two costs more than
spurious duplicate edits.

The same rule applies in reverse — changes that originate in
`plugins/spades-anywhere/` (rare, but possible — e.g. better
non-code task templates) should be evaluated for porting back to
`plugins/spades/`.

### Port the *principle*, not the *mechanics*

Porting is **adapt, not copy**. `plugins/spades/` is built for
coding agents in a git worktree — `${CLAUDE_PLUGIN_ROOT}` paths,
SCM, branches, PRs, `gh`, `/repo:sync`, `AskUserQuestion`, the
`Agent` tool. `plugins/spades-anywhere/` is built for humans
working in chat surfaces (Claude Projects, ChatGPT Custom GPTs,
Gemini Gems) — frequently at a coworking desk, on mobile, on the
road — with **no SCM and no AI harness primitives**.

The right port is therefore almost never line-for-line. The
mental model is:

1. **Identify the principle the spades change is teaching** —
   e.g. "in HTML mode, write a persistent human-viewable artefact
   alongside the AI-readable one"; "don't leave the workspace
   dirty after a metadata write"; "ask the human to confirm
   before destructive change".
2. **Strip the coding-specific mechanics** — git, branches, PRs,
   `gh`, `${CLAUDE_PLUGIN_ROOT}`, sub-agent fan-out, the harness
   tool calls that don't exist in chat surfaces.
3. **Re-express the principle in the chat-surface idiom** —
   "save this file to your Claude Project knowledge"; "paste
   this into a Notion page"; "tell me when you've copied it";
   numbered prompts instead of `AskUserQuestion`; `degraded`
   dispatch mode instead of `subagent-dispatch`.

If the principle has no equivalent in the non-coding context
(e.g. the entire change IS the SCM machinery, like the
auto-ship-metadata PR), mark it **Not applicable** in the PR
parity section — that is a valid outcome. But it is the
conclusion you reach after step 1, not a default to skip the
analysis.

#### Worked example — the auto-ship-metadata change

| Element of the spades change | Port to spades-anywhere? |
|------------------------------|--------------------------|
| Auto-branch + commit + push + `gh pr create` + AskUserQuestion("merged?") + cleanup | **Not applicable** — entire flow is SCM machinery. No git, no PR, nothing to port. |
| "Write a persistent `.spades/intent.html` alongside `INTENT.md` so the human has an HTML view" | **Port (deferred)** — the *principle* (`.md` for the AI, `.html` for the human, both persistent) applies. Equivalent: `spades-anywhere/intent` writes `.spades-anywhere/intent.html` next to `INTENT.md` in the chat-surface knowledge store. |
| Precondition gate (clean tree before write) | **Not applicable** — no worktree to be dirty. |

This is the shape every spades → spades-anywhere parity analysis
should take: per-element, per-PR, with explicit reasoning. The
PR's parity section (see below) records the conclusions.

## Decision rubric: port the change?

| The change touches… | Port to the sibling? |
|---------------------|---------------------|
| AGENTS.md operating rules (general) | **Yes** (unless it's a code-only rule) |
| FRAMEWORK.md § Six Phases, Hierarchy, ID Format, Audit Trail, Asking the Human, Target Resolution | **Yes** |
| FRAMEWORK.md § Output Format (CLI vs HTML) | **Yes** |
| FRAMEWORK.md § Sub-agent Dispatch (Fan-Out) | **Yes** |
| FRAMEWORK.md § Freshness, § INTENT gate | **Yes** |
| FRAMEWORK.md § Execution Posture | **Adapt** — postures differ (no `test-first` for a party) |
| FRAMEWORK.md § Backend Interface — Linear / local mechanics | **Yes** |
| FRAMEWORK.md § Backend Interface — SCM driver, two-phase resume, `EXTENDING-SCM.md` | **No** — code-only |
| Skill body: `scope`, `plan`, `approve`, `learn`, `list`, `status`, `intent`, `newproject`, `review`, `research`, `setup` | **Yes** |
| Skill body: `do`, `evaluate`, `ship` | **Adapt** — `spades` has code branches (PR, SCM, autonomous AI execution), `spades-anywhere` doesn't |
| Skill body: `close`, `quick` | **Adapt** — these exist in both plugins now; `spades` carries github bookkeeping-PR and LoC gate, `spades-anywhere` carries the same process shape with no-SCM finalisation and action-based gate |
| Anything mentioning `scm:`, `/repo:` plugin, branch creation, PR open, merge SHA, two-phase resume, `EXTENDING-SCM.md` | **No** — code-only |
| HTML templates (`template.html`) | **Yes** — same templates; only labels differ. Keep the B-style sizing / gold palette identical |
| Lint scripts (`scripts/lint/`) | **Yes** — same schema; adjust the path the walker scans |

## PR convention

When a PR touches `plugins/spades/`, the PR description MUST include
a `**spades-anywhere parity**` section in the body with one of:

- **Ported** — link to the equivalent edit in
  `plugins/spades-anywhere/` (same PR, separate commit or same
  commit — your call).
- **Not applicable** — one-line justification (e.g. "SCM-driver
  change, code-only — no port").
- **Deferred** — issue link or TODO line; must be addressed
  before the next cross-cutting framework version bump
  (i.e. before the next `spades` MINOR bump that touches
  framework-level behaviour).

Same rule in reverse for PRs that originate in
`plugins/spades-anywhere/`.

CI doesn't enforce this — it's a reviewer checklist. Reviewers
should reject PRs that omit the section.

## Version coupling

- The two plugins have **independent semver** (`spades` is at
  3.1.x, `spades-anywhere` started at 0.1.0). They do not need to
  move in lockstep.
- The **marketplace `metadata.version`** in
  `.claude-plugin/marketplace.json` is its own track — bump it
  when adding a new plugin (MINOR) or removing one (MAJOR).
- The two plugins' `version:` fields in their respective
  `plugin.json` bump independently per their own CHANGELOGs.
- When a cross-cutting framework change ships, both plugin
  versions should bump in the same PR (or back-to-back PRs) to
  signal the framework-level move.

## When in doubt

Read this file. Then port the change. Drift is the enemy.
