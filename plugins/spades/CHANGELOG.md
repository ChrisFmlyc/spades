# Changelog

All notable changes to the SPADES Framework are documented here.
Versions follow [semver](https://semver.org/) at the plugin level
(see `AGENTS.md` § Versioning for the policy: every merged PR bumps
the plugin version; per-skill `version:` fields bump only when that
skill's SKILL.md changes; `agents_version` bumps only when `AGENTS.md`
changes). The consumer-repo marker block in `AGENTS.md` carries the
**AGENTS.md version** via `<!-- SPADES-FRAMEWORK-START vX.Y.Z -->`.

## [5.2.0] — 2026-06-20

- **minor**: Reconcile the version that PR #57 (the cockpit HTML-template
  redesign) left un-bumped. #57 redesigned every skill's `template.html`
  to the dark "cockpit" design and wired the skills to feed new fields
  (objective banner, structured component/rule/ban cards, review-echo
  state, trivial counts), but shipped at 5.1.0 — so the updater treated
  installs as current and the redesign never reached anyone. The change
  is additive (new optional frontmatter fields with `|default`
  fallbacks, new render scalars; the static render contract is
  preserved), hence minor. Bumping to 5.2.0 makes the redesign install.
- Skills bumped: `anti-patterns` 1.3.0 → 1.4.0, `architecture` 1.2.0 →
  1.3.0, `evaluate` 3.6.0 → 3.7.0, `intent` 4.2.0 → 4.3.0, `learn`
  4.2.0 → 4.3.0, `list` 3.3.0 → 3.4.0, `newproject` 3.2.0 → 3.3.0,
  `objective` 1.0.0 → 1.1.0, `patterns` 1.2.0 → 1.3.0, `plan` 3.3.0 →
  3.4.0, `review` 3.3.0 → 3.4.0, `scope` 3.3.0 → 3.4.0, `status` 3.3.0
  → 3.4.0
- **minor (AGENTS.md)**: Make the version-bump rule hard to miss after
  the #57 miss, using Anthropic's own instruction-adherence guidance
  (sparing `IMPORTANT`/`YOU MUST` emphasis, conciseness, point-of-use
  repetition, a forced self-check). § Versioning now leads with a
  **release gate** the agent must fill in (`old → new` per line) before
  any commit touching the plugin; a one-line hard rule is added to
  "What You Must Never Do"; and a point-of-use reminder sits in the git
  operations section. `agents_version` 2.1.0 → 2.2.0.

## [5.1.0] — 2026-06-16

- **minor**: Introduce a third version level — `agents_version`, an
  independent semver for `AGENTS.md` pinned in `.spades/version`. The
  consumer-repo marker block now carries the AGENTS.md version instead
  of the plugin version, so a consumer's rules read as stale only when
  the rules themselves change, not on every unrelated plugin PR.
  Rewrites AGENTS.md § Versioning (two levels → three) and updates
  `/spades:setup` to stamp the marker with `agents_version` and to
  write both pins into the consumer's `.spades/version`.
- **fix**: Reconcile the plugin version that the v5.0.0 PR (#55, the
  Objectives feature) left un-bumped — it shipped a new `objective`
  skill but kept the plugin at 5.0.0, so the updater treated installs
  as current and the skill never reached anyone. Bumping to 5.1.0 makes
  the Objectives feature actually install.
- Skills bumped: `setup` 4.1.0 → 4.2.0
- AGENTS.md: introduced at `agents_version=2.1.0`

## [5.0.0] — 2026-06-15

**MAJOR** — Headline feature: Objectives (`O-`), a first-class
strategic layer independent of Scopes. This release also reconciles
the recorded plugin version with the manifest: `plugin.json` had
advanced to `5.0.0` during the skill-isolation refactors while the
CHANGELOG, `marketplace.json`, and `.spades/version` lagged at the
3.x line — all are now aligned at `5.0.0`.

An **Objective** is a coherent strategic action associated with a
project (Rumelt / OKR-objective sense). It is an independent sibling
of a Scope — never a parent or child, never attaches to or gates on a
Scope. Objectives are optional, repeatable, and do not run the
six-phase loop; their states are `open → complete | abandoned`.
Completion is the team lead's ungated judgement and never cascades to
the Project or any Scope. The record is minimal (name + 2–4 sentence
description, optional `strategy_link`). In `linear` mode an Objective
mirrors to a ProjectMilestone (`O-<slug>`) plus a sister tracking
Issue whose Done state is the completion signal; in `local` mode it is
just `.spades/objectives/O-<slug>.md`.

- **New skill**: `/spades:objective` (create or edit) — version `1.0.0`.
- **FRAMEWORK.md** (v2.11.0 → v2.12.0): Hierarchy → Objectives;
  Objective ID; local-layout `objectives/`; objectives frontmatter
  schema; backend ops (`create/get/list/update_objective`) + driver
  mapping; Terminal states (`complete`, no `rejected`);
  Target-Resolution ancestor row + objective-close exemption; Drift
  status-type mapping.
- Skills bumped: `objective` (new) 1.0.0, `close` 4.4.0 → 4.5.0
  (Objective Complete + Abandonment flows), `list` 3.2.0 → 3.3.0,
  `status` 3.2.0 → 3.3.0. AGENTS.md updated (skill table, hierarchy,
  fan-out).

## [3.11.0] — 2026-06-06

**MINOR** — Harden `/spades:close` against bad `gh pr view`
outcomes. Closes HIGH finding F-1 from the rev-8 plugin logic
review: previously, a transient `gh` auth/network failure on a
Quick item could push the human to *Drop* — which deletes the
marker — even though the underlying PR may have merged
successfully. Drop is the data-loss path; a failed probe must
never be sufficient signal to take it.

**Quick Close Flow — Step 1:**

- New "Outcome A — probe failure" branch (auth, network,
  malformed `gh` response, missing required JSON fields). On
  probe failure, abort cleanly with a remediation pointer
  (`gh auth status`, network, rate limit). Drop is NOT offered.
- New `CLOSED` decision option: *Update PR — the work shipped
  under a different PR*. Captures the replacement PR URL via a
  free-form follow-up, rewrites `pr_url` on the marker, re-probes.
  Handles the force-replace pattern (original PR closed, work
  shipped under a different PR number) without losing the audit
  trail.
- `OPEN` branch unchanged.
- `MERGED` branch unchanged (now requires `mergeCommit.oid`
  present, surfaced via the probe-failure branch if missing).

**Plan Pass Flow — Step 1:** same probe-failure branch added
(numbered Step 3). The Plan Pass Flow already exits cleanly on
non-MERGED, so this only adds the missing `gh`-error path —
surfacing the remediation explicitly instead of letting humans
guess. No destructive write happens here before Step 2.

- Skills bumped: `close` 4.1.1 → 4.2.0.
- No skill behaviour changes in `spades-anywhere` — its Quick
  Close Flow uses `AskUserQuestion` for the trigger, not `gh`.

## [3.10.0] — 2026-06-06

**MINOR** — Parent-status precondition. Producing skills (`scope`,
`plan`, `approve`, `do`, `evaluate`, `ship`, `close` Pass route)
now refuse hard when an ancestor in the target's container chain
has terminal status `abandoned` (or, for Projects, `archived`).
No override.

Pairs with the deliberate-no-cascade rule already in
`docs/FRAMEWORK.md § Terminal states`: abandoning a Scope does NOT
auto-reject its in-flight Plans, but every producing skill is now
the gatekeeper at the front door. Without the refusal, new work
silently lands on a dead initiative and the audit trail loses its
meaning. Closes HIGH finding H-2 from the rev-7 plugin logic
review.

Contract lives in `docs/FRAMEWORK.md § Target Resolution →
Parent-status precondition`; each producing SKILL.md adds one
Pre-Flight step referencing the rule.

Exemptions: `/close --abandon` and `/close --reject` (the actions
that *create* terminal status), `/list` and `/status` (read-only),
and `/quick` (independent of the Scope/Project hierarchy).

Mirrored in `spades-anywhere` v0.9.0.

- Skills bumped: `scope` 3.1.3 → 3.1.4, `plan` 3.1.3 → 3.1.4,
  `approve` 3.1.0 → 3.1.1, `do` 3.1.2 → 3.1.3, `evaluate`
  3.4.0 → 3.4.1, `ship` 3.1.2 → 3.1.3, `close` 4.1.0 → 4.1.1.
- Plugin version pin (`plugins/spades/.spades/version`) brought
  in sync with `plugin.json`.

## [3.9.0] — 2026-06-06

**MINOR** — Two-phase quick path. `/spades:quick` now writes the
marker at `status: shipping` (PR opened, not yet merged), and
`/spades:close Q-<id>` flips it to `status: shipped` after
verifying the merge via `gh pr view`. Mirrors the Plan ship →
close two-phase shape — `status: shipped` always means *actually
merged*, never PR-opened-but-unmerged.

Closes HIGH finding H-3 from the rev-7 plugin logic review and
incidentally closes MED finding M-5 (`/close` not recognising
`Q-` targets).

**`/spades:quick` changes:**
- Frontmatter `status: shipped` → `status: shipping`.
- Audit-trail line at marker-write: `Quick-path opened. Type: …`
  (the `Shipped` line is written later by `/spades:close`).
- Linear status transitions: Todo → In Progress → In Review only.
  The In Review → Done transition is `/spades:close`'s job.
- Confirmation nudge added: *"PR opened. Run `/spades:close Q-<id>`
  after it merges to finalise."*

**`/spades:close` changes:**
- Step 0 target detection recognises `Q-<slug>-<suffix>` IDs.
- New **Quick Close Flow** (lightweight — no bookkeeping PR, no
  Scope rollup):
  - `gh pr view` probe: merged → flip to shipped; open →
    ask Wait/Drop; closed-unmerged → ask Drop/Cancel.
  - On flip: append `Shipped (github). PR: …. Merge: <sha>.
    Merged by: <login>.` to the marker's audit trail
    (matches canonical Plan-close grammar).
  - On drop: delete the marker file (quick items have no
    `abandoned`/`rejected` terminal status — see § Deliberate
    non-goals in FRAMEWORK.md).
  - Linear In Review → Done on flip; In Review → Cancelled on drop.

**FRAMEWORK.md** § ID Format § Quick-item ID and § Fast-Track Path
updated to describe two-phase explicitly. § Terminal States's
"Quick items have no abandoned state" paragraph extended to
mention `/spades:close`'s Drop handling.

Mirrored in `spades-anywhere` v0.8.0 (same shape, human-confirm
trigger instead of PR-merge).

- Skills bumped: `quick` 2.0.1 → 2.1.0, `close` 4.0.0 → 4.1.0.

## [3.7.0] — 2026-06-05

**MINOR** — Universal additive HTML rule. Every producing skill
now writes the canonical `.md` in **both** modes; in HTML mode
it ADDITIONALLY writes the `.html` companion. CLI mode = `.md`
only; HTML mode = `.md` + `.html` coexisting. Strip the `.html`
out of HTML mode and you have CLI mode.

User context:

