# Changelog

All notable changes to `spades-anywhere` are documented here.
Versions follow [semver](https://semver.org/). Pre-1.0 versions
signal that the public surface may iterate.

The consumer-repo marker block in `AGENTS.md` carries the plugin
version via `<!-- SPADES-ANYWHERE-FRAMEWORK-START vX.Y.Z -->`.

## [0.1.0] — 2026-06-03

**INITIAL RELEASE.** Sister plugin to `spades`, in the same
`spades-framework` marketplace, targeting non-coding agents
(Claude Desktop, ChatGPT, web/mobile clients).

Same six-phase loop (Scope → Plan → Approve → Do → Evaluate →
Ship), same Project / Scope / Plan / Task hierarchy, same backends
(Linear / local), same HTML mode + B-style "Operational"
template, same sub-agent fan-out for Linear + local-file work,
same INTENT gate, same freshness-before-read rule.

Deliberate divergence from `spades` (the code-work plugin):

- **No SCM.** No `scm:` config field. No `/repo` plugin
  prerequisite. No branch creation, no PR open, no merge SHA,
  no two-phase ship resume.
- **`/spades-anywhere:do` is a marker, not a project manager.**
  No AI-autonomous code-execution branch. Routing is `human` or
  `hybrid` (AI assists with drafts / research / structure; the
  human acts). Do restates the Scope's acceptance criteria back to
  the human so they know what "done" looks like, then stands
  down. No assignee tracking, no cadence enforcement.
- **`/spades-anywhere:evaluate` is a human verdict.** Walk the
  Scope's acceptance criteria, mark each met / partial / not met,
  aggregate to PASS / PARTIAL / FAIL. No test execution. If not
  PASS, route back to `/spades-anywhere:do` and exit — the
  do → evaluate loop runs until PASS.
- **`/spades-anywhere:ship` is a confirmation walk** through the
  project's `INTENT.md` success criteria (broader than this
  Scope's local ACs), capturing evidence per criterion.
  `deliverable_type: artefact` (URL, file, doc) and `action`
  (evidence of a real-world action) are the only ship paths.
- **Execution Posture options swapped** for non-code work:
  `discover-first`, `outline-first`, `decide-first`, `iterate`,
  `straight-through`. The code-flavoured `test-first`,
  `characterization-first`, `refactor-first`, `spike` don't apply.
- **`/spades:close` and `/spades:quick` dropped.** No PR
  bookkeeping (close); no clean "≤50 LoC fast-track" equivalent
  for human work (quick).
- **Scope template "Architectural Constraints" → "Constraints"** —
  references budget, schedule, tools, stakeholder commitments
  rather than `ARCHITECTURE.md` / `PATTERNS.md` /
  `ANTI-PATTERNS.md`.
- **Plan template per-task "Tests" → "Verification"** — how will
  the human know this task is done?
- **Two of the four review personas adapted**: `review-security-lens`
  → `review-stakeholder-lens` (who's affected, who needs to be
  informed); `review-architecture-strategist` →
  `review-constraints-strategist` (conflicts with budget /
  schedule / tools / commitments). `review-scope-guardian` and
  `review-adversarial-reviewer` ported as-is.

Skills shipped (14): `setup`, `newproject`, `intent`, `scope`,
`plan`, `approve`, `do`, `evaluate`, `ship`, `learn`, `list`,
`status`, `review`, `research`.

Skills NOT shipped (2): `close`, `quick`.
