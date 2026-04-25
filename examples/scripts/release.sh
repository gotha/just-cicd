#!/usr/bin/env bash
#
# Release script following conventional commits specification.
#
# Usage:
#   ./scripts/release.sh preview           # Dry run - show what would be released
#   ./scripts/release.sh release           # Create stable release
#   ./scripts/release.sh release-candidate # Create release candidate
#
set -e

MODE="${1:-preview}"

# =============================================================================
# Helper Functions
# =============================================================================

get_latest_stable_version() {
    git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1
}

parse_version() {
    local version="$1"
    local component="$2"
    local version_without_v="${version#v}"
    
    case "$component" in
        major) echo "$version_without_v" | cut -d. -f1 ;;
        minor) echo "$version_without_v" | cut -d. -f2 ;;
        patch) echo "$version_without_v" | cut -d. -f3 ;;
    esac
}

get_commits_since() {
    local since_tag="$1"
    if [ "$since_tag" = "v0.0.0" ]; then
        git log --oneline --pretty=format:"%s"
    else
        git log "$since_tag"..HEAD --oneline --pretty=format:"%s"
    fi
}

count_commits_by_type() {
    local commits="$1"
    local pattern="$2"
    echo "$commits" | grep -iE "$pattern" | wc -l | tr -d ' '
}

determine_version_bump() {
    local commits="$1"
    
    # Check for breaking changes (major bump)
    if echo "$commits" | grep -qiE '^(major|breaking|BREAKING CHANGE)'; then
        echo "major"
    # Check for features (minor bump)
    elif echo "$commits" | grep -qiE '^feat'; then
        echo "minor"
    # Default is patch
    else
        echo "patch"
    fi
}

calculate_new_version() {
    local major="$1"
    local minor="$2"
    local patch="$3"
    local bump="$4"
    
    case "$bump" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
    esac
    
    echo "v${major}.${minor}.${patch}"
}

get_next_rc_number() {
    local base_version="$1"
    local latest_rc
    latest_rc=$(git tag --sort=-v:refname | grep -E "^${base_version}-rc[0-9]+$" | head -1)
    
    if [ -z "$latest_rc" ]; then
        echo "1"
    else
        local current_rc
        current_rc=$(echo "$latest_rc" | sed 's/.*-rc//')
        echo "$((current_rc + 1))"
    fi
}

print_commit_summary() {
    local commits="$1"
    local commit_count="$2"
    
    local breaking feat fix chore docs refactor other
    breaking=$(count_commits_by_type "$commits" '^(major|breaking|BREAKING CHANGE)')
    feat=$(count_commits_by_type "$commits" '^feat')
    fix=$(count_commits_by_type "$commits" '^(fix|bugfix|bug)')
    chore=$(count_commits_by_type "$commits" '^chore')
    docs=$(count_commits_by_type "$commits" '^docs')
    refactor=$(count_commits_by_type "$commits" '^refactor')
    other=$((commit_count - breaking - feat - fix - chore - docs - refactor))
    
    echo "───────────────────────────────────────────────────────────────"
    [ "$breaking" -gt 0 ] && echo "  🔥 Breaking changes: $breaking"
    [ "$feat" -gt 0 ] && echo "  ✨ Features:         $feat"
    [ "$fix" -gt 0 ] && echo "  🐛 Bug fixes:        $fix"
    [ "$chore" -gt 0 ] && echo "  🔧 Chores:           $chore"
    [ "$docs" -gt 0 ] && echo "  📚 Documentation:    $docs"
    [ "$refactor" -gt 0 ] && echo "  ♻️  Refactoring:     $refactor"
    [ "$other" -gt 0 ] && echo "  📦 Other:            $other"
    echo "───────────────────────────────────────────────────────────────"
}

# =============================================================================
# Main Logic
# =============================================================================

# Get the latest stable version
LATEST_STABLE=$(get_latest_stable_version)
if [ -z "$LATEST_STABLE" ]; then
    LATEST_STABLE="v0.0.0"
fi

# Parse version components
MAJOR=$(parse_version "$LATEST_STABLE" major)
MINOR=$(parse_version "$LATEST_STABLE" minor)
PATCH=$(parse_version "$LATEST_STABLE" patch)

