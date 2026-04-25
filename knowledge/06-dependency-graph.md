# Required recipe-dependency graph

```
release [--dry-run]           ──► quality (or quality-full) ──► test ──► build [──► build-docker]
release-candidate [--dry-run] ──► quality (or quality-full) ──► test ──► build [──► build-docker]

quality       ──► format ──► lint ──► typecheck
quality-quick ──► format ──► lint
quality-full  ──► quality ──► find-unused [──► other slow analyses]
```

`--dry-run` does not change the dependency chain; quality and tests
still run (so the preview reflects what *would* actually be released),
but the recipe MUST NOT create tags, push to a remote, publish
artifacts, or otherwise modify state when the flag is set.

All other recipes are leaves and may be run independently.

## Common workflows

### First-time setup

```bash
just setup
just db-migrate     # if migrations apply
just run            # or run-all for multi-process projects
```

### Daily development

```bash
just lint-fix
just test
just run
```

### Pre-commit

```bash
just quality
just test
```

### Cutting a release candidate

```bash
just release-candidate --dry-run    # preview next version
just release-candidate
```

### Promoting to stable

```bash
just release
```

### Reproducing CI locally

```bash
just ci
```

## Why this shape

- **`release` depends on `test`, not the other way around.** A release
  is the *output* of a passing pipeline.
- **`build` is a dependency of `release`, not a side-effect.** Anyone
  running `just build` should get the exact same artifact CI ships.
- **`quality` is a hard gate.** Linting and typechecking are fast and
  deterministic; failing them is cheap and catches an entire class of
  defects before tests run.
- **`--dry-run` does not skip dependencies.** A preview that doesn't
  reflect the actual gates is misleading. Skip only the publish/tag
  side-effects.
