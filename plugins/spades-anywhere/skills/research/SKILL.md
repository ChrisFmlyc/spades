---
name: research
description: Landscape research on a topic via an isolated Opus 4.7 subagent. Use when the human says "properly research this", "look into X", "check the prior art", "second opinion on the landscape", "what does the SOTA look like for X", or asks any open question that needs external fact-finding (libraries, frameworks, benchmarks, postmortems, comparisons). Returns a structured findings report; optionally posts to a Linear parent issue with explicit human consent. Callable any time — not tied to a SPADES phase. Also matches the explicit slash-command form `/spades-anywhere:research`.
version: 0.1.0
---

## Pre-Flight

### Step 1 — Freshness check (mandatory)

Per `docs/FRAMEWORK.md` § Freshness (the canonical contract for
this plugin; the sister `spades` plugin documents the same rule
under `AGENTS.md` § Freshness Before Read-Across), this skill spawns
a read-across researcher subagent. When research is scoped to an
existing Scope (via `--scope <S-…>` or implicit Scope context), the
researcher reads the local Scope file for context — a stale local
`main` would feed stale context into the research dispatch.

Verify before spawning the researcher — but only when the consumer
is in the local-backend + git scenario described in
`docs/FRAMEWORK.md § Freshness`. In Linear-backend or no-git local
scenarios (the common case for `spades-anywhere` — Claude Desktop
projects, mobile, ChatGPT), this probe is a no-op:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null && \
  git fetch origin --quiet && git rev-list --count main..origin/main
```

- No git repo, or returns `0` → fresh. Continue.
- Returns non-zero → abort with: *"Local `main` is N commits behind
  `origin/main`. Sync (e.g. `git pull` or `/repo:sync` if you have
  the `repo` plugin) then re-invoke `/spades-anywhere:research`. The
  researcher grounds its work against the current Scope; stale
  context produces stale research."* Do not proceed.

For purely standalone research (no Scope context, no repo reads),
this check is technically over-cautious — but enforcing it uniformly
keeps the rule easy to teach. The cost of one `git fetch` is
negligible.

### Step 2 — Backend

`/spades-anywhere:research` works with or without a configured backend.
`.spades-anywhere/config` is only read if the human chooses to post the
report to a backend (Linear, etc.) — otherwise research output is
displayed inline and forgotten.

# SPADES Research

You are dispatching landscape research to an isolated subagent and
presenting its report to the human. The skill itself is **a thin
coordinator** — the actual research happens inside a fresh
`researcher` subagent context (Opus 4.7, read-only tools,
defined by the bundled `researcher` agent). The output
schema is documented in `docs/FRAMEWORK.md#research`.

This skill is **callable any time**. It is not gated on a SPADES
phase. It does **not** create sub-issues, transition statuses, or
generate Plans. Its only state mutation is an optional Linear
comment, gated by explicit human consent.

## Invocation modes

### Standalone — no Scope context

The default. The human asks a research question; the skill spawns
the subagent, displays the structured report inline, and stops.
Nothing is written to Linear. Examples:

- *"Could you properly research how prompt-caching is configured in
  the Anthropic SDK?"*
- *"Look into what the SOTA is for Markdown-to-HTML rendering in Go
  CLIs."*
- *"Check the prior art on persistent learnings stores in agent
  frameworks."*

### Scoped — with `--scope <S-…>` or implicit Scope context

When the human passes `--scope S-add-ai-helper-bot` (or invokes the
skill from a session that already has a SPADES Scope or Plan in
context — for example, mid-`/spades-anywhere:plan` on `S-add-ai-helper-bot`),
the skill prefixes the report with the Scope ID and offers to record
the findings against the Scope or Plan. Recording is **never silent
and never free-form**: the skill asks the human via `AskUserQuestion`
(per `docs/FRAMEWORK.md` § Asking the Human) which path to take.

## How to run this conversation

1. **Identify the question.** Read what the human asked. If the ask
   is ambiguous ("research auth"), ask one short clarifying question
   in free-form prose before spawning the subagent — clarification is
   open-ended composition, not a fixed-option decision, so it stays
   free-form.

