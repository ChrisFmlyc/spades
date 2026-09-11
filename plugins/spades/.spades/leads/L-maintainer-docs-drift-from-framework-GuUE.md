---
id: L-maintainer-docs-drift-from-framework-GuUE
title: Maintainer documents disagree with current skill and lint contracts
project: spades-framework
type: documentation
area: ARCHITECTURE.md / PATTERNS.md / ANTI-PATTERNS.md
effort: small
confidence: high
status: open
created: 2026-09-11
discovered_while: P-reliable-leads-workflow-4Y6N
sightings: 1
promoted_to:
closed_reason:
linear_issue_id:
---

## What
ARCHITECTURE.md:17 reports 15 commands while skills/ contains 22 SKILL.md files. ARCHITECTURE.md:116 and PATTERNS.md:119–123 describe template path references as unused, although skills/evaluate/SKILL.md:140 uses a sibling template.html. ANTI-PATTERNS.md:89 permits Python lint helpers while ARCHITECTURE.md:124–131 and PATTERNS.md:160 specify TypeScript on Node.

## Why it matters
Planning against these documents can flag supported framework behaviour as an architectural conflict or choose an outdated lint toolchain.

## Suggested action
Reconcile the maintainer documents with the current skill inventory, template rendering and CI lint contracts; review their freshness dates.

## Sightings
- 2026-09-11 — while P-reliable-leads-workflow-4Y6N; context: P-reliable-leads-workflow-4Y6N/delivery-1; evidence: prerequisite reads of ARCHITECTURE.md:17,116,124–131; PATTERNS.md:119–123,160; ANTI-PATTERNS.md:89; skills/evaluate/SKILL.md:140; skills/ inventory (22); branch: fix/reliable-leads-workflow; revision: 3072a813e3b92e33c9464eed81e1f9782905ade0 plus approved working-tree rewrite.
