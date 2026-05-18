# Fixture — linear mode

A minimal SPADE consumer repo configured for **`linear` mode**, used to
verify M-879 by hand: an existing tracker-backed repo keeps resolving
`linear` and is unaffected by the local-mode work (existing-repo
non-regression).

## Shape

```
.spade/config                              mode: linear, team_id present
.spade/version                             spade_version pin
.spade/scopes/add-healthz-endpoint.md      one Scope (status: delivering)
.spade/plans/add-healthz-endpoint-plan.md  its Plan
```

This is the same shape as `examples/fixture-local-mode/`; only
`.spade/config` differs (here: explicit `mode: linear`, with a
`linear.team_id`).

## Manual exercise

With this directory as the working directory:

1. **`/spade-status`** and **`/spade-list`** resolve `linear` mode —
   `mode: linear` is explicit, so the resolver runs no probe and takes
   the tracker path.
2. The local `.spade/scopes/` and `.spade/plans/` files are **not** the
   canonical source in `linear` mode; they are present only so the
   fixture matches `fixture-local-mode/` shape for shape-diff testing.

**Pass:** the resolver reports `linear` mode and the skills take the
tracker path. **Fail:** the resolver picks `local`, or a skill reads
the local files as canonical.
