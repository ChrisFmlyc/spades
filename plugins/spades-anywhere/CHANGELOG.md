# Changelog

All notable changes to `spades-anywhere` are documented here.
Versions follow [semver](https://semver.org/). Pre-1.0 versions
signal that the public surface may iterate.

The consumer-repo marker block in `AGENTS.md` carries the plugin
version via `<!-- SPADES-ANYWHERE-FRAMEWORK-START vX.Y.Z -->`.

## [0.6.0] — 2026-06-05

**MINOR** — Mirror of `spades` v3.7.0's universal additive HTML
rule. CLI mode = `.md` only; HTML mode = `.md` + `.html`
coexisting. HTML is a strict superset of CLI.

Five swap-pattern skills converted to additive in this plugin:
`scope`, `plan`, `learn`, `review`, `newproject`. Each SKILL.md's
"Output format" section rewritten; "format swap only" language
removed; the `Do NOT also write a .md` instruction removed and
replaced with `both files coexist`.

`docs/FRAMEWORK.md` grows the canonical **"Universal rule"**
sub-section under `## Output Format (CLI vs HTML)`, mirroring
the coding plugin's wording (with `.spades-anywhere/` paths).

## [0.5.0] — 2026-06-05

**MINOR** — Mirror of `spades` 3.6.0. Three new facilitator
skills for the project-level docs, plus a unified setup
per-file ask, plus the agile "Operating Principles" section in
the AGENTS.md marker block.

### Three new skills (all v1.0.0)

| Skill | Owns | Sections (locked schema, non-coding framing) |
|-------|------|----------------------------------------------|
| `/spades-anywhere:architecture` | `ARCHITECTURE.md` — how the work is structured | Overview · Stages · Stakeholders · Cadence · Tools & Resources · Constraints |
| `/spades-anywhere:patterns` | `PATTERNS.md` — approved process conventions | Process Conventions · Communication · Decision Making · Quality Bar |
| `/spades-anywhere:anti-patterns` | `ANTI-PATTERNS.md` — explicit prohibitions | Process · Communication · Tools & Resources · Other Bans |

Each mirrors `/spades-anywhere:intent`'s Socratic facilitator
shape: "facilitate, never author"; Create vs Edit mode
detection; read existing file and update; `last_reviewed`
field; persistent `.spades-anywhere/<name>.html` in HTML mode.

### `/spades-anywhere:setup` Step 7 — unified per-file ask

Replaces the old optional INTENT-only scaffold with a Step 7
that asks per file (Create / Scaffold / Skip) for all four
project docs. Only prompts for incomplete docs; re-runnable and
idempotent.

### AGENTS.md — Operating Principles

New "Operating Principles — Agile, four pillars" section
(Collaborate · Deliver · Reflect · Improve) tied to the skill
map. Skills table updated to 17 entries (16 → 19 in coding
plugin terms minus the two `spades-anywhere`-missing skills
`close` and `quick`).

### `docs/FRAMEWORK.md`

`architecture`, `patterns`, `anti-patterns` added to the
producing-skills list.

## [0.4.0] — 2026-06-05

**MINOR** — Mirror of `spades` 3.5.0's two-page evaluate
redesign. Same field-reported bug; same root cause; same fix.
Adapted for the simpler chat-surface flow:

- Pre-Flight: dropped the Plan's and Scope's `.html` auto-open.
- New Pre-Flight Step 5: renders page 1
  (`<plan-id>-<date>-plan.html`) showing each acceptance
  criterion as a row with `verifier: Human` and verdict
  `PENDING`. Auto-opens before the per-criterion walk starts.
- Step 2 now captures a free-form one-paragraph rationale
  after the overall verdict AskUserQuestion.
- Step 2.5 rewritten as page 2 render
  (`<plan-id>-<date>-report.html`) — distinct file path,
  distinct `mode: report` framing.

Template v1.1.0 → v1.2.0 (byte-identical to coding plugin's
template apart from the version-banner comment).

There is no SCM in spades-anywhere — the human saves both pages
to their chat-surface knowledge store on their own cadence.

## [0.3.0] — 2026-06-04

**MINOR** — Verification table in the evaluate HTML report now
shows a "By" column with a coloured chip per row. Pairs with
`spades` 3.4.0 (same template change, same PR). In
`spades-anywhere` the chip is **always** `Human` (gold), since
this plugin runs in chat surfaces where there is no AI / test /
lint verification — but the column is rendered so the report
shape matches the coding plugin's report, and the gold-on-white
"Human" chip is itself a clear signal.

Files:

- `skills/evaluate/template.html` (template v1.0.0 → v1.1.0) —
  identical to the coding plugin's template apart from the
  version-banner comment.
- `skills/evaluate/SKILL.md` (→ 0.3.0) — placeholder list adds
  `{{block.verifier}}` (always `Human`) and
  `{{block.verifier_class}}` (always `human`).

## [0.2.0] — 2026-06-04

**MINOR** — Two changes ship together; both follow from the
coding-plugin `spades` 3.3.0 cross-cutting framework move plus
the deferred PR #29 parity port being addressed per the
repo-root AGENTS.md rule (*"Deferred must be addressed before the
next cross-cutting framework MINOR bump"*).

### `evaluate` — promoted to a producing skill in HTML mode

- `skills/evaluate/template.html` — **NEW**. Same template as the
  coding plugin's evaluate template (gold palette, sidebar verdict
  pill, per-criterion rows, audit timeline) — only the comment
  banner changes.
- `skills/evaluate/SKILL.md` (→ 0.2.0) — adds new Step 2.5 to
  render the verdict + per-criterion table to
  `.spades-anywhere/evaluations/<plan-id>-<YYYY-MM-DD>.html` and
  auto-open. `{{spades.evaluator}}` is always `human` in
  spades-anywhere. No SCM machinery — the human saves the file to
  their chat-surface knowledge store on their own cadence.
- `docs/FRAMEWORK.md` — adds `evaluate` to the producing-skills
  list, calls it dual-role (consumer at Pre-Flight, producer at
  Step 2.5), and documents that `intent` writes a persistent
  `.spades-anywhere/intent.html` in HTML mode (see next entry).
  Also fixed a stale reference to `/spades-anywhere:close` (this
  plugin never had a close skill — that's coding-plugin-only).

### `intent` — deferred PR #29 parity port

PR #29 (in the coding plugin) added a persistent
`.spades/intent.html` alongside `INTENT.md` in HTML mode and
marked the sister-plugin port **Deferred**. Per the AGENTS.md
rule, deferred work must land in the next cross-cutting framework
MINOR bump — this is that bump.

- `skills/intent/SKILL.md` (→ 0.2.0) — "Writing the File" now
  also writes a persistent `.spades-anywhere/intent.html`
  alongside `INTENT.md` in HTML mode (using the same template the
  transient `.tmp/intent.html` preview uses). Principle: `.md`
  for the AI to read, `.html` for the human to view. Removed the
  stale `git add INTENT.md` suggestion (no git in spades-anywhere).

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
