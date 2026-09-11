# Anti-Patterns

Things this project does not do, with rationale. AI agents must read
this file before generating any Plan. If a proposed solution uses any
of these patterns, it must be flagged and an alternative approach
proposed.

## Architectural Anti-Patterns

- **Do not introduce a runtime.** SPADES is a Claude Code plugin made
  of Markdown. Do not propose a Node / Python / Go service, a daemon,
  a background worker, or any long-lived process owned by this repo.
  Rationale: the value of the framework is that it is inspectable,
  forkable, and portable with zero build step.
- **Do not reintroduce bash to the runtime path.** v2.0 ships zero
  runtime shell — no `setup`, `setup.ps1`, or `bin/` directory. A PR
  that re-adds any of these is rejected unless it carries an explicit
  Scope arguing why the cross-platform property is worth giving up.
- **Do not add a compiled build step.** No compiled runtime or CLI
  inside the plugin tree. CI lint TypeScript runs directly on Node
  without a build step, as specified in `ARCHITECTURE.md`. Each compile
  step adds an install failure mode for consumers and a maintenance burden
  for the framework.
- **Keep templates in the producing skill directory.** A shared
  plugin-root `templates/` or `fragments/` directory separates
  templates from the workflow that owns them. Use the inline and
  reference-file layout in `PATTERNS.md`.
- **Do not bind to a single agent vendor in skill prose.** Skills
  should be readable by any coding agent that honours `AGENTS.md`.
  Claude Code is the primary target because of the plugin surface,
  but skill prose must not encode Claude-specific assumptions beyond
  the standard plugin surface and the agent-tool set.
- **Do not write per-vendor agent files.** SPADES maintains
  `AGENTS.md` and only `AGENTS.md`. Do not write `CLAUDE.md`,
  `CURSOR.md`, `CODEX.md`, or any other vendor variant. Claude Code,
  Cursor, Codex, Aider, and the rest all honour `AGENTS.md`.
- **Do not auto-probe the backend.** v2 requires an explicit
  `backend:` field in `.spades/config`. A PR that adds an MCP probe
  to "auto-detect Linear" is rejected — explicit is a feature.
- **Do not add a second external integration speculatively.** Linear
  is the only external backend shipped in-tree; local is filesystem-only.
  Another external backend (Notion, Confluence, GitHub Issues, …)
  is a scope decision and
  follows the contract in `docs/EXTENDING-BACKENDS.md`.
- **Do not centralise state outside the repo.** All per-project state
  lives in `.spades/`. Do not propose a remote config service or
  shared database.

## Code Anti-Patterns

- **Do not write scripts that duplicate skill prose.** If a skill
  already describes a behaviour in natural language, do not add a
  bash or node script that "enforces" it. The agent reads the prose.
- **Do not emit emojis in files, scripts, or skill output** unless
  the user explicitly asks. The framework writes to consumer repos;
  gratuitous emoji is noise.

## Security Anti-Patterns

- **Do not hard-code Linear tokens, API keys, or credentials anywhere.**
  Permissions come from the consumer project's
  `.claude/settings.local.json`.
- **Do not fetch and execute remote code.** Skills never `curl | bash`,
  never download a script from a remote and run it. Plugin
  distribution is handled by Claude Code itself.
- **Do not append blindly to consumer `AGENTS.md`.** Use the marker
  block so the setup flow is idempotent — repeated runs must not
  duplicate content. Non-idempotent writes can hide modifications
  by making actual contents diverge from the intended state.
- **Do not widen `.claude/settings.local.json` permissions by default.**
  Start minimal; require explicit opt-in for new MCP or Bash grants.

## Dependency Anti-Patterns

- **Do not add runtime dependencies.** There is no package manager
  inside the plugin tree. A PR that introduces `package.json`,
  `requirements.txt`, `go.mod`, `Cargo.toml` is rejected
  unless accompanied by an approved Plan that explicitly introduces a
  runtime.
- **Do not add dev-only tooling casually.** Each added tool (linter,
  formatter) is friction on first contribution. Only add when the
  value clearly outweighs the onboarding cost. The exception is the
  `scripts/lint/` TypeScript-on-Node and Bash helpers, which are
  CI-only and never run as part of a skill workflow.
- **Do not depend on an MCP server beyond the backend driver in use.**
  The framework must remain usable in environments with only the
  base tools and one backend.

## Process Anti-Patterns

- **Do not write code without a Scope.** Exceptions go through
  `/spades:quick`, which has ten explicit gate criteria (see
  AGENTS.md).
- **Do not start Deliver without an approved Plan** on the full loop.
  Approval is a STOP gate, and the approval records the routing
  decision on the Plan. If in doubt, ask.
- **Do not mark work shipped without verifying the deliverable is
  real.** The shipment flow verifies a PR merged, an artefact is
  reachable, or an action's evidence is filed. The audit trail closes on shipment.
- **Do not bundle unrelated changes into a single PR.** One Scope can
  hold many Plans; its code Plans share one delivery PR. Plans use
  `depends_on:` to order delivery on that Scope's branch.
- **Do not let the marker-block version drift.** When the AGENTS.md
  marker content changes, bump `agents_version` and the plugin
  version under `AGENTS.md § Versioning` so the next
  `/spades:setup` run re-stamps the block.
- **Do not add skills casually.** Each new skill is surface area the
  user must learn. New skills require a Scope and must explain what
  existing skill they subsume or what separate purpose they serve.
