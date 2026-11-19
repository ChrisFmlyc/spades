---
name: review-rules
description: Creates or maintains REVIEW.md, the project's rules for reviewing a code change — what counts as an Important finding, the nit cap, paths to skip, how findings cite file and line, re-review limits, and which paths need a person's sign-off. Starts from SPADES defaults the human tunes. Use when someone says "set up REVIEW.md", "update the review rules", "tune what the reviewer flags", "stop the review bot nitpicking", "skip these paths in code review", or when REVIEW.md is missing or flagged stale. Requires the human's confirmation before recording each section. A second opinion on a Scope or Plan is /spades:review.
version: 1.0.0
---

# /spades:review-rules

You are helping a human create or maintain `REVIEW.md` — the rules
every reviewer of a code change in this repository follows: the
fresh-context diff review in `/spades:evaluate` and `/spades:quick`,
review bots, and people. A root reference document, peer to
`INTENT.md`, `ARCHITECTURE.md`, `PATTERNS.md`, and `ANTI-PATTERNS.md`.

Read `docs/FRAMEWORK.md` § Asking the Human and § Output Format
before running.

### Output format

- **Both modes** — `REVIEW.md` at the repo root, the canonical
  record.
- **HTML mode** — additionally two renders from
  `${CLAUDE_PLUGIN_ROOT}/skills/review-rules/template.html`: a
  persistent `.spades/review-rules.html` and a transient
  `.spades/.tmp/review-rules.html` opened as the review surface for
  the assembled document. The per-section conversation stays in the
  terminal.
- **CLI mode** — each section's draft is presented in the CLI review
  pane (`docs/FRAMEWORK.md § CLI review pane`) on its confirmation
  question; the brief prints the write confirmation and the `Next:`
  line.

A committed root document; no backend mirror.

## Human confirmation

How the team's changes are reviewed is the team's decision. You start
from the defaults below, propose changes the repository suggests, and
suggest sharper wording. Every section lands only after the human
actively confirms it.

## What `REVIEW.md` is

It owns **how a change is reviewed**: what blocks a merge, what is
noise, and when a person must look. What the code should look like
is `PATTERNS.md` and `ANTI-PATTERNS.md`; how the system is built is
`ARCHITECTURE.md`. A reviewer checks a change against all of them,
using `REVIEW.md` to decide which findings matter.

### Who reads it

| Reviewer | How it reaches `REVIEW.md` |
|---|---|
| SPADES diff review (`/spades:evaluate`, `/spades:quick`) | Passed to the bundled `review-diff` agent on every review |
| Agents working in the repo | The SPADES block in `AGENTS.md` points them at it |
| Anthropic's Code Review on GitHub | Reads it automatically from the default branch |
| CodeRabbit | Through `knowledge_base.code_guidelines.filePatterns` in `.coderabbit.yaml` (§ Connecting CodeRabbit) |

## Inline template

The scaffold `/spades:setup` writes and Create mode starts from.
Exactly this shape; every section except Project Checks carries a
working default:

```markdown
---
last_reviewed: YYYY-MM-DD
---

# Review Rules

How a change to this repository is reviewed — by the SPADES diff
review, by review bots, and by people.

## Important

- **Correctness.** A wrong result, crash, lost or corrupted data, race, or unhandled failure path the change introduces.
- **Docs and config that lie.** Documentation, configuration, or prompts that contradict what the code does, or route something to the wrong place.
- **Security.** Injection, exposed secrets, missing authorisation, or unvalidated input crossing a trust boundary.
- **Broken contracts.** A change that breaks a documented interface, schema, command, or file format that others rely on.

## Nits

- **Five at most.** Report up to five nits per review, strongest first.
- **Never blocking.** A nit never holds up a merge.
- **Tooling owns style.** Formatting and style a formatter or linter enforces are not reported.

## Skip

- **Generated and vendored files.** Lockfiles, build output, vendored dependencies, and generated code.
- **SPADES records.** The `.spades/` audit records and their HTML renders.

## Writing Findings

- **Cite file and line.** Every finding names the file and line it concerns; a finding that cannot be placed on a line is left out.
- **Summary first.** A review opens with its count by severity, or states "No issues found."
- **Name the class.** Each finding names its bug class and lists every instance, so one fix covers them all.
- **Label pre-existing.** A defect on lines the change does not touch is labelled pre-existing and never blocks the change.

## Re-review

- **New commits only.** After the first round, a review covers only the commits since the last review.
- **No repeats.** A finding already reported, answered, or resolved is not reported again.
- **Rethink after three rounds.** When Important findings remain after three rounds, the reviewer recommends reconsidering the approach rather than another patch.

## Human Sign-off

- **CI and release.** `.github/workflows/` and release or deploy configuration.
- **Access control.** Authentication, authorisation, and permission code.
- **Secrets.** Code and configuration that store, load, or rotate credentials.

## Project Checks

<!-- List the checks specific to this project that a reviewer makes
     on every change, each with its reason. -->
```

