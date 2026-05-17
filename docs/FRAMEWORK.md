# The SPADE Framework

## A Human-AI Operating Model for Engineering Teams

This is the full reference document for the SPADE Framework. For quick-start
usage, see README.md. For agent enforcement rules, see AGENTS.md.

---

## Why This Exists

The way we build software is shifting. AI agents can now read codebases,
generate plans, write code, run tests, and manage project boards, but they
cannot decide what to build, and they should not ship without human verification.

SPADE is our framework for structuring this. It defines clear boundaries between
what humans own and what AI handles, creating a loop that is fast, auditable,
and safe.

**The core principle:** Humans own the edges (intent and verification). AI owns
the middle (planning and execution).

### Where Scopes Come From

Scopes do not appear from nowhere. They are derived from OKRs and roadmap
priorities through a collaborative process between leadership and the team.
The flow is:

1. OKRs and roadmap set the strategic direction for the quarter.
2. Leadership and the team collaboratively break those down into concrete,
   actionable Scopes.
3. A Scope should be specific enough that someone could start work on it
   without needing a follow-up conversation to clarify intent.

A bad Scope: "We need to do threat intel."
A good Scope: "Ingest Telegram messages on a regular basis into the TI stack."

The first is a strategic direction. The second is something someone can plan
against and deliver.

### What Makes a Good Milestone

A milestone is not a time-boxed container and it is not a task. It is an outcome
derived from an OKR. You look at your OKRs for the quarter and ask: what needs
to be true for this to be on track? Each answer is a milestone.

The shift from traditional project management is subtle but important. A task
describes activity: "Build the ETL pipeline." A milestone describes a verifiable
outcome: "Device telemetry is flowing into the intelligence platform and
available for analysis." The first tells you what to do. The second tells you
what done looks like.

Good milestones share a few properties: they are verifiable (you can demonstrate
whether the outcome has been achieved), they are meaningful (achieving them
materially advances the OKR), and they decompose cleanly into Scopes (you can
look at a milestone and identify the concrete pieces of work needed to get there).

### How Work Gets Picked Up

The default expectation is that team members operate with autonomy: understand
the priorities, pull work, and drive it forward. Not everyone operates the same
way though. Some people thrive with high autonomy and minimal direction. Others
need clearer sequencing, more explicit assignment, and tighter check-in points.
The framework accommodates both.

What matters is that the Scope is clear enough for either type of person to act
on it. Whether someone pulls work independently or receives a more explicitly
assigned Scope with closer check-ins, the expectation is the same: the person
who picks it up owns the outcome, not just the execution. The assignment model
might differ, but the accountability model does not.

The goal is ownership, not task assignment. But ownership requires the work to
be visible and the expectations to be unambiguous.

### Reactive and Unplanned Work

Not all Scopes originate from OKRs. Tickets, incidents, vulnerability reports,
and ad-hoc requests are a normal part of any security team's workload. SPADE
handles these the same way it handles planned work, but the loop runs at a pace
proportional to the size and urgency of the task.

For small reactive items (a bug fix, a configuration change, a quick
investigation), the loop compresses. The ticket itself is the Scope. Planning
might be a single AI-generated comment proposing an approach. Approval is a
quick check. Delivery and evaluation happen in the same session. The structure
is the same; the ceremony is lighter.

For larger reactive work (an incident requiring coordinated response, a
vulnerability investigation spanning multiple systems), the work gets a proper
parent issue in Linear, scoped with acceptance criteria just like any planned
work. It enters the active cycle and runs through the full SPADE loop.

What matters is that all work, planned or reactive, has a clear Scope and a
visible owner. The origin of the work is less important than the clarity of what
needs to happen and how you know it is done.

### Key-Person Risk

If the collaborative scoping process only exists in conversations, it creates a
single point of failure. Scopes should be written down and visible (in Linear,
or wherever the team tracks work) so that priorities are clear even if the
person who defined them is unavailable. This is not about bureaucracy. It is
about making sure the team can keep moving without depending on any one
individual being in the room.

---

## The Loop

```
SCOPE --> PLAN --> APPROVE --> DELIVER --> EVALUATE
 (H)       (AI)      (H)       (AI/H)       (H)
              ^                    |
              |                    |
              +---- Rework <-------+
```

### Scope (Human)

The engineer defines what needs to be achieved and why it matters. This is not
a task description. It is a statement of intent with clear acceptance criteria
and constraints.

A good Scope answers:
- What does success look like?
- What are the acceptance criteria?
- What architectural constraints apply? (tech stack, patterns, security requirements)
- What does this connect to upstream and downstream?

A Scope is not an Initiative or an OKR. It should be concrete enough that an AI
agent (or a human) can generate a plan from it in a single session. If you find
yourself writing a Scope that spans multiple systems, multiple teams, or multiple
months, it is probably too big. Break it down.

The Scope is the contract. Everything downstream is measured against it.

### Plan (AI)

