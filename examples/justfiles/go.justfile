# Reference Justfile for a Go project.
# Adapt the language-native commands; keep recipe names and contracts
# unchanged.

project_name := "myapp"
docker_tag   := "local/" + project_name + ":latest"
binary       := "./bin/" + project_name

# List all recipes.
default:
    @just --list

# Install/sync all development dependencies. Idempotent.
setup:
    go mod download
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Apply formatting (no lint fixes).
format:
    gofmt -s -w .

# Apply auto-fixes and formatting.
lint-fix:
    gofmt -s -w .
    golangci-lint run --fix ./...

# Static checks only — no auto-fixes. Suitable for CI.
lint:
    test -z "$(gofmt -s -l .)"
    golangci-lint run ./...

# Static type analysis.
typecheck:
    go vet ./...

# Run every code-quality check: format, lint, typecheck, staticcheck.
quality: format lint typecheck
    go install honnef.co/go/tools/cmd/staticcheck@latest
    staticcheck ./...

# Run the entire test suite. Exits non-zero on any failure.
test:
    go test ./...

# Produce a coverage report.
test-coverage:
    go test -coverprofile=coverage.out ./...
    go tool cover -html=coverage.out -o coverage.html

# Halt at first failure.
test-stop:
    go test -failfast ./...

# Build the project binary.
build:
    mkdir -p bin
    go build -o {{binary}} ./cmd/{{project_name}}

# Build the container image with a stable local tag.
build-docker:
    docker build -t {{docker_tag}} .

# Start the project locally.
run: build
    {{binary}}

# Cut a stable release. Pass --dry-run to preview; pipe `y` to skip the interactive confirmation.
release *args: quality test build
    ./scripts/release.sh release {{args}}

# Cut a release candidate. Pass --dry-run to preview without tagging.
release-candidate *args: quality test build
    ./scripts/release.sh release-candidate {{args}}

# Push the container image to its registry.
publish: build-docker
    docker push {{docker_tag}}

# Remove build artifacts. DESTRUCTIVE.
clean:
    rm -rf bin/ coverage.out coverage.html
