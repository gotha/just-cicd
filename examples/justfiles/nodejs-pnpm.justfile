# Reference Justfile for a Node.js / TypeScript project using `pnpm`.
# Adapt the language-native commands; keep recipe names and contracts
# unchanged.

project_name := "myapp"
docker_tag   := "local/" + project_name + ":latest"

# List all recipes.
default:
    @just --list

# Install all development dependencies. Idempotent.
setup:
    pnpm install --frozen-lockfile

# Apply formatting (no lint fixes).
format:
    pnpm exec prettier --write "src/**/*.{ts,tsx,js,jsx,json,md}"

# Apply auto-fixes and formatting.
lint-fix:
    pnpm exec prettier --write "src/**/*.{ts,tsx,js,jsx,json,md}"
    pnpm exec eslint --fix "src/**/*.{ts,tsx,js,jsx}"

# Static checks only — no auto-fixes. Suitable for CI.
lint:
    pnpm exec prettier --check "src/**/*.{ts,tsx,js,jsx,json,md}"
    pnpm exec eslint "src/**/*.{ts,tsx,js,jsx}"

# Static type analysis.
typecheck:
    pnpm exec tsc --noEmit

# Format + lint + typecheck.
quality: format lint typecheck

# format + lint only (fast).
quality-quick: format lint

# quality + extra static analysis.
quality-full: quality
    pnpm audit --prod

# Run the entire test suite. Exits non-zero on any failure.
test:
    pnpm test

# Re-run the suite on file change.
test-watch:
    pnpm test --watch

# Produce a coverage report.
test-coverage:
    pnpm test --coverage

# Halt at first failure.
test-stop:
    pnpm test --bail

# Build the project bundle.
build:
    pnpm build

# Build the container image with a stable local tag.
build-docker:
    docker build -t {{docker_tag}} .

# Start the project locally with hot-reload.
run:
    pnpm dev

# The same checks CI runs on every PR.
ci: quality-full test build

# Cut a stable release. Pass --dry-run to preview; pipe `y` to skip the interactive confirmation.
release *args: quality-full test build
    ./scripts/release.sh release {{args}}

# Cut a release candidate. Pass --dry-run to preview without tagging.
release-candidate *args: quality-full test build
    ./scripts/release.sh release-candidate {{args}}

# Publish the package to npm.
publish:
    pnpm publish --access public

# Remove build artifacts and caches. DESTRUCTIVE.
clean:
    rm -rf dist/ build/ coverage/ node_modules/.cache/