The AI agent takes the Scope and produces a structured plan: what to build, how
to build it, what to build it with, and in what order. The Plan is broken into
3-7 discrete tasks, each scoped tightly enough that an AI agent (or human) can
pick it up and deliver it in a focused session.

The Plan also includes:
- Technical approach and rationale
- Dependencies between tasks
- Risk callouts (what might go wrong, what assumptions are being made)
- Which tasks should be AI-delivered vs human-delivered
- Testing and verification approach: for software tasks, what tests are expected
  (unit, integration, E2E) and what passing looks like. For non-software tasks,
  what evidence demonstrates completion.

The Plan is a first-class artefact, not something that happens invisibly. It
gets documented and attached to the parent issue in Linear (as a comment or
Linear doc) so the team can see the reasoning, not just the output. This
behaviour is enforced through AGENTS.md which instructs AI agents to document
their plans and attach them to the relevant issue automatically.

### Approve (Human)

The engineer reviews the AI-generated Plan against reality. This is a gate,
not a rubber stamp.

Approval checks:
- Architecture alignment: Does this conform to our established patterns and
  tech stack?
- Completeness: Are there obvious gaps or missing edge cases?
- Feasibility: Can this actually be built this way with our constraints?
- Risk: Is the AI making assumptions that need to be validated?
- Scope: Is the task breakdown at the right granularity?

If the Plan does not pass Approval, it goes back to the AI with specific
feedback. Rejection is not failure. It is the framework working.

The biggest risk in SPADE is a weak Approval gate. A bad plan that gets rubber-
stamped leads to confidently wrong execution. If you are approving every plan
in 30 seconds, the gate is not working.

### Deliver (AI or Human)

The tasks from the Plan get executed. Some by AI agents, some by humans.

AI-delivered tasks are things like: writing code, building API endpoints,
creating data pipelines, generating configuration, writing tests, producing
documentation, and managing project boards.

Human-delivered tasks are things like: stakeholder conversations, hardware
testing, vendor negotiations, security reviews requiring physical access,
relationship-building, and anything requiring organisational context that AI
cannot access.

The framework does not pretend everything is AI-deliverable. It embraces the
mix and is explicit about who does what.

### Evaluate (Human)

After delivery, the engineer verifies the output against the original Scope.
This is distinct from the Approval stage. It is output validation, not approach
validation.

Evaluation checks:
- Does the output meet the acceptance criteria from the Scope?
- Does it actually work in practice (not just in theory)?
- Are there quality issues, edge cases, or regressions?
- Would I be comfortable shipping this?

If evaluation fails, work goes back, either to Deliver (minor fixes) or to Plan
(fundamental approach was wrong).

---

## Plan Schema

Every Plan produced by `/spade-plan` must conform to a documented schema so
downstream skills (delivery, review, evaluation) can consume it
deterministically. Consumers read Plans; drift in the schema breaks them.

### Required fields

Per Plan:

- Scope reference (issue ID or link)
- Technical approach summary (2-3 sentences)
- Risks and assumptions
- Delivery sequence
- Delivery bundles (default: one; see `/spade-plan` for split rules)

Per task:

- Title
- Description — what needs to be done
- Delivery mode — `ai-delivered` or `human-delivery`
- Dependencies — which other tasks must complete first
- Effort estimate — brief, moderate, or significant
- Approach — how it will be done
- Tests — what tests are expected, or what evidence demonstrates completion
- **Execution posture** — see vocabulary below

### Execution posture

Execution posture declares the delivery strategy for a task: not *what* to
build but *how* to approach the build. Posture propagates from Plan to
delivery: `/spade-plan` emits it, and delivery skills (or humans) honour it
when picking up the task.

Vocabulary (locked; extensions require a new Scope):

| Posture                 | When to choose                                                                                                     | Typical signal                                                                                          |
|-------------------------|--------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| `test-first`            | The desired behaviour is well-specified and you want failing tests to drive implementation.                        | New features with clear acceptance criteria; protocol/contract work.                                    |
| `characterization-first`| You are fixing a bug or refactoring existing code and need to pin down current behaviour *before* changing it.     | Bug fixes on code without adequate tests; pre-refactor safety nets.                                     |
| `refactor-first`        | Touching the area is only viable after a preparatory refactor; the new behaviour follows the cleanup.              | Code you cannot cleanly extend without first reshaping it.                                              |
| `spike`                 | The correct approach is genuinely unknown; the task's output is learning, not shippable code.                      | New technology evaluation; hard-to-estimate architectural choices.                                      |
| `straight-through`      | The change is mechanical enough that test-first / characterization-first ceremony adds no value.                   | Typo fixes, config bumps, docs edits, one-liners covered by existing tests.                             |

There is no silent default. Every task must declare a posture. If
`straight-through` is chosen, the Plan must state *why* — typically "covered
by existing tests" or "mechanical change". This avoids the failure mode
where posture becomes a rubber-stamp field.

A task may declare mixed posture when the work naturally splits (for
example, `characterization-first` on the existing module; `test-first` on
the new behaviour). Write it as `Execution posture: characterization-first on X; test-first on Y.`.

