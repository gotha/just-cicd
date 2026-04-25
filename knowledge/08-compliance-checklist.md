# Compliance checklist

A `Justfile` follows this spec when:

- [ ] `just --list` shows `build`, `lint`, `lint-fix`, `test`, `run`,
      `release`, `release-candidate`.
- [ ] `just release --dry-run` and `just release-candidate --dry-run`
      print the planned version without modifying state.
- [ ] `just test` runs the whole suite and exits non-zero on any
      failure.
- [ ] `just release` and `just release-candidate` depend on quality +
      test + build.
- [ ] No recipe hard-requires Nix when running outside the Nix shell.
- [ ] Optional sections (Docker, Compose, DB, CLI helpers) are only
      present when the underlying technology is actually used.
- [ ] Recipe names are language-agnostic (no `cargo-*`, `go-*`,
      `npm-*`, `pytest-*`).
- [ ] Destructive recipes (`clean`, `*-clean`, `down -v`) are clearly
      labelled in their recipe comments.
- [ ] Any recipe that asks for interactive confirmation is pipeable
      (`echo y | just release`) and the expected answer is documented
      in the recipe comment.
- [ ] `build` produces the artifact but does NOT publish or push.
- [ ] If the project has a CI pipeline, a `ci` recipe exists that
      mirrors what CI runs on every PR.

## How to use this checklist

When **authoring** a `Justfile`, treat the unchecked boxes as a
backlog: each item that doesn't apply (e.g. no Docker, no migrations)
should be explicitly justified, not silently omitted.

When **reviewing** a `Justfile`, walk the checklist top to bottom. The
first three items are the highest-value gates — if they fail, the
project does not have a usable SDLC contract.

When **adopting** the spec on an existing project, focus on the
required items first (`build`, `lint`, `lint-fix`, `test`, `run`,
`release`, `release-candidate`) and add the recommended/optional
sections later.