2. **Identify the Scope context.** Was `--scope <id>` passed? Is the
   current session already operating on a SPADES parent issue (e.g.
   the human is mid-`/spades-anywhere:plan`)? If yes, capture the Scope ID for
   the consent prompt below. If no, this is a standalone run.

3. **Spawn the researcher subagent.** Use the `Agent` tool with
   `subagent_type: researcher`. Pass:
   - The question, verbatim.
   - The Scope ID and a brief Scope summary if scoped (so the
     subagent knows what context the report is informing).
   - Any local repo paths the subagent should be aware of, if the
     question implies "compare our X to library Y".
   - Foreground (not background) — you need the report before the
     next step.

4. **Display the report.** When the subagent returns, show the report
   inline to the human exactly as the subagent emitted it (the
   schema is locked at the framework level and consumers parse it
   positionally — do not summarise or reformat).

5. **If standalone, stop.** No Linear write, no further action.

6. **If scoped, ask the consent question via `AskUserQuestion`.**
   The question is *"This report can be posted as a comment on
   <issue-id>. Which would you like?"*. The options are exactly:

   - *Post this comment to <issue-id>*
   - *Just show me — don't post*
   - *Let me edit it first, then post*
   - *Cancel*

   Never use a free-form "y/n?" prompt. Never default to posting.
   Never proceed without an answer.

7. **Act on the consent answer.**

   - **Post this comment** — post the report to the parent issue
     verbatim, prefixed with `research:` on its own line at the top of
     the comment body so it is visually distinct from Plan comments
     (which start with `# Plan for ...`). Confirm to the human with
     the comment URL.

   - **Just show me** — do nothing. The report is already displayed
     inline; the conversation continues.

   - **Let me edit it first** — display the report in a code block
     marked `markdown` and ask the human to paste back the edited
     version. When they do, post their edited version with the
     `research:` prefix.

   - **Cancel** — drop it. No comment, no follow-up.

## Linear write — partial-failure handling

If the consent path is "post" and the Linear write fails (MCP
unreachable, parent issue resolved-mid-flight, comment write
rejected), follow the same precedent as `/spades-anywhere:plan`'s Linear
Integration:

1. Surface the failure to the human exactly: which step failed, what
   error came back.
2. Display the report **back inline** (in case the human's terminal
   scroll-back lost it) so they can manually paste it elsewhere if
   they want.
3. Do **not** retry indefinitely. One retry is fine if the failure
   looks transient (e.g. proxy 503); two failures means stop.
4. Do **not** auto-create a fallback `.spades-anywhere/research/<id>.md` file —
   research outputs are ephemeral by design (see
   `docs/FRAMEWORK.md#research`). If the human wants persistence,
   they can copy the report into a file themselves.

## What this skill does NOT do

- It does not generate a Plan, create sub-issues, or transition any
  Linear status. Research is informational; it informs human
  judgement, but doesn't drive the SPADES loop directly.
- It does not invoke `/spades-anywhere:review`. Research is fact-finding from
  outside; review is opinion on our own work. They're different.
- It does not capture findings as `/spades-anywhere:learn` learnings
  automatically. If the report uncovers something worth carrying
  forward to future Plans, the human can invoke `/spades-anywhere:learn`
  separately.
- It does not iterate. One question per invocation. Follow-up
  research is a follow-up invocation.

## After research

If the report changed the human's view on a Scope or Plan they're
working on, suggest the next SPADES step they might want to take:

- New finding that affects an in-flight Scope → suggest the human
  edit the Scope (`/spades-anywhere:scope` on the parent issue) to incorporate
  the new constraint or option.
- New finding that affects an in-flight Plan → suggest revisiting
  the Plan (revise via `/spades-anywhere:plan` if the Plan is still in
  Approval, or open a follow-up Scope if delivery has started).
- Finding worth keeping for future Scopes → suggest
  `/spades-anywhere:learn` to capture it as a public-safe or private learning.

These are suggestions, not actions. The human decides what to do
with the report.
