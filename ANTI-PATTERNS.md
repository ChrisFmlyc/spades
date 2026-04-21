# Anti-Patterns

Things this project does not do, with rationale. AI agents must read this file
before generating any Plan. If a proposed solution uses any of these patterns,
it must be flagged and an alternative approach proposed.

## Architectural Anti-Patterns

- **Do not introduce a runtime.** SPADE is Markdown + shell. Do not propose a
  Node / Python / Go service, a daemon, a background worker, or any long-lived
  process owned by this repo. Rationale: the value of the framework is that it
  is inspectable, forkable, and portable with zero build step.
- **Do not add a compiled build step.** No TypeScript, no Rust CLI, no Go
  binary. Rationale: every compile step adds an install failure mode for
  consumers and a maintenance burden for the framework.
- **Do not bind to a single agent platform in skill prose.** Skills should be
  readable by any agent runtime that supports Markdown skills. Claude Code is
  the primary target but skills must not encode Claude-specific assumptions.
- **Do not add a second external tracker integration speculatively.** Linear
  is the only one today. A second one (GitHub Issues, Jira) is a scope
  decision, not a pattern to pile on.
- **Do not centralise state outside the repo.** All per-project state lives in
  `.spade/`. Do not propose a remote config service or shared database.

## Code Anti-Patterns

- **Do not write scripts that duplicate skill prose.** If a skill already
  describes a behaviour in natural language, do not add a bash or node script
  that "enforces" it. The agent reads the prose.
- **Do not use GNU-only flags in `setup`.** `sed -i` without extension,
  `readlink -f`, `realpath`, non-POSIX `find` predicates. macOS bash 3.2 is
  the floor.
- **Do not let `bin/` utilities exit non-zero on soft failures.** A failed
  update check must never break a skill invocation.
- **Do not skip PowerShell parity.** A change to `setup` without the matching
  `setup.ps1` change is incomplete and must be rejected at review.
- **Do not emit emojis in files, scripts, or skill output** unless the user
  explicitly asks. The framework writes to consumer repos; gratuitous emoji
  is noise.

## Security Anti-Patterns

- **Do not hard-code Linear tokens, API keys, or credentials anywhere.**
  Permissions come from the consumer project's `.claude/settings.local.json`.
- **Do not curl | bash.** `setup` operates only on local repo contents.
  `spade-update-check` fetches from the pinned remote and never executes
  anything it pulls.
- **Do not append blindly to consumer `AGENTS.md` / `CLAUDE.md`.** Use fragment
  markers so onboarding is idempotent — repeated runs must not duplicate
  content. Non-idempotent writes are a correctness bug with a security
  flavour: drift between the intended and actual state hides modifications.
- **Do not widen `.claude/settings.local.json` permissions by default.**
  Start minimal; require explicit opt-in for new MCP or Bash grants.

## Dependency Anti-Patterns

- **Do not add runtime dependencies.** There is no package manager here. A PR
  that introduces `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`
  is rejected on sight unless accompanied by an approved Plan that explicitly
  introduces a runtime.
- **Do not add dev-only tooling casually.** Each added tool (linter,
  formatter) is friction on first contribution. Only add when the value
  clearly outweighs the onboarding cost.
- **Do not depend on an MCP server beyond Linear** without explicit scope.
  The framework must remain usable in environments with only the base tools.

## Process Anti-Patterns

- **Do not write code without a Scope.** Exceptions go through `/spade-quick`,
  which has ten explicit gate criteria (see AGENTS.md).
- **Do not deliver without an approved Plan** on the full loop. Approval is a
  STOP gate. If in doubt, ask.
- **Do not mark a parent Scope issue as Done from the AI side.** Only humans
  transition parents to Done — this is the audit-trail closure point.
- **Do not bundle unrelated changes into a single PR.** One Scope → one Plan →
  N bundles → N PRs. Each PR closes only its bundle's sub-issues.
- **Do not let fragment versions drift.** When a fragment changes, bump the
  marker version and update `/spade-update` so consumers can pull the new
  content safely.
- **Do not add skills casually.** Each new skill is surface area the user must
  learn. New skills require a Scope and must explain what existing skill they
  subsume or why they are genuinely orthogonal.