> *html mode is basically an alternative that also generates a
> html file...because its easier for a human to read. For ai
> files, agents, patterns, architecture etc...they should also
> generate a human read html file...but remember, they're there
> for the ai...so md is a must. In all cases, cli mode is just
> the html alternative — if its cli mode you just replace html
> with md/cli the whole way through.*

Fixes a real inconsistency: scope / plan / learn / review /
newproject used to **swap** extensions (CLI = `.md` only;
HTML = `.html` only). That meant in HTML mode the `.md` didn't
exist on disk — so the AI, other harnesses (Cursor, Codex,
Aider, Cline), and the GitHub web UI all lost the readable
markdown form. Project docs (intent / architecture / patterns /
anti-patterns) were already additive; evaluate was already
correct in its own way. This PR makes the rule universal.

### Skills changed

| Skill | Before | After |
|-------|--------|-------|
| `scope` | CLI=`.md`; HTML=`.html` only | `.md` always; HTML mode also writes `.html` |
| `plan` | same | same |
| `learn` | same | same |
| `review` | CLI=`.md`+terminal digest; HTML=`.html`+terminal digest (double-render) | `.md` always; HTML mode adds `.html` and **suppresses** the CLI digest (HTML is the only surface; `.md` is the fallback if HTML doesn't display); CLI mode unchanged |
| `newproject` | CLI=`.md`; HTML=`.html` only | `.md` always; HTML mode also writes `.html` |

In each SKILL.md:

- "Output format" section rewritten: `In both modes write .md;
  in HTML mode additionally write .html`. The "format swap only"
  language removed.
- The CLI-vs-HTML mode branch in the Write step renamed to
  "Write the canonical `.md` (both modes)" + "Additionally
  render the HTML (HTML mode only)" — both modes now go through
  the `.md` write; HTML mode just adds the second step.
- The `Do NOT also write a .md. The HTML is canonical in HTML
  mode` line removed and replaced with `The .md is unchanged —
  both files coexist`.

The `review` skill additionally drops its previous
"digest still prints regardless" carve-out: in HTML mode the
panel digest is now suppressed (the `.html` is the human's
review surface, and the `.md` is the fallback). The digest
*does* print as a backup if the `.md` / `.html` write fails —
so the human never misses the panel output, but they don't see
it duplicated in successful runs either.

### `docs/FRAMEWORK.md`

New canonical **"Universal rule — `.md` always, `.html` additive
in HTML mode"** sub-section under `## Output Format (CLI vs
HTML)`. Spelled out load-bearing-ly: HTML is a strict superset
of CLI. Covers the two special cases (evaluate's two-page split,
status/list's transient views) so the rule's apparent
exceptions are documented inline.

The `### Producing skills — cli vs html write` sub-section
expanded to include the four project-doc skills (intent /
architecture / patterns / anti-patterns) and updated to reflect
that HTML mode is additive, not swap.

Pairs with `spades-anywhere` v0.6.0 in the same PR (same fix,
same skills + the spades-anywhere FRAMEWORK rule).

## [3.6.0] — 2026-06-05

**MINOR** — Promotes the three project-level docs that have lived
as setup-time scaffolds into first-class facilitator skills,
peers of `/spades:intent`. Setup now asks per-file whether to
create, scaffold, or skip each — only prompting for docs that are
incomplete. AGENTS.md marker block grows an explicit
"Operating Principles — Agile, four pillars" section
(Collaborate · Deliver · Reflect · Improve) tied to the skill
map.

User context (paraphrased):

> *create skill for the other md files, which during setup
> should ask if you want to create each or skip... rerunning
> them should read the current state/docs and update, not write
> from scratch... very keen on focusing on agile: collaborate,
> deliver, reflect, improve.*

### Three new skills (all v1.0.0)

| Skill | Owns | Sections (locked schema) |
|-------|------|--------------------------|
| `/spades:architecture` | `ARCHITECTURE.md` — how the system is built | Overview · Tech Stack · Components · Data Flow · Security Posture · Operational Posture |
| `/spades:patterns` | `PATTERNS.md` — approved conventions | Code Organisation · Error Handling · Testing · Naming |
| `/spades:anti-patterns` | `ANTI-PATTERNS.md` — explicit prohibitions | Runtime Dependencies · Hidden State · Premature Abstraction · Other Bans |

Each:

- Mirrors `/spades:intent`'s Socratic facilitator shape:
  "facilitate, never author"; Create vs Edit mode detection;
  read existing file and update; `last_reviewed` field.
- Bundles a B-style `template.html` (gold palette, black text on
  white panels). Anti-patterns gets a red left-rail per section
  to distinguish prohibitions visually.
- Writes a persistent `.spades/<name>.html` in HTML mode
  alongside the `.md`, plus a transient `.spades/.tmp/<name>.html`
  preview during the edit flow. `.md` is the AI-readable source
  of truth; `.html` is the human's view.

### `/spades:setup` Step 7 — unified per-file ask

Replaces the old "Step 7 — Scaffold ARCHITECTURE.md /
PATTERNS.md / ANTI-PATTERNS.md" + "Step 8 — Optional: scaffold
INTENT.md" with a single Step 7 that:

- Detects per-file state (missing / scaffolded-but-unfilled /
  complete).
- Skips silently if complete.
- Otherwise asks per file via AskUserQuestion: *Create now*
  (invokes the relevant skill inline) / *Scaffold empty
  template* / *Skip*.

Re-runnable and idempotent — re-running setup later only prompts
for docs that are still incomplete.

### AGENTS.md — Operating Principles section

New "Operating Principles — Agile, four pillars" section in the
marker block:

1. **Collaborate** — Scope / Plan / Approve / Review.
2. **Deliver** — Do / Ship / Quick.
3. **Reflect** — Evaluate / Status.
4. **Improve** — Learn / Intent · Architecture · Patterns ·
   Anti-Patterns refresh.

The skill table grows from 16 → 19 entries.

### `docs/FRAMEWORK.md`

`architecture`, `patterns`, `anti-patterns` added to the
producing-skills list.

Pairs with `spades-anywhere` v0.5.0 in the same PR (same three
skills with non-coding framing: architecture covers stages /
stakeholders / cadence / tools / constraints; patterns covers
process / communication / decisions / quality bar; anti-patterns
covers process / communication / tools / other bans).

## [3.5.0] — 2026-06-05

**MINOR** — Restructures `/spades:evaluate` HTML output into TWO
distinct pages with a human approval gate between them. Fixes a
field-reported bug where the user invoked evaluate in HTML mode,
saw the Plan's `.html` open in the browser (from Pre-Flight),
and reported "the eval rendered the plan, not the evaluation."

Root cause: Pre-Flight auto-opened the Plan's `.html` ("the open
`.html` IS the review surface"); the evaluation HTML only
appeared at the end as a wrap-up. The user looked at the wrong
tab during the verification walk-through and didn't see the
human/AI/test row breakdown until after the work was done.

### Two-page redesign

| Page | When written | What it shows |
|------|--------------|---------------|
| 1. `<plan-id>-<date>-plan.html` | Step 2.5, after verification plan agreed | Concrete verification steps + verifier chips, all verdicts `PENDING`. Human reviews and approves at Step 2.6 before any tests fire. |
| 2. `<plan-id>-<date>-report.html` | Step 5.5, after human picks verdict + provides rationale | Same template, verdicts filled in, aggregate verdict pill, rationale in summary card. |

The Plan's `.html` is no longer auto-opened by evaluate. Each
eval page carries the Plan ID + parent Scope in its breadcrumb.

### Schema changes

- Template v1.1.0 → v1.2.0:
  - New `{{spades.mode}}` (`plan` | `report`) drives sidebar
    brand, H1 prefix, tagline, browser title.
  - Column rename: `Criterion` → `Verification step`.
  - Block-field rename: `{{block.criterion}}` →
    `{{block.step}}`. New `{{block.criterion_ref}}` (small grey
    suffix linking back to e.g. `C1`).
  - New `PENDING` verdict state and `pending` CSS class for
    page 1's rows.
- SKILL.md (→ 3.4.0):
  - Pre-Flight: drop the Plan's `.html` auto-open in HTML mode.
  - New Step 2.5 (page 1 render) and Step 2.6 (approve gate).
  - Step 5 now captures a free-form one-paragraph rationale
    after the verdict AskUserQuestion.
  - Step 5.5 rewritten as page 2 render (distinct file path,
    distinct `mode` framing).

Pairs with `spades-anywhere` v0.4.0 (same two-page redesign,
adapted for the simpler human-only flow).

## [3.4.0] — 2026-06-04

**MINOR** — Evaluate HTML report's verification table now shows
**who/what checked each criterion** as a coloured chip in a new
"By" column. User noted the previous v3.3.0 render didn't make it
obvious whether a row was verified by AI, a human, a test, etc.

Verifier types and their chip colours:

| Verifier | Chip | When to use |
|----------|------|-------------|
| `AI`     | Blue (`#3b82f6`)  | Claude verified autonomously |
| `Human`  | Gold (`#FFC107`)  | Eyes-on / manual check (org primary) |
| `Test`   | Green (`#16a34a`) | Automated test (unit / integration / e2e) |
| `Lint`   | Purple (`#8b5cf6`) | Static check (linter / typecheck / formatter) |
| `Manual` | Gray (`#6b7280`)  | Catch-all human check (e.g. "tried it in staging") |

The "Method" column still carries the specific detail (test name,
file path, "Eyes-on in staging") — the chip is the at-a-glance
signal, the method is the detail.

Files:

- `skills/evaluate/template.html` (template v1.0.0 → v1.1.0) —
  adds `--verifier-*` palette to `:root`, new `.by-badge.*` styles,
  new "By" column in the verification-rows table. Responsive rule
  now hides the Method column (`nth-child(3)`) on narrow screens
  while keeping the chip visible — chip is more informative than
  raw method text on mobile.
- `skills/evaluate/SKILL.md` (→ 3.3.0) — placeholder list adds
  `{{block.verifier}}` and `{{block.verifier_class}}`. Per-row
  values enumerated.

Pairs with `spades-anywhere` v0.3.0 in the same PR — same chip
column rendered with `verifier: Human` for every row (no AI /
test / lint in a chat-surface context).

## [3.3.0] — 2026-06-04

**MINOR** — `/spades:evaluate` promoted from consumer to producer
in HTML mode. The verification plan + verdict now renders to a
persistent `.spades/evaluations/<plan-id>-<YYYY-MM-DD>.html` using
the new bundled `template.html` (B-style, gold palette, sidebar
verdict pill, per-criterion rows, audit timeline). The Plan's
audit-trail line remains the AI-readable source of truth; the new
HTML is purely the human's rich view. CLI mode is unchanged.

