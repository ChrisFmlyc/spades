---
name: fixture-unguarded-skill
description: Planted-violation fixture for lint-mcp-guard.sh. NOT a real skill.
---

# Fixture — Unguarded Skill

This file is a **deliberate violation** used by
`scripts/lint/lint-mcp-guard.sh` to prove its detection logic still
fires. It names a Linear MCP tool (`list_issues`) and intentionally
carries **no** `## Mode Resolution` section.

If the MCP-guard lint ever stops failing on this file, the detection
logic has rotted and the real check (across the nine SPADE skills) is
blind. The lint's self-test asserts this fixture is still caught.

**Do not "fix" this file** — its job is to stay broken.
