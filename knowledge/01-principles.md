# Principles

The aim of this spec: anyone who clones a repository following it can run
`just --list` and immediately know how to **build**, **lint**, **test**,
**run**, and **release** the project, regardless of language, packaging
system, or deployment target.

`just` (https://github.com/casey/just) is the only hard requirement.

## Scope and assumptions

- **Language**: any (Go, Python, JavaScript/TypeScript, Rust, Java, …).
  Recipes call into the language's native toolchain
  (`go build`, `npm run build`, `cargo build`, `uv sync`, `mvn package`, …)
  but their **names and contracts** are uniform across projects.
- **Containerization** (Docker / Compose): optional. If used, dedicated
  recipes are added; if absent, those recipes are simply omitted.
- **Nix**: optional. If a flake is present, recipes MAY prefer the Nix
  toolchain but MUST still work outside of `nix develop` provided the
  required tools are on `PATH`.
- **Operating system**: assumed POSIX-like; Windows users run via WSL or
  Git Bash.

## Principles

1. **SDLC-first.** Every project MUST expose `build`, `lint`, `test`,
   `run`, and a `release` family. These are the contract.
2. **One purpose per recipe.** Composite recipes are composed of named
   single-purpose recipes (e.g. `quality: format lint typecheck`).
3. **Recipe names are language-agnostic.** Use `test`, not `pytest`;
   `build`, not `cargo-build`; `run`, not `uvicorn`.
4. **`test` validates the code.** A single `just test` invocation runs
   every test the project has and exits non-zero if any of them fail.
5. **Optional features are opt-in.** Docker, Compose, Nix, and
   migrations live in clearly-prefixed sections; the core SDLC recipes
   work without them.
6. **Side effects are explicit.** Long-running processes, daemons, and
   destructive cleanups have their own named recipes (`run`, `stop`,
   `clean`) — they are never side-effects of a build or a test.
7. **Failures are loud.** Each recipe exits non-zero on failure. CI
   invokes recipes directly without parsing their output.
8. **No hidden state.** A recipe behaves the same way for every
   developer given the same checkout and the same prerequisites on
   `PATH`.
