# Conventions

## Naming

- **kebab-case** (`build-docker`, not `buildDocker` or `build_docker`).
- **Verb-first** (`run-api`, `create-user`, not `api-run`).
- **Group prefix matches the section** (`docker-compose-*`, `db-*`,
  `test-*`, `cli-*`, `logs-*`).
- **Avoid language names** in recipe names. `build`, not `go-build`;
  `test`, not `pytest`.

## Composition

Use `just`'s native dependency syntax (`recipe: dep1 dep2`) rather than
shelling out to `just <other>` from inside a recipe. The native form
makes the dependency graph visible to `just --evaluate` and to readers.

```just
# Good
quality: format lint typecheck

# Avoid — opaque dependency, slower, separate `just` invocation
quality:
    just format
    just lint
    just typecheck
```

## Variables

Group recipe-shared values at the top of the relevant section as
`name := "value"`. Avoid environment-variable lookups inside recipes
when a `just` variable will do.

```just
project_name := "myapp"
docker_tag   := "local/" + project_name + ":latest"

build-docker:
    docker build -t {{docker_tag}} .
```

## Inline shell scripts

Recipes that need branching, loops, or process management SHOULD use
the `#!/usr/bin/env bash` shebang form so they run as a single script
with `set -e`. Trivial recipes stay as one-liners.

```just
# Wait for the database to accept connections.
db-wait:
    #!/usr/bin/env bash
    set -euo pipefail
    for i in {1..30}; do
        pg_isready -h localhost && exit 0
        sleep 1
    done
    echo "database did not come up in time" >&2
    exit 1
```

## Comments

Each recipe SHOULD have a one-line comment immediately above it
describing what it does. The comment is what `just --list` shows.

```just
# Run all checks CI runs on PRs (quality-full + test + build).
ci: quality-full test build
```

## Forwarding arguments

Use `*args` to forward arbitrary flags to the underlying tool. This is
how `--dry-run` is wired through `release`:

```just
# Cut a stable release. Pass --dry-run to preview without tagging.
release *args:
    ./scripts/release.sh release {{args}}
```

## Cross-platform notes

- Stick to POSIX shell features in inline scripts unless you've already
  pinned `bash` via a shebang.
- Do not assume GNU coreutils flags; either use POSIX equivalents or
  pin tools through Nix / Docker.
