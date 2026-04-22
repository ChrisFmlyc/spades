---
scope: M-323
scope_url: https://linear.app/m-kopa/issue/M-323
title: "SPADE v1.1 — compound-engineering borrows"
plan_version: 1
generated_by: spade-plan (Claude Opus 4.7)
generated_at: 2026-04-21
status: approved
---

# Plan — SPADE v1.1 improvements (M-323)

## Summary

Five discrete bundles, delivered in low-risk → high-risk order. Each bundle
= one branch = one PR = one Linear sub-issue. Later bundles benefit from
earlier CI coverage.

Delivery order:

1. **Onboarding idempotency fix** (M-323-A) — defensive, enables safe re-runs
2. **Execution posture in Plan** (M-323-B) — schema + example + prose only
3. **CI + frontmatter lint** (M-323-C) — catches regressions in later bundles
4. **Learnings loop** (M-323-D) — new skill + storage + plan integration
5. **Multi-persona /spade-review** (M-323-E) — subagents + skill upgrade + docs

Version markers move from `v1.0.0` to `v1.1.0` in the final bundle.

---

## Bundle A — Onboarding idempotency fix

**Label:** `bundle:v11-onboarding-idempotency`
**Delivery mode:** AI
**Execution posture:** `characterization-first` — write the failing fixture
test first, then fix the skill and setup logic.

### Why this first

The recon against this repo confirmed `AGENTS.md` and `CLAUDE.md` carry
duplicated `SPADE-FRAMEWORK-START v1.0.0` sections — repeated onboarding
appends instead of replacing. That drift is a correctness + security-flavoured
bug (see `ANTI-PATTERNS.md#security-anti-patterns`). Fixing it first means
every later bundle can safely re-run onboarding in fixtures.

### Approach

1. Read current `/spade-onboard` skill prose to confirm the exact insertion
   instructions it gives the agent.
2. Rewrite the insertion contract: *if markers already exist, replace the
   delimited region in place; if absent, append with markers.*
3. Add explicit prose for the two-file case (`AGENTS.md` + `CLAUDE.md`) and
   the edge cases: (a) file missing, (b) markers with older version
   (`v1.0.0`) — replace and bump, (c) unterminated markers — refuse and
   surface an error to the human.
4. De-duplicate the existing `AGENTS.md` and `CLAUDE.md` in this repo as part
   of the same delivery (cannot ship the fix without cleaning up the evidence
   of the bug).

### Files touched

- `.claude/skills/spade-onboard/SKILL.md` — insertion contract rewrite
- `AGENTS.md` — collapse duplicated v1.0.0 block
- `CLAUDE.md` — collapse duplicated v1.0.0 block
- `tests/fixtures/onboard-clean/` and `tests/fixtures/onboard-existing/` — new
- `tests/onboard-idempotency.sh` — new (pure bash, runs the skill's contract
  against the two fixtures via a scripted inline onboarding shim)

### Risks

- **R1** — the "skill" is prose, not code; a fixture test has to simulate
  what the agent would do. Mitigation: the test targets the deterministic
  *file-writing contract* (fragment marker regex + replace-in-place), not the
  agent's decision-making. A small bash helper in `bin/` implements the
  contract and is what the skill prose tells the agent to call.
- **R2** — rewriting the skill could change its behaviour for v1.0.0
  consumers who then run `/spade-update`. Mitigation: new contract recognises
  `v1.0.0` markers and rewrites them to `v1.1.0` atomically.

### Dependencies

None. This is the base of the stack.

### Testing strategy

- New fixture test: run the marker-replace helper twice against
  `onboard-clean/` and `onboard-existing/`; diff the second-run output
  against the first. They must be identical.
- Manual: `/spade-onboard` on a scratch repo, re-run, `git diff` shows no
  change on the second run.

### Definition of done for bundle

- Fixture test passes locally.
- `AGENTS.md` and `CLAUDE.md` in this repo carry exactly one v1.0.0 block
  (they will be rewritten to v1.1.0 in the final bundle).
- PR description links back to M-323.

---

## Bundle B — Execution posture in Plan template