### Storage (v1.2.0+)

The canonical store for an approved Plan is the **tracker** (today:
Linear) — posted as a comment on the parent issue, with sub-issues
created for each Plan task. When the tracker is unavailable, the Scope
has no parent issue, or the Linear write fails, `/spade-plan` falls
back to a local file in the consumer repo and marks it with a fallback
banner. The filename is `.spade/plans/<issue-id>-plan.md` when the
Scope has a tracker identifier (e.g. `M-420-plan.md`), and
`.spade/plans/<scope-slug>-plan.md` when there is no parent issue at
all — the slug is a short kebab-case derivation from the Scope title
(e.g. `ingest-telegram-messages-plan.md`). Either way the file uses
the same frontmatter schema, so historical archives and v1.2+
fallbacks are interchangeable on the read path.

The same `.spade/plans/` path also preserves **historical archives**
written under v1.0–v1.1, when the framework defaulted to a dual-write.
v1.2.0 is non-destructive: existing archives are never deleted, moved,
or rewritten. Read-path skills (`/spade-evaluate` in particular) read
the tracker first and fall back to `.spade/plans/` if the tracker
cannot supply the Plan, so historical archives remain reachable
indefinitely.

The behaviour gate is "did the tracker accept the Plan", not merely
"is MCP present" — see `/spade-plan` § "Saving the Plan" for the
precise rule.

---

## Why SPADE Works

### It matches how AI agents actually perform

AI is excellent at planning (exploring solution spaces, breaking down problems,
identifying approaches) and delivery (writing code, following patterns, producing
output). AI is poor at deciding what matters to the business and verifying that
output works in the real world. SPADE puts AI where it is strong and humans where
AI is weak.

### It creates an audit trail

Every piece of work has: a human-written Scope (the "what"), an AI-generated
Plan (the "how"), an Approval decision (the "approved by"), delivery records
(the "done"), and an Evaluation (the "verified"). You can trace any delivered
work back through the full chain.

This matters for two specific reasons. First, AI-delivered work can easily become
opaque. Without a recorded plan, developers end up unable to explain what
frameworks, patterns, or architectural decisions went into the output. The audit
trail ensures that every piece of delivered work has a visible reasoning chain,
not just a result. Second, when something breaks in production, you need to trace
back through scope, plan, approval, and delivery to understand what went wrong
and where. Without that chain, debugging AI-delivered work is guesswork.

This is not overhead because it is automated. AGENTS.md instructs AI agents to
document plans and attach them to issues as part of the standard workflow.
Nobody is writing audit logs manually.

### It scales fractally (within limits)

The same SPADE loop works at every level of tactical and implementation scope:

- Tactical: "Build the ETL pipeline" -> AI plans the sub-tasks -> Human
  approves -> AI writes code -> Human evaluates
- Granular: "Implement schema validation" -> AI plans the approach -> Quick
  approval -> AI writes the function -> Human checks

The Approval gate gets lighter as scope gets smaller and risk gets lower.

At the strategic level, SPADE does not apply in the same way. Strategy requires
free-form thinking about business problems, customer needs, and market context.
AI can assist with research, analysis, and structuring options, but it should not
be planning your strategy for you. The output of strategic thinking feeds into
SPADE as Scopes and Milestones, but the thinking itself is human-owned.

### It prevents the two failure modes of AI-assisted work

Failure mode 1: Humans doing everything manually. Without a framework, teams use
AI as a fancy autocomplete, asking it to write individual functions but still
doing all the planning, structuring, and project management manually. SPADE
pushes planning and delivery to AI, freeing humans for judgement.

Failure mode 2: AI doing everything unsupervised. Without a framework, teams hand
AI an open-ended goal and hope for the best. The output might be technically
functional but architecturally wrong, insecure, or solving the wrong problem.
SPADE's Approve and Evaluate gates prevent this.

---

## Tooling: How It Works in Practice

SPADE is a pattern, not a product integration. The framework works regardless of
which tools you use to implement it. What follows describes our current tooling
choices, but if the tools change, the pattern holds. What matters is the human-AI
handoff loop, not the specific products.

### Linear as the System of Record

We use Linear to manage the full SPADE lifecycle. The hierarchy maps naturally:

```
Milestone (outcome derived from OKRs)
  +-- Parent Issue (SCOPE, human-written)
        |-- Sub-issue 1 (AI-planned task, AI-delivered)
        |-- Sub-issue 2 (AI-planned task, human-delivered)
        |-- Sub-issue 3 (AI-planned task, AI-delivered)
        +-- Plan Document (attached as comment or Linear doc)
```

The parent issue is the Scope. Written by a human. It contains the acceptance
criteria, constraints, and architectural context. This is the contract.

The sub-issues are the AI-generated Plan, broken into deliverable tasks. Each
sub-issue is small enough that an AI agent can complete it in a focused session.

The workflow tracks SPADE phases on the parent issue:

