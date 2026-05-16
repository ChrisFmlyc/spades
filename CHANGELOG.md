# Changelog

All notable changes to the SPADE Framework are documented here.
Versions follow [semver](https://semver.org/) at the framework level
(consumer fragments carry their own version stamp via
`<!-- SPADE-FRAMEWORK-START vX.Y.Z -->` markers).

## [1.6.1] — 2026-05-16

**Patch release — renderer fix and polish.** v1.6.0's HTML renderer
did not work on Pandoc 3.x. This release fixes it, gives the rendered
output a real visual design, and realigns the render lint with what
the feature is — a local-only convenience renderer, not a web app.

Renderer:

- `render/template.html`: fixed the `$for(css)$` block. It called
  non-existent Pandoc partials (`$styles.css()$`, `$css-content()$`)
  and made `spade-render` fail with exit 3 (`Could not find data file
  templates/styles.css`) on Pandoc 3.x. The stylesheet is now linked
  and inlined via `--embed-resources`, with `$highlighting-css$` for
  syntax highlighting. The `<html>` element carries `data-spade-status`
  so the stylesheet can theme to the document's phase.
- `bin/spade-render`: switched the deprecated `--highlight-style` flag
  to `--syntax-highlighting` (Pandoc 3.9+).
- `render/spade.css`: editorial redesign — status-coloured top accent
  bar, restructured document header (kicker pills, prominent title,
  quiet meta line), refined table of contents with nested indent
  guides, zebra-striped tables, softer code chips, tightened type
  scale. Light and dark both verified. 8.9KB, within the 12KB budget.

Lint:

- `scripts/lint/lint-render-security.sh` → `lint-render-smoke.sh`. The
  XSS / CSP / path-leak scan is replaced by a render smoke test: every
  fixture must render (exit 0) to a non-empty, standalone HTML document
  with the stylesheet inlined. `spade-render` turns the user's own
  Markdown into a local file they open themselves, so there is no
  web-security threat model to enforce; a functional regression guard
  (it would have caught the Pandoc 3.x breakage) is the right check.
  CI job renamed `render-security` → `render-smoke`.

Skills:

- `/spade-scope`: the render-and-link step is now a mandatory closing
  step, promoted from a trailing section so it is not treated as an
  optional appendix.

No fragment changes. Consumers on v1.6.0 only need to bump their
`.spade/version` pin to `1.6.1`.

## [1.6.0] — 2026-05-13

**HTML rendering for scopes and plans (Pandoc).** Every locally-stored
SPADE Scope and Plan now gets a sibling `.html` rendering produced by
the new `bin/spade-render` POSIX-shell wrapper around `pandoc`.
`/spade-scope` and `/spade-plan` append a clickable
`View in browser: file://...` link on every local write — modern
terminals (iTerm2, Warp, VS Code, Terminal.app) auto-linkify the URL
for cmd-click. Markdown remains canonical; HTML is a read-only
rendered view.

Released artefacts:

- `bin/spade-render` — POSIX-shell wrapper around `pandoc`, ≤100 lines.
- `render/template.html` — Pandoc HTML5 template (status header from
  frontmatter, TOC, restrictive CSP meta).
- `render/spade.css` — ≤12KB inlined stylesheet (system-font
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

- `/spade-scope` and `/spade-plan` gained a "Rendering and terminal
  link (v1.6+)" closing section. The render + link step is purely
  additive; existing skill behaviour is unchanged. Render failure
  never aborts the skill — the `.md` is always written.
- `/spade-update` documents the v1.3.x → v1.6.0 upgrade recipe with
  an informational pandoc presence check. No bulk render of historical
  `.md` files (lazy on next write only).

Architectural posture preserved:

- No vendored third-party code. No Node, no npm, no compiled
  artefacts. Pandoc is a recommended consumer dep, not a library.
- `PATTERNS.md` unchanged — "Markdown + YAML frontmatter is the only
  data format" still holds; HTML is a rendered view, not data.
- Graceful degradation: when pandoc is absent, `spade-render` exits 2
  and the calling skill surfaces an install hint on every write
  (not one-time-per-session) until pandoc is installed.

Deferred to v1.7+ (out of scope here):

- Mermaid pre-rendering (would pull in headless Chromium via `mmdc`).
- Terminal links on read skills (`/spade-status`, `/spade-list`,
  `/spade-approve`, `/spade-evaluate`, `/spade-review`).
- Bulk render on `/spade-update`.
- Auto-injection into the consumer's `.gitignore` (documented for
  opt-in only).
- AC checkbox state persistence, sticky TOC, dark-mode toggle button.
- Panel-report and learnings HTML rendering.

Scope: M-901. Two `/spade-review` panel rounds on the pre-shipped
drafts (33 + 41 findings, 4 blocking on the original Node-bundle
architecture) drove the switch to Pandoc and the minimum-viable
shape.

## [1.3.0] — 2026-04-28

- New skill `/spade-research` — landscape research via an isolated
  Opus 4.7 read-only subagent.
- New framework convention "Asking the Human" (`AskUserQuestion` for
  fixed-option decisions).
- Several skills retrofitted to the new convention.

## [1.2.0] — earlier

- M-420: Linear-canonical Plan storage. `.spade/plans/` becomes a
  fallback for Linear-less environments rather than a default
  dual-write.

## [1.1.x] — earlier

- Multi-persona `/spade-review` panel (5 subagents).
- `/spade-learn` skill.
- Execution posture field in Plan templates.
- CI lint suite.

## [1.0.0] — earlier

- Initial release: `/spade-scope`, `/spade-plan`, `/spade-approve`,
  `/spade-evaluate`, `/spade-quick`, `/spade-onboard`,
  `/spade-status`, `/spade-list`, `/spade-update`.
- Fragment-marker-based onboarding via `bin/spade-marker-replace`.