**Label:** `bundle:v11-execution-posture`
**Delivery mode:** AI
**Execution posture:** `test-first` against documented examples — update
`examples/example-plan.md` first to show the new shape, then teach
`/spade-plan` to emit it.

### Why second

Pure documentation + skill-prose change. No new code paths. Low blast radius.
Landing it early means the later bundles (particularly Bundle D and E) can
rely on the Plan schema already carrying posture.

### Approach

1. Define the posture vocabulary in one place (`docs/FRAMEWORK.md#plan-schema`):
   `test-first`, `characterization-first`, `refactor-first`, `spike`,
   `straight-through` (default). One-paragraph definition each.
2. Extend `examples/example-plan.md` with a per-task `Execution posture:` line.
3. Extend `/spade-plan` skill prose to (a) require the field on every task,
   (b) explain how to choose a posture from the vocabulary, (c) default to
   `straight-through` only when explicitly justified.
4. Extend `.spade/examples/example-plan.md` in lock-step (it is a committed
   copy).

### Files touched

- `docs/FRAMEWORK.md` — vocabulary reference
- `examples/example-plan.md` — shape example
- `.claude/skills/spade-plan/SKILL.md` — schema requirement
- `fragments/AGENTS-section.md` — brief mention
- `.gitignore` — prevent `.spade/docs/` and `.spade/examples/` residue from being committed

**Deviation from the original file list (per cross-bundle risk C1):** the
original plan included `.spade/docs/FRAMEWORK.md` and
`.spade/examples/example-plan.md` as "committed copies in sync". Those
paths are not, and should not be, tracked in the framework repo itself —
Bundle A's self-onboard guard establishes that this repo is the source of
truth and never carries injected copies. The `.spade/docs/` and
`.spade/examples/` directories exist here only as residue from a pre-guard
local onboarding run. Bundle B therefore updates only the canonical
`docs/FRAMEWORK.md` and `examples/example-plan.md`, and adds those two
paths to `.gitignore` so the residue cannot accidentally be committed
later. Consumer repos will continue to receive `.spade/docs/` and
`.spade/examples/` via `/spade-onboard`. of the field

### Risks

- **R1** — vocabulary bike-shedding. Mitigation: lock the five values in
  this Plan; extensions are future scope.
- **R2** — examples drift (one copy updated, the other not). Mitigation:
  the CI lint from Bundle C will catch this; in the interim the PR review
  does.

### Dependencies

- Bundle A (only for clean re-onboarding fixtures; not a hard dep).

### Testing strategy

- Manual: generate a trivial Plan via `/spade-plan` in a scratch repo;
  verify every task carries a posture line.
- Will be covered by CI lint in Bundle C (example schema validation).

### Definition of done

- Documented vocabulary exists and is referenced from the skill.
- Both example files render the posture on every task.
- PR description links M-323.

---

## Bundle C — CI + frontmatter lint

**Label:** `bundle:v11-ci-frontmatter-lint`
**Delivery mode:** AI
**Execution posture:** `test-first` — the CI workflow *is* the test.

### Why third

The previous two bundles introduce new schemas (marker contract; posture
field). Putting CI in place next protects every later change from silent
regressions. It is also the first bundle that touches `.github/workflows/`,
so a failure here is visible and contained.

### Approach

1. Add `.github/workflows/lint.yml`:
   - triggers: `pull_request`, `push` to `main`
   - runs on `ubuntu-latest`
   - uses only bash + `yq` (or a small pure-python frontmatter parser,
     preferred — avoids external action dependency) and `awk`
2. Add `scripts/lint/` (bash + small python helper, no npm):
   - `lint-skill-frontmatter.sh` — iterates `.claude/skills/*/SKILL.md`,
     parses frontmatter, asserts `name` and `description` present; optional
     fields (`phase`, `requires_mcp`, `min_spade_version`) validated if
     present.
   - `lint-examples.sh` — asserts `examples/example-scope.md` has the
     documented headings; `examples/example-plan.md` has `Execution posture:`
     on every task.
   - `lint-fragments.sh` — asserts `fragments/AGENTS-section.md` and
     `fragments/CLAUDE-section.md` carry exactly one `START` / `END` pair
     and the version markers match `.spade/version`.
   - `lint-onboard-idempotency.sh` — invokes the Bundle A marker-replace
     helper twice against fixtures; diffs must be empty.
