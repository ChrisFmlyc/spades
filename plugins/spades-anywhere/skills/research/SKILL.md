---
name: research
description: Landscape research on a topic via an isolated researcher subagent. Use when the human says "properly research this", "look into X", "check the prior art", "second opinion on the landscape", "what does the SOTA look like for X", or asks any open question that needs external fact-finding (venues, vendors, options, comparisons, how others did it). Returns a structured findings report; optionally posts to a Linear parent issue with explicit human consent. Callable any time — not tied to a SPADES phase. Also matches the explicit slash-command form `/spades-anywhere:research`.
version: 0.2.0
---

# /spades-anywhere:research

You are dispatching fact-finding to an isolated subagent and
presenting its report. The skill is a thin coordinator: the research
happens inside a fresh `researcher` context (the bundled agent under
`agents/researcher.md`, read-only tools plus web search and fetch),
and the report comes back in that agent's fixed shape — `##
Question`, `## Findings` with footnoted citations, `##
Recommendation`, `## Sources`. On a surface without sub-agent
dispatch, the coordinator runs the researcher's instructions itself
in `degraded` mode and says so.

Research is callable at any point and mutates no SPADES state. Its
one optional side effect is a Linear comment, posted only with the
human's explicit consent.

Read `docs/FRAMEWORK.md` § Freshness and § Asking the Human before
running.

## Pre-Flight

1. **Freshness.** Applies in the local-backend-in-git scenario
   (`docs/FRAMEWORK.md § Freshness`) when the research is scoped and
   the researcher reads the local Scope:

   ```bash
   git rev-parse --is-inside-work-tree 2>/dev/null && \
     git fetch origin --quiet && git rev-list --count main..origin/main
   ```

   No git repo, or `0` → continue. Non-zero → abort: *"Local `main`
   is N commits behind `origin/main`. Sync, then re-invoke
   `/spades-anywhere:research`."*
2. **Backend.** `.spades-anywhere/config` is read only when a scoped
   run posts to Linear. Research works without a configured backend.

## Invocation modes

**Standalone** (default) — the human asks a question; the skill
spawns the researcher, displays the report, and stops.

**Scoped** — `--scope S-…` was passed, or the session is already
working on a Scope or Plan. The report is prefixed with the Scope ID
and the skill offers to record it against the Scope's backend
record.

## The conversation

1. **Identify the question.** An ambiguous ask gets one short
   free-form clarifying question first.
2. **Identify the Scope context**, if any.
3. **Spawn the researcher** via the Agent tool, `subagent_type:
   researcher`, in the foreground: the question verbatim, the Scope
   ID and a brief summary when scoped, and any local paths the
   question implies.
4. **Display the report** exactly as emitted.
5. **Standalone → stop.**
6. **Scoped with `backend: linear` → consent** via
   `AskUserQuestion`: *"This report can be posted as a comment on
   <issue-id>. Which would you like?"* — **Post this comment** (posted
   verbatim with `research:` on its own first line; confirm with the
   URL) / **Just show me — don't post** / **Let me edit it first,
   then post** (show it in a `markdown` code block, take the edited
   version back) / **Cancel**. With `backend: local` there is no
   issue to post to and the report stays in the conversation.

## Linear write failure

Surface which step failed and the error; display the report again
inline; retry once for a transient failure and stop after two.
Research output is ephemeral by design — the human saves it to
their knowledge store if they want it kept.

## Boundaries

Research informs judgement; it generates no Plan, creates no
sub-issue, transitions no status, invokes no
`/spades-anywhere:review`, and records no learning. One question per
invocation.

## After research

When the report changes the human's view of in-flight work, suggest
the next step and leave the decision with them: an in-flight Scope
→ `/spades-anywhere:scope` (Edit mode); an in-flight Plan →
`/spades-anywhere:plan` while `draft`, or a follow-up Scope once the
work has started; something worth keeping → `/spades-anywhere:learn`.
