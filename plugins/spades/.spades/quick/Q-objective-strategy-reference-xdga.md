---
id: Q-objective-strategy-reference-xdga
id_suffix: xdga
project: spades-framework
title: "Ask for the Objective strategy reference before writing"
type: bug
status: shipping
pr_url:
branch: fix/objective-strategy-reference
delivery: ai
created: 2026-09-07
updated: 2026-09-07
---

# Ask for the Objective strategy reference before writing

## What

Require the strategy-reference question after slug confirmation, validate Horizon ULIDs, and verify the Linear label description on create/edit.

## Why

An Objective could be created without asking for the reference that binds it to the intended Horizon outcome.

## Gate Check

- [x] Single concern
- [x] 49 changed implementation/release lines, excluding this audit marker
- [x] Objective skill and required release metadata
- [x] No new dependencies
- [x] No schema or migration changes
- [x] No architectural changes
- [x] No security-sensitive code
- [x] No public API changes
- [x] Revertible as one fix commit
- [x] Existing repository checks cover the skill format

## Verification

All five native lint checks passed; final skill-frontmatter rerun passed for all 22 skills. All four plugin version pins match 6.1.4. The generic skill-creator validator rejects SPADES' existing required top-level version field; that pre-existing format difference is preserved.

Manual instruction walkthrough: missing reference after slug confirmation waits for the answer; a supplied reference is confirmed; Edit asks retain/replace and prompts when missing; a Horizon homepage or Linear UUID needs the outcome ULID; an explicit non-Horizon None remains unbound; Linear label read-back and conflicting milestone/issue IDs cannot be reported as a confirmed Horizon sync. Seven reference cases checked against Horizon's actual extractUlid implementation: bare, lowercase and URI ULIDs resolve; homepage, O-slug, Linear UUID and an embedded alphanumeric token do not.

## Audit Trail

- 2026-09-07: Quick-path opened. Type: bug. Branch: fix/objective-strategy-reference. Delivery: ai. User explicitly requested the reference prompt and correct binding behavior. No Linear objects or Horizon data changed.
- 2026-09-07: Fix verified locally; publication pending. Plugin 6.1.3 → 6.1.4; objective 1.3.1 → 1.3.2; AGENTS version unchanged; changelog added.
