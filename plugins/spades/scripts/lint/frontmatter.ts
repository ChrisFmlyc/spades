#!/usr/bin/env node
/**
 * SPADES Framework v2.0 — minimal YAML-frontmatter parser and schema validator.
 *
 * Node built-ins only: no npm, no package.json, no node_modules, no YAML
 * library. SPADES frontmatter is intentionally shallow (flat key: value pairs,
 * optionally with list values like `[a, b, c]` or dash-prefixed items). If we
 * ever need nested structures we'll either take a YAML dependency or simplify
 * the schema.
 *
 * Runs under Node's native TypeScript type-stripping — `node frontmatter.ts`,
 * no build step, no transpiler, no flags. Requires **Node >= 22.18** (or >=
 * 23.6), where type-stripping is on by default. Keep this file to *erasable*
 * TypeScript syntax only: type annotations, interfaces, type aliases, and
 * `as` casts are fine; `enum`, `namespace`, and parameter properties are not,
 * because Node strips types rather than compiling them.
 *
 * Usage:
 *     scripts/lint/frontmatter.ts <file> [--require KEY[,KEY,...]] [--print]
 *     scripts/lint/frontmatter.ts --schema project <file>
 *     scripts/lint/frontmatter.ts --schema scope <file>
 *     scripts/lint/frontmatter.ts --schema plan <file>
 *     scripts/lint/frontmatter.ts --schema learning <file>
 *
 * Exit codes (plain parse mode):
 *     0  frontmatter parsed successfully and all required keys present
 *     1  usage error
 *     2  file has no frontmatter (no leading '---' line)
 *     3  frontmatter not terminated (no closing '---')
 *     4  a required key is missing
 *     5  frontmatter is malformed
 *
 * Exit codes (--schema mode):
 *     0  no hard-fail violations (warnings permitted, printed to stdout)
 *     1  usage error, or a hard-fail schema violation
 */

import { readFileSync, statSync } from "node:fs";
import process from "node:process";

type Fields = Map<string, string>;