3. Add `scripts/lint/README.md` — one page, how to run locally.
4. Pin Python to 3.11 via `actions/setup-python`; no other toolchains.

### Files touched

- `.github/workflows/lint.yml` — new
- `scripts/lint/*.sh` and `scripts/lint/frontmatter.py` — new
- `tests/fixtures/` — potentially extended with lint fixtures
- `README.md` — two-line mention under "Development"

### Risks

- **R1** — Python introduces a "runtime dependency" in the weak sense
  (CI needs it). `ANTI-PATTERNS.md` forbids runtime deps for the framework
  itself, but CI tooling is explicitly out of scope for that rule. Still,
  preferred: keep Python to `scripts/lint/` and use stdlib only; do not add
  `requirements.txt`.
- **R2** — flaky CI on first PRs while shaking it out. Mitigation: ship the
  workflow in `continue-on-error: false` but mark the job non-required in
  GitHub settings until two green runs pass on `main`.

### Dependencies

- Bundle A (marker-replace helper must exist to be called from
  `lint-onboard-idempotency.sh`).
- Bundle B (posture example must exist to be validated).

### Testing strategy

- CI on the PR itself is the test — the workflow must go green.
- Deliberately land a red-change commit (in a throwaway branch, not merged)
  to verify each of the four checks fails when it should.

### Definition of done

- Workflow green on PR.
- All four lints demonstrably fail on deliberately broken fixtures.
- Local `./scripts/lint/*.sh` runs succeed from a clean checkout.

---

## Bundle D — Learnings loop

**Label:** `bundle:v11-learnings-loop`
**Delivery mode:** AI
**Execution posture:** `test-first` on the storage format; `spike` on the
plan-integration prose (new pattern, iterate once landed).

### Why fourth

This is the largest surface area change: new skill, new directory, new
integration into `/spade-plan`. Placing it after CI means its new schemas
are lint-covered from day one.

### Approach

1. **Storage format.** `.spade/learnings/YYYY-MM-DD-<slug>.md` with YAML
   frontmatter:
   ```yaml
   ---
   title: string
   scope_ref: LIN-123          # optional, links back to originating Scope
   area: [onboarding, planning, delivery, review, other]
   tags: [list, of, strings]
   created: 2026-04-21
   status: active              # active | archived
   ---
   ```
   Body is free-form Markdown with two suggested sections: *What we learned*
   and *Why it matters for future work*.
2. **`/spade-learn` skill** — new at `.claude/skills/spade-learn/SKILL.md`.
   Two modes: default (capture) and `--refresh` (archive stale or
   contradictory entries; interactive, human-gated).
3. **Plan integration** — extend `/spade-plan` prose: before producing the
   Plan, grep `.spade/learnings/` for entries tagged with any term in the
   Scope's title or the tech stack row from `ARCHITECTURE.md`; surface
   matches in a dedicated "Prior learnings considered" section of the Plan.
4. **Lint** — validate learning frontmatter on any file under
   `.spade/learnings/`.

   **Deviation at delivery time (per cross-bundle risk C1):** the
   original Plan said "extend `scripts/lint/lint-examples.sh`" to do
   this. At delivery, the lint landed as its own script
   `scripts/lint/lint-learnings.sh` with a matching CI job, matching the
   "one lint = one concern" pattern Bundle C established. Extending
   `lint-examples.sh` would have given it two unrelated concerns
   (example files + learning files) and a misleading name. The
   behaviour, coverage, and failure shape are equivalent; only the
   file location differs. The `lint-learnings.sh` script also warns on
   active entries older than 180 days to pre-empt the R1 staleness
   risk.
5. **Seed** — commit two genuine learnings distilled from this Scope's
   recon:
   - `2026-04-21-onboarding-must-be-idempotent.md`
   - `2026-04-21-single-reviewer-is-weaker-than-panel.md`

### Files touched

- `.claude/skills/spade-learn/SKILL.md` — new
- `.spade/learnings/*.md` — new directory, seeded
- `.claude/skills/spade-plan/SKILL.md` — integration prose
- `scripts/lint/lint-examples.sh` — extend
- `docs/FRAMEWORK.md` — learnings section
- `.spade/docs/FRAMEWORK.md` — sync

