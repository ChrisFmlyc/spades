# Review report format

Read this when you reach "Presenting the Report" in
`skills/review/SKILL.md`. It owns the envelope schema, the
dispatch-mode banner, the tiered inline digest, and the persisted
report — everything about *how the panel's output is shaped*. The
merge that produces the findings is SKILL.md's job, not this
file's.

## Contents

- Report envelope (v2.0.0) — the JSON block and its required fields
- Dispatch-mode banner — the three-point agreement check
- Tiered inline report — CLI vs HTML branching, ordering, budgets,
  and both worked shapes (normal and degraded)
- Persisted full report — canonical `.md`, HTML render, failure
  fallback

---

## Report envelope (v2.0.0)

The merged report carries a top-level envelope so downstream tooling
can parse the report without inspecting the Markdown prose. The
envelope appears as a `json` code block immediately after the banner
(see Presenting the Report below) and MUST be valid JSON.

```json
{
  "schema_version": "2.0.0",
  "dispatch_mode": "subagent-dispatch",
  "personas_spawned": 4,
  "personas_completed": 4,
  "findings_total": 0
}
```

Required fields:

- `schema_version` — the string `"2.0.0"` for this contract. A consumer
  that encounters a different version knows to fall back to prose
  parsing or flag the mismatch. `2.0.0` is the M-994 redesign: four
  personas, `nit` removed from `severity`, `confidence` recast to a
  `high | low` string, no merge-side confidence filter. This is the
  **report-envelope** contract version — it is independent of the
  framework's `.spades-anywhere/version` and of the fragment-marker mechanism
  `/spades-anywhere:setup` uses to refresh consumer files on plugin upgrade.
- `dispatch_mode` — one of `subagent-dispatch`, `sequential-inproc`,
  `degraded`. Same value as the banner line.
- `personas_spawned` — integer count of personas actually invoked.
  Always `4` under v2.0.0.
- `personas_completed` — the number of personas whose `spades-findings`
  block parsed successfully. Count them; do not estimate. If a
  persona's JSON block failed to parse, its prose still shows in the
  report but it does NOT increment this counter.
- `findings_total` — the number of findings in the merged report:
  literally the length of the final merged list, counted after
  convergence merging. Do not estimate.

**When the review target is a Plan, stamp the panel tally onto that
Plan** so the Plan page can echo it — write `panel_blocking`,
`panel_major`, `panel_minor` (the counts of merged findings by
severity) into the Plan's frontmatter. This is the review writing to
the artefact it reviewed; not a cross-skill call. The Plan template
reads these; absent → it shows `not run`.

The v1.1 envelope carried a sixth field,
`findings_filtered_low_confidence`, counting findings dropped by the
merge-side confidence filter. v2.0.0 removes both the filter and the
field — `confidence` is no longer a float, and the per-persona caps
moved filtering to generation time.

Per-persona finding shape changed in v2.0.0: `severity` lost the `nit`
value and `confidence` became a `high | low` string. If a future
version changes finding shape again, bump `schema_version`.

## Presenting the Report

A panel run produces two artefacts: a **tiered inline report** written
to the terminal, and a **full report** persisted to a file. The inline
report is a digest — it leads with the signal and fits on a screen; the
full report is the complete audit record.

### The dispatch-mode banner and envelope

Both artefacts begin with a **dispatch-mode banner** (the value you
recorded during spawning) and the **report envelope** JSON. The banner
line (`Dispatch mode: <value>`) is ALWAYS the first line of output,
before any prose, the envelope JSON, or the section title — so a
`head -n 1` or a regex scan of the top-of-report surfaces the mode
without parsing the envelope.

The section title depends on dispatch mode:

- When `dispatch_mode` is `subagent-dispatch` or `sequential-inproc`,
  the title is `PANEL SECOND OPINION`.
- When `dispatch_mode` is `degraded`, the title is
  `SINGLE-CONTEXT SIMULATION (degraded)`. You MUST NOT use the words
  "panel" or "multi-persona" anywhere in a degraded report's header or
  framing prose — see "What This Skill Must Never Do" below.

**Degraded-detection check.** The dispatch mode is asserted in three
places that MUST agree: the banner's first line, the envelope's
`dispatch_mode` field, and the section title (`PANEL SECOND OPINION`
for a real panel; `SINGLE-CONTEXT SIMULATION (degraded)` for a degraded
run). A reader — or a downstream tool — confirms a run was a genuine
multi-context panel by checking that all three agree and none say
`degraded`. If the three disagree, the report is malformed. This
three-point agreement is the stated check that a degraded run can never
be silently presented as a panel; it holds in the inline report and the
persisted file alike.

