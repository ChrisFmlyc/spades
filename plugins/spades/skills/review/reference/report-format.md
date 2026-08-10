# Review report format

Read this when you reach "Presenting the Report" in
`skills/review/SKILL.md`. It owns the envelope schema, the
dispatch-mode banner, the tiered inline digest, and the persisted
report — everything about *how the panel's output is shaped*. The
merge that produces the findings is SKILL.md's job, not this file's.

## Contents

- **Report envelope (v2.0.0)** — the JSON block, required fields, and
  the Plan frontmatter stamp
- **Dispatch-mode banner** — the three-point agreement check
- **Tiered inline report** — CLI vs HTML branching, ordering, budgets,
  and both worked shapes (normal and degraded)
- **Persisted full report** — canonical `.md`, the
  `worker-html-review` dispatch, failure fallback

---

## Report envelope (v2.0.0)

The merged report carries a top-level envelope so downstream tooling
can parse it without inspecting Markdown prose. It appears as a
`json` code block immediately after the banner and MUST be valid
JSON.

```json
{
  "schema_version": "2.0.0",
  "dispatch_mode": "subagent-dispatch",
  "personas_spawned": 4,
  "personas_completed": 4,
  "findings_total": 0
}
```

| Field | Contract |
|---|---|
| `schema_version` | `"2.0.0"` for this contract. A consumer seeing a different version falls back to prose parsing or flags the mismatch. Independent of `.spades/version` and of the fragment-marker mechanism `/spades:setup` uses. |
| `dispatch_mode` | `subagent-dispatch` \| `sequential-inproc` \| `degraded`. Same value as the banner. |
| `personas_spawned` | Integer count actually invoked. Always `4` under v2.0.0. |
| `personas_completed` | Personas whose `spades-findings` block parsed successfully. **Count them; do not estimate.** A persona whose JSON failed to parse still shows its prose but does **not** increment this. |
| `findings_total` | Length of the final merged list, counted after convergence merging. Do not estimate. |

**When the target is a Plan, stamp the tally onto that Plan** —
write `panel_blocking`, `panel_major`, `panel_minor` (merged finding
counts by severity) into its frontmatter. This is the review writing
to the artefact it reviewed, not a cross-skill call. The Plan
template reads these; absent → it shows `not run`.

v2.0.0 is the M-994 redesign: four personas, `nit` removed from
`severity`, `confidence` recast to a `high | low` string, and no
merge-side confidence filter. The v1.1 sixth field
`findings_filtered_low_confidence` is gone with the filter it
counted. If finding shape changes again, bump `schema_version`.

## Dispatch-mode banner

Both artefacts begin with the banner (the value recorded during
spawning) then the envelope JSON. **`Dispatch mode: <value>` is
always the first line of output** — before any prose, the envelope,
or the title — so `head -n 1` or a top-of-report regex surfaces the
mode without parsing JSON.

The section title depends on the mode:

- `subagent-dispatch` / `sequential-inproc` → `PANEL SECOND OPINION`
- `degraded` → `SINGLE-CONTEXT SIMULATION (degraded)`, and the words
  "panel" and "multi-persona" MUST NOT appear anywhere in the header
  or framing prose.

**Three-point agreement check.** The mode is asserted in three places
that must agree: the banner's first line, the envelope's
`dispatch_mode`, and the section title. A reader confirms a run was
a genuine multi-context panel by checking all three agree and none
say `degraded`. Disagreement means the report is malformed. This is
what makes it impossible to silently present a degraded run as a
panel, and it holds in the inline digest and the persisted file
alike.

## Tiered inline report

**Read `review_format:` from `.spades/config` and branch.**

- **CLI mode** — this digest IS the human's review surface; print it
  in full.
- **HTML mode** — do **not** print it. The rendered `.html` is the
  review surface; the terminal gets only `✓ Review written: <path>`
  plus conversational text.

Both modes still write the canonical `.md`. The digest content is
identical between surfaces — only where it renders differs.

Order:

1. Banner and envelope JSON.
2. Section title.
3. **Persona summaries** — each persona's prose **verbatim**. Never
   summarise a persona in your own words; the point is that the human
   sees each independent view unfiltered.
