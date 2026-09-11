---
last_reviewed: 2026-05-29
---

# Project Intent

## Problem

Teams need a shared, auditable model for deciding what humans and AI
handle. Using AI only for code completion leaves humans with all the
planning and project management. Giving it open-ended goals without
review gates can produce work that is architecturally wrong, insecure,
or solves the wrong problem. Without a recorded plan, developers also
lack an explanation of the frameworks, patterns, and decisions behind
the output when debugging it.

## Users

Engineering teams using any coding agent that honours `AGENTS.md`
(Claude Code, Cursor, Codex, Aider, …) who want a fast but auditable
loop for AI-assisted delivery. Two roles are served: **engineers**, who
get a structured handoff between human judgement and AI execution; and
**engineering leadership**, who get a traceable audit trail for every
piece of AI-delivered work. SPADES is *not* for end users of any
product — it is a developer-workflow framework, not a runtime anyone
ships to customers.

## What it does

SPADES is a convention-plus-skills framework. It defines a six-phase loop —
Scope → Plan → Approve → Deliver → Evaluate → Ship — with explicit ownership:
humans define Scope, AI drafts Plans, and approval records delivery
routing (AI / human / hybrid). Evaluation checks the result. Under
`/spades:loop`, the AI handles gates it can complete; verification
that requires a human waits for that person. A Project layer above
Scopes groups related work; pluggable backends (Linear MCP, local filesystem,
extensible) keep the framework agnostic about where artefacts live.
It ships as Claude Code skills (`/spades:*`), with templates bundled
inside each producing skill directory, and `AGENTS.md` operating rules
for agents that read project context.

## Success

SPADES is working when every delivered piece of work can be traced back through
project → scope → plan(s) → approval (with routing) → deliver → evaluation → ship,
and a developer can explain *why* the output looks the way it does.
Approval catches defective Plans, delivery follows its recorded routing,
and captured learnings inform later Plans.

## Non-goals

- SPADES is **not** a runtime, service, or package — there is no server, no
  database, no daemon, no compiled artefact. It will never become one.
- SPADES does **not** plan strategy. Deciding *what* to build and *why it
  matters to the business* is human-owned; SPADES consumes the output of
  strategic thinking as Scopes, it does not generate it.
- AI never decides what to build. Shipment requires verification under
  the recorded evaluation routing; checks that require a human wait
  for that person.
- SPADES does **not** bind to a single agent vendor (no `CLAUDE.md`,
  no `CURSOR.md`) and does **not** auto-probe for a backend — backend
  selection is explicit.
- SPADES does **not** centralise state outside the consumer's repo.

## Maturity

SPADES governs its own development through the same loop it provides.
It has been in production since v2.0, which introduced a substantial
restructure (Project layer above Scopes, six-phase loop with Deliver and
Ship as first-class phases, pluggable backends behind a documented
contract, every template embedded in its producing skill). The core
loop is stable; future evolution is expected to be additive (more
backend drivers, sharper review heuristics, richer learning recall)
rather than structural.
