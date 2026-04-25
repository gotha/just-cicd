# Optional sections

These are added only when the project actually uses the underlying
technology. When omitted, nothing in the required-recipes section
breaks.

## Nix

If `flake.nix` is present, expose:

- `shell` — `nix develop`

Recipes MUST NOT hard-require Nix. A developer with the right tools on
`PATH` should be able to run any recipe without entering the Nix shell.
This keeps Nix as a convenience for contributors and a reproducibility
guarantee for CI, not a barrier to entry.

## Docker

If a `Dockerfile` is present, expose:

- `build-docker` — build the image with a stable local tag,
  conventionally `local/<project>:latest`

`build-docker` is separate from `build` so that `build` remains
language-native and fast, and so CI can build the language artifact
even when Docker is unavailable.

## Docker Compose

If `docker-compose.*.yaml` files are present, follow the
composable-files pattern: each file represents a single concern
(`base`, `dev`, `prod`/`gpu`, `tools`), and recipes stack them with
`-f` flags.

Naming: prefix every recipe with `docker-compose-`. Typical recipes:

- `docker-compose-up` — production-mode start (background)
- `docker-compose-dev` — dev-mode start (foreground, hot-reload)
- `docker-compose-down` — stop
- `docker-compose-clean` — stop and delete volumes (destructive — make
  this clear in the recipe comment)

Do NOT wrap operations that already have ergonomic native syntax
(`logs`, `ps`, `restart`, `scale`, `exec`). Document them in the
project's compose guide instead so users learn the underlying tool.

## Migrations / database

If the project owns a schema, expose:

- `db-migrate` — apply pending migrations
- `db-migrate-rollback` — undo the last migration
- `db-migrate-status` — show the current revision
- `db-migrate-history` — show all revisions
- `create-db-migration <name>` — scaffold a new migration

When migrations also need to run inside a container, mirror these under
`docker-compose-migrate*`.

## Project CLI / API helpers

If the project exposes a CLI or HTTP API, add thin wrappers for
operations the developer performs many times a day (creating a test
user, calling a frequently-used endpoint with `curl`, tailing a
specific log). Keep them in their own clearly-named section
(e.g. `cli-*`, `api-*`) so they don't pollute the SDLC core.

## Publishing (`publish`)

The required `build` recipe MUST NOT publish. When the project produces
artifacts that are pushed to a registry (container registry, package
index, language registry), expose a separate `publish` recipe:

- `publish` — push the artifacts produced by the most recent `build` /
  `build-docker` to their registry. MUST be safe to run only after a
  successful `build`.

This keeps the local-only build path clean and gives CI a single,
explicit verb for "now ship the artifact."
