---
name: spade-unhinged
title: /spade-unhinged — release-valve mode for POCs and spikes
status: scoped
type: feature
phase: scope
created: 2026-05-13
updated: 2026-05-13
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
linear_issue: M-889
linear_url: https://linear.app/m-kopa/issue/M-889/spade-unhinged-release-valve-mode-for-pocs-and-spikes-v15
panel_review: 2026-05-13 (subagent-dispatch, 33 findings, 0 filtered)
---

## Scope: /spade-unhinged — release-valve mode for POCs and spikes

**Intent:** Provide a deliberate, opt-in "release-valve" skill for genuinely exploratory work — POCs, spikes, throwaway scripts — where the SPADE audit loop adds no value. The skill suspends Scope/Plan/Linear ceremony for the conversation but does **not** suspend the framework's safety rails: a path-glob-enforced gate refuses unhinged mode on production-adjacent files, and the runtime's destructive-operation confirmation rules stand. Git history + a mandatory `[unhinged]` PR-prefix together constitute the audit chain — this is the v1.5 amendment to AGENTS.md's Audit Trail invariant, not a violation of it.

Tiebreaker against `/spade-quick`: **if you intend to keep the change, use `/spade-quick` (audited fast-track). If it's a spike likely to be torn out, rewritten, or thrown away, use `/spade-unhinged`.** Unhinged code that ends up shipping is fine — the `[unhinged]` PR-prefix is the reviewer's signal.

---

### Acceptance Criteria

