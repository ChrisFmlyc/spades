---
last_reviewed: 2026-05-29
---

# Project Intent

## Problem

Teams adopting AI agents for engineering work fall into one of two failure
modes. Either AI is used as fancy autocomplete — humans still do all the
planning, structuring, and project management, so there is no leverage. Or AI
is handed open-ended goals with no review gates — and produces work that is
confidently wrong: architecturally off, insecure, or solving the wrong
problem. There is no shared, auditable operating model for *where humans
decide and where AI executes*. A second pain compounds it: AI-delivered work
becomes opaque — with no recorded plan, nobody can later explain what
frameworks, patterns, or decisions went into the output, and debugging it in
production is guesswork.

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
Scope → Plan → Approve → Do → Evaluate → Ship — with explicit ownership:
humans own the edges (intent at Scope, verification at Evaluate, gating at
Approve), AI owns the middle (planning and execution), and Do is routed at
Approve time (AI / human / mixed). A Project layer above Scopes groups
related work; pluggable backends (Linear MCP, local filesystem,
extensible) keep the framework agnostic about where artefacts live.
It ships as Claude Code skills (`/spades:*`), with templates embedded
inside each producing skill, and an `AGENTS.md` enforcement layer any
agent reads.

## Success

SPADES is working when every delivered piece of work can be traced back through
project → scope → plan(s) → approval (with routing) → do → evaluation → ship,
and a developer can explain *why* the output looks the way it does. When the
Approve gate genuinely catches bad plans rather than rubber-stamping them.
When neither failure mode (all-manual, or unsupervised-slop) shows up in
practice. And when each pass of the loop makes the next one stronger —
captured learnings actually reach the next Plan.

## Non-goals

- SPADES is **not** a runtime, service, or package — there is no server, no
  database, no daemon, no compiled artefact. It will never become one.
- SPADES does **not** plan strategy. Deciding *what* to build and *why it
  matters to the business* is human-owned; SPADES consumes the output of
  strategic thinking as Scopes, it does not generate it.
- AI never decides what to build, and AI output is never shipped without
  human verification — this is a permanent boundary, not a maturity stage.
- SPADES does **not** bind to a single agent vendor (no `CLAUDE.md`,
  no `CURSOR.md`) and does **not** auto-probe for a backend — backend
  selection is explicit.
- SPADES does **not** centralise state outside the consumer's repo.

## Maturity

In production at v2.0 and dogfooding itself — SPADES governs its own
development through the same loop it provides. v2.0 was a substantial
restructure (Project layer above Scopes, six-phase loop with Do and
Ship as first-class phases, pluggable backends behind a documented
contract, every template embedded in its producing skill). The core
loop is stable; future evolution is expected to be additive (more
backend drivers, sharper review heuristics, richer learning recall)
rather than structural.
