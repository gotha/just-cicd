---
name: just-cicd
description: Agent skill for designing language-agnostic Justfiles and the CI/CD pipelines that drive them. Use when working with `Justfile` / `just` command runners, when standardizing build/lint/test/release commands across a project, when authoring or reviewing a Justfile, or when wiring a CI/CD pipeline (GitHub Actions, GitLab CI, CircleCI, Drone, Jenkins) on top of `just` recipes.
---

# just-cicd

Agent skill for the [`just`](https://github.com/casey/just) command runner.
Provides:

- A language-agnostic specification for what every project's `Justfile`
  should expose (`build`, `lint`, `lint-fix`, `test`, `run`, `release`,
  `release-candidate`).
- Conventions for optional sections (Nix, Docker, Docker Compose,
  database migrations, project CLI helpers).
- Patterns for using a spec-conformant `Justfile` as the backbone of a
  CI/CD pipeline so that local commands and pipeline steps are identical.

## When to use this skill

Activate this skill when the user:

- Mentions `just`, `Justfile`, or `justfile` in any context.
- Asks how to standardize build/test/release commands across projects.
- Is authoring a new `Justfile` or reviewing an existing one.
- Is designing a CI/CD pipeline and wants the pipeline YAML to call into
  the project's local task runner instead of duplicating commands.
- Asks how to structure release automation, version bumping, or
  pre-release / dry-run workflows.
- Wants language-agnostic recipe naming conventions.

## Knowledge map

| Topic | File |
|---|---|
| Scope, assumptions, principles | `knowledge/01-principles.md` |
| Required recipes (the contract) | `knowledge/02-required-recipes.md` |
| Recommended recipes (`setup`, `format`, `typecheck`, quality, test variants) | `knowledge/03-recommended-recipes.md` |
| Optional sections (Nix, Docker, Compose, DB, CLI helpers) | `knowledge/04-optional-sections.md` |
| Naming, composition, variables, comments | `knowledge/05-conventions.md` |
| Required dependency graph + common workflows | `knowledge/06-dependency-graph.md` |
| Wiring a Justfile into CI/CD | `knowledge/07-cicd-integration.md` |
| Compliance checklist | `knowledge/08-compliance-checklist.md` |

## Examples

| Path | Purpose |
|---|---|
| `examples/justfiles/python-uv.justfile` | Reference Justfile for a Python project using `uv` |
| `examples/justfiles/go.justfile` | Reference Justfile for a Go project |
| `examples/justfiles/nodejs-pnpm.justfile` | Reference Justfile for a Node.js project using `pnpm` |

## Core contract (the one-paragraph version)

Every `Justfile` following this spec exposes the same SDLC verbs:
`build`, `lint`, `lint-fix`, `test`, `run`, `release`,
`release-candidate`. Recipe names are language-agnostic. Each recipe
exits non-zero on failure. `release` and `release-candidate` MUST depend
(in order) on quality checks, `test`, and `build`, and MUST accept a
`--dry-run` flag that previews the next version without modifying state.
Optional sections (Docker, Nix, DB migrations) are only present when the
underlying technology is actually used.

## How to use this skill

1. **Authoring a new Justfile.** Read `knowledge/01-principles.md` and
   `knowledge/02-required-recipes.md` first; pick the closest example
   from `examples/justfiles/`; copy it; adapt the language-native
   commands while keeping the recipe names and contracts unchanged.

2. **Reviewing an existing Justfile.** Run through
   `knowledge/08-compliance-checklist.md`. Flag deviations and propose
   spec-conformant replacements.

3. **Designing a CI/CD pipeline.** Read
   `knowledge/07-cicd-integration.md`. The pipeline YAML is a thin
   orchestrator that calls `just <recipe>`; logic lives in the
   `Justfile`, not in the YAML. Translate the recipe calls and the
   trigger contract to whichever CI provider the project uses.

4. **Adding optional sections.** Only when the underlying technology is
   actually used. See `knowledge/04-optional-sections.md` for the
   prefix-naming convention (`docker-compose-*`, `db-*`, `cli-*`,
   `logs-*`).

## Non-negotiable rules

These are enforced by `prompts/system.md` and apply whenever the agent
authors or reviews a `Justfile`:

- Each recipe exits non-zero on failure.
- `release` and `release-candidate` MUST depend on quality + test + build.
- Both MUST accept `--dry-run`.
- No recipe hard-requires Nix when running outside `nix develop`.
- Recipe names are language-agnostic (`build`, not `cargo-build`).
- Destructive recipes (`clean`, `*-clean`, compose `down -v`) are
  clearly labelled in their recipe comments.
- A `release` recipe that asks for interactive confirmation MUST be
  pipeable (`echo y | just release`) and the expected answer MUST be
  documented in the recipe comment.
