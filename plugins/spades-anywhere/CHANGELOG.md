# Changelog

All notable changes to `spades-anywhere` are documented here.
Versions follow [semver](https://semver.org/). Pre-1.0 versions
signal that the public surface may iterate.

The consumer-repo marker block in `AGENTS.md` carries the plugin
version via `<!-- SPADES-ANYWHERE-FRAMEWORK-START vX.Y.Z -->`.

## [0.1.2] — 2026-06-03

**PATCH** — Universal template-use enforcement for HTML-rendering
skills. Same cross-cutting change as `spades` 3.1.3 (ship in the
same PR per the repo-root parity rule). Audit revealed every
HTML-rendering skill had a block-name mismatch between its SKILL.md
HTML-mode step and the bundled `template.html` — likely why Claude
in consumer contexts kept falling back to hand-rolled HTML instead
of using the bundled template.

The principle is canonical in
`docs/FRAMEWORK.md § Output Format → HTML rendering: validate and
use the bundled template`: (1) read sibling `template.html`;
(2) validate block names match; (3) substitute placeholders;
(4) never invent layout.

Per-skill changes (8 HTML-rendering skills, all → 0.1.2):

- `scope`, `plan`, `newproject`, `learn`, `review`, `status`,
  `list`, `intent` — each SKILL.md HTML-mode step now lists the
  correct `SPADES-BLOCK:*` names (matching the bundled template),
  declares per-item fields explicitly, and carries a defensive
  clause forbidding hand-rolled HTML.

**No template changes.** The bundled `template.html` files were
already correct; the SKILL.mds had drifted away from them.

Plugin / marketplace version: 0.1.1 → 0.1.2 (marketplace 3.2.1 →
3.2.2).

## [0.1.1] — 2026-06-03

**PATCH** — Mode mutual-exclusion at consumer-skill gates. Same
cross-cutting change as `spades` 3.1.2 (ship in the same PR per the
repo-root parity rule). In HTML mode, long review-form text never
duplicates between the open `.html` file and the CLI.

The principle is canonical in
`docs/FRAMEWORK.md § Output Format → What counts as review-form
text`. Same line as `spades`:

- **Stays CLI in both modes** — `AskUserQuestion` polls, final
  confirmation summaries, pre-flight narration, error messages,
  hand-off pointers, short status acknowledgements.
- **Routed through the mode-selected surface** — artefact bodies,
  acceptance/INTENT criteria lists, cumulative verdict tables,
  ship-time evidence records, "let me show you what we're about
  to X" previews.

Per-skill change (4 skills, all → 0.1.1):

- `evaluate/SKILL.md` — Pre-Flight Step 4 defensive clause
- `do/SKILL.md` — Pre-Flight Step 6 defensive clause **plus**
  Step 2 (Restate the acceptance criteria) now branches on
  `review_format`: HTML mode prints a one-line pointer only
  ("the open Scope tab shows what 'done' looks like"); CLI mode
  restates the AC list inline as before. The AC list IS
  review-form content — in HTML mode the human reads it in the
  open Scope tab, not duplicated to the CLI.
- `ship/SKILL.md` — Pre-Flight Step 5 defensive clause
- `intent/SKILL.md` — Transient HTML preview defensive clause

Framework doc:

- `docs/FRAMEWORK.md § Output Format → HTML mode is review-via-file`
  — new sub-section "What counts as review-form text vs
  conversational text" (same content as the `spades` sister doc).

Plugin / marketplace version: 0.1.0 → 0.1.1 (marketplace 3.2.0 →
3.2.1).

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