| Status      | Phase | Who is Active                                    |
|-------------|-------|--------------------------------------------------|
| Scoped      | S     | Human has defined the scope and acceptance criteria |
| Planning    | P     | AI is generating plan and sub-issues               |
| Approval    | A     | Human is reviewing the approach                    |
| Delivering  | D     | Sub-issues being worked (AI or human)              |
| Evaluating  | E     | Human validating against acceptance criteria       |
| Done        | ✓     | Shipped and verified                               |

Sub-issues use a simpler workflow: Todo -> In Progress -> Done

Labels indicate execution mode:

| Label              | Meaning                                    |
|--------------------|--------------------------------------------|
| ai-planned         | Plan was generated by AI                   |
| ai-delivered       | Task was completed by an AI agent          |
| human-delivery     | Task requires human hands                  |
| plan-rejected      | Plan was reviewed and sent back            |
| needs-arch-review  | Touches architecture, needs senior review  |

### Claude Code + Linear MCP

Claude Code (Anthropic's command-line AI agent) natively integrates with Linear
via MCP (Model Context Protocol). This means Claude Code can:

- Read issues: pull the Scope, acceptance criteria, and context directly from Linear
- Generate plans: create sub-issues on a parent issue with descriptions, priorities,
  labels, and assignments
- Deliver tasks: write code, build features, run tests, all with the Linear issue
  context loaded
- Update status: move issues through the SPADE workflow as work progresses
- Create documentation: attach plan documents, architecture notes, and decision
  records to projects

### Other AI Agents

SPADE is not locked to Anthropic tooling. The framework works with any AI agent
that can:

- Read a structured Scope (from Linear, Notion, or any project tool)
- Generate a structured Plan (sub-tasks with context)
- Deliver discrete tasks (code, documentation, configuration)
- Report completion status

Cursor, GitHub Copilot Workspace, Codex, or any future agent that supports MCP
can slot into the Deliver phase. The framework is tool-agnostic. It is about the
human-AI handoff pattern, not specific products.

---

## Cycle Rhythm

SPADE does not prescribe a rigid daily schedule. The rhythm is driven by two
concrete touchpoints per cycle, with everything else happening asynchronously.

Start of cycle: Scoping and Planning. The team reviews active Milestones and
agrees on the Scopes for this cycle. Each engineer owns their parent issues and
is responsible for ensuring the Scope is clear enough for AI to plan against.

End of cycle: Evaluation. Parent issue owners verify completed work against the
original Scope. Does it meet the acceptance criteria? Does it work end-to-end?
Issues that pass move to Done. Issues that fail go back with specific feedback.

Between those two points, delivery is continuous and asynchronous. Sub-issues get
worked by AI agents and humans as they become unblocked. New Scopes can be added
mid-cycle as priorities shift. The backlog is a living thing, not a quarterly
contract.

---

## Principles

1. Humans own the edges. Humans define what to build (Scope) and confirm it was
   built correctly (Evaluate). AI never decides what to build, and AI output is
   never shipped without human verification.
2. Plans are artefacts, not ephemeral. Every AI-generated plan is documented and
   attached to the work item.
3. Approval is a gate, not a rubber stamp. If you are approving every plan in
   30 seconds, the gate is not working.
4. Delivery mode is explicit. Every task is labelled as AI-delivered or
   human-delivery.
5. Feedback loops are first-class. A rejected plan goes back to Planning. A
   failed evaluation goes back to Delivery. The loop is expected to iterate.
6. Architecture constraints are codified, not memorised. Maintain living
   documents (ARCHITECTURE.md, PATTERNS.md, ANTI-PATTERNS.md) that AI reads
   during planning.
7. Scope determines approval depth. Strategic decisions get deep review.
   Granular implementation tasks get light review.

---

## Multi-persona Review

The `/spade-review` skill is a second-opinion gate. Since v1.1 it
operates as a **panel of persona subagents** rather than a single
generalist reviewer — five personas through v1.1–v1.x, four since
M-994. Each persona is defined under `.claude/agents/` and is primed to
care about one specific concern:

| Persona                         | Focus                                                                       |
|---------------------------------|------------------------------------------------------------------------------|
| `scope-guardian`                | Scope completeness, testability, Plan→Scope traceability; gold-plating / proportionality (absorbed remit). |
| `architecture-strategist`       | Conflicts with `ARCHITECTURE.md` / `PATTERNS.md` / `ANTI-PATTERNS.md`.      |
| `security-lens`                 | Auth, injection, secrets, supply chain, IAM, data sensitivity.               |
| `adversarial-reviewer`          | The strongest attack on the Plan — what will fail, and why; second-order / compounding cost (absorbed remit). |

M-994 folded the former `yagni-simplicity` persona's remit into the
scope guardian (gold-plating and proportionality) and the adversarial
reviewer (second-order and compounding cost); see §"Why a panel and
not a bigger generalist" below.

The rationale is captured in `.spade/learnings/2026-04-22-single-reviewer-is-weaker-than-panel.md`:
a generalist reviewer tends to collapse a review into the single most
obvious concern; a persona panel forces several independent angles and
surfaces findings the generalist would miss.

### How the panel runs

`/spade-review` assembles a structured summary of the Scope and/or
Plan (the same summary for every persona), then spawns all four
subagents in parallel where the runtime supports it. Each persona
returns a short prose summary followed by a JSON block of findings:

```json
{
  "persona": "scope-guardian",
  "severity": "blocking | major | minor",
  "confidence": "high | low",
  "category": "scope-completeness | ...",
  "message": "One or two lines describing the finding.",
  "refs": ["<file path>:<line>", "<linear id>", ...]
}
```

The coordinating skill then:

1. Parses every persona's JSON block.
2. **Detects convergence** by clustering findings that describe the
   same underlying concern — even across personas that filed them
   under different `category` values — into one finding, recording the
   other personas in `also_flagged_by`. This is a coordinator
   judgement, not a mechanical key match; see `/spade-review` SKILL.md
   § Merging.
3. **Sorts** by severity, then by convergence (the size of the
   `also_flagged_by` set). `confidence` is a display-only `high | low`
   flag, not a sort key — there is no `severity × confidence`
   arithmetic.
4. Presents a **tiered report** — convergence findings and every
   `blocking` finding inline, `major` up to an inline budget with the
   rest plus all `minor` collapsed to count lines — and persists the
   full untiered report to `.spade/reviews/`. Each persona's prose
   summary is shown **verbatim**, never summarised, plus a cross-model
   synthesis of disagreements and tensions for the human to resolve.

### Dispatch mode and the report envelope (v2.0.0)

Every `/spade-review` run emits two machine-parseable signals at the
top of its report so consumers can tell a real panel from a simulation:

1. **Dispatch-mode banner.** The first line of output is always
   `Dispatch mode: <value>` where `<value>` is one of:

   | Value                  | Meaning                                                                 |
   |------------------------|--------------------------------------------------------------------------|
   | `subagent-dispatch`    | Each persona ran as an independent Claude Code subagent context, in parallel. The strongest path — true multi-context review. |
   | `sequential-inproc`    | Each persona ran in an isolated context, but sequentially (runtime didn't support parallel spawns). Still genuinely multi-context; slower. |
   | `degraded`             | No isolated-context path was available; the coordinator simulated personas by re-prompting a single model context with each persona's priming. **Not a panel.** |

2. **Report envelope (JSON).** Immediately after the banner, a JSON
   code block carries structured metadata:

   ```json
   {
     "schema_version": "2.0.0",
     "dispatch_mode": "subagent-dispatch",
     "personas_spawned": 4,
     "personas_completed": 4,
     "findings_total": 0
   }
   ```

   - `schema_version` — report-envelope contract version. v1.1.1 added
     the envelope; v2.0.0 (M-994) is the four-persona redesign — `nit`
     dropped from `severity`, `confidence` recast to `high | low`, and
     the merge-side confidence filter removed. It is independent of the
     framework's `.spade/version` and fragment-marker mechanism.
   - `dispatch_mode` — matches the banner value.
   - `personas_completed` — counts only personas whose JSON parsed
     successfully. If a persona's output was unparseable, its prose is
     still shown but this counter does not increment.

### Degraded-mode honesty

When `dispatch_mode == "degraded"`, two honesty rules take effect:

- The report's section title is **`SINGLE-CONTEXT SIMULATION (degraded)`**,
  not `PANEL SECOND OPINION`.
- The coordinator is explicitly forbidden from using the words
  "panel" or "multi-persona" in the report title, framing prose, or
  synthesis. A single-context simulation is not a panel; claiming it
  is would retroactively falsify every audit trail citing the report.

These rules are load-bearing: the whole dispatch-mode machinery exists
to let consumers tell a real panel from a simulation. If the
coordinator launders a degraded run as a panel, the machinery is
useless.

### Non-blocking by contract

The panel is informational. It never gates approval or delivery. The
approval checklist in `/spade-approve` is the gate; the panel
supplements that checklist, it does not replace it.

### Why a panel and not a bigger generalist

Two reasons. **Coverage**: each persona is primed to care about one
angle, so a security concern and an architecture conflict don't
compete for the same attention budget. **Calibration**: structured
output with explicit severity and confidence lets the human defer
low-confidence findings without losing them — a generalist's prose
review is all-or-nothing.

The panel was five personas through v1.1–v1.x; M-994 reduced it to
four, folding the `yagni-simplicity` persona's remit into the scope
guardian (gold-plating and proportionality) and the adversarial
reviewer (second-order and compounding cost). Changing the panel
roster — adding or removing a persona — requires a new Scope that
explains the coverage rationale: more personas dilute the signal with
duplicate findings, fewer lose coverage.

---

## Asking the Human

SPADE skills routinely ask the human to make a decision: approve a
Plan, pick a verdict, confirm a destructive action, choose a label.
From v1.3.0 onward, the framework's convention for *fixed-option*
decision prompts is **Claude Code's `AskUserQuestion` tool** rather
than free-form prose. The structured prompt renders as a numbered
choice list — the human picks one, and the skill receives a clean,
unambiguous answer instead of having to parse a free-text reply.

This section defines the convention. Skill prose **references** it
rather than re-stating the rule in every skill.

### When to use `AskUserQuestion`

Use `AskUserQuestion` whenever **all** of the following hold:

- The set of valid answers is **closed** — there are 2–5 distinct
  choices and you can name each one.
- The human is being asked to **decide**, not to compose. ("Approve /
  Revise / Reject" is a decision; "Describe why this should ship" is
  composition.)
- The skill's next action **branches on which choice** the human
  picked. (If the choice doesn't change behaviour, why ask?)

Examples that fit:

- `/spade-approve`: *Approve / Approve with notes / Revise / Reject*.
- `/spade-evaluate`: *PASS / PARTIAL / FAIL*.
- `/spade-learn`: *Public-safe / Private / Skip*.
- `/spade-update`: *Pull updates / Skip*; destructive recovery
  *Confirm — wipe and reinstall / Cancel*.
- `/spade-scope`: priority *Urgent / High / Medium / Low*; *File in
  Linear now / Save as draft locally*.
- `/spade-research`: consent before Linear write *Post / Show only /
  Edit then post / Cancel*.

### When **not** to use `AskUserQuestion`

Stay free-form when:

- The human is composing content (writing a Scope's intent, drafting
  acceptance criteria, describing what failed in evaluation).
- The set of valid answers is open or unbounded (resolving an
  architecture conflict, naming a new pattern).
- The reply is naturally multi-line (a code-review comment, a
  rationale paragraph).

The convention is fixed-option-only. Forcing an open-ended question
into a 5-option list erases information the skill genuinely needs.

### Option-label style

Keep options scannable:

- **Verb-first.** *Approve*, *Revise*, *Pull updates*, *Confirm and
  wipe*. Not *Approval* or *Yes I would like to pull updates*.
- **Sentence case.** *Approve with notes*, not *APPROVE WITH NOTES*
  or *approve_with_notes*.
- **≤8 words per option.** Longer means split the prompt or rethink
  the question.
- **Distinguishable at a glance.** Two options that read nearly the
  same are a sign you should collapse them.

### Limits

- **≤5 options per prompt.** If a decision genuinely needs more,
  break it into two sequential prompts (e.g. "first pick a category,
  then pick a sub-option") or rethink whether some of those options
  are really the same choice.
- **One question at a time.** Don't bundle independent decisions into
  one prompt — they belong in separate prompts so the human can
  reverse one without re-doing the other.

### Why prose-only enforcement

The convention lives in skill prose, not in code or lint. SPADE skills
are Markdown — the agent reads the prose and follows it. We **don't**
have a runtime that intercepts free-form prompts and rewrites them.
That means the convention is a **review surface**: `/spade-review`'s
scope-guardian persona can flag prose prompts that should have been
`AskUserQuestion`. New skills are expected to
follow the convention from day one.

---

## Research

The `/spade-research` skill (v1.3.0+) spawns an isolated subagent
(`spade-researcher`, defined under `.claude/agents/`) on Opus 4.7 with
a read-only tool allowlist (`Read`, `Grep`, `Glob`, `WebSearch`,
`WebFetch`) to perform **landscape research** on a question the human
asks: prior art, library/SOTA evaluation, comparison shape, external
documentation reads. The subagent returns a single condensed report;
the parent skill displays it inline and (optionally, with explicit
human consent) posts it as a comment on a Linear parent issue.

The skill is **callable any time** — it is not tied to a SPADE phase.
Auto-trigger phrases include *"properly research this"*, *"look into
X"*, *"check the prior art"*, *"second opinion on the landscape"*, plus
the explicit slash-command form.

### Findings schema (locked)

Every report from the researcher subagent conforms to this shape, in
this order, with no preamble:

```markdown
## Question

<the asker's question, verbatim or near-verbatim>

## Findings

- <bullet 1, with inline footnote citation [^1]>
- <bullet 2, [^2]>
- <bullet 3, (no source — model knowledge)>
- ...

## Recommendation

<one paragraph, opinionated, ≤8 lines>

## Sources

[^1]: <Title> — <URL> (fetched YYYY-MM-DD)
[^2]: <Title> — <URL> (fetched YYYY-MM-DD)
```

The shape is locked. Consumers (`/spade-research`, future
`/spade-evaluate` integrations) parse it positionally.

### Read-only contract

The researcher subagent's tool allowlist is exactly `Read, Grep,
Glob, WebSearch, WebFetch`. It **may not** edit files, run shell
commands, create Linear issues, or chain to other subagents. The
parent `/spade-research` skill — running in the main session, not the
subagent — is responsible for any state mutation, gated by explicit
human consent.

### No fabricated citations

The single rule that distinguishes a research subagent from a
plausible-sounding bullshitter:

- Every URL in **Sources** must come from a real `WebSearch` /
  `WebFetch` result actually retrieved during the run.
- Facts from training data are marked `(no source — model
  knowledge)` inline in the bullet — never given a fake URL.
- Failed fetches are reported as failures, not papered over.

This rule is reinforced in the subagent's prose contract because the
failure mode (a fabricated citation that looks real) erodes trust
faster than any other.

### Consent before Linear write

When `/spade-research` is invoked with a Scope context (`--scope
<linear-id>` or implicitly from a phase that already has a parent
issue), it asks the human via `AskUserQuestion` (per the "Asking the
Human" convention above) whether to post the report:

- *Post this comment to <issue-id>*
- *Just show me — don't post*
- *Let me edit it first, then post*
- *Cancel*

Never silent, never free-form. The Linear comment, when posted,
carries a `research:` prefix in the body so it is visually distinct
from Plan comments.

### Ephemeral by default

Research outputs are not persisted under `.spade/`. There is no
`.spade/research/` directory and no read-back from past research. If
the human wants the report retained, they choose to attach it to a
Linear issue at consent-prompt time. Otherwise the report exists only
in the conversation transcript.

This is a deliberate constraint. A persistent research store would
introduce a second source-of-truth alongside Linear, the same drift
risk that v1.2.0 eliminated for Plans. If a real need for persistent
research surfaces, it gets a separate Scope.

### One question per invocation

The skill is one-shot per call. Iterative deep-dives, batched
multi-question runs, and follow-up "now research X' from those
findings" are out of scope and are expected to be separate
invocations.

---

## Learnings

Each pass of the SPADE loop should produce knowledge that strengthens the
next pass. Without a place to capture it, that knowledge vanishes into PR
descriptions and Evaluate comments. SPADE addresses this with a small
learnings store and a plan-time integration.

### Storage

Learnings live under `.spade/learnings/` in the consumer repo, one file
per learning, with the filename pattern
`YYYY-MM-DD-<short-slug>.md`:

- `.spade/learnings/*.md` — **public-safe** learnings. Committed with
  the rest of the repo.
- `.spade/learnings/private/*.md` — **not public-safe**. Gitignored.
  Use for entries that reference internal systems, credentials paths,
  security details, or anything else that must not leak into public
  forks.

Each file carries the following flat YAML frontmatter (no nested
structures — the framework's linter only supports flat keys):

```yaml
---
title: One-line summary of what was learned
area: onboarding | planning | delivery | review | other
tags: comma, separated, keywords
created: YYYY-MM-DD
status: active               # or "archived"
public_safe: true            # or false
scope_ref: LIN-123           # optional; link to originating Scope
---
```

Body conventionally has two sections: *What we learned* (specific
observation, not a platitude) and *Why it matters for future work* (the
concrete implication). See `.spade/learnings/` in this repo for two
worked examples distilled from the M-323 recon.

### Capture

Use `/spade-learn` to capture a learning (see
`.claude/skills/spade-learn/SKILL.md`). The skill drafts a complete
entry from context, asks whether it is public-safe, and routes to the
correct directory on write. Capture is cheap and meant to be used
freely — aim for a few learnings per Scope, not one per quarter.

### Refresh

Learnings decay. `/spade-learn --refresh` is a periodic (quarterly at
most), human-gated pass that:

- Lists active entries older than 180 days for triage (keep active /
  archive / delete).
- Flags pairs of active entries whose tags overlap ≥50% and whose titles
  appear to contradict, so the human can resolve before surfacing them
  to future Plans.
- Never silently modifies anything — every action requires explicit
  human approval, just like the Approve gate in the main loop.

The lint at `scripts/lint/lint-learnings.sh` surfaces stale entries as
warnings on every PR so staleness can't accumulate silently.

### Plan-time integration

Before producing a Plan, `/spade-plan` greps `.spade/learnings/*.md` for
entries that match the current Scope:

- A learning matches if its `scope_ref` equals the current Scope's
  Linear identifier, OR
- At least **`T`** of its `tags` appear in the Scope title or the tech
  stack row of `ARCHITECTURE.md`, where `T` is determined by the
  cold-start threshold below.

#### Cold-start threshold (v1.1.1)

`T` varies with store size to avoid two opposite failure modes:

- **Empty / small store (cold start):** `N < 20` active non-archived
  entries → `T = 1`. A single shared tag surfaces a learning. Without
  this, a consumer's first several Scopes never match anything and the
  loop looks dead on day one — the store stays empty because capture
  feels pointless.
- **Established store:** `N ≥ 20` active non-archived entries → `T = 2`.
  Single-tag coincidence becomes noise at this volume; two shared tags
  is the signal.

`N` counts entries with `status: active` under `.spade/learnings/`.
Archived entries are always excluded. The `private/` subdirectory is
excluded **by default** and included only when the operator explicitly
opts in via `/spade-plan` — matching the same opt-in rule the skill
uses when globbing for matches. The cutover is deterministic —
`/spade-plan` reads the count at match time.

The `scope_ref` path is unaffected by `T`. An entry whose `scope_ref`
equals the current Scope's identifier always surfaces, at any store
size.

The `20` threshold is a **deliberate, named number**. Changing it
requires a new Scope. Rationale: 20 is large enough that single-tag
matches produce noticeable noise, but small enough that most repos
cross the cutover within the first few cycles.

#### Matched-learnings log (v1.1.1)

When `/spade-plan` surfaces learnings, each entry in the `Prior
Learnings Considered` section carries a match-reason line showing why
it fired:

- `Match reason: scope_ref=<ID>` — the scope_ref path matched.
- `Match reason: tags matched [<tag1>, <tag2>, ...]` — the tag path
  matched; lists only the tags that actually matched the Scope, not
  the entry's full tag set.

This gives a human scanning the Plan a way to see when matching is
off — the prose framework has no telemetry, so the match reason is
the minimum viable observability for "which knob is the learnings
loop turning."

Matched entries surface in a `Prior Learnings Considered` section near
the top of the Plan. Archived entries are skipped. No matches = no
section; silence is cheaper than padding.

### Why this matters

The biggest failure mode of AI-assisted delivery is treating each task
as isolated. The same mistakes get made repeatedly because the
knowledge from Evaluate doesn't reach the next Plan. A 60-second
capture during or after Evaluate closes that loop for free.

Without a refresh mechanism, the store would rot. The pair of capture
+ refresh is what keeps the store high-signal over years, not weeks.

## HTML Rendering

From v1.6, every locally-stored Scope and Plan gets a sibling HTML
rendering produced by `bin/spade-render` (a POSIX-shell wrapper around
`pandoc`). Markdown remains canonical — HTML is a **read-only rendered
view**, regeneratable and `.gitignore`-able. Skills never read HTML
back; they read `.md`.

### Installing pandoc

| OS      | Command                                          |
|---------|--------------------------------------------------|
| macOS   | `brew install pandoc`                            |
| Linux   | `sudo apt install pandoc` (or distro equivalent) |
| Windows | `winget install pandoc`                          |

Pandoc 3.0+ is required (`--embed-resources` was added in 3.0,
replacing the removed `--self-contained`). When pandoc is absent,
`spade-render` exits 2 and the calling skill surfaces an install hint
on every write until pandoc is installed — the `.md` is the canonical
artefact and is always written.

### Renderer interface

```bash
spade-render <input.md>                   # writes sibling <input>.html
spade-render <input.md> --output <file>   # writes to <file>
spade-render <input.md> --stdout          # prints HTML to stdout
```

Exit codes: 0 success (prints absolute output path to stdout); 1 usage
or input-not-found; 2 pandoc not installed; 3 pandoc render error.

### Status pill palette

The renderer maps frontmatter `status:` to a coloured pill. These six
hex values are the single source of truth — mirrored verbatim in
`render/spade.css` as `--spade-status-<phase>` custom properties:

| Phase        | Colour    |
|--------------|-----------|
| `scoped`     | `#4f6cb5` |
| `planning`   | `#c69022` |
| `approval`   | `#d96e2a` |
| `delivering` | `#7b4ec3` |
| `evaluating` | `#2a8a8a` |
| `done`       | `#2f8b46` |

### Security stance

Renderer pins these Pandoc flags: `--from markdown-raw_html` (strips
inline HTML, blocking `<script>` and event-handler attribute
injection), `--standalone --embed-resources` (self-contained HTML, no
external references). The template emits a restrictive Content
Security Policy meta on every render:

```text
default-src 'none'; style-src 'unsafe-inline'; img-src data:; base-uri 'none'; form-action 'none'
```

CI enforces this via `scripts/lint/lint-render-security.sh` (greps
rendered fixtures for `<script`, `on*=`, `javascript:`, leaked
filesystem paths, and the exact CSP literal). The fixture suite lives
at `tests/fixtures/render/`.

### Recommended `.gitignore` line

By default, HTML siblings are regeneratable and need not be committed.
Add this line to the consumer's `.gitignore` to keep them out of PR
diffs:

```gitignore
.spade/**/*.html
```

This is **not** auto-injected by `/spade-onboard`; consumers add it
explicitly. Teams that prefer to commit HTML (offline reading,
PR-comment screenshots, GitHub Pages hosting) can leave it out.

### Terminal `file://` links

`/spade-scope` and `/spade-plan` append a closing line on every local
write:

```text
View in browser: file://<absolute-path>.html
```

Modern terminals (iTerm2, Warp, VS Code, Terminal.app) auto-linkify
the URL for cmd-click. SSH, tmux, screen and CI runners may not — the
plain-text URL still works as a copy-paste fallback. macOS/Linux paths
map directly (`file:///Users/...`, `file:///home/...`); Windows under
Git-Bash/WSL produces `file:///C:/...` via `realpath`.

### Determinism

Identical `.md` produces identical `.html` **within the same Pandoc
minor version**. Across minor versions, output may differ slightly
(typically whitespace and id slug changes). Consumers who commit HTML
should expect small diffs on Pandoc upgrades; this is documented
behaviour, not a defect.

---

*The SPADE Framework v1.1, April 2026, M-KOPA Product Security Team*