User principle landed (continuing PR #29's direction): artefacts
the AI reads stay Markdown / audit-trail lines; artefacts the
human views in HTML mode get a persistent HTML rendering.

Files:

- `skills/evaluate/template.html` — **NEW**. Mirrors the review
  template's sidebar + verdict + structured-rows layout, adapted
  for verification-plan data.
- `skills/evaluate/SKILL.md` (→ 3.2.0) — rewrites the output
  format section; inserts Step 5.5 (render HTML) between Step 5
  and the worker fan-out; no precondition gate (evaluate runs
  mid-flow on a feature branch).
- `docs/FRAMEWORK.md` — adds `evaluate` to the producing-skills
  list and clarifies it's a dual-role skill (consumes the Plan's
  `.html` at Pre-Flight, produces the evaluation `.html` at
  Step 5.5).

Pairs with `spades-anywhere` v0.2.0 in the same PR — the same
promotion happens there at Step 2.5 (writes
`.spades-anywhere/evaluations/<plan-id>-<date>.html`, evaluator
always `human`, no SCM).

## [3.2.0] — 2026-06-04

**MINOR** — `/spades:learn` and `/spades:intent` now auto-ship
their own metadata in a bookkeeping PR (mirroring `/spades:close`),
so they don't leave the worktree dirty and block the next
`/repo:sync`. User reported: invoking either skill wrote metadata
files into the working tree and merely "suggested" a commit;
running `/repo:sync` afterwards correctly refused (dirty tree),
breaking flow.

Skills:

- `learn/SKILL.md` (→ 3.2.0) — replaces the old "Step 5: Suggest
  a commit" prose with a full "Step 5: Ship the learning metadata"
  flow: precondition check (on `main`, clean tree, `gh` available
  when `scm: github`) BEFORE writing; `chore/learn-<date>-<slug>`
  branch off `main`; commit; push; `gh pr create`; wait on
  `AskUserQuestion("Has the learning PR been merged?")`; post-merge
  cleanup. Private learnings (`public_safe: false`) skip the entire
  ship step — `private/` is gitignored. `scm: local-git` pushes (if
  remote configured) and skips the AskUserQuestion wait.
- `intent/SKILL.md` (→ 3.2.0) — same ship pattern. Branch name
  `chore/intent-update-<YYYY-MM-DD>` (with a 4-char random suffix
  on same-day collision). In HTML mode, the skill also writes a
  persistent `.spades/intent.html` alongside `INTENT.md` (using
  the existing template) — both files ship in the same bookkeeping
  PR. The pre-existing transient `.spades/.tmp/intent.html` preview
  is unchanged.

User principle landed: artefacts the AI consumes stay Markdown
(`.md`); artefacts the human views in HTML mode get a persistent
`.html` rendering committed alongside. The two co-exist —
`INTENT.md` is the source of truth, `.spades/intent.html` is the
human's view.

Out of scope for this minor: sister-plugin `spades-anywhere`
(no SCM); other metadata-writing skills (`scope`, `plan`,
`newproject` — those land mid-flow with downstream dependencies);
a learnings index page (separable follow-up).

## [3.1.3] — 2026-06-03

**PATCH** — Universal template-use enforcement for HTML-rendering
skills. User observed `/spades:status` rendering a too-narrow page
in a consumer repo (`max-width: 1000px` on a hand-rolled HTML
instead of the bundled fluid template). Audit revealed that
**every** HTML-rendering skill had a block-name mismatch between
its SKILL.md HTML-mode step and the actual `template.html` —
which is likely why Claude in consumer repos kept falling back to
hand-rolling. Same anti-pattern as PR #21 / #24 / #26.

This patch makes template-use load-bearing:

Framework doc:

- `docs/FRAMEWORK.md § Output Format → HTML mode is
  review-via-file` — new sub-section "HTML rendering: validate
  and use the bundled template, never hand-roll" with a four-step
  canonical rule: (1) read sibling `template.html`; (2) validate
  block names match; (3) substitute placeholders; (4) never invent
  layout.

Per-skill enforcement clauses + corrected block-name lists (all 8
HTML-rendering skills, all → 3.1.3):

- `scope/SKILL.md` Step 7.B — list now matches template
  (`acceptance-items`, `dependencies-items`, `out-of-scope-items`,
  `audit-events`); defensive clause added.
- `plan/SKILL.md` Step 5.B — list now matches template (`tasks`,
  `risks-items`, `delivery-sequence`, `audit-events`); defensive
  clause added.
- `newproject/SKILL.md` Step 3.B — list now matches template
  (`repos-items`, `owners-items`, `status-filters`, `scopes-rows`,
  `audit-events`); defensive clause added.
- `learn/SKILL.md` Step 4 HTML branch — list now matches template
  (`tags-items`, `related-items`, `audit-events`); defensive
  clause added.
- `review/SKILL.md` HTML mode sub-section — list now matches
  template (`persona-cards`, `convergence-cards`, `findings`);
  defensive clause added.
- `status/SKILL.md` Step 6 HTML mode — list now matches template
  (`ready-items`, `in-flight-items`, `blocked-items`,
  `plan-nodes`); defensive clause added. **This is the trigger
  case from the user-reported bug.**
- `list/SKILL.md` Step 6 HTML mode — list now matches template
  (`status-filters`, `scopes-rows`); defensive clause added.
- `intent/SKILL.md` Transient HTML preview — list now matches
  template (`users-items`, `non-goals-items` + prose
  substitutions); defensive clause added.

**No template changes.** The bundled `template.html` files were
already correct; the SKILL.mds had drifted away from them. This
PR aligns SKILL.mds *to* templates, not the other way around.

Plugin / marketplace version: 3.1.2 → 3.1.3 (marketplace 3.2.1 →
3.2.2). Cross-cutting framework change — `spades-anywhere` ships
the same enforcement at 0.1.1 → 0.1.2 in the same PR per the
repo-root parity rule.

## [3.1.2] — 2026-06-03

**PATCH** — Mode mutual-exclusion at consumer-skill gates. PR #21
(3.0.2) and #24 (3.1.1) added the explicit "do NOT also paste" rule
to producing skills and `/spades:approve`. This patch extends the
same defensive clause to the remaining consumer skills
(`evaluate`, `do`, `ship`, `close`, `intent`) so that in HTML mode,
long review-form text never duplicates between the open `.html`
file and the CLI.

The principle (now canonical in
`docs/FRAMEWORK.md § Output Format → What counts as review-form
text`):

- **Stays CLI in both modes** — `AskUserQuestion` polls, final
  confirmation summaries, pre-flight narration, error messages,
  hand-off pointers, short status acknowledgements.
- **Routed through the mode-selected surface** — artefact bodies,
  acceptance/INTENT criteria lists, cumulative verdict tables,
  ship-time evidence records, "let me show you what we're about
  to X" previews.

Per-skill change (5 skills, all → 3.1.2):

- `evaluate/SKILL.md` — Pre-Flight Step 5 defensive clause
- `do/SKILL.md` — Pre-Flight Step 6 defensive clause
- `ship/SKILL.md` — Pre-Flight Step 5 defensive clause
- `close/SKILL.md` — Pre-Flight Step 7 defensive clause
- `intent/SKILL.md` — Transient HTML preview defensive clause

Framework doc:

- `docs/FRAMEWORK.md § Output Format → HTML mode is review-via-file`
  — new sub-section "What counts as review-form text vs
  conversational text" defining the line once.

Plugin / marketplace version: 3.1.1 → 3.1.2 (marketplace 3.2.0 →
3.2.1). Cross-cutting framework change — `spades-anywhere` ships
the same clause at 0.1.0 → 0.1.1 in the same PR per the repo-root
parity rule.

## [3.1.1] — 2026-06-02

**PATCH** — Producing skills in HTML mode were still pasting full
draft bodies to the CLI for human approval before writing the file
(observed in `/spades:scope` and `/spades:plan`). The skills' write
steps correctly branched on `review_format:` and wrote the right
extension, but nothing forbade Claude from inserting a "show full
draft for approval" CLI paste step *before* the write. In HTML mode
that defeats the whole point: the file IS the review surface.

This patch makes the rule explicit and enforceable.

Per-skill change (4 producing skills, all 3.1.0 → 3.1.1; `learn` was
at 3.0.2):

- `plugins/spades/skills/scope/SKILL.md` — § Output format and Step 7
  forbid pre-write CLI paste in HTML mode; pin the review-via-file
  iteration workflow.
- `plugins/spades/skills/plan/SKILL.md` — same pattern at § Output
  format and Step 5.
- `plugins/spades/skills/newproject/SKILL.md` — same at § Output
  format and Step 3.
- `plugins/spades/skills/learn/SKILL.md` — same at § Output format
  and Step 4; Step 2 ("Propose a draft") now branches: CLI mode
  presents inline, HTML mode skips straight to Step 3 + 4.

Framework docs:

- `plugins/spades/docs/FRAMEWORK.md` § Output Format → Producing
  skills — new sub-section "HTML mode is review-via-file, not
  review-via-CLI" documenting the canonical rule and the
  review-via-file iteration loop.

Iteration in HTML mode: write the file as a working draft → auto-open
→ human reviews in browser → coordinator applies *targeted edits*
to the file (human reloads to see changes). Never re-paste a full
draft to the CLI.

Plugin / marketplace / `.spades/version` 3.1.0 → 3.1.1.

## [3.1.0] — 2026-06-01

**MINOR** — Sub-agent fan-out for Linear + local artefact work.
Producing skills (and writeback-heavy consumer skills) now dispatch
parallel sub-agents — one per resource (one local file, one Linear
operation) — instead of running their file writes and Linear MCP
calls serially. The pattern that already powered `/spades:review`
(four persona sub-agents) and `/spades:research` (one isolated
researcher) is extended to every-invocation worker work.

The rule: **one sub-agent owns one resource.** Two sub-agents in the
same dispatch wave must not write to the same resource. The
coordinator (the skill body itself) is not a sub-agent — after the
fan-out wave it does small integration writes (e.g. injecting a
captured `linear_issue_id` into a file the file sub-agent already
wrote).

Skills updated (5 skills, all 3.0.2 → 3.1.0):

- `plugins/spades/skills/newproject/SKILL.md` — Step 3 Linear branch:
  parallel file sub-agent + Linear sub-agent; coordinator back-writes
  `linear_project_id`.
- `plugins/spades/skills/scope/SKILL.md` — Step 7 file write + Step 8
  Backend Mirror collapsed into one fan-out wave; coordinator
  back-writes `linear_issue_id`.
- `plugins/spades/skills/plan/SKILL.md` — Step 5 plan write + Step 6
  scope-audit append + Step 7 Linear create dispatched as three
  parallel sub-agents; coordinator back-writes `linear_issue_id`.
- `plugins/spades/skills/approve/SKILL.md` — Write the Decision is now
  three parallel sub-agents (plan file, scope file, Linear). No
  back-write.
- `plugins/spades/skills/evaluate/SKILL.md` — Write the Verdict is now
  two or three parallel sub-agents (plan file, optional scope rollup,
  Linear). No back-write.

Framework docs:

- `plugins/spades/docs/FRAMEWORK.md` — new canonical
  § "Sub-agent Dispatch (Fan-Out)" covering the contract, dispatch
  modes (`subagent-dispatch` / `sequential-inproc` / `degraded`),
  freshness probe, and failure semantics.