4. **Convergence** — every merged finding with a non-empty
   `also_flagged_by`, in full. Convergence is the panel's strongest
   signal, so it leads.
5. **Blocking and major.** Every `blocking` finding in full, always —
   blocking is never suppressed or collapsed. `major` findings then
   fill an inline budget of roughly 5–7 findings total (convergence
   and blocking already shown count toward it). Overflow collapses to
   `+N more major finding(s) — see full report`.
6. **Minor** never prints individually — one count line: `N minor
   finding(s) — see full report`.
7. `Full report: <path>`.

### Shape — `subagent-dispatch` or `sequential-inproc`

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

Full report: .spades/reviews/s-add-ai-helper-bot-2026-05-17.md

════════════════════════════════════════════════════════════
```

### Shape — `degraded`

Identical structure, with the honest framing swapped in:

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

  <four sections, as above>

Convergence — runs that landed on the same concern:

  ...

Findings — every blocking in full; major up to the inline budget:

  ...
  +N more major finding(s) — see full report.
  N minor finding(s) — see full report.

Full report: .spades/reviews/s-add-ai-helper-bot-2026-05-17.md

════════════════════════════════════════════════════════════
```

## Persisted full report

On **every** run — `degraded` included — write the full report under
`.spades/reviews/`, **before** the inline digest prints.

### Canonical `.md` (both modes)

- **Path:** `.spades/reviews/<slug>-<date>.md`. `<slug>` is the
  reviewed Scope or Plan's tracker identifier lower-cased (e.g.
  `s-add-ai-helper-bot`), or a short kebab-case slug from its title
  when there is no identifier. `<date>` is `YYYY-MM-DD`.
- **Collision rule:** if the path exists — a repeat run on the same
  date — append a numeric suffix (`-2`, then `-3`, …). **Never
  overwrite an existing review file**; each run is its own audit
  record.
- **Contents:** banner, envelope, section title, every persona's
  prose verbatim, **every** merged finding at every severity in full
  (the file is not tiered — it is the complete record), and the
  cross-model synthesis.
- `.spades/reviews/` is gitignored by default — a local audit
  artefact, not committed output. Create the directory lazily on
  first write.

### `worker-html-review` dispatch (HTML mode only)

When `review_format: html`, dispatch `worker-html-review` per
`docs/FRAMEWORK.md § worker-html-* — parallel HTML rendering`, in the
same wave as the `.md` write. No inline render.

- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/review/template.html`
- `output_path`: `.spades/reviews/<slug>-<date>.html` — same slug and
  collision rules as the `.md`
- `frontmatter`: `{ target_id, target_title, mode (Scope|Plan|Full),
  verdict, date, dispatch_mode, project }`, also embedded verbatim in
  `<script id="spades-frontmatter">`. `project` is the active project
  slug, for the properties rail; optional.
- `blocks`:
  - `objective-banner` — 0 or 1 item `{ id, title }` per
    `FRAMEWORK.md § Objective banner`. Resolve from the reviewed
    target's `strategy_link` (a Scope's, or a Plan's parent Scope's),
    counting it **only** when it matches an existing
    `.spades/objectives/O-<slug>.md`; otherwise `[]`.
  - `persona-cards` — one per persona (4). Fields: `persona,
    summary_html, finding_count`.
  - `findings` — one per merged finding, every severity, ungated.
    Fields: `severity, confidence, category, persona, message_html,
    refs, also_flagged_by`.
  - `convergence-cards` — one per cluster. Fields: `label, personas,
    severity`.
- `prose_sections`: `{ synthesis_html }` (cross-model synthesis).

Required markers: `<!-- SPADES-BLOCK:persona-cards -->`,
`<!-- SPADES-BLOCK:findings -->`,
`<!-- SPADES-BLOCK:convergence-cards -->`.

### Failure fallback

The inline report's `Full report:` pointer names the file just
written. If a write fails, say so plainly inline (`Full report: write
failed — <reason>`) and continue — **a failed persistence write never
aborts the review.** If the `.md` and/or `.html` write failed in HTML
mode, print the digest to the CLI as a backup so the human still sees
the panel output. In CLI mode this is moot; the digest is already the
primary display.