### Risks

- **R1** — learnings store becomes stale fast. Mitigation: `--refresh` mode
  is part of the initial delivery, not a follow-up. Lint warns on entries
  older than 180 days with `status: active`.
- **R2** — `/spade-plan` surfaces irrelevant learnings and becomes noisy.
  Mitigation: require at least two tag matches or an explicit `scope_ref`
  to surface. Humans can override.
- **R3** — the learnings store is checked into consumer repos and could
  accidentally carry proprietary info from a private codebase into a public
  fork. Mitigation: docs call this out; `/spade-learn` prompts the human
  to classify as `public-safe: yes|no` and the latter routes to a
  `.spade/learnings/private/` subdirectory that `.gitignore` by default.

### Dependencies

- Bundle B (posture field — learning templates reference it).
- Bundle C (lint covers learning frontmatter).

### Testing strategy

- Lint fixture: a malformed learning file fails lint.
- Manual: create a learning, then run `/spade-plan` on a new Scope with a
  matching tag — verify the learning surfaces.
- Manual: run `/spade-learn --refresh` on a fixture with one stale entry
  and one active entry; verify only the stale one prompts for archive.

### Definition of done

- `/spade-learn` skill present and documented.
- Two seed learnings committed.
- `/spade-plan` surfaces learnings in a generated Plan on a test Scope.
- Lint covers learning frontmatter.

---

## Bundle E — Multi-persona /spade-review + docs + v1.1 marker bump

**Label:** `bundle:v11-multi-persona-review`
**Delivery mode:** AI
**Execution posture:** `test-first` on the persona contract; `refactor-first`
on the existing `/spade-review` prose.

### Why last

The most structural change (new `.claude/agents/` directory; existing skill
reshaped). Landing after CI + learnings means we can lean on both when
validating the new review output.

### Approach

1. **Persona definitions.** `.claude/agents/spade-review-*.md`, one per
   persona. Each file has frontmatter with `persona`, `focus`,
   `output_schema` (JSON), and prose that primes the sub-agent to stay in
   role. Personas (minimum set):
   - `scope-guardian` — is the Scope complete, testable, unambiguous?
   - `architecture-strategist` — does the Plan honour `ARCHITECTURE.md` /
     `PATTERNS.md` / `ANTI-PATTERNS.md`? Flag conflicts.
   - `security-lens` — auth, injection, secrets, supply chain, IAM.
   - `yagni-simplicity` — is anything proposed that isn't required by the
     Scope? Is the delivery bundle count proportional?
   - `adversarial-reviewer` — what is the strongest reason this will fail
     or produce the wrong thing?
2. **Finding schema.** JSON:
   ```json
   { "persona": "string", "severity": "blocking|major|minor|nit",
     "confidence": "0.0..1.0", "category": "string",
     "message": "string", "refs": ["file:line"] }
   ```
3. **Merge logic** in `/spade-review` prose: spawn personas in parallel,
   collect findings, dedupe by `(category, first 100 chars of message)`,
   sort by severity × confidence, emit one Markdown report.
4. **Prompt pinning.** Each persona is pinned to Opus 4.7 with high
   reasoning — consistent with the existing `/spade-review` pin.
5. **Docs update (AC 6).** Rewrite README, AGENTS.md, CLAUDE.md to cover
   the new personas, `/spade-learn`, and posture vocabulary. Bump all
   fragment version markers to `v1.1.0`. Update
   `.spade/version` (`spade_version=1.1.0`).
6. **`/spade-update` migration.** Ensure `/spade-update` can rewrite a
   consumer's `v1.0.0` fragment blocks to `v1.1.0` idempotently (this
   leans on Bundle A's contract).

### Files touched

- `.claude/agents/spade-review-*.md` × 5 — new
- `.claude/skills/spade-review/SKILL.md` — reshape
- `.claude/skills/spade-update/SKILL.md` — v1.0 → v1.1 migration prose
- `fragments/AGENTS-section.md`, `fragments/CLAUDE-section.md` — v1.1.0 bump
- `.spade/version` — `spade_version=1.1.0`
- `README.md`, `AGENTS.md`, `CLAUDE.md` — doc refresh
- `docs/FRAMEWORK.md`, `.spade/docs/FRAMEWORK.md` — doc refresh
- `scripts/lint/` — extend to validate persona frontmatter