- `plugins/spades/AGENTS.md` — new § "Sub-agent Fan-Out" pointing at
  the framework section.

Deliberately out of scope (deferred to a later PR): `/spades:do`,
`/spades:ship`, `/spades:close` mix Linear + local files with git
side effects where ordering matters (push → open PR → record
marker). Parallelizing those would introduce partial-success states
that are harder to recover from. Validate the simpler-flow pattern
first.

Plugin / marketplace / `.spades/version` 3.0.3 → 3.1.0.

## [3.0.3] — 2026-06-01

**PATCH** — HTML templates: main column auto-sizes to page width.
The shipped 3.0.0 templates capped `main` at a fixed `max-width:`
(820–1100px depending on template), so on a wide monitor content
sat in a narrow column with empty space to the right. Now the main
column fills the available width, with generous right-side padding
that scales at wide-screen breakpoints.

Per-template change (all 8 templates):

- `.layout { grid-template-columns: 375px 1fr; }` →
  `.layout { grid-template-columns: 375px minmax(0, 1fr); }` so the
  track can shrink correctly when content has wide non-wrapping
  elements (long inline `<code>` strings, code blocks).
- `main { padding: 3rem 4rem; max-width: <820–1100>px; }` →
  `main { padding: 3rem 4rem; min-width: 0; }` (cap removed; main
  fills the 1fr track).
- New media queries bump padding generously on wide monitors so
  prose doesn't run edge to edge:
  - `@media (min-width: 1600px)` → `padding: 3rem 6rem`
  - `@media (min-width: 2200px)` → `padding: 3.5rem 8rem`
- Mobile breakpoint (`@media (max-width: 900px)`) unchanged.

Template version stamps bumped to `v1.1.0 (matches plugin v3.0.3)`
in all 8 template files. No SKILL.md changes — pure template-CSS
fix — so no per-skill `version:` field bumps. Plugin / marketplace /
`.spades/version` bumped 3.0.2 → 3.0.3.

## [3.0.2] — 2026-06-01

**PATCH** — HTML mode is now actually enforced where it was only
nominally promised in 3.0.0. Every producing skill's Write step
explicitly branches on `review_format:` and writes the right
extension; every consumer skill has an explicit "open the artefact"
step rather than a header-only mention.

Before 3.0.2 the skills had an "Output format" paragraph at the top
mentioning HTML mode, but the actual Write step still said
`Write `.spades/<dir>/<filename>.md``. Claude followed the explicit
step instruction and wrote markdown (or, in some cases, just dumped
the draft to the CLI without writing a file at all). 3.0.2 makes
HTML mode load-bearing.

Producing skills — Write step now branches CLI/HTML:

- `plugins/spades/skills/plan/SKILL.md` — Step 5 split into 5.A
  (CLI) and 5.B (HTML render + auto-open). `3.0.0 → 3.0.2`.
- `plugins/spades/skills/scope/SKILL.md` — Step 7 split similarly.
  `3.0.0 → 3.0.2`.
- `plugins/spades/skills/newproject/SKILL.md` — Step 3 split into
  3.A / 3.B; Linear branch references unified format. `3.0.0 → 3.0.2`.
- `plugins/spades/skills/learn/SKILL.md` — Step 4 branches on
  format; public/private path rules apply to both. `3.0.0 → 3.0.2`.
- `plugins/spades/skills/review/SKILL.md` — persisted-report step
  branches on format with the same slug + collision rules.
  `3.0.0 → 3.0.2`.

Consumer skills — explicit "open the artefact" pre-step:

- `plugins/spades/skills/approve/SKILL.md` — Pre-Flight Step 5 opens
  the Plan's `.html`. `3.0.0 → 3.0.2`.
- `plugins/spades/skills/evaluate/SKILL.md` — Pre-Flight Step 5
  opens the target's `.html`. `3.0.0 → 3.0.2`.
- `plugins/spades/skills/do/SKILL.md` — Pre-Flight Step 6 opens the
  Plan's `.html` before execution. `3.0.0 → 3.0.2`.
- `plugins/spades/skills/ship/SKILL.md` — Pre-Flight Step 5 opens
  Plan + Scope `.html`. `3.0.0 → 3.0.2`.
- `plugins/spades/skills/close/SKILL.md` — Pre-Flight Step 7 opens
  the Plan's `.html`. `3.0.0 → 3.0.2`.
- `plugins/spades/skills/status/SKILL.md` — new Step 6 branches on
  format: CLI mode prints, HTML mode renders + opens transient
  `.spades/.tmp/status.html`. `3.0.0 → 3.0.2`.
- `plugins/spades/skills/list/SKILL.md` — same pattern, new Step 6.
  `3.0.0 → 3.0.2`.
- `plugins/spades/skills/intent/SKILL.md` — Writing-the-File step
  now does the HTML preview render + open; previous "no HTML
  render" sentence (a 3.0.0 leftover that contradicted the header)
  removed. `3.0.0 → 3.0.2`.

## [3.0.1] — 2026-06-01

**PATCH** — `/spades:setup` now appends `.spades/.tmp/` to the
consumer repo's `.gitignore` (idempotent, append-only). The transient
HTML scratch directory written by `/spades:status`, `/spades:list`,
and `/spades:intent` in HTML mode is regenerated on every invocation
and has no archival value, so it must not be committed. Previously
FRAMEWORK.md only suggested the consumer *may* gitignore it; this
makes it automatic at install/re-run time.

- `plugins/spades/skills/setup/SKILL.md` — new Step 5.5
  ("Ignore transient HTML scratch"); `version: 3.0.0 → 3.0.1`.
- `plugins/spades/docs/FRAMEWORK.md` § Output Format — updated to
  state setup writes the entry, not the consumer.

## [3.0.0] — 2026-06-01

**MAJOR** — opt-in HTML review mode. `/spades:setup` asks a new
question (CLI vs HTML); HTML-mode repos get standalone HTML
artefacts under `.spades/` instead of `.md`, auto-opened in the
browser when a skill would otherwise paste a large block to the
CLI. CLI mode is unchanged from v2 — same flow, same files, same
output. The framework, AGENTS.md, and all other developer docs stay
Markdown.

### What's new

- **`/spades:setup` Step 1.7 — Review format (CLI or HTML).** New
  question between SCM and Active Project. Same context-line /
  no-keep-current pattern as backend, SCM, and project. Recorded as
  `review_format: html | cli` in `.spades/config`.
- **Five producing skills carry a sibling `template.html`** —
  `skills/newproject/template.html`, `skills/scope/template.html`,
  `skills/plan/template.html`, `skills/learn/template.html`,
  `skills/review/template.html`. In HTML mode, the skill reads the
  sibling template, fills `{{spades.field}}` placeholders, expands
  `<!-- SPADES-BLOCK:name -->` repeating sections, and writes
  `.spades/<dir>/<id>.html`. In CLI mode, the skill writes `.md` as
  in v2. Skill flow is identical between modes; only the artefact
  format changes.
- **Three consumer skills carry transient `template.html`** —
  `skills/status/template.html`, `skills/list/template.html`,
  `skills/intent/template.html`. In HTML mode, render to
  `.spades/.tmp/<view>.html` and auto-open.
- **Eight consumer skills auto-open in HTML mode** — `approve`,
  `evaluate`, `do`, `ship`, `close`, `status`, `list`, `intent`.
  When a step would today paste a Plan/Scope summary to the CLI,
  in HTML mode the skill auto-opens the relevant `.html` via the
  OPEN_CMD prelude (`open` / `xdg-open` / `start`).
- **Templates are sibling resource files**, not inlined in
  SKILL.md. Same pattern as `skills/ship/scm-github.md` —
  installed via the plugin marketplace alongside the skill body.
  This keeps SKILL.md focused on flow / decisions and templates
  focused on presentation.
- **B-style "Operational" visual language** across all eight
  templates (validated as `/tmp/spades-samples/v2-*.html` during
  design). 375px sidebar, 17.5px body text, line-height 1.6, gold
  `#FFC107` accents on white panels, status pills colour-mapped
  per the SPADES status enum, severity colours for review
  findings, vanilla-JS interactivity (project scope filter, plan
  task expand, review severity tabs). No external dependencies —
  every generated `.html` is `file://`-safe and standalone.

### Architecture

- **Frontmatter symmetry across formats.** `.md` artefacts keep
  their YAML frontmatter at the top between `---` delimiters
  (unchanged). `.html` artefacts embed the same frontmatter as a
  `<script type="application/yaml" id="spades-frontmatter">`
  block inside `<body>`. The browser ignores the script (non-JS
  MIME type); the lint script parses either source format with the
  same schema. New helpers in `scripts/lint/frontmatter.py`:
  `_extract_yaml_body(text)` + `_parse_yaml_body(body)`. The
  local-frontmatter lint walker now globs both `*.md` and `*.html`
  under `.spades/projects/`, `.spades/scopes/`, `.spades/plans/`.
- **Audit trail symmetry.** A second `<script type="application/yaml"
  id="spades-audit-trail">` block carries the chronological audit
  entries. Same shape across `.md` and `.html`.
- **OPEN_CMD prelude.** Skills detect OS once per session
  (`open` / `xdg-open` / `start`); empty fallback prints
  *"Open this file: <path>"* without crashing.
- **Backend mirror unchanged.** Linear backend continues to
  receive artefact content as Issue descriptions (Markdown). HTML
  mode affects only the local file format and presentation
  medium.

### Documentation

- **New `docs/FRAMEWORK.md § Output Format (CLI vs HTML)`** —
  canonical contract documenting the dual-format render rules,
  template placeholder syntax, OPEN_CMD detection, and template
  authoring guide. Every skill body that writes or presents an
  artefact references this section instead of restating the rules
  inline.

### What's NOT changed (intentional)

- **SKILL.md files stay Markdown.** Skills are framework
  instructions; Claude reads them. Same for `AGENTS.md`,
  `README.md`, `INTENT.md`, `ARCHITECTURE.md`, `PATTERNS.md`,
  `ANTI-PATTERNS.md`, `CHANGELOG.md`, and `docs/FRAMEWORK.md` /
  `docs/EXTENDING-*.md`. Only the *artefacts the human reads to
  review their work* flip to HTML in HTML mode.
- **No migration of existing artefacts.** A v2 repo that
  upgrades and picks HTML mode keeps its old `.md` files on
  disk — they're not auto-converted. Mode-switching on re-setup
  writes new artefacts in the new format only.
- **Existing CLI-mode behaviour is unchanged.** A v2 repo that
  upgrades but stays in CLI mode behaves exactly as v2 — same
  files, same prompts, same paste-to-terminal output.

### Versions

- Plugin **2.12.0 → 3.0.0** (MAJOR — new artefact format).
- Marketplace **3.0.0**, `.spades/version` **3.0.0**.
- All 14 skills bumped to 3.0.0:
  - Producing: `setup`, `newproject`, `scope`, `plan`, `learn`,
    `review` (templates added + render branch).
  - Consumer: `approve`, `evaluate`, `do`, `ship`, `close`,
    `status`, `list`, `intent` (auto-open branch).

