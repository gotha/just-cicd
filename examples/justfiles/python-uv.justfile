# Reference Justfile for a Python project using `uv`.
# Adapt the language-native commands; keep recipe names and contracts
# unchanged.

project_name := "myapp"
docker_tag   := "local/" + project_name + ":latest"

# List all recipes.
default:
    @just --list

# Install all development dependencies. Idempotent.
setup:
    uv sync --all-extras

# Apply formatting (no lint fixes).
format:
    uv run ruff format src/ tests/

# Apply auto-fixes and formatting.
lint-fix:
    uv run ruff format src/ tests/
    uv run ruff check --fix src/ tests/

# Static checks only — no auto-fixes. Suitable for CI.
lint:
    uv run ruff format --check src/ tests/
    uv run ruff check src/ tests/

# Static type analysis.
typecheck:
    uv run mypy src/

# Run every code-quality check: format, lint, typecheck, dead-code detection.
quality: format lint typecheck
    uv run vulture src/ --min-confidence 80

# Run the entire test suite. Exits non-zero on any failure.
test:
    uv run pytest

# Re-run the suite on file change.
test-watch:
    uv run ptw -- tests/

# Produce a coverage report.
test-coverage:
    uv run pytest --cov=src --cov-report=term-missing --cov-report=html

# Halt at first failure.
test-stop:
    uv run pytest -x

# Build the Python wheel.
build:
    uv build

# Build the container image with a stable local tag.
build-docker:
    docker build -t {{docker_tag}} .

# Start the project locally with hot-reload.
run:
    uv run uvicorn src.main:app --reload --host 127.0.0.1 --port 8000

# Cut a stable release. Pass --dry-run to preview; pipe `y` to skip the interactive confirmation.
release *args: quality test build
    ./scripts/release.sh release {{args}}

# Cut a release candidate. Pass --dry-run to preview without tagging.
release-candidate *args: quality test build
    ./scripts/release.sh release-candidate {{args}}

# Push the most recently built artifacts to their registry.
publish:
    uv publish

# Apply pending database migrations.
db-migrate:
    uv run alembic upgrade head

# Undo the last migration.
db-migrate-rollback:
    uv run alembic downgrade -1

# Show the current revision.
db-migrate-status:
    uv run alembic current

# Show all revisions.
db-migrate-history:
    uv run alembic history

# Scaffold a new migration.
create-db-migration name:
    uv run alembic revision --autogenerate -m "{{name}}"

# Remove build artifacts and caches. DESTRUCTIVE.
clean:
    rm -rf dist/ build/ .pytest_cache/ .ruff_cache/ .mypy_cache/ htmlcov/
    find . -name __pycache__ -type d -exec rm -rf {} +
