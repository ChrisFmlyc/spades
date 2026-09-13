---
id: L-agent-backend-statement-drift-GSnt
title: Consumer operating rules hardcode a backend that disagrees with configuration
project: spades-framework
type: documentation
area: plugins/spades/AGENTS.md:39
effort: trivial
confidence: high
status: open
created: 2026-09-13
discovered_while: P-projectlead-assignment-hX8p
sightings: 1
promoted_to:
closed_reason:
linear_issue_id:
---

## What
The consumer operating rules at plugins/spades/AGENTS.md:39 state that the active backend is linear, while plugins/spades/.spades/config:6 selects local. Both statements exist in the delivery base revision.

## Why it matters
An agent reading the operating rules can choose the wrong backend for the framework's own project work, despite configuration being authoritative.

## Suggested action
Make the operating rules direct agents to read the active backend from .spades/config instead of hardcoding its value.

## Sightings
- 2026-09-13 — while P-projectlead-assignment-hX8p; context: P-projectlead-assignment-hX8p/delivery-1; evidence: plugins/spades/AGENTS.md:39 and plugins/spades/.spades/config:6; branch: feat/projectlead-assignment; revision: bbeff04f678312a4c0dd1c56c5bf87a1a1e7651b.