## [2.12.0] — 2026-06-01

**Minor** — `/spades:setup` always re-runs the full interview; new
AI-assisted backend migration.

Previously setup short-circuited on re-runs: a meta-question at the
top asked *"what do you want to change?"* and each per-step
question recommended "Keep current". Humans drifted through
re-configurations without re-engaging with the choices, and config
grew stale.

This release flips that UX. Same questions every time. Current
state surfaced as context, never as bias. Diff shown before any
writes. Backend switch triggers AI-assisted migration.

- **New Step 0.7 — Existing config probe.** Captures
  `current_backend / current_scm / current_project / current_linear_*`
  / `current_github_remote` from `.spades/config` if it exists. These
  feed downstream as *context lines* on each question, not as
  routing inputs.
- **Steps 1, 1.5, 2 re-ask every time.** "Keep current" recommended
  option language removed throughout. Each question carries a
  *"Currently configured: X — pick whatever you actually want now"*
  context line on re-runs. Fresh installs see no context line.
- **New Step 2.5 — Diff & Confirm.** Before writing anything,
  setup shows the diff between captured current values and the
  human's new answers:
  - **No-change re-runs** get a "Nothing changed — refresh
    scaffolding?" prompt with Yes / Cancel options.
  - **Changed re-runs** get a full diff block (`field: old → new`
    or `(unchanged)`) with **Apply changes** / **Cancel** options.
  - **First-runs** skip the diff display (nothing to diff against).
