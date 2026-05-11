# Recommended recipes

Provide these when the project's tooling supports them.

## `setup`

One-shot install of all dependencies needed for development.
Idempotent. Wraps the language's package manager (`uv sync`, `npm ci`,
`go mod download`, `cargo fetch`, `bundle install`, `mvn install`, …).
MAY also pull pre-commit hooks, model files, fixtures, or seed data.

## `format`

Apply formatting only (no lint fixes). Often subsumed by `lint-fix`;
expose separately when the project uses distinct format and lint tools
(e.g. `gofmt` + `golangci-lint`, `prettier` + `eslint`,
`ruff format` + `ruff check`).

## `typecheck`

Static type analysis (`mypy`, `tsc --noEmit`, `go vet`, `cargo check`,
`flow check`, …). Required for typed languages; omitted otherwise.

## `quality`

A single composite recipe that groups every code-quality check the
project runs: `format` + `lint` + `typecheck` plus any slower static
analysis the project relies on (dead-code detection, import-graph
linting, security scanners, dependency audits, …).

```just
# Run every code-quality check.
quality: format lint typecheck
    # …project-specific slower analyses go here…
```

`quality` is the single quality gate. Everything it runs is also
reachable via the single-purpose recipes (`format`, `lint`,
`typecheck`); `quality` exists so the pipeline and developers have one
recipe to call for "all static checks".

The spec deliberately does NOT split this into fast/slow tiers
(`quality-quick`, `quality-full`). If a project wants a faster inner
loop, the developer runs `just lint` or `just typecheck` directly;
splitting `quality` itself creates ambiguity about which tier the
release gate depends on.

## Test variants

When applicable, expose:

- `test-watch` — re-run the suite on file change
- `test-coverage` — produce a coverage report
- `test-feature <name>` / `test-scenario <name>` — narrow to one case
- `test-stop` — halt at first failure
