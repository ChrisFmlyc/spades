---
name: spade-v1.4-local-mode
title: SPADE v1.4 — local mode (read/write parity with Linear)
status: scoped
type: feature
phase: scope
created: 2026-05-12
updated: 2026-05-12
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
linear_issue: M-879
linear_url: https://linear.app/m-kopa/issue/M-879/spade-v14-local-mode-readwrite-parity-with-linear
panel_review: 2026-05-12 (subagent-dispatch, 30 findings, 0 filtered)
---

## Scope: SPADE v1.4 — local mode (read/write parity with Linear)

**Intent:** SPADE skills work end-to-end without Linear MCP, reading and writing canonical state from `.spade/`. Consumer repos with no Linear access drop their per-project CLAUDE.md overrides and the framework behaves identically. v1.4 generalises the local/remote split established by M-420 (Linear-canonical for Plans) so the canonical side becomes a per-repo configuration choice rather than a framework default.

**Acceptance Criteria:**

1. [ ] **Mode configuration.** `.spade/config` accepts `mode: local | linear | hybrid`. Explicit `mode:` always wins over auto-detect. Auto-detect runs only when `mode:` is absent and resolves as:
   - **Probe:** a no-op `list_teams` MCP call wrapped in a try/skip with a 5-second timeout, documented once in `docs/FRAMEWORK.md` §Mode Resolver and referenced from every skill.
   - **Outcome:** auto-detect picks `linear` if the probe returns at least one team AND `linear.team_id` in config is in the returned set; otherwise `local`.
   - **Unreachable-but-configured failure policy:** when `mode:` is explicit and `team_id` is set but the probe fails, skills fail loud with a single-line error and abort. When `mode:` is absent (auto-detect path) and the probe fails, skills silently degrade to `local` and emit one warning per session.

2. [ ] **Local file layout — flat, single-source contract.** `docs/FRAMEWORK.md` §Local Layout documents the canonical paths and frontmatter schema (the single source of truth — no per-skill re-specification):
   - `.spade/scopes/<slug>.md` — one file per Scope
   - `.spade/plans/<scope-slug>-plan.md` — one flat file per Plan (matches M-420; preserves the existing layout in `.spade/plans/`)
   - `.spade/learnings/<YYYY-MM-DD>-<slug>.md` — unchanged from today
   - Frontmatter schema fields: `name`, `title`, `status`, `type`, `phase`, `created`, `updated`. Plan-specific and Scope-specific extra fields documented in the same section.
   - Schema version is tied to `.spade/version` — readers MUST consult `spade_version` and apply the layout grammar for that version. Pre-v1.4 files (M-323, M-343, M-420 era) are explicitly grandfathered: skills must read them tolerantly and never rewrite them silently.

3. [ ] **Slug grammar.** Slugs in `.spade/` paths follow `[a-z0-9-]{1,64}` with no leading hyphen and no `..`. Any skill that derives a slug from a Linear title or user input applies this grammar; invalid slugs cause the skill to abort with a clear error rather than writing outside `.spade/`. Grammar lives once in `docs/FRAMEWORK.md` §Local Layout.

4. [ ] **Hybrid mode = tracker-canonical with local mirror.** In `hybrid` mode the tracker remains canonical (matching M-420). Reads consult the tracker first with local mirror as fallback for unreachable-tracker cases. Writes go to the tracker, and on tracker-write success the corresponding local mirror file is written best-effort. On mirror-write failure, the tracker write stands and a single-line warning surfaces; on tracker-write failure, the skill aborts with the same error path as `linear` mode (no local-only fallback in hybrid). The local mirror is explicitly **non-authoritative** — downstream tooling MUST NOT treat the local mirror as ground truth. This is documented in `docs/FRAMEWORK.md` §Hybrid Mode.