- **New Step 2.6 — Backend-switch migration (AI-assisted).** Fires
  only when backend changed. Walks the existing artefacts and
  mirrors them to the new backend:
  - **`local → linear`** — for each `.spades/projects/`,
    `.spades/scopes/`, `.spades/plans/` file: search Linear for a
    matching artefact via the Linear MCP; link if matched, create
    if not. Writes `linear_*_id` back into the local file's
    frontmatter and appends an audit-trail entry. Status mapped
    SPADES → Linear (`scoped` → "Triage", `delivering` → "In
    Progress", `shipped` → "Done", etc.). Surfaces inline progress.
    Learnings stay local-only by design.
  - **`linear → local`** — reverse: pulls bound Linear Project's
    Issues + sub-Issues down to local files with `linear_issue_id`
    preserved.
  - **Skip migration** — write the new config but leave the old
    artefacts untouched. For genuinely-starting-fresh cases.
  - **Cancel the backend switch** — backs out the switch; backend
    stays as-is.
- **Error handling.** MCP unreachable mid-walk → graceful abort;
  already-linked items keep their `linear_*_id` so re-runs can
  resume. Duplicate-title disambiguation via `AskUserQuestion`.
  Rate-limit / network errors surfaced verbatim with retry /
  skip-this-item / abort options.
- **Step 9 summary** now shows actual transitions (`backend: local
  → linear`) where applicable and a `Migrated: N projects, M
  scopes, K plans → Linear` line when Step 2.6 ran.
- **Re-Run Behaviour section deleted.** The old meta-question is
  gone; its logic is fully absorbed into Step 0.7 (state capture)
  + Step 2.5 (diff/confirm) + Step 2.6 (migration).
- **Skills bumped:** `setup` 2.7.1 → 2.8.0 (Pre-Flight + per-step
  + new Steps 2.5/2.6 + Step 9 + intro rewrite + Re-Run section
  removal). No other skill bodies touched — the migration uses
  the existing Linear MCP surface area already documented in
  `docs/EXTENDING-BACKENDS.md`.

## [2.11.0] — 2026-05-31

**Minor** — audit follow-up batch 3: Scope rollup semantics
canonicalised, hybrid per-task routing format spec'd, README +
FRAMEWORK header version drift refreshed.

- **Scope status rollup — now canonical.** Previously each skill
  (do, ship, close) mentioned Scope rollup informally with
  slightly different wording, and the rule was nowhere documented
  at framework level. New § `docs/FRAMEWORK.md § Hierarchy →
  Scope status rollup (from child Plans)` documents:
  - Scope status = the **highest phase** any child Plan has
    reached (`scoped` → `planning` → `approval` → `delivering`
    → `evaluating` → `shipping` → `done`).
  - Plans drive Scope status, not the reverse.
  - Per-skill ownership of each transition is listed explicitly.
  - One-way transitions only — Scopes never move backward.
  - Rejected Plans are terminal but don't block rollup; mixed
    terminal Scopes (some shipped, some rejected) require a
    human decision before the Scope can move to `done`.

- **Hybrid per-task routing — now spec'd.** Previously
  `/spades:do` Branch C read "which task is AI vs human" from
  the Plan body, but neither `/spades:plan` nor `/spades:approve`
  documented the format. First-time consumers had to invent it.

  The canonical format is a `- **Routing:** ai | human` bullet
  under each task in the Plan body. Required when
  `delivery: hybrid`; omitted (inherits Plan-level routing) when
  `delivery: ai` or `delivery: human`. Documented at:
  - `skills/plan/SKILL.md` — task template now lists Routing as
    a per-task field with usage rules.
  - `skills/approve/SKILL.md` — when Hybrid is chosen, walk each
    task asking AI vs human; refuse to save approval if any
    task is missing its Routing field.
  - `skills/do/SKILL.md` Branch C — explicit "parse each task's
    Routing field; abort if missing" prose, replacing the
    earlier "should record which is which" hand-wave.

- **README + FRAMEWORK.md header version refreshed.** The README
  badge said `version-2.0.0` (stale since v2.1.0); the
  FRAMEWORK.md H1 header said `v2.0`. Both refreshed to
  `v2.11.0` to match the actual current version. Drift caught
  by the original audit — cosmetic but embarrassing on a README
  that's the first thing new users see.

- **Skills bumped:** `plan` 2.0.0 → 2.1.0 (Routing field added
  to task template), `approve` 2.0.0 → 2.1.0 (Hybrid walks per
  task), `do` 2.3.0 → 2.4.0 (Branch C reads canonical Routing
  format). Other skills unchanged.

## [2.10.0] — 2026-05-31

**Minor** — two small fixes from external review feedback.

- **Spelling fix: `Revertable` → `Revertible`.** CodeRabbit flagged
  this on a downstream consumer repo's stamped AGENTS.md, which
  traced back to the embedded marker block in
  `skills/setup/SKILL.md`. Five occurrences fixed across the
  framework — `docs/FRAMEWORK.md` § Fast-Track Path, the
  consumer-facing setup marker block, `skills/quick/SKILL.md`
  (gate criterion + retrospective checklist), and the dogfood
  `AGENTS.md`. Consumer repos pick up the fix on next
  `/spades:setup` re-stamp.

- **`/spades:do` Step 3.A / Step 5 redundancy removed.** Branch A
  (the AI-delivery path) previously transitioned the Plan status
  to `evaluating` *and* appended an audit-trail line, then Step 5
  did effectively the same thing — duplicated status-transition
  logic in two places. Tightened: Step 3.A now records completion
  in the audit trail only (no status change) and falls through to
  Step 5, which owns the single canonical transition to
  `evaluating`. Same outcome, single source of truth for the
  status change.

- **Skills bumped:** `do` 2.2.0 → 2.3.0 (Step 3.A body change),
  `setup` 2.7.0 → 2.7.1 (typo fix in marker block), `quick`
  2.0.0 → 2.0.1 (typo fix). Other skills unchanged.

## [2.9.0] — 2026-05-30

**Minor** — AGENTS.md now codifies "defer to the `repo` plugin for
all git operations" as an explicit operating rule.

A SPADES skill that tries to roll its own `git init` / branch
creation / post-merge cleanup risks drifting out of agreement with
the `repo` plugin's discipline (branch-name regex,
no-commits-on-main rule, refuse-on-dirty pulls). The principle was
already followed in practice (`/spades:close` invokes `/repo:sync`;
`/spades:do` and `/spades:close` create branches under
`/repo:branch`'s validation) but wasn't written down.

This PR writes it down. Documentation-only — no skill body changes.

- **New §** `plugins/spades/AGENTS.md` § Defer to the `repo` Plugin
  for Git Operations — operating rule listing the four common
  cases (init, new branch, post-merge sync, no-commits-on-main)
  and the matching `repo` slash command for each. Plus a
  *"If you don't have a git repo yet, run `/repo:init` first"*
  subsection covering the brand-new-repo case.
- **Mirrored into the consumer-facing marker block** in
  `skills/setup/SKILL.md` so every SPADES-configured consumer repo
  gets the rule stamped into its own `AGENTS.md` on next
  `/spades:setup`.
- **The dependency is one-directional**: SPADES → `repo`. The
  `repo` plugin never calls SPADES. This is consistent with the
  freshness convention (PR #12) where `/spades:close` invokes
  `/repo:sync` but `/repo:sync` never calls `/spades:close`.
- **Belt-and-braces — new Step 0.5 in `/spades:setup`: git-repo
  probe.** Complements the AGENTS.md rule above with a mechanical
  enforcement at setup time:

  ```bash
  git rev-parse --git-dir >/dev/null 2>&1
  ```

  If the cwd isn't a git repository, setup aborts cleanly with a
  pointer to `/repo:init`. No auto-init — the human runs
  `/repo:init` explicitly so they can confirm origin URL and branch
  preferences. SPADES setup resumes once `/repo:init` has
  completed.

  Layered defense: the AGENTS.md rule tells *agents* what to do;
  the Step 0.5 probe enforces it *mechanically* at setup time so a
  brand-new-repo flow can't accidentally produce SPADES files
  outside version control.

- **Skills bumped:** `setup` 2.5.0 → 2.7.0 (marker block content
  changed + new Step 0.5 probe). No other skill bodies touched.

## [2.8.0] — 2026-05-30

**Minor** — `/spades:scope` hard-gates on `INTENT.md`; framework docs
the two-layer intent model.

A Scope is meaningless without a north star to measure against. The
previous flow allowed `/spades:scope` to run even when `INTENT.md`
was missing — silent scope-drift waiting to happen. This PR closes
that gap.

- **`skills/scope/SKILL.md` Pre-Flight Step 3 (new) — INTENT.md
  gate.** Probes for `INTENT.md` at the project root. If missing,
  asks the human (via `AskUserQuestion`):
  - **Run `/spades:intent` now** *(Recommended)* — composes
    project intent before scoping, then resumes.
  - **Override and proceed without INTENT** — for throwaway /
    sandbox repos. Records `- YYYY-MM-DD: Scope created without
    INTENT.md (override).` in the new Scope's audit trail. Drift
    risk accepted by the human.
  - **Abort** — exit, handle manually.

  Friction is the feature. `/spades:intent` is six probing
  questions; the cost of running it is minutes, the cost of months
  of silent scope drift is much higher.

- **`docs/FRAMEWORK.md` § Hierarchy → Two layers of "intent"
  (new).** Documents the project-vs-scope intent split:
  - **Project-level** = `INTENT.md` at the repo root.
  - **Scope-level** = the `## Statement of Intent` section in each
    `S-…md`. There is no separate per-scope INTENT file; the
    section is the intent.

  Each Scope's intent should be measured against the project-level
  INTENT.md. A Scope whose intent contradicts INTENT is a drift
  signal — refresh INTENT before scoping (or revise the Scope so
  it fits). The doc also states the hard-gate explicitly so a
  reader knows the contract before invoking `/spades:scope`.

- **Skills bumped:** `scope` 2.1.0 → 2.2.0 (new Pre-Flight Step 3).
  Other skills unchanged.

## [2.7.0] — 2026-05-30

**Minor** — audit follow-up trio: Strategy/Roadmap hook, canonical
`Shipped` marker contract, rejection-cascade rule.

These three additions came out of the 2026-05-30 consistency audit
(captured in memory). Bundled into one PR because each is small and
they touch overlapping files (`FRAMEWORK.md`, scope + do skills,
example fixture, frontmatter linter).

- **Strategy/Roadmap hook on Scopes.** SPADES is the implementation
  layer; Strategy / Roadmap / OKR planning lives above it in
  whatever tool an org uses. A Scope is the moment a roadmap item
  becomes concrete — but the framework had no documented link
  upward. Fixed by:
  - **New §** `docs/FRAMEWORK.md` § Hierarchy → *What sits above a
    Scope* — paragraph + ASCII diagram of the audit chain from
    Roadmap item → Scope → Plan → shipped.
  - **New optional Scope frontmatter field:** `strategy_link:` —
    free-form string (URL, Linear ID, OKR code, Notion ref).
    Omitted when a Scope arises reactively; `origin:` carries that
    rationale.
  - `skills/scope/SKILL.md` adds Step 4 / Question 11 — *"Does this
    scope trace to a roadmap item or OKR?"* — recorded verbatim if
    supplied.
  - `examples/example-scope.md` shows the field as a commented row
    so the shape is visible.
  - `scripts/lint/frontmatter.py` allow-list extended to accept
    `strategy_link` as a known optional Scope field.
- **Canonical `Shipped` marker contract.** SCM drivers emit
  `Shipped` markers with varying suffixes (`Shipped. PR: ...`,
  `Shipped (local-git). Branch: ...`). The audit found this drift
  was un-documented at the framework level — `/spades:ship` Step 0
  and `/spades:close` Step 1 both grep these markers but the
  contract was scattered. Fixed by:
  - **New §** `docs/FRAMEWORK.md` § Audit Trail → *The `Shipped`
    marker (contract)* — table mapping each SCM driver to its
    marker shape, plus the universal rule: every Plan reaching
    `status: shipped` MUST have a line beginning with `Shipped`.
  - Driver fragments unchanged — they already emit conforming
    markers; this just makes the contract canonical.
- **Plan rejection — no cascade rule.** A Plan with `status:
  rejected` no longer leaves dependants in undefined state. Fixed
  by:
  - **New §** `docs/FRAMEWORK.md` § Audit Trail → *Plan rejection —
    no cascade* — explicit contract: dependants stay in their
    current state, but `/spades:do` refuses to start any Plan
    whose `depends_on:` chain contains a `rejected` ancestor.
    Human decides whether to replan the ancestor or mark
    dependants rejected too.
  - `skills/do/SKILL.md` dependency-check (Pre-Flight Step 5)
    extended: aborts with a pointer to `/spades:plan` when any
    `depends_on:` ancestor is `rejected`. Prevents silent stuck
    work.
- **Skills bumped:** `scope` 2.0.0 → 2.1.0 (strategy_link prompt),
  `do` 2.1.0 → 2.2.0 (rejected-dependency abort). Other skills
  unchanged — the Shipped-marker contract is FRAMEWORK-only.

## [2.6.0] — 2026-05-30

**Minor** — Freshness convention (`docs/FRAMEWORK.md` § Freshness +
`AGENTS.md` operating rule) and Layer-2 subagent freshness
pre-flights in `/spades:review` and `/spades:research`.

- **The problem.** SPADES skills read files from the local
  filesystem. If a recently merged PR isn't pulled locally,
  audits, plan-drafting, do-phase branch creation, and review
  subagents all silently operate against the wrong source of
  truth. We hit this on 2026-05-30 — an audit produced findings
  ("`/spades:close` doesn't exist") that were already false on
  `origin/main` because the local checkout hadn't been pulled
  after PR #10 merged. Two of eleven audit findings were stale.
- **Layer 1 — Behavioural rule.** Operators run `/repo:sync`
  immediately after any PR merge, before context-switching to a
  new SPADES skill. Captured as the rule in:
  - **New §** `docs/FRAMEWORK.md` § Freshness — canonical
    definition + when-it-applies block.
  - **New §** `plugins/spades/AGENTS.md` § Freshness Before
    Read-Across — operating-rule restatement; same rule appears
    in the consumer-facing marker block inside
    `skills/setup/SKILL.md` so consumer repos get it stamped into
    their AGENTS.md on next `/spades:setup`.
- **Layer 2 — Subagent prompt pre-flights.** Skills that spawn
  read-across subagents now run the freshness check before
  spawning, so the subagents never produce findings against stale
  state:
  - `skills/review/SKILL.md` — Pre-Flight Step 1 (mandatory)
    runs `git rev-list --count main..origin/main`. If non-zero,
    abort with a pointer to `/repo:sync`; the four-persona panel
    is never spawned against stale code.
  - `skills/research/SKILL.md` — same Pre-Flight check before
    spawning the researcher. The researcher's Scope-context reads
    stay fresh.
- **Why the rule lives in FRAMEWORK + AGENTS, not in every
  skill.** A single canonical definition (FRAMEWORK) +
  operating-rule restatement (AGENTS) covers every SPADES skill
  without repeating the check in each Pre-Flight. Skills that
  spawn subagents codify the check explicitly (Layer 2); other
  skills inherit the rule via AGENTS. Adding a new skill that
  reads cross-cutting state? The skill author reads FRAMEWORK §
  Freshness and references it; the convention propagates.
- **Skills bumped:** `setup` 2.4.0 → 2.5.0 (new § in marker
  block), `review` 2.0.0 → 2.1.0 (new Pre-Flight Step 1),
  `research` 2.0.0 → 2.1.0 (new Pre-Flight Step 1). Other skills
  unchanged.

## [2.5.0] — 2026-05-30

**Minor** — new `/spades:close` skill (post-merge close-out) + setup
now probes for the prerequisite `repo` plugin.

- **New skill `/spades:close`** — the SPADES-specific half of the
  post-`/spades:ship` workflow. After the human runs `/repo:sync`
  (which cleans up the local checkout), `/spades:close P-<id>`:
  1. Verifies the ship PR merged (`gh pr view`).
  2. Checks preconditions — must be on a clean `main` that's
     fast-forwarded to origin. If not, refuses and points at
     `/repo:sync`. **Does not duplicate sync logic.**
  3. Creates a `chore/close-<plan-id>` bookkeeping branch off main.
  4. Applies the close-out edits there: Plan → `status: shipped` +
     `Shipped` audit-trail marker, Scope → `done` if every sibling
     Plan is shipped.
  5. Pushes the bookkeeping branch and opens its PR.
  6. **Waits** via `AskUserQuestion` for the human to merge the
     bookkeeping PR on GitHub (no auto-merge — branch protection /
     required reviews are respected).
  7. Cleans up after confirmation: ff-pull main, delete the local
     bookkeeping branch.
  8. Mirrors completion to Linear when `backend: linear` (sub-issue
     → Done, parent Issue → Done if rolled up).
  9. Suggests `/spades:learn` and prints the summary.
- **Why a bookkeeping PR?** The `Shipped` audit-trail marker is part
  of the source-of-truth on `main` — it MUST land via a regular PR,
  not as an unversioned local file edit. The bookkeeping PR is
  markdown-only, gates against `/repo:branch`'s no-commits-on-main
  rule, and gives the human one explicit moment to approve the
  close-out before Linear sees Done.
- **GitHub-only.** For `scm: local-git`, `/spades:close` aborts with
  a note pointing at `/spades:ship`'s single-phase flow (local-git
  Plans go straight to `shipped` inside ship; there's no second
  command to run).
- **`/spades:setup` now probes for the `repo` plugin** (Step 0). The
  `repo` plugin from the [`ai-skills` marketplace](https://github.com/ChrisFmlyc/ai-skills)
  provides `/repo:sync` and `/repo:branch`, both of which SPADES
  skills rely on. If the plugin isn't installed, setup walks the
  human through `plugin marketplace add` + `plugin install` and
  re-probes before continuing. The human can skip the probe if they
  prefer to install later — but `/spades:close`, `/spades:do`, and
  `/spades:ship` will refuse to run without it.
- **Workflow integration with `/repo:sync`** — `/repo:sync` stays in
  the `repo` plugin as the canonical post-merge git-cleanup command.
  `/spades:close` runs after it as the SPADES-specific bookkeeping
  step. A future enhancement to the `repo` plugin would have
  `/repo:sync` auto-detect Plans in `status: shipping` and offer to
  chain into `/spades:close`; until then, the two commands run in
  sequence.
- **`skills/ship/scm-github.md`** Phase 1 handoff updated: now reads
  *"Once squash-merged: `/repo:sync` then `/spades:close P-<id>`"*.
  `/spades:ship` Step 6 stays in place as a legacy fallback for any
  in-flight Plans from 2.4.0.
- **AGENTS.md skill tables** (both `skills/setup/SKILL.md`'s
  consumer-facing marker block and `plugins/spades/AGENTS.md`'s
  dogfood mirror) updated to 16 rows including `/spades:close`.
- **Skills bumped**: new `close` at 2.0.0; `setup` 2.3.0 → 2.4.0
  (added Step 0 repo-plugin probe). Other skills unchanged.

## [2.4.0] — 2026-05-30

**Minor** — `/spades:ship` progressive disclosure by SCM.

- **The per-SCM ship flow moves out of `skills/ship/SKILL.md` into
  sibling driver files.** SKILL.md now reads `scm:` from
  `.spades/config` and Reads only the matching `scm-<value>.md`
  driver — never both at once. As more SCMs are added (GitLab,
  Bitbucket), SKILL.md's context cost stays flat instead of growing
  linearly with options the human never uses on a given run.
- **New files:** `plugins/spades/skills/ship/scm-github.md`
  (two-phase: fresh ship + resume after merge) and
  `plugins/spades/skills/ship/scm-local-git.md` (single-phase push +
  record). Both have no frontmatter — they are instruction fragments
  consumed by SKILL.md, not skills on their own. The lint walker
  (`skills/*/SKILL.md`) ignores them, by design.
- **SKILL.md** keeps the SCM-agnostic skeleton: Pre-Flight, Step 0
  fresh-vs-resume detection (now general — recognises `PR opened:`
  and `MR opened:` per `docs/EXTENDING-SCM.md` § 4), Step 1 status
  transition, Step 2 dispatch on `deliverable_type`, Steps 3–5
  finalise / learning / confirm. Step 2 Branch A and Step 6 are
  thin "Read the driver and follow it" hand-offs.
- **No behaviour change for end users.** The GitHub two-phase flow
  and the local-git single-phase flow are byte-for-byte the same
  procedure as 2.3.0 — only the file they live in changed. Resume
  marker contract (`PR opened:` / `MR opened:` / `Shipped`) is
  unchanged.
- **Skills bumped**: `ship` 2.2.0 → 2.3.0. Other skills unchanged.

## [2.3.0] — 2026-05-29

**Minor** — SCM (source-code-management) abstraction.

- **`/spades:setup` now asks for an SCM choice** alongside the
  backend question. Two options ship: `local-git` (default — work
  commits stay local, optional push to a remote) and `github` (work
  flows through GitHub PRs via the `gh` CLI). The choice is stored
  as `scm:` in `.spades/config`. Re-runnable.
- **GitHub install guidance** — if the human picks GitHub and `gh
  auth status` fails, the skill walks them through installing the
  `gh` CLI (brew / apt / winget) and authenticating, mirroring the
  Linear-MCP install guide added in 2.1.0.
- **`/spades:ship`'s code branch is routed by `scm:`**:
  - `scm: github` — original two-phase flow (push + `gh pr create`,
    resume after squash-merge).
  - `scm: local-git` — new single-phase flow: push to the configured
    remote if any, record the commit SHA, mark the Plan `shipped`.
    No PR loop.
- **Other SCMs** (GitLab, Bitbucket) are documented as extension
  points in `docs/EXTENDING-SCM.md` (new file).
- **AGENTS.md + the consumer-facing setup fragment** updated Phase
  6 (Ship) to describe the SCM routing.
- **`.spades/config` schema in `docs/FRAMEWORK.md`** updated with
  the new `scm:`, `github:`, and `local_git:` blocks.
- **Skills bumped**: `setup` 2.2.0 → 2.3.0, `ship` 2.1.0 → 2.2.0.
  Other skills unchanged.

## [2.2.0] — 2026-05-29

**Minor** — code-deliverable branch lifecycle is now first-class.

- **`/spades:do` creates a feature branch** at the start of the
  `deliverable_type: code` flow (Step 1, before any commits land).
  Branch name is derived from the Plan's title via the same slug
  rules as `/repo:newbranch`, prefixed `feat/` / `fix/` /
  `refactor/` per the change's nature, and validated against the
  `/repo:branch` regex. The branch name is recorded in the Plan's
  `## Audit Trail` for `/spades:ship` to pick up later.
- **`/spades:ship` becomes two-phase** for `deliverable_type: code`:
  - **Phase 1 (fresh):** verify the Do branch, run pre-push checks,
    push to origin, `gh pr create` with body derived from the Plan,
    record `PR opened: <URL>` in the audit trail, exit. Plan stays
    in `status: shipping`. CodeRabbit runs against the PR; fixes
    commit to the same branch.
  - **Phase 2 (resume after squash-merge):** re-invoke
    `/spades:ship` after `/repo:sync` cleans up. Step 0 detects the
    resume via the `PR opened:` audit-trail marker, verifies the PR
    is `MERGED` via `gh pr view`, captures the merge SHA, records
    `Shipped. PR: <URL>. Merge: <sha>` in the audit trail, marks
    the Plan `shipped`.
  - No more auto-merge from inside the skill — squash-merge happens
    in GitHub after CodeRabbit review.
- **AGENTS.md + the consumer-facing setup fragment** updated to
  reflect both changes in the Phase Rules.
- **Skills bumped**: `do` 2.0.0 → 2.1.0, `ship` 2.0.0 → 2.1.0,
  `setup` 2.1.0 → 2.2.0. Other 12 skills unchanged.

## [2.1.0] — 2026-05-29

**Minor** — additive changes accumulated since 2.0.0, plus the new
per-PR versioning policy.

- **Per-PR versioning policy** documented in `AGENTS.md` § Versioning
  and in the consumer-facing fragment embedded in
  `skills/setup/SKILL.md`. Plugin version bumps on every PR;
  per-skill `version:` bumps only when that skill changes; both
  follow semver.
- **New `version:` field** required on every `SKILL.md` frontmatter,
  enforced by `scripts/lint/lint-skill-frontmatter.sh` (semver
  format check: `X.Y.Z`). All 15 skills seeded at `version: 2.0.0`;
  `setup` bumps to `2.1.0` since this PR modifies its body.
- **Catches up changes accumulated since 2.0.0:**
  - PR #2 — `setup` skill: Linear MCP install guidance when the
    probe fails (skill body expansion)
  - PR #3 — interactive target pickers for `scope`, `plan`,
    `approve`, `do`, `evaluate`, `ship`, `review` (new framework
    section `§ Target Resolution`, all six skills updated)
  - PR #4 — `review` skill: rule-delimited persona summaries
    in the inline report (presentation refactor)
  - PR #5 — `evaluate` skill: AI / Human / Hybrid routing with
    two-phase resume; renamed `delivery: mixed` → `delivery: hybrid`;
    new `evaluation:` Plan frontmatter field; vocabulary aligned
    across `approve` / `do` / `evaluate`
- **Skills bumped**: `setup` 2.0.0 → 2.1.0 (modified in this PR for
  the policy embedding). All other 14 skills remain at 2.0.0 (no
  body changes in this PR — only the new `version:` frontmatter
  field, which is bookkeeping, not behaviour).

## [2.0.0] — 2026-05-29

**Substantial restructure.** Treat this as a new framework that shares
the SPADES name with v1 — there is no automatic migration.

### Six-phase loop, with Do and Ship as first-class phases

The loop is now **Scope → Plan → Approve → Do → Evaluate → Ship**. The
old "Deliver" phase splits into **Do** (execute the work — `code`,
`artefact`, or `action`) and **Ship** (release the deliverable: open a
PR + review + merge, or record an artefact reference, or record
evidence of a completed action). Each phase has its own skill.

### Project layer above Scope

A new top-level record — a Project — groups related Scopes under one
identity (a repo, a service, a set of repos). Per-repo `.spades/config`
names exactly one active project. `/spades:newproject` creates new
Project records.

### Pluggable backends

Storage and audit-trail recording are abstracted behind the contract
in `docs/FRAMEWORK.md` § Backend Interface. v2.0 ships two drivers:
**Linear MCP** and **local filesystem**. Adding a backend (Notion,
Confluence, GitHub Issues, …) means writing a driver per
`docs/EXTENDING-BACKENDS.md` and per-skill branches — no core
changes. The auto-probe Mode Resolver from v1 is gone; backend
selection is explicit at `/spades:setup` time and stored under
`backend:` in `.spades/config`.

### Semantic IDs

- Projects: `<project-slug>` (lowercase, hyphen-safe).
- Scopes: `S-<description-slug>`.
- Plans: `P-<description-slug>-<4-char-suffix>[-<dep-suffix>...]`.
  The dependency chain is encoded in the filename in dependency order
  (most recent dep first) and authoritatively in `depends_on:`
  frontmatter.

Plan dependencies replace v1's delivery bundles — each Plan stands on
its own and can list earlier Plans it relies on.

### 15 skills

`setup`, `newproject`, `scope`, `plan`, `approve`, `do`, `evaluate`,
`ship`, `quick`, `review`, `learn`, `research`, `list`, `status`,
`intent`. `init` was absorbed by `setup`; `do` and `ship` are new;
the rest were rewritten or trimmed for the new IDs and backend
contract.

### Routing decision recorded at Approve

`/spades:approve` now asks the routing question — `ai` /
`human` / `mixed` — and writes the answer to the Plan's `delivery:`
frontmatter. `/spades:do` reads that field and routes accordingly,
rather than rediscovering the answer at execution time.

### Embedded templates — no `templates/` or `fragments/` directories

Every template the framework injects into a consumer repo lives
inline inside the SKILL.md of the producing skill: the AGENTS.md
marker-block content and the ARCHITECTURE / PATTERNS / ANTI-PATTERNS
scaffolding live inside `skills/setup/SKILL.md`; the INTENT.md
template lives inside `skills/intent/SKILL.md`; the Scope and Plan
body shapes live inside their respective skills. The standalone
`templates/` and `fragments/` directories are gone.

### `AGENTS.md` only — no `CLAUDE.md`

SPADES now writes only `AGENTS.md` into consumer repos. AGENTS.md is
the cross-vendor convention (Claude Code, Cursor, Codex, Aider all
read it), and a single source-of-truth file beats one file per
vendor. The `CLAUDE.md` fragment, the `CLAUDE-section.md` injection,
and the framework's own dogfooded `CLAUDE.md` are all removed.

### Lint suite refresh

The lint suite is now five checks (skills, agents, examples,
learnings, local-mode artefacts). `lint-fragments.sh` and
`lint-mcp-guard.sh` are gone (their premises no longer apply). The
local-mode lint covers v2 Project, Scope, and Plan schemas with
planted-fixture self-tests for both passing and failing cases.

### Renamed config field

`mode:` in `.spades/config` becomes `backend:`. There is no `hybrid`
backend — that mode was rarely correct in practice; teams now pick
`linear` or `local` and stay there.

### Migration

No automatic migration tool. v2.0 is a fresh start. Existing v1
artefacts (M-NNN-plan.md files, sp-XXXXXX scope IDs) won't pass the
v2 lint. Users should treat v2 as a clean install — run
`/spades:setup`, `/spades:newproject`, and re-create scopes as needed.

## [Earlier history — v1.x]

## [Previous 2.0.0 marketplace-repackage entry] — 2026-05-24

**Breaking — pure-Markdown plugin. No bash, no `~/.spades`, no setup
script.** SPADES is now distributed solely as a Claude Code plugin.
The two-place install (`/plugin install` + `git clone ~/.spades && setup`)
collapses to one command. All bash helpers are gone; the marker-replace
contract that maintains the framework block in consumer `AGENTS.md` /
`CLAUDE.md` now lives in skill prose as a state machine Claude executes
through `Read` and `Edit`.

Skill renames (breaking):

- All skills lose their `spades-` filename prefix. They are now
  plugin-namespaced as `/spades:<name>` via the plugin name in
  `.claude-plugin/plugin.json`.
- `/spades-onboard` → `/spades:init` — clearer name for the
  initialise-this-project flow.
- `/spades-update` — **deleted.** Plugin marketplace handles updates
  (`/plugin update spades@spades-framework`); re-running `/spades:init`
  re-stamps the consumer's fragment markers in place.
- `/spades-handoff` — **deleted.** The macOS-only AppleScript spawner
  is gone; humans can still launch a fresh agent manually.

Distribution / install:

- Repo restructured to canonical plugin layout: `skills/` and
  `agents/` at the root (no longer under `.claude/`); fragments,
  templates, examples, and docs at the plugin root.
- `setup`, `setup.ps1`, `bin/` directory (4 bash helpers), the
  `scripts/spades-*` mirrors, `scripts/release-plugin.sh`, and
  `render/` (HTML CSS) — all deleted.
- Skill prose references bundled siblings via
  `${CLAUDE_PLUGIN_ROOT}/<path>` substitution.

Templates:

- New `templates/ARCHITECTURE.md`, `templates/PATTERNS.md`,
  `templates/ANTI-PATTERNS.md` — proper blank templates with
  `<!-- Describe ... -->` placeholders for consumer repos. The
  framework's own root architecture docs no longer double as
  consumer templates (a pre-existing wart from v1.x).

CI:

- `.github/workflows/lint.yml` drops the `handoff`,
  `render-css-budget`, and `render-smoke` jobs. Deleted lints:
  `lint-render-smoke.sh`, `lint-handoff.sh`.

Cross-platform:

- Windows works natively without WSL or Git-Bash. The "External
  Toolchain Policy" subsection covering `bin/spades-marker-replace`
  bash dependency is gone.

Scope: M-1024 (collapse to pure plugin).

## [1.8.0] — 2026-05-18

**Local-mode artefact hardening — schema enforcement + stable IDs.**
The local-mode frontmatter schema is now machine-enforced in CI, and
every local Scope carries a stable identifier independent of its slug.

- `docs/FRAMEWORK.md` § Local Layout — adds the `id` field: a stable
  short identifier (`sp-` + six base32 characters) generated once at
  Scope creation, distinct from the title-derived slug, collision-
  resistant without a central allocator, and correctness-only — not an
  authorisation or trust primitive. The `status` / `type` / `priority`
  value sets are marked the canonical enum lists the schema lint
  enforces.
- New `scripts/lint/lint-local-frontmatter.sh` + a `local-frontmatter`
  CI job. `frontmatter.py` gains a `--schema` mode: Scope files
  hard-fail on an invalid `status` / `type` / `priority` enum value or
  a missing core field, and warn (not fail) on an unknown field or a
  missing `id` (grandfathered on pre-v1.8 files). Plan files get a
  light warn-only check; learnings stay with `lint-learnings.sh`. A
  legacy fixture and a bad-enum fixture self-test the check.
- `/spades:scope` now generates the `id` for new Scopes and aborts on a
  slug collision rather than silently overwriting an existing Scope.

Scope: M-1023. v1.8.0 also carries the `/spades-handoff` launcher,
merged unreleased since v1.7.0.

## [1.7.0] — 2026-05-18

**Local mode — read/write parity without Linear.** SPADES skills now
work end-to-end with no Linear MCP, reading and writing canonical state
from `.spades/`. A repo declares `mode: local | linear | hybrid` in
`.spades/config`; the canonical store becomes a per-repo choice rather
than a framework default. Consumer repos running under a hand-written
CLAUDE.md override to force local behaviour can drop that override.

Operating modes:

- `docs/FRAMEWORK.md` § Operating Modes — new single-source contract.
  § Mode Resolver: an explicit `mode:` wins; otherwise a `list_teams`
  probe with a 5-second timeout, resolving `linear` only when the
  configured `team_id` is in the returned set. Failure policy is
  asymmetric — fail-loud when an explicitly-configured tracker is
  unreachable, degrade-quiet to `local` when the repo was never
  configured. § Local Layout: canonical `.spades/` paths, slug grammar
  `[a-z0-9-]{1,64}`, the Scope frontmatter schema, and the
  `.spades/version` tie with pre-v1.7 grandfathering. § Hybrid Mode:
  tracker-canonical with a **non-authoritative** local mirror.

Skills:

- All nine skills (`/spades:scope`, `/spades:plan`, `/spades:approve`,
  `/spades:evaluate`, `/spades:list`, `/spades:status`, `/spades:learn`,
  `/spades:quick`, `/spades:init`) carry a "Mode Resolution" section
  and key tracker-vs-local behaviour off the resolved mode.
- `/spades:list` and `/spades:status` gain genuine `local`-mode code
  paths — they scan `.spades/scopes/` and parse frontmatter instead of
  hard-requiring Linear MCP. This was the M-879 origin bug.
- `/spades:init` scaffolds `.spades/scopes|plans|learnings` and writes
  a starter `.spades/config` with an explicit `mode:` chosen once at
  onboard time.
- `/spades-update` adds the v1.6.1 → v1.7.0 migration: it writes an
  explicit `mode:` line into `.spades/config` if absent, leaving every
  `.spades/plans/*` file grandfathered.

Lint:

- New `scripts/lint/lint-mcp-guard.sh` + `mcp-guard` CI job — fails
  when a skill names a Linear MCP tool without a "## Mode Resolution"
  section. A planted-violation fixture self-tests the check on every
  run, closing the manual-verification gap.

Fixtures:

- `examples/fixture-local-mode/` and `examples/fixture-linear-mode/` —
  minimal consumer repos for the manual happy-path verification.

Scope: M-879 (planned and delivered under the SPADES loop; the Scope's
stale "v1.4.0" version target was re-pointed to 1.7.0 at planning, the
framework already being at 1.6.1). v1.7.0 also carries the INTENT.md
project-intent loop (M-951).

## [1.6.1] — 2026-05-16

**Patch release — renderer fix and polish.** v1.6.0's HTML renderer
did not work on Pandoc 3.x. This release fixes it, gives the rendered
output a real visual design, and realigns the render lint with what
the feature is — a local-only convenience renderer, not a web app.

Renderer:

- `render/template.html`: fixed the `$for(css)$` block. It called
  non-existent Pandoc partials (`$styles.css()$`, `$css-content()$`)
  and made `spades-render` fail with exit 3 (`Could not find data file
  templates/styles.css`) on Pandoc 3.x. The stylesheet is now linked
  and inlined via `--embed-resources`, with `$highlighting-css$` for
  syntax highlighting. The `<html>` element carries `data-spades-status`
  so the stylesheet can theme to the document's phase.
- `bin/spades-render`: switched the deprecated `--highlight-style` flag
  to `--syntax-highlighting` (Pandoc 3.9+).
- `render/spades.css`: editorial redesign — status-coloured top accent
  bar, restructured document header (kicker pills, prominent title,
  quiet meta line), refined table of contents with nested indent
  guides, zebra-striped tables, softer code chips, tightened type
  scale. Light and dark both verified. 8.9KB, within the 12KB budget.

Lint:

- `scripts/lint/lint-render-security.sh` → `lint-render-smoke.sh`. The
  XSS / CSP / path-leak scan is replaced by a render smoke test: every
  fixture must render (exit 0) to a non-empty, standalone HTML document
  with the stylesheet inlined. `spades-render` turns the user's own
  Markdown into a local file they open themselves, so there is no
  web-security threat model to enforce; a functional regression guard
  (it would have caught the Pandoc 3.x breakage) is the right check.
  CI job renamed `render-security` → `render-smoke`.

Skills:

- `/spades:scope`: the render-and-link step is now a mandatory closing
  step, promoted from a trailing section so it is not treated as an
  optional appendix.

No fragment changes. Consumers on v1.6.0 only need to bump their
`.spades/version` pin to `1.6.1`.

## [1.6.0] — 2026-05-13

**HTML rendering for scopes and plans (Pandoc).** Every locally-stored
SPADES Scope and Plan now gets a sibling `.html` rendering produced by
the new `bin/spades-render` POSIX-shell wrapper around `pandoc`.
`/spades:scope` and `/spades:plan` append a clickable
`View in browser: file://...` link on every local write — modern
terminals (iTerm2, Warp, VS Code, Terminal.app) auto-linkify the URL
for cmd-click. Markdown remains canonical; HTML is a read-only
rendered view.

Released artefacts:

- `bin/spades-render` — POSIX-shell wrapper around `pandoc`, ≤100 lines.
- `render/template.html` — Pandoc HTML5 template (status header from
  frontmatter, TOC, restrictive CSP meta).
- `render/spades.css` — ≤12KB inlined stylesheet (system-font
  typography, six status pill colours, syntax highlighting via
  Pandoc's Skylighting, `prefers-color-scheme: dark`, `@media print`).
- `scripts/lint/lint-render-security.sh` + new `render-css-budget` and
  `render-security` CI jobs — fixture-driven XSS / path-leak / CSP
  assertions enforced on every PR.
- `tests/fixtures/render/{xss-attempts,minimal-scope}.md` — security
  and smoke fixtures.
- `docs/FRAMEWORK.md` §HTML Rendering — single source of truth for the
  Pandoc install matrix, renderer interface, status pill palette
  (hex values), security stance, recommended `.gitignore` line,
  `file://` linkification rule, and determinism contract.
- `ARCHITECTURE.md` §External Toolchain Policy — Pandoc named as a
  recommended consumer binary (same category as `git`/`jq`).

Skill changes:

- `/spades:scope` and `/spades:plan` gained a "Rendering and terminal
  link (v1.6+)" closing section. The render + link step is purely
  additive; existing skill behaviour is unchanged. Render failure
  never aborts the skill — the `.md` is always written.
- `/spades-update` documents the v1.3.x → v1.6.0 upgrade recipe with
  an informational pandoc presence check. No bulk render of historical
  `.md` files (lazy on next write only).

Architectural posture preserved:

- No vendored third-party code. No Node, no npm, no compiled
  artefacts. Pandoc is a recommended consumer dep, not a library.
- `PATTERNS.md` unchanged — "Markdown + YAML frontmatter is the only
  data format" still holds; HTML is a rendered view, not data.
- Graceful degradation: when pandoc is absent, `spades-render` exits 2
  and the calling skill surfaces an install hint on every write
  (not one-time-per-session) until pandoc is installed.

Deferred to v1.7+ (out of scope here):

- Mermaid pre-rendering (would pull in headless Chromium via `mmdc`).
- Terminal links on read skills (`/spades:status`, `/spades:list`,
  `/spades:approve`, `/spades:evaluate`, `/spades:review`).
- Bulk render on `/spades-update`.
- Auto-injection into the consumer's `.gitignore` (documented for
  opt-in only).
- AC checkbox state persistence, sticky TOC, dark-mode toggle button.
- Panel-report and learnings HTML rendering.

Scope: M-901. Two `/spades:review` panel rounds on the pre-shipped
drafts (33 + 41 findings, 4 blocking on the original Node-bundle
architecture) drove the switch to Pandoc and the minimum-viable
shape.

## [1.3.0] — 2026-04-28

- New skill `/spades:research` — landscape research via an isolated
  Opus 4.7 read-only subagent.
- New framework convention "Asking the Human" (`AskUserQuestion` for
  fixed-option decisions).
- Several skills retrofitted to the new convention.

## [1.2.0] — earlier

- M-420: Linear-canonical Plan storage. `.spades/plans/` becomes a
  fallback for Linear-less environments rather than a default
  dual-write.

## [1.1.x] — earlier

- Multi-persona `/spades:review` panel (5 subagents).
- `/spades:learn` skill.
- Execution posture field in Plan templates.
- CI lint suite.

## [1.0.0] — earlier

- Initial release: `/spades:scope`, `/spades:plan`, `/spades:approve`,
  `/spades:evaluate`, `/spades:quick`, `/spades:init`,
  `/spades:status`, `/spades:list`, `/spades-update`.
- Fragment-marker-based onboarding via `bin/spades-marker-replace`.
