# Wiring a Justfile into CI/CD

A spec-conformant `Justfile` is designed to be the backbone of a CI/CD
pipeline. The `Justfile` exposes the individual phases of the SDLC as
named recipes; the pipeline YAML orchestrates them — deciding which
recipes to call, in what order, and on what trigger.

## Division of responsibilities

| Layer | Owns |
|---|---|
| `Justfile` | What each individual SDLC phase ("build", "test", "release") means in this project. |
| CI YAML | Which recipes run, in what order, on what trigger, on what runners, with what caches and secrets. |
| Deployment tool (Helm, Terraform, Ansible, Fly, …) | Where the artifact ends up. |

The `Justfile` does NOT bundle the pipeline into a single composite
recipe. Pipeline composition (which steps run on which trigger) is the
CI layer's job; the `Justfile`'s job is to make each step individually
runnable, locally and in CI.

If something is missing, **add a recipe** — never an inline shell block
in the YAML. That preserves local/CI parity.

## Recommended recipes for CI

Add these to projects that have a CI pipeline:

- `publish` — push artifacts produced by `build` / `build-docker` to a
  registry. Separate from `release` so the release tag and the registry
  push are independent failure domains.
- `deploy <env>` (optional, project-specific) — apply the published
  artifact to a target environment. Typically delegates to a deployment
  tool; the recipe just provides a uniform local entry point.

## Trigger contract

Pin a tag-trigger contract so CI behavior is predictable across
projects. The pipeline calls recipes one by one — fail fast at each
step:

| Trigger | Pipeline behavior |
|---|---|
| Pull request | `just quality-full` → `just test` → `just build` |
| Push to `main` | `just quality-full` → `just test` → `just build` (canary, no publish) |
| Tag matching `v*-rc*` | `just quality-full` → `just test` → `just build` → `just publish` to staging channel |
| Tag matching `v*` (no suffix) | `just quality-full` → `just test` → `just build` → `just publish` to stable channel |

## Caching strategy

Use `just setup` as the cache-key seed. It is idempotent and project-
managed, so CI doesn't need to know what language the project is:

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.cache/uv
      ~/.cargo
      node_modules
      ~/go/pkg/mod
    key: ${{ runner.os }}-just-setup-${{ hashFiles('**/uv.lock', '**/Cargo.lock', '**/pnpm-lock.yaml', '**/go.sum') }}
- run: just setup
```

## Detecting CI in the Justfile

The `release` recipe asks for interactive confirmation. In CI, skip the
prompt by detecting `CI=true`:

```bash
# scripts/release.sh
if [ "${CI:-false}" = "true" ]; then
    confirm="y"
else
    read -rp "Cut release? [y/N] " confirm
fi
```

This means CI YAML can do `just release` without piping `echo y`.

## What the spec deliberately does NOT cover

These belong to the deployment target, not the project's task runner:

- **Environment promotion** (dev → staging → prod). Implement as
  separate `deploy-<env>` recipes if you want a uniform local entry
  point, but the actual logic is target-specific.
- **Rollback.** Same.
- **Secrets management.** Handled by the CI provider's secret store.
- **Notifications** (Slack, email). Belong in CI YAML.
- **Required-status-check naming.** Repo configuration, not code.
- **Matrix builds.** Pure YAML concern; the recipes themselves are
  language-agnostic and run identically on every matrix cell.

## Provider portability

Because every meaningful step is `just <recipe>`, switching CI
providers becomes a matter of translating the YAML plumbing. A typical
adoption path:

1. Get the project to spec compliance locally (each required recipe
   runs successfully on its own).
2. Wire the project's CI provider so that every meaningful step is a
   `just <recipe>` invocation; keep YAML to plumbing only (checkout,
   toolchain install, cache, secrets).
3. Add additional providers by translating only the YAML; the recipe
   calls stay identical.

## Anti-patterns to avoid

- **Inlining shell logic in CI YAML.** If you write more than two lines
  of shell in YAML, it belongs in a recipe.
- **Bundling the whole pipeline into a single composite recipe.**
  Orchestration is the CI layer's job; the `Justfile` exposes the
  individual phases. A monolithic `ci` recipe hides which step failed
  and forces local users into the same all-or-nothing flow.
- **Duplicating commands across providers.** The set of recipes a
  provider calls on each trigger should match the trigger contract
  above; every provider calls the same recipes in the same order.
- **CI-only steps that aren't reproducible locally.** A developer
  should always be able to run the same checks CI runs without special
  privileges.
- **Building inside the publish step.** `publish` consumes the output
  of `build`; it doesn't rebuild.