Each rule is one bullet with a bold short title — `- **Title.**
explanation.` — so the renderer can card and count them. Paths in
Skip and Human Sign-off may be written as globs (`docs/generated/**`).

## Modes

Inspect `./REVIEW.md`: **Missing** → Create; **present** → Edit. The
scaffold `/spades:setup` writes already holds the defaults, so a
first tuning pass on it runs in Edit.

**Create.** Ask: **Tune the defaults section by section**
*(Recommended)* / **Write the defaults as they are**.

**Edit.** Read the existing file first, then ask how far the edit
goes: **Refresh `last_reviewed` only** / **Revise specific sections**
/ **Add a rule** (free-form, in the human's own wording) / **Full
review pass**. Untouched sections are preserved.

## Tuning a section

One section at a time, in the schema's order. Show the section's
current rules in the CLI review pane and ask: **Keep these**
*(Recommended)* / **Change them** (the human describes the change
under *Other*) / **Leave this section empty**.

Bring evidence from the repository into the proposal, labelled as
inferred:

- **Skip** — generated or vendored paths that exist here
  (`dist/`, `vendor/`, `*.lock`, `*.generated.*`).
- **Human Sign-off** — the concrete paths behind each default, such
  as the workflow files present and the directories holding
  authentication or secret handling.
- **Project Checks** — recurring review findings: Leads and learnings
  that describe the same class of problem more than once, and
  `PATTERNS.md` conventions a diff can visibly break.

Probe vague rules. "Don't be noisy" cannot be checked; "five nits at
most, none for formatting" can. A rule the team would not act on
stays out.

## The seven sections

A locked schema.

1. **Important** — what a reviewer reports as blocking. Each entry
   names a class of defect, not a single file.
2. **Nits** — what non-blocking findings look like and how many a
   review carries.
3. **Skip** — paths and file kinds a reviewer leaves alone.
4. **Writing Findings** — the shape of every finding and of the
   review's opening line.
5. **Re-review** — how later rounds narrow to new commits, avoid
   repeats, and end.
6. **Human Sign-off** — paths whose changes a person approves.
   `/spades:evaluate` adds a Human row for any changed path listed
   here.
7. **Project Checks** — checks particular to this project, each with
   its reason.

## `last_reviewed`

Set to today's date on every Create and every meaningful Edit,
including a "still accurate" pass.

## Writing the file

Write `./REVIEW.md` once the human has confirmed every section in
play.

**HTML mode** — after the write, dispatch two
`worker-html-review-rules` sub-agents in one wave per
`docs/FRAMEWORK.md § worker-html-*`, shared content and `open_path`,
different `output_path`: `.spades/review-rules.html` (persistent) and
`.spades/.tmp/review-rules.html` (transient, opened).

- `open_path`: the absolute `.spades/.tmp/review-rules.html` path for
  initial presentation when this document is the active task; `null`
  for refreshes or background use. Both workers inherit it per
  § Review-page ownership.
- `template_path`: `${CLAUDE_PLUGIN_ROOT}/skills/review-rules/template.html`
- `frontmatter`: `{ project_slug, last_reviewed, rendered_at,
  plugin_version }`
- `rule_count` *(scalar)*: total rules across the seven sections
- `signoff_count` *(scalar)*: rules under Human Sign-off
- `blocks`:
  - `important-rules`, `nit-rules`, `skip-rules`, `finding-rules`,
    `rereview-rules`, `signoff-rules`, `project-rules` — one card per
    bullet under the matching section. Fields: `title` (the bold
    lead), `text_html` (the rest).
  - `objective-banner` — the project's sole `open` Objective
    `{ id, title }` when exactly one exists, else `[]`.

Required markers: the seven `*-rules` blocks.

## Connecting CodeRabbit

CodeRabbit reads `AGENTS.md` and `CLAUDE.md` as code guidelines and
reads further files only through `.coderabbit.yaml`. When the
repository has a `.coderabbit.yaml`, or the human says CodeRabbit
reviews it, ask: **Add REVIEW.md to CodeRabbit's code guidelines**
*(Recommended)* / **Leave CodeRabbit's configuration as it is**.

On add, merge this into `.coderabbit.yaml`, creating the file when it
is absent and keeping every existing key and pattern:

```yaml
knowledge_base:
  code_guidelines:
    filePatterns:
      - "REVIEW.md"
```

The change lands in the same commit as `REVIEW.md`. Claude Code's
local `/code-review` follows `CLAUDE.md`; in a SPADES repository the
diff review in `/spades:evaluate` and `/spades:quick` carries
`REVIEW.md` to the local review.

## Brief

**HTML mode** (report “opened” only from `opened: true`; if opening
was requested but failed, link that selected page for manual opening.
With `open_path: null`, report the write only):

```
✓ REVIEW.md written (last reviewed YYYY-MM-DD)
✓ .coderabbit.yaml: REVIEW.md added to code guidelines      # when added
○ .spades/.tmp/review-rules.html opened in browser
Next: /spades:scope <title>
```

**CLI mode:** the write confirmation and the same `Next:` line; every
section was already reviewed in the pane.