1. **New skill `/spade-unhinged`.** Lives at `.claude/skills/spade-unhinged/SKILL.md` and follows the existing SKILL.md format. When invoked it:
   - Prompts the user for a one-line free-text intent string (no fixed-option picker — single open prompt).
   - Runs the hard-gate path check (AC#2). On match, refuses with the message **"this is not unhinged-eligible — use `/spade-quick` or the full loop"** and exits.
   - Surfaces a one-line warning if the current branch is `main`/`master` or if there are unrelated dirty files, via `AskUserQuestion` with options *Proceed anyway* / *Cancel and clean up*. This is the only soft warning; no separate two-tier gate concept.
   - Emits the unhinged-mode briefing (AC#3).
   - Returns control. No Scope, no Plan, no Linear issue, no sub-issue.

2. **Hard gate — path-glob enforcement.** The skill runs `git diff --name-only HEAD` plus `git status --porcelain` and refuses if any changed or untracked file matches the canonical glob list committed in `docs/FRAMEWORK.md` §Unhinged Mode. The initial list (committed in the Plan, not the Scope, so it can iterate without re-scoping) includes at minimum:
   - `auth/**`, `**/auth/**`, `**/*auth*` (auth code)
   - `**/migrations/**`, `**/*migration*`, `**/*schema*.sql` (schema/migration)
   - `**/secrets/**`, `**/*secret*`, `**/*credential*`, `**/.env*` (secrets — also blocked by .gitignore conventions but belt-and-braces)
   - `.github/workflows/**`, `.gitlab-ci.yml`, `Jenkinsfile`, `azure-pipelines.yml` (CI/CD)
   - `terraform/**`, `infra/**`, `pulumi/**`, `**/iam*.{tf,yaml,yml,json}`, `**/k8s/**`, `helm/**` (production infra)
   - Any file the runtime's destructive-operation rules already gate (e.g. `package.json` major-version deps, lockfiles — Plan to enumerate)
   The list is **single-source in FRAMEWORK.md**; SKILL.md references it by section anchor, not by re-listing. **The hard gate has no override path** — refusal is final and the skill exits without writing to the log.

3. **Unhinged-mode briefing.** On successful entry, the skill emits a fixed-format briefing the user sees verbatim:
   - "You are in unhinged mode for this conversation. SPADE ceremony is suspended."
   - The captured intent string.
   - **What is suspended:** Scope, Plan, Linear ticket, approval gate, acceptance criteria, evaluation.
   - **What is NOT suspended (verbatim re-statement of the never-bypass list — not just a link):** the AC#2 path-glob list, the runtime's destructive-operation confirmation rules (force-push, history rewrite, branch deletion, prod infra mutation), and git discipline (real branches, real commits).
   - **Mandatory PR-prefix:** `[unhinged] <intent-string>` in the title and a one-line "what I shipped" note in the body. This is the audit signal reviewers receive in lieu of a Linear ticket.
   - **End-of-session prompt (advisory text only, no hook):** "Run `/spade-learn` if anything's worth carrying forward."
   - The briefing prose MUST NOT contain the phrase "all ceremony suspended" or any equivalent that omits the carve-out — security-lens finding.

4. **`docs/FRAMEWORK.md` §Unhinged Mode.** New section, target ≤ 80 lines, contains:
   - When unhinged is appropriate (POCs, spikes, learning, throwaway scripts).
   - When unhinged is **not** appropriate (the path-glob list — single source of truth for AC#2).
   - The tiebreaker rule vs `/spade-quick` (keeping vs throwaway, verbatim from the Scope intent paragraph).
   - The PR-prefix convention as a normative requirement.
   - The audit-chain definition: git history + `[unhinged]` PR-prefix + body note = the recognised audit artefact for unhinged work (cross-referenced from AC#5's AGENTS.md amendment).

5. **`AGENTS.md` Audit Trail amendment.** The existing §Audit Trail section is amended (not appended-to with a parallel paragraph) to recognise unhinged work as a valid audit-chain shape. The invariant "never deliver work that cannot be traced" is preserved; the chain definition gains a second valid form: `Scope → Plan → Sub-issue → PR` (full loop / quick) **or** `git history + [unhinged] PR-prefix + body note` (unhinged). The amendment names the FRAMEWORK.md §Unhinged Mode section as the canonical reference for which work qualifies as unhinged-eligible.

6. **Release packaging.** Ships as **v1.5.0**:
   - `VERSION` set to `1.5.0`.
   - `CHANGELOG.md` entry covering the new skill, path-glob gate, AGENTS.md amendment, FRAMEWORK section, CLAUDE.md row.
   - `/spade-update` migration recipe added for v1.4.x → v1.5.0 (fragment re-stamp, same pattern as v1.3.0).
   - `CLAUDE-section.md` consumer fragment gains a `/spade-unhinged` row in the skill table.
   - No AGENTS-section.md change beyond the Audit Trail amendment (which is in consumer-fragment territory — Plan must confirm whether the amendment ships via fragment or is repo-only).

---

### Architectural Constraints

- Follow `docs/FRAMEWORK.md` patterns: `AskUserQuestion` for the soft-warning override prompt only; free-text for the intent. No fixed-option picker for intent.
- **No cross-skill awareness mechanism.** Sister skills do not check conversation history for prior `/spade-unhinged` invocation. The briefing tells the user "don't invoke other SPADE skills in this conversation"; if they do, normal skill behaviour applies. This deliberately drops AC#6 from the v1 scope draft per panel convergence (yagni + architecture + adversarial + scope-guardian).
- **No append-only log file.** The `[unhinged]` PR-prefix in git history is the only retrospective signal. No `.spade/unhinged.log`. PATTERNS.md "Markdown + YAML is the only data format" is preserved.
- The hard-gate path-glob list is single-source in `docs/FRAMEWORK.md` §Unhinged Mode. SKILL.md and AGENTS.md reference it by section anchor; neither re-lists.
- Skill is **prose-only** with `Bash` calls for `git diff --name-only HEAD` and `git status --porcelain`. No runtime layer.
- No new dependencies.

---

### Dependencies

- None. Self-contained framework work. Ships independently of M-879 (v1.4 local mode) — no ordering constraint either direction.

### Context

- **Upstream:** v1.0 introduced `/spade-quick` as fast-track for trivial-but-real work. `/spade-unhinged` extends the spectrum downward to throwaway/exploratory.
- **Downstream:** Consumer repos pick up via `/spade-update` v1.4.x → v1.5.0 fragment re-stamp (same recipe as v1.3.0).
- **Related:** v1.4 (M-879, local mode) — orthogonal. No interaction; this scope's gate uses local git state regardless of SPADE mode.

### Out of Scope

- Cross-skill awareness (sister skills detecting prior unhinged invocation). Cut after panel review.
- Append-only `.spade/unhinged.log` file. Cut after panel review.
- A separate AGENTS.md "behaviour reminder" paragraph parallel to existing rules. The Audit Trail section is **amended**, not added-to.
- Override-tracking, cultural-drift telemetry, or `/spade-status` integration to surface unhinged frequency. Defer to v1.6+ if real demand surfaces.
- A "global" or repo-wide unhinged toggle.
- Automated detection of "unhinged work" from PR titles or branch names.
- Time-limited unhinged sessions (TTL, expiry).
- Retroactive unhinging — once you've started a full SPADE loop, abandon the in-flight Scope/Plan first.
- A "yolo" alias or any non-`/spade-*` invocation name.

### Origin

Ad-hoc — user request 2026-05-13 for a release-valve mode supporting POCs and testing work that doesn't justify SPADE ceremony. After panel review the original v1 draft was stripped to minimum viable shape to address blocking findings on undetectable gates, audit-trail-invariant conflict, and skill-feature creep.

### Risk / Unknowns

- **Cultural drift toward unhinged-as-default.** The panel called this out as the strongest realistic failure mode and the stripped scope removes the log-based "we'll notice" mitigation entirely. The replacement mitigation is the path-glob hard gate (which makes the cultural ceiling concrete — you cannot habitually unhinge work that touches the protected paths) plus the mandatory PR-prefix (which makes overuse visible at PR-review time). If both prove insufficient, v1.6 can add `/spade-status` surfacing of `[unhinged]` PRs.
- **`/spade-quick` cannibalisation.** The intent-based tiebreaker (keeping vs throwaway) is the only defence. If usage data shows `/spade-quick` decaying, the v1.6 mitigation is making the tiebreaker enforceable (e.g. unhinged PRs cannot merge to main without a quick/scope rerun). Out of scope for v1.5.
- **Path-glob list completeness.** The initial list in AC#2 is best-effort; the Plan must commit to a specific list reviewable by a human. Risk: a category of work is omitted (e.g. "feature flag config") and unhinged sessions habitually touch it. Mitigation: the list lives in FRAMEWORK.md and is amendable without re-scoping.
- **AGENTS.md amendment delivery.** The Audit Trail section is normative framework prose; amending it affects every consumer at upgrade time. The Plan must include the diff in the upgrade notes and confirm `/spade-update` re-stamps the fragment correctly.

### Delivery Preference

Mostly AI-delivered — single new SKILL.md, FRAMEWORK.md section addition, AGENTS.md amendment, CLAUDE.md row, CHANGELOG entry, VERSION bump. Manual verification is human-driven: you invoke `/spade-unhinged` against three fixtures (clean feature branch with safe edits; clean feature branch with auth-path edits — gate must refuse; main branch with safe edits — soft warning must fire), and confirm the briefing text contains the never-bypass list verbatim.

### Priority

This cycle. Low downside if delayed; meaningful quality-of-life win once shipped.

---

### Panel Review (2026-05-13)

A 5-persona `/spade-review` panel ran on the pre-revision Scope and surfaced 33 findings (0 filtered). Decisions applied in this revision:

| Severity | Persona | Finding | Disposition |
|----------|---------|---------|-------------|
| blocking | scope-guardian / adversarial | AC#2 never-bypass gate has no detection mechanism — theatre | **AC#2 rewritten as path-glob enforcement with concrete `git diff` probe; list committed to FRAMEWORK.md** |
| blocking | scope-guardian | AC#6 cross-skill awareness has no defined detection pattern | **AC#6 cut entirely; sister skills behave normally; briefing tells user to not invoke other SPADE skills mid-conversation** |
| major | architecture-strategist | "executing actions with care" phantom reference — phrase doesn't exist in SPADE docs | **Removed phantom references; AC#5 amends AGENTS.md Audit Trail directly** |
| major | architecture-strategist | "no audit trail" framing conflicts with AGENTS.md Audit Trail invariant | **AC#5 amends Audit Trail to recognise git+[unhinged] PR-prefix as a valid audit chain shape — invariant preserved, not violated** |
| major | architecture-strategist + yagni | `.spade/unhinged.log` violates PATTERNS.md "Markdown+YAML only" + self-contradictory committable-or-gitignored | **AC#5 cut entirely; no log file** |
| major | scope-guardian + adversarial | quick↔unhinged boundary ambiguous, cannibalisation risk | **Tiebreaker rule (keeping vs throwaway) added to Scope intent and AC#4 FRAMEWORK section** |
| major | security-lens | PR-prefix was "suggested", not mandatory | **AC#3 makes PR-prefix mandatory** |
| major | security-lens | AGENTS.md paragraph (old AC#9) too thin against prompt injection | **Replaced with Audit Trail amendment (AC#5) + briefing must re-state never-bypass verbatim (AC#3)** |
| major (4 personas converged) | yagni / architecture / adversarial / scope-guardian | AC#6 cross-skill awareness | **Cut entirely** |
| major | yagni | Override-tracking sub-format on log | **Moot — log cut** |
| major | adversarial | Cultural-drift mitigation is hope | **Mitigation replaced: path-glob ceiling + mandatory PR-prefix visibility; further backstops deferred to v1.6** |
| major | scope-guardian | AC#1 option picker too coarse to feed AC#2 | **Cut option picker; free-text intent only** |
| major | scope-guardian | /spade-learn integration ambiguous | **Clarified as advisory text only, no hook** |
| minor | architecture | Two-tier gate not in PATTERNS.md | **Collapsed: one hard gate (path-glob) + one soft warning (main/dirty). No "two-tier" framing.** |
| minor | yagni | Full v1.5 release ceremony excessive for one skill | **Kept v1.5.0 — the AGENTS.md amendment is consumer-fragment territory and warrants the minor bump regardless of skill size** |

Findings explicitly rejected:
- "Drop the skill entirely; ship docs only" (yagni-simplicity) — kept skill per user choice (a slash-command invocation surface has value over pure docs).
- "Rename gate to advisory" (adversarial alternative) — kept hard-gate framing per user choice; path-glob enforcement makes "no override" honest.

Findings carried forward to the Plan:
- Specific glob list (AC#2): the categories are enumerated in the Scope but the exact glob strings live in the Plan to allow iteration without re-scoping.
- Fragment-vs-repo-only decision for the AGENTS.md amendment (AC#6 release packaging).
- Manual verification fixture details (3 fixtures named in Delivery Preference).
