# just-cicd

An agent skill for designing language-agnostic `Justfile`s and the CI/CD
pipelines that drive them.

## Philosophy

The development lifecycle of every project — building, linting,
testing, running locally, releasing — is centred on a single
`Justfile` of locally runnable recipes. The same recipes a developer
uses on their laptop are the recipes any CI/CD system invokes. There
is one source of truth for "what running this project means", and it
lives in version control next to the code.

This is a deliberate replacement for the patchwork of language- and
ecosystem-specific task runners that typically grow around a project:

- `npm`/`pnpm`/`yarn` `scripts` blocks in `package.json`
- `Makefile`s (with their tab-vs-space and recursive-make pitfalls)
- `tox`, `nox`, `invoke`, `poethepoet` for Python
- `rake`, `mix`, `gradle` task aliases, `mage`, `task`, `dagger`, etc.
- Per-team `bin/` scripts and ad-hoc `bash` wrappers
- CI-only scripts that drift from local development

These all solve the same problem (give the project a uniform set of
verbs) but each does so with a different syntax, a different
dependency model, and a different blast radius across a polyglot
estate. In an organisation with multiple services in multiple
languages, that means every microservice is a small puzzle: which
runner does it use, what are the conventions, what does "test" even
mean here?

`just` collapses that into one tool. This skill goes one step further
and standardises the **shape** of the `Justfile` itself — the names,
contracts, and dependency graph of the recipes — so that every
project, regardless of language, exposes the same vocabulary:

```
just setup       just lint        just test        just release
just build       just lint-fix    just run         just release-candidate
                 just typecheck   just ci          just release --dry-run
```

A developer (or an AI agent) moving between a Python service, a Go
service, and a Node.js front-end finds the same verbs doing the same
things. The internals differ; the interface does not.

### How CI/CD fits in

Because every meaningful action is already a recipe, CI/CD pipelines
become thin orchestrators. The pipeline YAML handles plumbing only —
checkout, toolchain install, caching, secrets — and every step that
matters is `just <recipe>`. This yields three concrete properties:

1. **Local/CI parity.** Any failure in CI can be reproduced locally
   by running the same `just` command. There is no
   "works-on-my-machine, fails-in-CI" surface area inside the recipe.
2. **Provider portability.** Switching from one CI/CD provider to
   another (GitHub Actions, GitLab CI, CircleCI, Jenkins, Buildkite,
   …) is a YAML translation exercise. The recipe calls do not
   change.
3. **Uniformity across a portfolio.** Every microservice's pipeline
   looks the same at the YAML level because every microservice's
   `Justfile` looks the same at the recipe level. New services
   inherit a working pipeline by conforming to the spec.

## Overview

This skill provides AI agent capabilities for:

- **Authoring `Justfile`s** that follow the uniform SDLC contract
  (`build`, `lint`, `test`, `run`, `release`) regardless of language.
- **Reviewing `Justfile`s** against a compliance checklist.
- **Wiring CI/CD pipelines** where the pipeline YAML is a thin
  orchestrator around `just` recipes — same commands locally and in CI.

The skill content is grounded in a single, opinionated specification.
See `SKILL.md` for the entry point and `knowledge/` for the full spec.

## Installation

### Using `npx skills` (recommended)

```bash
npx skills add gotha/just-cicd
```

### Using a git submodule

```bash
git submodule add https://github.com/gotha/just-cicd.git .skills/just-cicd
git submodule update --init --recursive
```

Then point your AI assistant at `.skills/just-cicd`.

### Manual clone

```bash
git clone https://github.com/gotha/just-cicd.git ~/.agents/skills/just-cicd
```

## Updating

```bash
# via npx skills
npx skills update gotha/just-cicd

# via git submodule
git submodule update --remote .skills/just-cicd
git add .skills/just-cicd && git commit -m "Update just-cicd skill"
```

## Project structure

```
just-cicd/
├── SKILL.md              # Skill entry point (frontmatter + overview)
├── README.md             # This file
├── prompts/
│   └── system.md         # System-prompt fragment with compliance rules
├── knowledge/            # Markdown reference docs the agent loads on demand
│   ├── 01-principles.md
│   ├── 02-required-recipes.md
│   ├── 03-recommended-recipes.md
│   ├── 04-optional-sections.md
│   ├── 05-conventions.md
│   ├── 06-dependency-graph.md
│   ├── 07-cicd-integration.md
│   └── 08-compliance-checklist.md
├── examples/
│   └── justfiles/        # Reference Justfiles per language
└── flake.nix             # Optional Nix dev shell for working on the skill
```

## Development

```bash
# Enter the dev shell (optional, only if you want a pinned `just` toolchain)
nix develop

# Validate the example Justfiles
for f in examples/justfiles/*.justfile; do
  just --justfile "$f" --list >/dev/null
done
```

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/my-change`.
3. Make your changes (keep the spec language-agnostic).
4. If you change a recipe contract, update the matching example
   `Justfile`s and the compliance checklist.
5. Open a pull request.

### Adding knowledge

Add focused markdown files to `knowledge/`. Keep each file under ~150
lines and topical — the agent loads them on demand based on the section
of the spec it is reasoning about.

### Adding examples

Add language-specific reference `Justfile`s to `examples/justfiles/`.
New examples MUST satisfy the compliance checklist in
`knowledge/08-compliance-checklist.md`.

## License

MIT
