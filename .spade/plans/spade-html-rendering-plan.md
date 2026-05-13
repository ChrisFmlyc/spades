---
issue: M-901
title: SPADE v1.6 — HTML rendering for scopes and plans (Pandoc)
date: 2026-05-13
status: approved
scope_ref: .spade/scopes/spade-html-rendering.md
linear_url: https://linear.app/m-kopa/issue/M-901
bundle: html-rendering
---

> **Local mirror.** Plan is canonically stored on Linear M-901 as a parent-issue
> comment + sub-issues (M-902–M-908). This local file is a maintainer-requested
> mirror (anticipating v1.4 hybrid-mode behaviour from M-879). On any conflict,
> Linear is authoritative.

## Plan for M-901 — SPADE v1.6 HTML rendering (Pandoc)

### Technical Approach Summary

A POSIX-shell wrapper at `~/.spade/bin/spade-render` invokes `pandoc` with a pinned set of safety flags, a custom HTML5 template, and a ≤12KB inlined stylesheet. `/spade-scope` and `/spade-plan` SKILL.md files gain a closing block that calls the wrapper and prints the terminal link. Security is enforced through Pandoc flags + template-level CSP meta + a fixture-based CI grep suite.

### Prior Learnings Considered

- *Any write into a consumer file must be idempotent via delimited markers, never append* (`2026-04-22-onboarding-must-be-idempotent.md`) — T7's `CLAUDE-section.md` fragment version-stamp bump and the `/spade-update` migration recipe go through the existing `bin/spade-marker-replace` machinery rather than inventing a new mechanism. The renderer itself never writes to consumer files (only the consumer's own `.spade/scopes/*.md` triggers a sibling `.html` in their own tree).
  Match reason: tags matched [onboarding, markers]

### Risks and Assumptions

- **Sequencing dependency on M-879.** T4 references M-879's mode resolver (render in `local`/`hybrid`, skip in `linear`). M-879 is scoped but not delivered. Assumption: M-879 ships before M-901 delivery starts. If not, T4 reverts to "always write locally" behaviour with a follow-up to re-add the resolver branch when M-879 ships.
- **Sequencing dependency on M-889 for the `/spade-update` recipe.** T7's recipe is `v1.5.x → v1.6.0`. If M-889 hasn't shipped, the recipe handles `v1.3.x → v1.6.0` directly.
- **Pandoc 3.0+ feature usage.** `--embed-resources` was added in Pandoc 3.0 (replaced `--self-contained` which was removed). Plan pins 3.0 as the floor; verify on `brew`/`apt`/`winget` default versions.
- **CSS 12KB budget.** Typography + 6 pill colours + Skylighting hooks + dark variant + print stylesheet inside 12KB is tight but achievable. CI lint enforces; document the budget in the stylesheet header.
- **Cross-platform `file://` URL construction.** macOS/Linux → `file:///Users/...` or `file:///home/...`; Windows → `file:///C:/...` with `/` not `\`. POSIX-shell-safe transform, bash 3.2 floor per ARCHITECTURE.md.
- **Graceful-degradation testability.** Manual verification step covers the no-pandoc path; no automated CI matrix.
- **Pandoc template syntax for custom frontmatter.** `linear_url` / `panel_review` are SPADE-specific fields. Pandoc accesses via `$linear_url$`; T1 verifies arbitrary-field access works.

### Tasks

| # | Title | Issue | Mode | Posture | Effort | Deps | AC |
|---|-------|-------|------|---------|--------|------|----|
| 1 | Pandoc HTML template + frontmatter status header | M-906 | ai-delivered | test-first | moderate | — | #2 |
| 2 | Stylesheet (spade.css, ≤12KB) | M-907 | ai-delivered | straight-through (mechanical CSS, no logic; CI byte budget + manual browser check) | moderate | — | #3 |
| 3 | Renderer wrapper `~/.spade/bin/spade-render` | M-902 | ai-delivered | test-first | moderate | T1, T2 | #1 |
| 4 | Skill integration — `/spade-scope` and `/spade-plan` | M-903 | ai-delivered | characterization-first (pin existing skill behaviour first) | moderate | T3 | #4 |
| 5 | Security fixture suite + CI grep | M-908 | ai-delivered | test-first (task IS the tests) | moderate | T3 | #5 |
| 6 | Documentation — FRAMEWORK §HTML Rendering + ARCHITECTURE one-liner | M-904 | ai-delivered | straight-through (pure prose) | moderate | T1, T2, T3 | #6 |
| 7 | Release packaging (VERSION, CHANGELOG, /spade-update recipe, fragment stamp) | M-905 | ai-delivered | straight-through (mechanical; matches v1.3.0 release pattern) | brief | T1–T6 | #7 |

### Delivery Sequence

1. **T1 + T2** in parallel (no deps).
2. **T3** after T1+T2.
3. **T4** after T3.
4. **T5 + T6** in parallel after T3 (T6 also needs T1+T2 referenced).
5. **T7** last.

### Delivery Bundle

**Single bundle: `html-rendering`**

- **Branch:** `spade/M-901-html-rendering`
- **PR title:** `SPADE v1.6: HTML rendering for scopes and plans (Pandoc) (M-901)`
- **Tasks:** M-906, M-907, M-902, M-903, M-908, M-904, M-905
- **Rationale:** All seven tasks interlock through the renderer pipeline. A multi-bundle split would force reviewers to mentally stitch the rendering story back together across PRs.

### Labels note

Sub-issues created with `ai-planned` + `ai-delivered`. M-904 also carries `needs-arch-review` for the ARCHITECTURE.md one-line amendment. The `bundle:html-rendering` label was not recognised by Linear (label does not yet exist in the workspace) and was silently dropped on creation — the bundle grouping is documented in this Plan until the label is created.
