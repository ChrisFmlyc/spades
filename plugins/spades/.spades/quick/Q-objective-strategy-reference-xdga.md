---
id: Q-objective-strategy-reference-xdga
id_suffix: xdga
project: spades-framework
title: "Ask for the Objective strategy reference before writing"
type: bug
status: shipping
pr_url: https://github.com/ChrisFmlyc/spades/pull/100
branch: fix/objective-strategy-reference
delivery: ai
created: 2026-09-07
updated: 2026-09-08
---

# Ask for the Objective strategy reference before writing

## What

Require the strategy-reference question after slug confirmation, accept a URL or ID without imposing a Horizon ULID, and verify the unchanged reference in the Linear label description on create/edit.

## Why

An Objective could be created without asking for the reference that binds it to the intended Horizon outcome.

## Gate Check

- [x] Single concern
- [x] Fewer than 50 changed implementation/release lines from the PR base, excluding this audit marker
- [x] Objective skill and required release metadata
- [x] No new dependencies
- [x] No schema or migration changes
- [x] No architectural changes
- [x] No security-sensitive code
- [x] No public API changes
- [x] Revertible as one PR change
- [x] Existing repository checks cover the skill format

## Verification

All five native lint checks passed; final skill-frontmatter rerun passed for all 22 skills. All four plugin version pins match 6.1.4. The generic skill-creator validator rejects SPADES' existing required top-level version field; that pre-existing format difference is preserved.

Manual instruction walkthrough: missing reference after slug confirmation waits for the answer; supplied URLs and IDs are confirmed and stored verbatim; a URL without any UUID/ULID is accepted; a URL containing a ULID stays a URL; UUIDs and ULIDs are alternative IDs, not required formats; Edit asks retain/replace and prompts when missing; explicit None remains empty; Linear read-back checks the exact reference. Saving a reference is distinguished from proving Horizon resolved it. Earlier extraction checks describe Horizon's reader, not restrictions on this skill's accepted input.

## Audit Trail

- 2026-09-07: Quick-path opened. Type: bug. Branch: fix/objective-strategy-reference. Delivery: ai. User explicitly requested the reference prompt and correct binding behavior. No Linear objects or Horizon data changed.
- 2026-09-07: Fix verified locally; publication pending. Plugin 6.1.3 → 6.1.4; objective 1.3.1 → 1.3.2; AGENTS version unchanged; changelog added.
- 2026-09-07: Draft PR opened: https://github.com/ChrisFmlyc/spades/pull/100. Fix commit: 6b5510a. Local Claude and Codex installed objective skills updated to 1.3.2 with original-file backups under /private/tmp/spades-objective-reference-install-backup; this local patch precedes the 6.1.4 release. No merge performed.

- 2026-09-08: User clarified that a URL is an alternative to an ID. Removed the unintended Horizon ULID requirement and URL extraction; reference collection remains mandatory and storage preserves the supplied value. Corrected the same unreleased PR.
- 2026-09-08: Corrected instructions passed all five native SPADES lint checks; reviewed URL-without-ID, URL-with-ID, UUID, ULID, missing-reference and edit-reference paths.
