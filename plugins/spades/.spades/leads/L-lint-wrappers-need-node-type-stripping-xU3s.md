---
id: L-lint-wrappers-need-node-type-stripping-xU3s
title: Lint wrappers fail opaquely on Node builds without TypeScript type stripping
project: spades-framework
type: testing
area: plugins/spades/scripts/lint/*.sh (node frontmatter.ts); scripts/lint/README.md:23; ARCHITECTURE.md:129,148
effort: small
confidence: high
status: open
created: 2026-10-27
discovered_while: P-narrow-skill-triggers-and-newproject-disclosure-8XWy
sightings: 1
promoted_to:
closed_reason:
github_issue: https://github.com/ChrisFmlyc/spades/issues/118
linear_issue_id:
---

## What
All five lint wrappers in plugins/spades/scripts/lint/ run `node frontmatter.ts` and fail for every file with `ERR_UNKNOWN_FILE_EXTENSION ".ts"` under a distro-packaged Node v22.22.1, also with `--experimental-strip-types`. That build reports `process.features.typescript: false` (compiled without the bundled type stripper). scripts/lint/README.md:23 and ARCHITECTURE.md:129,148 give "Node 22.18+" as the only requirement. CI (setup-node "22") passes. It reproduces on clean main.

## Why it matters
A Node that meets the documented version still fails every lint, one opaque error per file, so local runs look like content failures and maintainers fall back to trusting CI.

## Suggested action
Preflight `process.features.typescript` once in the lint wrappers (or run-all.sh) and exit with a message naming the requirement; state "Node 22.18+ with native type stripping" in scripts/lint/README.md and ARCHITECTURE.md.

## Sightings
- 2026-10-27 — while P-narrow-skill-triggers-and-newproject-disclosure-8XWy; context: eval:8XWy:local-lint-node-ts; evidence: evaluation run of plugins/spades/scripts/lint/*.sh on this branch and on clean main (ERR_UNKNOWN_FILE_EXTENSION for scripts/lint/frontmatter.ts; process.features.typescript false); .github/workflows/lint.yml NODE_VERSION "22"; branch: fix/narrow-skill-triggers-newproject-disclosure; revision: 1b3716eba9629ffc8d7ed4a7f1df892697c63095.

## History
- 2026-10-27 — GitHub mirror created: issue #118 (https://github.com/ChrisFmlyc/spades/issues/118), labels spades:lead + testing (labels spades:lead and testing created in the repo); result verified by read-back of title, OPEN state, labels and body; worker-leads, dispatch mode degraded (caller asked for no further delegation).
