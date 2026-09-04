# Review report format

Read this at "Presenting the report" in `skills/review/SKILL.md`. It
owns the envelope, the dispatch-mode banner, the tiered digest, and
the persisted report. The merge is SKILL.md's job.

## Contents

- Report envelope — the JSON block, its fields, and the Plan stamp
- Dispatch-mode banner — the three-point agreement check
- Tiered digest — CLI vs HTML, ordering, budgets, both shapes
- Persisted report — canonical `.md`, the `.html`, failure fallback

---

## Report envelope

A JSON code block immediately after the banner, valid JSON:

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
| `schema_version` | `"2.0.0"`. Independent of `.spades-anywhere/version` and the setup marker; bumps when finding shape changes. |
| `dispatch_mode` | `subagent-dispatch` \| `sequential-inproc` \| `degraded`; the banner's value. |
| `personas_spawned` | `4`. |
| `personas_completed` | Personas whose `spades-findings` block parsed; counted, not estimated. |
| `findings_total` | Length of the merged list after convergence; counted. |

**Plan targets get a stamp.** Write `panel_blocking`, `panel_major`,
`panel_minor` into the Plan's frontmatter; the Plan template reads
them and shows `not run` when absent.

## Dispatch-mode banner

`Dispatch mode: <value>` is the first line of both artefacts. The
section title follows the mode: `PANEL SECOND OPINION` for
`subagent-dispatch` and `sequential-inproc`; `SINGLE-CONTEXT
SIMULATION (degraded)` for `degraded`, whose framing prose describes
the run as one context re-prompted per persona.

**Three-point agreement.** The banner line, the envelope's
`dispatch_mode`, and the section title agree; disagreement means a
malformed report. This is what lets an audit trail citing
"multi-persona review" know what produced it.

## Tiered digest

**CLI mode** — the digest is the review surface; print it in full.
**HTML mode** — the rendered `.html` is the surface; the terminal
gets `✓ Review written: <path>` and conversational text. Both modes
write the canonical `.md`.

Order:

1. Banner and envelope.
2. Section title.
3. **Persona summaries** — each persona's prose verbatim.
4. **Convergence** — every merged finding with a non-empty
   `also_flagged_by`, in full.
5. **Blocking and major** — every `blocking` in full, always;
   `major` up to a budget of roughly 5–7 findings total, overflow
   collapsing to `+N more major finding(s) — see full report`.
6. **Minor** — `N minor finding(s) — see full report`.
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

Full report: .spades-anywhere/reviews/s-plan-birthday-party-2026-05-17.md

════════════════════════════════════════════════════════════
```

### Shape — `degraded`

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

Full report: .spades-anywhere/reviews/s-plan-birthday-party-2026-05-17.md

════════════════════════════════════════════════════════════
```

## Persisted report

Written on every run, `degraded` included, before the digest.

### Canonical `.md` (both modes)

- **Path:** `.spades-anywhere/reviews/<slug>-<date>.md` — the
  reviewed artefact's ID lower-cased, `YYYY-MM-DD`.
- **Collision:** a repeat run on the same date appends `-2`, `-3`, …
- **Contents:** banner, envelope, section title, every persona's
  prose verbatim, every merged finding at every severity in full,
  and the cross-model synthesis.
- The directory is created lazily on first write. Where the
  knowledge store is a git repo, `.spades-anywhere/reviews/` is
  ignored by default.

### The `.html` (HTML mode)

Rendered from `${CLAUDE_PLUGIN_ROOT}/skills/review/template.html` to
`.spades-anywhere/reviews/<slug>-<date>.html` (same slug and
collision rules) per `docs/FRAMEWORK.md § Output Format → HTML
rendering`:

- `frontmatter`: `{ target_id, mode (Scope|Plan|Full),
  personas_count, dispatch_mode, verdict_class, verdict_label,
  blocking_count, major_count, minor_count, nit_count, rendered_at,
  plugin_version, project }`, embedded verbatim in
  `<script id="spades-frontmatter">`. `project` is optional.
  `verdict_class` is a CSS class the template styles (`clean` /
  `no-blocking` green the BLOCKING deck); `verdict_label` the human
  string beside it. The `*_count` scalars are numbers.
- `blocks`:
  - `objective-banner` — 0 or 1 item `{ id, title }` per
    `docs/FRAMEWORK.md § Objective banner`, from the target's
    `strategy_link` (a Scope's, or a Plan's parent Scope's); else
    `[]`.
  - `persona-cards` — one per persona. Fields: `persona_id,
    persona_class, findings_count, summary_html`.
  - `findings` — one per merged finding, every severity. Fields:
    `severity, title_html, source, body_html`.
  - `convergence-cards` — one per cluster. Fields: `title,
    corroborated_by, desc_html`.

The template has no synthesis placeholder; the synthesis lives in
the `.md` and the digest. Field names are the template's and are
substituted literally.

Required markers: `persona-cards`, `findings`, `convergence-cards`.

### Failure fallback

A failed persistence write never aborts the review. Say so inline
(`Full report: write failed — <reason>`) and continue; in HTML mode
print the digest to the CLI as the backup surface.
