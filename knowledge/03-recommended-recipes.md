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

## `quality`, `quality-quick`, `quality-full`

Composite recipes that group the checks above:

- `quality-quick` — `format` + `lint`
- `quality` — `format` + `lint` + `typecheck`
- `quality-full` — `quality` + dead-code detection + any slower static
  analysis (e.g. import-graph linting, security scanners)

These exist for ergonomics; everything they do is also reachable via
the single-purpose recipes.

## Test variants

When applicable, expose:

- `test-watch` — re-run the suite on file change
- `test-coverage` — produce a coverage report
- `test-feature <name>` / `test-scenario <name>` — narrow to one case
- `test-stop` — halt at first failure

## `ci`

A single composite recipe that mirrors what CI runs on every pull
request. Useful so a developer can reproduce the pipeline locally with
one command.

```just
# Run the same checks CI runs on every PR.
ci: quality-full test build
```

When a container image is part of the deliverable, append `build-docker`.