### The tiered inline report (CLI mode)

**Read `review_format:` from `.spades-anywhere/config` and branch.**
In CLI mode this digest IS the human's review surface and prints to
the terminal in full. In HTML mode the digest is *not* printed
inline — the rendered `.html` (written under "The persisted full
report" below) is the human's review surface, and the terminal gets
only a short `✓ Review written: <path>` line plus any conversational
text. Both modes still write the canonical `.md`; the digest content
is identical between surfaces — only where it renders differs.

The inline report shows, in order:

1. The banner and the envelope JSON.
2. The section title.
3. **Persona summaries** — each persona's prose summary, verbatim.
   Never summarise a persona's prose in your own words; the whole point
   is that the human sees each independent view unfiltered.
4. **Convergence** — every merged finding with a non-empty
   `also_flagged_by` array, shown in full. Convergence is the panel's
   strongest signal, so it leads the findings.
5. **Blocking and major findings.** Every `blocking` finding is shown
   in full, always — blocking is never suppressed or collapsed. `major`
   findings then fill an inline budget of roughly 5–7 findings total
   (the convergence and blocking findings already shown count toward
   that budget). `major` findings beyond the budget are not printed
   individually — they collapse to a count line:
   `+N more major finding(s) — see full report`.
6. **Minor findings** never print individually inline. They collapse to
   a single count line: `N minor finding(s) — see full report`.
7. A pointer to the persisted full report: `Full report: <path>`.

Inline shape when dispatch mode is `subagent-dispatch` (or
`sequential-inproc`):

```
Dispatch mode: subagent-dispatch

```json
{"schema_version":"2.0.0","dispatch_mode":"subagent-dispatch",
 "personas_spawned":4,"personas_completed":4,"findings_total":14}
```

PANEL SECOND OPINION
════════════════════════════════════════════════════════════

Summary from each persona (their own words, verbatim):

─── scope-guardian ─────────────────────────────────────────

  <prose summary>

─── architecture-strategist ────────────────────────────────

  <prose summary>

─── security-lens ──────────────────────────────────────────

  <prose summary>

─── adversarial-reviewer ───────────────────────────────────

  <prose summary>

Convergence — independent personas on the same concern:

  [major, also_flagged_by ×2] security-lens — <message>
    refs: Plan Task 2
    also_flagged_by: [adversarial-reviewer, architecture-strategist]

Findings — every blocking in full; major up to the inline budget:

  [blocking] architecture-strategist — <message>
    refs: ANTI-PATTERNS.md#..., Plan Task 4
  [major]    scope-guardian — <message>
    refs: Plan Task 3
  +3 more major finding(s) — see full report.
  9 minor finding(s) — see full report.

Full report: .spades-anywhere/reviews/s-add-ai-helper-bot-2026-05-17.md

════════════════════════════════════════════════════════════
```

Inline shape when dispatch mode is `degraded`:

```
Dispatch mode: degraded

```json
{"schema_version":"2.0.0","dispatch_mode":"degraded",
 "personas_spawned":4,"personas_completed":4,"findings_total":14}
```

SINGLE-CONTEXT SIMULATION (degraded)
════════════════════════════════════════════════════════════

This report was produced by re-prompting a single model context with
each persona's priming in turn — it is NOT a multi-context review.
Consumers relying on independence between reviewers should treat
findings as lower-confidence than the headline severity suggests.

Summary from each persona-prompted run (verbatim):

─── scope-guardian ─────────────────────────────────────────

  <prose summary>

─── architecture-strategist ────────────────────────────────

  <prose summary>

─── security-lens ──────────────────────────────────────────

  <prose summary>

─── adversarial-reviewer ───────────────────────────────────

  <prose summary>

Convergence — runs that landed on the same concern:

  ...

Findings — every blocking in full; major up to the inline budget:

  ...
  +N more major finding(s) — see full report.
  N minor finding(s) — see full report.

Full report: .spades-anywhere/reviews/s-add-ai-helper-bot-2026-05-17.md

════════════════════════════════════════════════════════════
```

### The persisted full report

On **every** panel run — `degraded` runs included — write the full
report to a file under `.spades-anywhere/reviews/`. **Read `review_format:`
from `.spades-anywhere/config` and branch on the format.** The review MUST
write a file before the inline digest is printed.

#### Write the canonical `.md` (both modes)

- **Path:** `.spades-anywhere/reviews/<slug>-<date>.md`. `<slug>` is the reviewed
  Scope or Plan's tracker identifier lower-cased (e.g. `s-add-ai-helper-bot`), or a
  short kebab-case slug derived from its title when there is no
  identifier; `<date>` is `YYYY-MM-DD`.
- **Collision rule:** if that path already exists — a repeat run of the
  same slug on the same date — append a numeric suffix:
  `<slug>-<date>-2.md`, then `-3`, and so on. Never overwrite an
  existing review file; each run is its own audit record.

#### Additionally render the HTML (HTML mode only)

When `review_format: html`, after the `.md` above is written,
render the HTML companion file. The `.md` is unchanged; the
`.html` is **additive**.


**You MUST render via the bundled `template.html`. Do NOT
hand-roll the HTML.** Validate the template exists and the named
blocks below match the markers in the actual file before
substituting; abort and surface any mismatch. See
`docs/FRAMEWORK.md § Output Format → HTML rendering: validate and
use the bundled template` for the canonical rule.

- Read the template at
  `${CLAUDE_PLUGIN_ROOT}/skills/review/template.html`.
- Validate it contains the block markers listed below; if any are
  missing, abort.
- Substitute placeholders per `docs/FRAMEWORK.md § Output Format`:
  - Envelope values fill `{{spades.target_id}}`,
    `{{spades.target_title}}`, `{{spades.mode}}` (Scope / Plan /
    Full), `{{spades.verdict}}` (overall), `{{spades.date}}`,
    `{{spades.dispatch_mode}}`, `{{spades.project}}` (the active
    project slug from `.spades-anywhere/config`, for the properties
    rail; optional).
  - The envelope YAML block also goes verbatim into the
    `<script type="application/yaml" id="spades-frontmatter">` tag.
  - `<!-- SPADES-BLOCK:objective-banner -->` — 0 or 1 item
    `{{block.id}}`, `{{block.title}}` per `docs/FRAMEWORK.md §
    Objective banner`. Resolve from the reviewed target's
    `strategy_link` (a Scope's, or a Plan's parent Scope's),
    counting it ONLY when it matches an existing
    `.spades-anywhere/objectives/O-<slug>.md` file — then pass
    `[{ id, title }]` (title read from that file); otherwise `[]`.
  - `<!-- SPADES-BLOCK:persona-cards -->` — repeated once per
    persona (4 cards: scope-guardian, architecture-strategist,
    security-lens, adversarial-reviewer). Per-item:
    `{{block.persona}}`, `{{block.summary_html}}`,
    `{{block.finding_count}}`.
  - `<!-- SPADES-BLOCK:findings -->` — repeated once per merged
    finding (every severity, ungated). Per-item: `{{block.severity}}`,
    `{{block.confidence}}`, `{{block.category}}`, `{{block.persona}}`,
    `{{block.message_html}}`, `{{block.refs}}`,
    `{{block.also_flagged_by}}`.
  - `<!-- SPADES-BLOCK:convergence-cards -->` — repeated once per
    convergence cluster. Per-item: `{{block.label}}`,
    `{{block.personas}}`, `{{block.severity}}`.
  - The cross-model synthesis prose is a direct
    `{{spades.synthesis_html}}` substitution, not a repeating block.
- **Path:** `.spades-anywhere/reviews/<slug>-<date>.html` with the same slug
  rules. Collision rule applies identically: `<slug>-<date>-2.html`,
  `-3`, etc.
- Auto-open via the OPEN_CMD prelude
  (`docs/FRAMEWORK.md § OPEN_CMD detection prelude`). **In HTML
  mode, do NOT print the inline CLI digest** — the open `.html`
  is the human's review surface. The terminal in HTML mode gets
  only the short `✓ Review written: <path>` confirmation +
  any conversational text. The full digest lives in the `.html`
  (and the same content is in the `.md` for the AI / fallback
  reading via `cat`).
- The `.md` from the previous sub-step is unchanged — both files coexist.
- **Contents:** the banner, the envelope, the section title, every
  persona's prose summary verbatim, **every** merged finding at every
  severity shown in full (the file is not tiered — it is the complete
  record), and the cross-model synthesis.
- `.spades-anywhere/reviews/` is gitignored by default; the review file is a
  local audit artefact, not committed output.

Create `.spades-anywhere/reviews/` lazily on the first write;
do not pre-create it. The inline report's `Full report:`
pointer names the file just written. If the write fails, say so
plainly inline (`Full report: write failed — <reason>`) and
continue — a failed persistence write never aborts the review.
**Failure fallback**: if the `.md` and / or `.html` write
failed in HTML mode, the digest *is* printed to CLI as a
backup so the human still sees the panel output. In CLI mode
this is moot — the digest is the primary display already.