const HTML_FRONTMATTER_OPEN_RE =
  /<script\s+type=["']application\/yaml["']\s+id=["']spades-frontmatter["']\s*>/i;
const HTML_FRONTMATTER_CLOSE_RE = /<\/script>/i;

/**
 * Render a string the way Python's `repr()` would, so parse-failure messages
 * are byte-identical to the ones this file's predecessor emitted. CI logs and
 * the lint scripts' `sed`-indented output both surface these verbatim.
 */
function repr(value: string): string {
  const escaped = value
    .replace(/\\/g, "\\\\")
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\r")
    .replace(/\t/g, "\\t");
  // Python prefers single quotes, switching to double quotes only when the
  // value contains a single quote but no double quote.
  if (escaped.includes("'") && !escaped.includes('"')) {
    return `"${escaped}"`;
  }
  return `'${escaped.replace(/'/g, "\\'")}'`;
}

/** Python's str.splitlines(), for the line endings that actually occur here. */
function splitLines(text: string): string[] {
  return text.split(/\r\n|\r|\n/);
}

/** Python's str.lstrip() / str.rstrip() with the default whitespace set. */
function lstrip(s: string): string {
  return s.replace(/^\s+/, "");
}

function rstrip(s: string): string {
  return s.replace(/\s+$/, "");
}

/** Return the YAML body lines from either a `.md` or `.html` artefact. */
function extractYamlBody(text: string): string[] {
  const lines = splitLines(text);

  // Markdown frontmatter — opens with `---` on line 1.
  if (lines.length > 0 && lines[0].trim() === "---") {
    const body: string[] = [];
    let closed = false;
    for (const line of lines.slice(1)) {
      if (line.trim() === "---") {
        closed = true;
        break;
      }
      body.push(line);
    }
    if (!closed) {
      throw new Error("frontmatter not terminated by '---'");
    }
    return body;
  }

  // HTML <script type="application/yaml" id="spades-frontmatter"> block.
  const mOpen = HTML_FRONTMATTER_OPEN_RE.exec(text);
  if (mOpen) {
    const after = text.slice(mOpen.index + mOpen[0].length);
    const mClose = HTML_FRONTMATTER_CLOSE_RE.exec(after);
    if (!mClose) {
      throw new Error(
        "spades-frontmatter <script> tag not closed by </script>",
      );
    }
    return splitLines(after.slice(0, mClose.index));
  }

  throw new Error("no opening frontmatter delimiter");
}

/** Parse the YAML body lines (same logic for both source formats). */
function parseYamlBody(body: string[]): Fields {
  const fields: Fields = new Map();
  // Hyphens are permitted in keys because harness-level skill frontmatter
  // uses them (`disable-model-invocation`, `allowed-tools`) alongside the
  // underscore-only keys the SPADES artefact schemas define. Widening the
  // key charset does not loosen any schema: the per-kind allow-lists in
  // checkUnknown() still decide which keys a project/scope/plan/learning
  // file may carry.
  const keyRe = /^([A-Za-z_][A-Za-z0-9_-]*)\s*:\s*(.*)$/;
  let currentKey: string | null = null;

  for (const raw of body) {
    if (raw.trim() === "") {
      currentKey = null;
      continue;
    }
    // YAML-style line comments — skip whole-line `#` comments inside
    // frontmatter. Lets authors annotate optional fields (e.g. "#
    // strategy_link: ...") without uncommenting; the linter ignores them.
    // Inline trailing comments after a key:value pair stay part of the value
    // (single-line parser; that's fine).
    if (lstrip(raw).startsWith("#")) {
      currentKey = null;
      continue;
    }
    if (lstrip(raw).startsWith("- ") && currentKey !== null) {
      fields.set(currentKey, `${fields.get(currentKey)}\n${lstrip(raw)}`);
      continue;
    }
    const m = keyRe.exec(raw);
    if (!m) {
      throw new Error(`cannot parse frontmatter line: ${repr(raw)}`);
    }
    const key = m[1];
    const value = rstrip(m[2]);
    if (fields.has(key)) {
      throw new Error(`duplicate frontmatter key: ${repr(key)}`);
    }
    fields.set(key, value);
    currentKey = key;
  }
  return fields;
}

/**
 * Extract the YAML frontmatter block as a flat map of string values.
 *
 * Supports two source formats:
 *   - Markdown `.md` artefacts with traditional `---` delimited frontmatter
 *     at the top of the file.
 *   - HTML `.html` artefacts (introduced in v3.0.0) that embed their
 *     frontmatter inside a `<script type="application/yaml"
 *     id="spades-frontmatter">…</script>` tag near the top of `<body>`.
 *
 * The dual format keeps the lint contract symmetric across CLI mode (`.md`
 * artefacts) and HTML mode (`.html` artefacts) — same schema, same enums,
 * same field allow-lists, only the source location changes.
 */
function parseFrontmatter(text: string): Fields {
  return parseYamlBody(extractYamlBody(text));
}

// ---------------------------------------------------------------------------
// v2.0 schemas. The canonical enum value sets MUST mirror
// docs/FRAMEWORK.md § .spades/ Local Layout. Extending an enum means editing
// both this block AND that section together. Do not broaden lists to paper
// over a real file that fails — fix the file or the schema deliberately.
// ---------------------------------------------------------------------------

type Enums = Record<string, readonly string[]>;

// --- Project schema ---------------------------------------------------------
const PROJECT_CORE_REQUIRED = [
  "id", "title", "description", "created", "updated",
] as const;
const PROJECT_KNOWN_FIELDS = new Set<string>([
  ...PROJECT_CORE_REQUIRED,
  "repos", "owners", "linear_project_id",
]);
const PROJECT_ID_RE = /^[a-z0-9](?:[a-z0-9-]{0,63})$/;

// --- Scope schema -----------------------------------------------------------
const SCOPE_CORE_REQUIRED = [
  "id", "title", "project", "status", "type", "created", "updated",
] as const;
const SCOPE_ENUMS: Enums = {
  status: [
    "scoped", "planning", "delivering",
    "evaluating", "shipping", "done", "rejected",
  ],
  type: [
    "feature", "bug", "chore", "docs", "refactor", "investigation",
  ],
  priority: [
    "urgent", "high", "this-cycle", "medium", "low", "backlog", "exploratory",
  ],
  origin: ["okr", "reactive", "ad-hoc"],
};
const SCOPE_KNOWN_FIELDS = new Set<string>([
  ...SCOPE_CORE_REQUIRED,
  ...Object.keys(SCOPE_ENUMS),
  "linear_issue_id", "strategy_link", "branch", "base_commit",
]);
const SCOPE_ID_RE = /^S-[a-z0-9](?:[a-z0-9-]{0,63})$/;

// --- Plan schema ------------------------------------------------------------
const PLAN_CORE_REQUIRED = [
  "id", "id_suffix", "scope", "title", "status",
  "deliverable_type", "created", "updated",
] as const;
const PLAN_ENUMS: Enums = {
  status: [
    "draft", "approved", "delivering", "evaluating", "shipped", "rejected",
  ],
  delivery: ["ai", "human", "hybrid", "undecided"],
  evaluation: ["ai", "human", "hybrid", "undecided"],
  deliverable_type: ["code", "artefact", "action"],
};
const PLAN_KNOWN_FIELDS = new Set<string>([
  ...PLAN_CORE_REQUIRED,
  ...Object.keys(PLAN_ENUMS),
  "depends_on", "linear_issue_id",
]);
const PLAN_ID_RE = /^P-[a-z0-9](?:[a-z0-9-]{0,63})-[A-Za-z0-9]{4}$/;
const PLAN_SUFFIX_RE = /^[A-Za-z0-9]{4}$/;

// --- Learning schema --------------------------------------------------------
const LEARNING_CORE_REQUIRED = ["title", "area", "created", "status"] as const;
const LEARNING_ENUMS: Enums = {
  area: ["scope", "plan", "approve", "do", "evaluate", "ship", "other"],
  status: ["active", "archived"],
};
const LEARNING_KNOWN_FIELDS = new Set<string>([
  ...LEARNING_CORE_REQUIRED,
  ...Object.keys(LEARNING_ENUMS),
  "tags", "public_safe", "scope_ref", "plan_ref",
]);

interface Verdict {
  fails: string[];
  warns: string[];
}

function checkEnums(fields: Fields, enums: Enums, rel: string): string[] {
  const fails: string[] = [];
  for (const [key, allowed] of Object.entries(enums)) {
    const value = fields.get(key);
    if (value && !allowed.includes(value)) {
      fails.push(
        `${rel}: invalid '${key}' value ${repr(value)} — ` +
          `expected one of: ${allowed.join(", ")}`,
      );
    }
  }
  return fails;
}

function checkRequired(
  fields: Fields,
  required: readonly string[],
  rel: string,
  kind: string,
): string[] {
  return required
    .filter((key) => !fields.get(key))
    .map((key) => `${rel}: missing required ${kind} field: ${key}`);
}

function checkUnknown(
  fields: Fields,
  known: Set<string>,
  rel: string,
  kind: string,
): string[] {
  return [...fields.keys()]
    .filter((key) => !known.has(key))
    .map((key) => `${rel}: unrecognised ${kind} field: ${key}`);
}

function validateProject(fields: Fields, rel: string): Verdict {
  const fails = checkRequired(fields, PROJECT_CORE_REQUIRED, rel, "Project");
  const warns = checkUnknown(fields, PROJECT_KNOWN_FIELDS, rel, "Project");
  const pid = fields.get("id");
  if (pid && !PROJECT_ID_RE.test(pid)) {
    fails.push(
      `${rel}: invalid project id ${repr(pid)} — must match [a-z0-9][a-z0-9-]{0,63}`,
    );
  }
  return { fails, warns };
}

function validateScope(fields: Fields, rel: string): Verdict {
  const fails = checkRequired(fields, SCOPE_CORE_REQUIRED, rel, "Scope");
  fails.push(...checkEnums(fields, SCOPE_ENUMS, rel));
  const warns = checkUnknown(fields, SCOPE_KNOWN_FIELDS, rel, "Scope");
  const sid = fields.get("id");
  if (sid && !SCOPE_ID_RE.test(sid)) {
    fails.push(
      `${rel}: invalid scope id ${repr(sid)} — must match S-[a-z0-9][a-z0-9-]{0,63}`,
    );
  }
  return { fails, warns };
}

function validatePlan(fields: Fields, rel: string): Verdict {
  const fails = checkRequired(fields, PLAN_CORE_REQUIRED, rel, "Plan");
  fails.push(...checkEnums(fields, PLAN_ENUMS, rel));
  const warns = checkUnknown(fields, PLAN_KNOWN_FIELDS, rel, "Plan");
  const pid = fields.get("id");
  if (pid && !PLAN_ID_RE.test(pid)) {
    fails.push(
      `${rel}: invalid plan id ${repr(pid)} — must match P-<slug>-<4char-suffix>`,
    );
  }
  const suf = fields.get("id_suffix");
  if (suf && !PLAN_SUFFIX_RE.test(suf)) {
    fails.push(
      `${rel}: invalid id_suffix ${repr(suf)} — must be 4 chars [A-Za-z0-9]`,
    );
  }
  return { fails, warns };
}

function validateLearning(fields: Fields, rel: string): Verdict {
  const fails = checkRequired(fields, LEARNING_CORE_REQUIRED, rel, "Learning");
  fails.push(...checkEnums(fields, LEARNING_ENUMS, rel));
  const warns = checkUnknown(fields, LEARNING_KNOWN_FIELDS, rel, "Learning");
  return { fails, warns };
}

const VALIDATORS: Record<string, (fields: Fields, rel: string) => Verdict> = {
  project: validateProject,
  scope: validateScope,
  plan: validatePlan,
  learning: validateLearning,
};

function isFile(path: string): boolean {
  try {
    return statSync(path).isFile();
  } catch {
    return false;
  }
}

function runSchema(kind: string, file: string): number {
  if (!isFile(file)) {
    console.error(`frontmatter: not a file: ${file}`);
    return 1;
  }
  const rel = file;
  const text = readFileSync(file, "utf8");
  let fields: Fields;
  try {
    fields = parseFrontmatter(text);
  } catch (exc) {
    const msg = exc instanceof Error ? exc.message : String(exc);
    console.error(`  FAIL: ${rel}: malformed frontmatter — ${msg}`);
    return 1;
  }
  const validator = VALIDATORS[kind];
  if (!validator) {
    console.error(`frontmatter: unknown schema kind: ${kind}`);
    return 1;
  }
  const { fails, warns } = validator(fields, rel);
  for (const w of warns) {
    console.log(`  warn: ${w}`);
  }
  for (const f of fails) {
    console.error(`  FAIL: ${f}`);
  }
  if (fails.length > 0) {
    return 1;
  }
  console.log(`  ok:   ${rel}`);
  return 0;
}

interface Args {
  file: string | null;
  require: string;
  print: boolean;
  schema: string | null;
}

/**
 * Mirrors the argparse surface the Python original exposed: one positional
 * `file`, plus `--require`, `--print`, and `--schema`. Both `--flag value`
 * and `--flag=value` forms are accepted, as argparse does. Usage errors exit
 * 2, again matching argparse.
 */
function parseArgs(argv: string[]): Args {
  const args: Args = { file: null, require: "", print: false, schema: null };
  // Reproduces argparse's wrapped usage banner verbatim — continuation lines
  // indent to len("usage: ") + len(prog) + 1 = 22.
  const usage =
    "usage: frontmatter.ts [-h] [--require REQUIRE] [--print]\n" +
    "                      [--schema {project,scope,plan,learning}]\n" +
    "                      file";

  const fail = (message: string): never => {
    console.error(usage);
    console.error(`frontmatter.ts: error: ${message}`);
    process.exit(2);
  };

  const takeValue = (arg: string, inline: string | undefined): string => {
    if (inline !== undefined) return inline;
    const next = argv.shift();
    if (next === undefined) fail(`argument ${arg}: expected one argument`);
    return next as string;
  };

  argv = [...argv];
  while (argv.length > 0) {
    const arg = argv.shift() as string;
    const eq = arg.indexOf("=");
    const name = arg.startsWith("--") && eq !== -1 ? arg.slice(0, eq) : arg;
    const inline =
      arg.startsWith("--") && eq !== -1 ? arg.slice(eq + 1) : undefined;

    if (name === "-h" || name === "--help") {
      console.log(
        `${usage}\n\n` +
          "Parse and validate SPADES frontmatter.\n\n" +
          "positional arguments:\n" +
          "  file\n\n" +
          "options:\n" +
          "  -h, --help            show this help message and exit\n" +
          "  --require REQUIRE\n" +
          "  --print\n" +
          "  --schema {project,scope,plan,learning}\n" +
          "                        validate the file against a SPADES v2 schema",
      );
      process.exit(0);
    } else if (name === "--require") {
      args.require = takeValue(name, inline);
    } else if (name === "--print") {
      args.print = true;
    } else if (name === "--schema") {
      const value = takeValue(name, inline);
      if (!(value in VALIDATORS)) {
        fail(
          `argument --schema: invalid choice: ${repr(value)} ` +
            `(choose from ${Object.keys(VALIDATORS).map(repr).join(", ")})`,
        );
      }
      args.schema = value;
    } else if (name.startsWith("-") && name !== "-") {
      fail(`unrecognized arguments: ${arg}`);
    } else if (args.file === null) {
      args.file = arg;
    } else {
      fail(`unrecognized arguments: ${arg}`);
    }
  }

  if (args.file === null) {
    fail("the following arguments are required: file");
  }
  return args;
}

function main(): number {
  const args = parseArgs(process.argv.slice(2));
  const file = args.file as string;

  if (args.schema) {
    return runSchema(args.schema, file);
  }

  if (!isFile(file)) {
    console.error(`frontmatter: not a file: ${file}`);
    return 1;
  }

  const text = readFileSync(file, "utf8");
  let fm: Fields;
  try {
    fm = parseFrontmatter(text);
  } catch (exc) {
    const msg = exc instanceof Error ? exc.message : String(exc);
    console.error(`${file}: ${msg}`);
    if (msg.includes("no opening")) return 2;
    if (msg.includes("not terminated")) return 3;
    return 5;
  }

  const required = args.require
    .split(",")
    .map((k) => k.trim())
    .filter((k) => k !== "");
  const missing = required.filter((k) => !fm.get(k));
  if (missing.length > 0) {
    for (const k of missing) {
      console.error(`${file}: missing required frontmatter field: ${k}`);
    }
    return 4;
  }

  if (args.print) {
    for (const [k, v] of fm) {
      console.log(`${k}=${v}`);
    }
  }
  return 0;
}

process.exit(main());