### Risks

- **R1** — parallel sub-agent spawning behaviour depends on the runtime.
  Mitigation: skill prose says "spawn each persona in parallel *if the
  runtime supports it; otherwise run sequentially*" and never promises
  latency.
- **R2** — persona output schemas drift from reality when we tune prompts
  post-ship. Mitigation: the schema lives inline in each persona file, not
  in a central place — one file changes per persona.
- **R3** — Bundle E is big and will be hard to review end-to-end.
  Mitigation: split the PR into two commits — (1) personas + skill reshape,
  (2) docs + version bump — reviewable independently even if landed as one.

### Dependencies

- All prior bundles (A, B, C, D).

### Testing strategy

- Lint: persona frontmatter validated.
- Manual: run `/spade-review` against this very Scope (M-323). Expect at
  least one finding from each persona; scope-guardian should flag nothing
  (the Scope is well-formed); adversarial-reviewer should challenge at
  least one risk.
- Manual: run `/spade-update` on a fixture repo with v1.0.0 markers;
  verify clean rewrite to v1.1.0 markers and no duplication.

### Definition of done

- All five persona files present, linted.
- `/spade-review` emits a merged multi-persona report on a test input.
- Fragment markers and `.spade/version` pin v1.1.0.
- README / AGENTS.md / CLAUDE.md / FRAMEWORK.md describe v1.1 surface.
- `/spade-update` migrates a v1.0.0 consumer cleanly.

---

## Cross-bundle risks

| # | Risk                                                                  | Mitigation                                                                                         |
|---|-----------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| C1 | Scope creep inside a bundle                                           | Plan fixes each bundle's file list; any deviation requires updating this Plan before delivery.     |
| C2 | Fragment marker drift between bundles before Bundle E bumps to v1.1.0 | Markers stay v1.0.0 on A–D; version bump batched into E only.                                      |
| C3 | Existing consumers break on `/spade-update`                           | Bundle E explicitly tests v1.0.0 → v1.1.0 migration on a fixture.                                  |
| C4 | PowerShell parity slips                                               | Any `setup` change in A/E is mirrored in `setup.ps1` in the same PR; reviewer must block otherwise. |
| C5 | Duplicated content in examples (`examples/` vs `.spade/examples/`)    | Bundle C lint covers this; until then, bundle authors update both.                                 |

## Approval checklist

Before approving this Plan, verify:

- [ ] Each acceptance criterion in M-323 maps to exactly one bundle (AC 1→A, 4→B, 5→C, 2→D, 3→E, 6→E, 7 covered by E's update migration test).
- [ ] No bundle violates `ANTI-PATTERNS.md` (no runtime, no new integration, no build step).
- [ ] Delivery order is defensible (low-risk first, CI before the two biggest changes).
- [ ] Each bundle has a concrete risk list and definition of done.
- [ ] Dependencies between bundles are linear and stated.
- [ ] Shell parity is noted where relevant.
- [ ] No skill is added beyond `/spade-learn`.

## Sub-issue layout (to be created in Linear)

| Bundle | Sub-issue title                                                       | Labels                                                     |
|--------|-----------------------------------------------------------------------|------------------------------------------------------------|
| A      | Fix onboarding marker idempotency and de-duplicate repo docs          | `ai-planned`, `bundle:v11-onboarding-idempotency`          |
| B      | Add execution_posture field to Plan schema, examples, and /spade-plan | `ai-planned`, `bundle:v11-execution-posture`               |
| C      | CI lint: frontmatter, examples, fragments, onboard idempotency        | `ai-planned`, `bundle:v11-ci-frontmatter-lint`             |
| D      | Learnings loop: /spade-learn skill, .spade/learnings/, plan integration | `ai-planned`, `bundle:v11-learnings-loop`                |
| E      | Multi-persona /spade-review + docs refresh + v1.1.0 marker bump       | `ai-planned`, `bundle:v11-multi-persona-review`, `needs-arch-review` |

Sub-issues will link back to this Plan document and to the parent Scope M-323.