# Get commits since last stable release
COMMITS=$(get_commits_since "$LATEST_STABLE")

if [ -z "$COMMITS" ]; then
    echo "❌ No commits since last release ($LATEST_STABLE). Nothing to release."
    exit 1
fi

COMMIT_COUNT=$(echo "$COMMITS" | wc -l | tr -d ' ')

# Determine version bump
BUMP=$(determine_version_bump "$COMMITS")

# Calculate new version
NEW_STABLE=$(calculate_new_version "$MAJOR" "$MINOR" "$PATCH" "$BUMP")

# Get next RC number
RC_NUM=$(get_next_rc_number "$NEW_STABLE")
NEW_RC="${NEW_STABLE}-rc${RC_NUM}"

# =============================================================================
# Mode-specific Logic
# =============================================================================

case "$MODE" in
    preview)
        echo "═══════════════════════════════════════════════════════════════"
        echo "  🔍 Release Preview (dry run)"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "Latest stable release: $LATEST_STABLE"
        echo "Commits since last release: $COMMIT_COUNT"
        echo ""
        echo "Commit summary:"
        print_commit_summary "$COMMITS" "$COMMIT_COUNT"
        echo ""
        echo "Version bump: $BUMP"
        echo ""
        echo "Next versions:"
        echo "  • Release candidate: $NEW_RC"
        echo "  • Stable release:    $NEW_STABLE"
        echo ""
        echo "Run 'just release-candidate' or 'just release' to create."
        echo ""
        ;;

    release)
        echo "═══════════════════════════════════════════════════════════════"
        echo "  📦 Creating new release..."
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "Latest stable release: $LATEST_STABLE"
        echo "Commits since last release: $COMMIT_COUNT"
        echo ""
        echo "Commits since $LATEST_STABLE:"
        echo "$COMMITS" | head -20
        echo ""
        echo "Version bump: $BUMP"
        echo "New version: $NEW_STABLE"
        echo ""

        read -p "Create release $NEW_STABLE? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Release cancelled."
            exit 1
        fi

        # Tag Docker image with release version
        echo "Tagging Docker image..."
        docker tag local/dissona:latest "local/dissona:$NEW_STABLE"
        echo "  ✓ Tagged local/dissona:$NEW_STABLE"

        # Create and push git tag
        echo "Creating git tag $NEW_STABLE..."
        git tag -a "$NEW_STABLE" -m "Release $NEW_STABLE"
        git push origin "$NEW_STABLE"

        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "  ✅ Release $NEW_STABLE created successfully!"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "  Git tag: $NEW_STABLE (pushed to origin)"
        echo "  Docker:  local/dissona:$NEW_STABLE"
        echo ""
        ;;

    release-candidate)
        echo "═══════════════════════════════════════════════════════════════"
        echo "  📦 Creating new release candidate..."
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "Latest stable release: $LATEST_STABLE"
        echo "Commits since last release: $COMMIT_COUNT"
        echo ""
        echo "Commits since $LATEST_STABLE:"
        echo "$COMMITS" | head -20
        echo ""
        echo "Version bump: $BUMP"
        echo "Target version: $NEW_STABLE"
        echo "RC version: $NEW_RC"
        echo ""

        read -p "Create release candidate $NEW_RC? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Release candidate cancelled."
            exit 1
        fi

        # Tag Docker image with RC version
        echo "Tagging Docker image..."
        docker tag local/dissona:latest "local/dissona:$NEW_RC"
        echo "  ✓ Tagged local/dissona:$NEW_RC"

        # Create and push git tag
        echo "Creating git tag $NEW_RC..."
        git tag -a "$NEW_RC" -m "Release candidate $NEW_RC"
        git push origin "$NEW_RC"

        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "  ✅ Release candidate $NEW_RC created successfully!"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "  Git tag: $NEW_RC (pushed to origin)"
        echo "  Docker:  local/dissona:$NEW_RC"
        echo ""
        echo "  To promote to stable release, run: just release"
        echo ""
        ;;

    *)
        echo "Usage: $0 {preview|release|release-candidate}"
        exit 1
        ;;
esac
