# just-cicd

An agent skill for designing language-agnostic `Justfile`s and the CI/CD
pipelines that drive them.

## Overview

This skill provides AI agent capabilities for:

- **Authoring `Justfile`s** that follow a uniform SDLC contract
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