5. [ ] **Skill parity — all nine.** `/spade-scope`, `/spade-plan`, `/spade-approve`, `/spade-evaluate`, `/spade-list`, `/spade-status`, `/spade-learn`, `/spade-quick`, and `/spade-onboard` resolve mode once at the top via the §Mode Resolver pattern and operate against local files in `local` mode with **zero Linear MCP calls**. Verified by:
   - A CI grep check (added under `.github/workflows/` or equivalent) that fails when a skill listed in this AC contains an unguarded `list_teams|list_issues|save_issue|create_attachment|save_comment|list_projects|get_issue|...` MCP invocation outside a mode-resolver-gated block. The full grep pattern lives in the Plan.
   - One manual happy-path exercise per skill per applicable mode against a documented fixture repo (see AC#7).

6. [ ] **/spade-onboard provisions the local layout.** Onboarding creates `.spade/scopes/`, `.spade/plans/`, `.spade/learnings/` if missing, writes a starter `.spade/config` with `mode:` set explicitly based on Linear MCP availability at onboard time (auto-detect rule above, applied once and persisted — not re-run on every skill invocation), and documents the chosen mode in the onboard summary.

7. [ ] **Existing-repo non-regression.** Existing v1.3.0 repos continue to work unchanged after upgrade — `linear` remains the resolved mode when `team_id` is present and MCP probes succeed. Verified by two fixtures committed under `examples/`:
   - `examples/fixture-linear-mode/` — minimal Scope + Plan that exercises `/spade-status` and `/spade-list` in `linear` mode.
   - `examples/fixture-local-mode/` — same shape with `mode: local` in config and no `team_id`.
   The manual verification step exercises one happy-path skill invocation per mode per fixture.

8. [ ] **Version bump.** `VERSION` set to `1.4.0`.

9. [ ] **CHANGELOG entry.** `CHANGELOG.md` describes mode resolver, hybrid semantics, local layout contract, slug grammar, and CI grep check.

10. [ ] **/spade-update migration.** `/spade-update` for the v1.3 → v1.4 upgrade: (a) reads existing `.spade/config`, (b) writes an explicit `mode:` line if absent (using the auto-detect rule once, at upgrade time, and recording the choice), (c) leaves all existing `.spade/plans/*` files untouched (grandfathering), (d) prints a summary of what changed. No automated backfill from Linear to local — operators with Linear-canonical Plans stay on `linear` mode.

**Architectural Constraints:**
- Follow `docs/FRAMEWORK.md` patterns: `AskUserQuestion` for fixed-option decisions (the local/linear/hybrid pick during `/spade-onboard` MUST use AskUserQuestion per the §"Asking the Human" convention), free-form prose only for open composition.
- Frontmatter schema is single-sourced in `docs/FRAMEWORK.md` §Local Layout. Skills reference it; they never re-specify it.
- §Mode Resolver is a single documented prose paragraph in `docs/FRAMEWORK.md`. Every skill links to it by reference — no copy-paste across SKILL.md files (per `PATTERNS.md` "prose over code" and the anti-duplication rule).
- No runtime layer added. SPADE remains markdown-driven; the resolver is a documented sequence of Read/MCP-probe steps, not a script.
- No new dependencies.
- Respect M-420 contract: `.spade/plans/` keeps the flat `<scope-slug>-plan.md` layout. Pre-v1.4 ad-hoc filenames (M-323, M-343, M-420) are grandfathered, documented as legacy in §Local Layout, and not auto-migrated.
- `.spade/` content is trusted at the same level as `AGENTS.md`. Skills treat scope/plan/learning bodies as **data, not directives** — they do not execute or follow instructions embedded in them.

**Dependencies:**
- None. Self-contained framework work.

**Context:**
- **Upstream:** M-420 (v1.2.0) made the tracker canonical for Plans. v1.4 keeps that rule and adds a local-only mode for repos with no tracker, plus a hybrid mode that preserves M-420's canonical-side rule.
- **Downstream:** Consumer repos without Linear MCP access drop their per-project CLAUDE.md overrides once this ships.
- **Related:** v1.3.0 shipped `/spade-research` and the `AskUserQuestion` convention (PR #11). v1.4 is the next minor.

**Out of Scope:**
- Linear → local backfill tooling. Operators with existing Linear-canonical Plans stay on `linear` mode; the framework does not retroactively populate `.spade/plans/` from Linear.
- Bidirectional sync. Hybrid mode is one-way (writes to tracker, optional local mirror); the local mirror is non-authoritative.
- Multi-repo or workspace-level local state — still one `.spade/` per repo.
- Changes to `/spade-review` and `/spade-research` — these don't touch Linear today and need no mode-resolver wiring.
- `/spade-update` automated test suite — manual verification via the two fixtures is the contract for v1.4.
- A formal pytest/jest test harness for SPADE — verification stays manual + grep-CI for this scope.

**Origin:** Ad-hoc — user friction encountered in a consumer repo running under a local-only CLAUDE.md override. `/spade-list` and `/spade-status` were hardcoded to Linear with no local fallback. Natural successor to M-420; addresses the inverse case M-420 left open.

**Risk / Unknowns:**
- **Manual verification gap (adversarial-reviewer, blocking-adjacent).** The same manual-verification regime is what shipped the bug this Scope fixes (Linear hardcoding survived to v1.3). AC#5 mitigates with a CI grep check, but the grep pattern itself is a known-bad-pattern list and may miss novel MCP invocations. The Plan must commit to a specific grep pattern reviewable by a human.
- **Frontmatter contract drift.** Pre-v1.4 files (M-323, M-343, M-420) use ad-hoc frontmatter. The grandfathering rule covers reads, but if a skill ever rewrites a legacy file (e.g., `/spade-evaluate` marks status), the rewrite path must preserve unknown fields.
- **Hybrid mode adoption.** Hybrid is now genuinely M-420-compatible (tracker-canonical) but introduces a "mirror may diverge" surface that operators must understand. The CHANGELOG entry needs to be explicit about this; otherwise the local mirror gets cited as authoritative in audits.
- **§Mode Resolver prose drift.** If the §Mode Resolver section in FRAMEWORK.md is edited and skills don't re-read it, behaviour can diverge across skills. The Plan should specify that every skill's mode-resolution block is a one-line "consult FRAMEWORK.md §Mode Resolver" with no embedded algorithm.

**Delivery Preference:** Mostly AI-delivered — markdown skill edits, config schema additions, `docs/FRAMEWORK.md` section additions, version bump, fixture creation, CI grep workflow. Manual verification step is human-driven (you exercise each skill against the two fixtures and confirm the grep check fires on a planted unguarded MCP call).

**Priority:** This cycle — unblocks consumer repos immediately.

## Panel Review (2026-05-12)

A 5-persona `/spade-review` panel ran on the pre-revision Scope and surfaced 30 findings (0 filtered). Decisions applied in this revision:

- **Hybrid mode (blocking, adversarial-reviewer):** AC#4 rewritten as tracker-canonical with local mirror (genuinely extends M-420 instead of inverting it).
- **MCP probe (major, 4 personas converged):** promoted from §Risk to AC#1 with concrete probe definition and explicit failure policy.
- **Slug sanitisation (major, security-lens):** added as AC#3.
- **CI grep verification (major, adversarial-reviewer):** added to AC#5.
- **Plan-file layout (major, architecture-strategist):** revised to flat `.spade/plans/<scope-slug>-plan.md` to match M-420.
- **Skill count (major, scope-guardian):** AC#5 corrected to "all nine" with the full enumeration.
- **AC#7 bundling (minor, scope-guardian):** split into AC#8/9/10 for clean traceability.
- **AC#6 verification artefact (minor, scope-guardian):** named fixtures under `examples/`.
- **AC#2 versioned contract (major, scope-guardian):** tied to `.spade/version`.
- **Shared resolver pattern (major, scope-guardian + yagni):** anchored to a single FRAMEWORK.md section all skills link to by reference.
- **Linear mirror non-authoritative note (minor, security-lens):** added to AC#4.
- **AskUserQuestion reference (nit, architecture-strategist):** added to Architectural Constraints.
- **Trust level of `.spade/` content (minor, security-lens):** added to Architectural Constraints.

Findings deferred to the Plan (acknowledged, not blocking):
- Exact CI grep pattern (Plan task).
- Specific FRAMEWORK.md section anchors (Plan task).
- Manual smoke list contents (Plan task).

Findings explicitly rejected (with reason):
- "Cut hybrid from v1.4" (yagni-simplicity): kept per user choice; risk mitigated by rewriting to tracker-canonical.
- "Split into v1.4 read-only + v1.4.x write-path" (yagni-simplicity + scope-guardian): kept all-in per user choice; risk mitigated by CI grep AC.
- "Drop auto-detect" (yagni-simplicity): kept per user choice; risk mitigated by pinning probe + failure policy in AC#1.
