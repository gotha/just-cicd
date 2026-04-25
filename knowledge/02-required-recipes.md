# Required recipes

These MUST exist in every Justfile that follows this spec. Their
implementation is language-specific; their contract is fixed.

## `default`

Lists all recipes. Conventionally:

```just
default:
    @just --list
```

## `build`

Produce the project's deployable artifact (binary, wheel, jar, JS
bundle, Docker image base layer, …). MUST be reproducible from a clean
checkout. MUST NOT push or publish anything.

When the project also produces a container image, the language-native
build stays in `build` and the image build goes into `build-docker`
(see `04-optional-sections.md`).

## `lint`

Static checks only — no formatting changes, no auto-fixes. Exits
non-zero on any violation. Suitable for CI.

## `lint-fix`

Apply auto-fixes and formatting. Idempotent: running it twice produces
no diff.

## `test`

Run the project's test suite and validate that the code is working.
MUST exit non-zero on any failure. MUST cover the project's tests as a
whole — unit, integration, end-to-end — so that a green `just test` is
sufficient evidence that the code is in a releasable state.

## `run`

Start the project locally so the developer can interact with it. For an
API this means starting the server on `localhost`; for a CLI this means
invoking the entry point with sensible defaults; for a library it MAY
mean opening a REPL with the package preloaded.

`run` SHOULD use hot-reload / watch mode where the language ecosystem
supports it, runs in the foreground, and binds only to a local
interface.

If the project consists of multiple processes, also expose:

- `run-all` — start all processes in the background, redirecting logs
  to a known directory
- `stop-all` — terminate the processes started by `run-all`
- `logs-<process>` and `logs-all` — tail those log files

## `release`, `release-candidate`

- `release-candidate` — produce a pre-release artifact and tag (e.g.
  `vX.Y.Z-rcN`).
- `release` — promote to a stable release tag (`vX.Y.Z`).

Both recipes MUST accept a `--dry-run` argument that prints what *would*
be released (next version, commits since last tag, version-bump
category) and MUST NOT modify anything when it is passed:

- `just release --dry-run`
- `just release-candidate --dry-run`

In `just` this is typically implemented by declaring an optional
positional argument on the recipe and forwarding it to the underlying
release script, e.g.:

```just
# Cut a stable release. Pass --dry-run to preview without tagging.
release *args:
    ./scripts/release.sh release {{args}}
```

Both `release` and `release-candidate` MUST depend on, in order:

1. quality checks (formatting + lint + typecheck if applicable)
2. `test`
3. `build` (and `build-docker` if a container is part of the
   deliverable)

The implementation SHOULD derive the next version from
conventional-commit prefixes (`feat:` → minor, `fix:` / `chore:` /
`refactor:` / `docs:` → patch, `BREAKING CHANGE` → major) and SHOULD
push the resulting git tag.

A recipe that asks for interactive confirmation (typical for `release`)
MUST be runnable non-interactively by piping the answer to stdin, and
the expected answer MUST be documented in the recipe's comment.

A reference implementation of the underlying script lives at
`examples/scripts/release.sh`. It demonstrates the moving parts a
spec-conformant release needs — discovering the latest stable tag,
classifying conventional-commit messages into a major/minor/patch
bump, computing the next version, and pushing the resulting git tag
(plus an optional matching Docker tag). It is a starting point, not a
drop-in: adopting projects are expected to copy it into their own
`scripts/` directory and tailor the project name, the registry, the
artifact-tagging steps, and the `--dry-run` argument handling to match
the recipe contract above.
