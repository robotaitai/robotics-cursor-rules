#!/bin/bash
#
# Bootstrap a project memory tree under agent-docs/memory/.
#
# Usage:
#   ./bootstrap-memory-tree.sh [project-dir] [profile]
#   ./bootstrap-memory-tree.sh .                 # auto-detect profile
#   ./bootstrap-memory-tree.sh /path/to/project web-app
#
# Profiles: web-app | robotics | ml-platform | hybrid
#
# What it does:
#   1. Detects project type (or uses the provided profile)
#   2. Reads areas from templates/memory/profile.<type>.yaml
#   3. Creates agent-docs/memory/MEMORY.md from root template
#   4. Creates one area stub per profile area
#   5. Creates agent-docs/evidence/ placeholder
#   6. Creates decisions/INDEX.md
#
# What it does NOT do:
#   - Populate memory with real content (that is the agent's job)
#   - Overwrite an existing MEMORY.md (run with --force to override)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_RULES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$AGENTS_RULES_DIR/templates/memory"

TARGET_PROJECT="${1:-.}"
PROFILE="${2:-}"
FORCE="${FORCE:-}"

TARGET_PROJECT="$(cd "$TARGET_PROJECT" && pwd)"
MEMORY_DIR="$TARGET_PROJECT/agent-docs/memory"
EVIDENCE_DIR="$TARGET_PROJECT/agent-docs/evidence"
DATE="$(date +%Y-%m-%d)"

# ---------------------------------------------------------------------------
# Profile detection
# ---------------------------------------------------------------------------
detect_profile() {
    local dir="$1"

    # Web app: frontend framework in package.json
    if [ -f "$dir/package.json" ] && \
       grep -qE '"react"|"next"|"vue"|"svelte"|"angular"|"nuxt"' "$dir/package.json" 2>/dev/null; then
        echo "web-app"; return
    fi

    # Robotics: ROS package.xml or CMakeLists.txt with ros
    if find "$dir" -maxdepth 3 -name "package.xml" 2>/dev/null | grep -q .; then
        echo "robotics"; return
    fi
    if [ -f "$dir/CMakeLists.txt" ] && grep -qi "ros\|catkin\|ament" "$dir/CMakeLists.txt" 2>/dev/null; then
        echo "robotics"; return
    fi

    # ML platform: Python project with ML directories or ML libs
    if [ -f "$dir/pyproject.toml" ] || [ -f "$dir/requirements.txt" ]; then
        if [ -d "$dir/notebooks" ] || [ -d "$dir/models" ] || [ -d "$dir/data" ] || \
           grep -qE 'torch|tensorflow|jax|sklearn|transformers|ray' \
             "$dir/requirements.txt" "$dir/pyproject.toml" 2>/dev/null; then
            echo "ml-platform"; return
        fi
    fi

    # Hybrid: monorepo signals
    if [ -f "$dir/pnpm-workspace.yaml" ] || [ -f "$dir/nx.json" ] || \
       [ -f "$dir/turbo.json" ] || \
       ( [ -f "$dir/package.json" ] && grep -q '"workspaces"' "$dir/package.json" 2>/dev/null ) || \
       [ -d "$dir/packages" ] || [ -d "$dir/services" ] || [ -d "$dir/apps" ]; then
        echo "hybrid"; return
    fi

    echo "hybrid"
}

# ---------------------------------------------------------------------------
# Parse areas from profile YAML
# Parse line: areas: [stack, architecture, conventions, gotchas, ...]
# ---------------------------------------------------------------------------
parse_areas() {
    local profile_file="$1"
    grep "^areas:" "$profile_file" \
        | sed 's/^areas: *\[//;s/\].*//' \
        | tr ',' '\n' \
        | tr -d ' \t'
}

# ---------------------------------------------------------------------------
# Resolve profile
# ---------------------------------------------------------------------------
if [ -z "$PROFILE" ]; then
    PROFILE="$(detect_profile "$TARGET_PROJECT")"
    echo "Auto-detected profile: $PROFILE"
fi

PROFILE_FILE="$TEMPLATES_DIR/profile.$PROFILE.yaml"
if [ ! -f "$PROFILE_FILE" ]; then
    echo "Unknown profile: $PROFILE"
    echo "Available: web-app, robotics, ml-platform, hybrid"
    exit 1
fi

# ---------------------------------------------------------------------------
# Guard: skip if already bootstrapped (unless forced)
# ---------------------------------------------------------------------------
if [ -f "$MEMORY_DIR/MEMORY.md" ] && [ -s "$MEMORY_DIR/MEMORY.md" ] && [ -z "$FORCE" ]; then
    echo "Memory tree already exists at $MEMORY_DIR/MEMORY.md"
    echo "To re-bootstrap, delete MEMORY.md or set FORCE=1."
    echo "To reorganize, run: scripts/compact-memory.sh $TARGET_PROJECT"
    exit 0
fi

PROJECT_NAME="$(basename "$TARGET_PROJECT")"
echo "Bootstrapping memory tree: $PROJECT_NAME ($PROFILE)"
echo ""

mkdir -p "$MEMORY_DIR/decisions"
mkdir -p "$EVIDENCE_DIR"

# ---------------------------------------------------------------------------
# Root MEMORY.md
# ---------------------------------------------------------------------------
ROOT_SRC="$TEMPLATES_DIR/MEMORY.root.template.md"
ROOT_DST="$MEMORY_DIR/MEMORY.md"

sed \
    -e "s/<project-name>/$PROJECT_NAME/g" \
    -e "s/<profile-type>/$PROFILE/g" \
    -e "s/<date>/$DATE/g" \
    "$ROOT_SRC" > "$ROOT_DST"

echo "  created: agent-docs/memory/MEMORY.md"

# ---------------------------------------------------------------------------
# Area stubs — derived from profile
# ---------------------------------------------------------------------------
AREA_SRC="$TEMPLATES_DIR/area.template.md"
AREAS="$(parse_areas "$PROFILE_FILE")"

# Capitalize first letter of a word (portable - no GNU sed needed)
capitalize_first() {
    echo "$1" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}' FS=- OFS=' '
}

for area in $AREAS; do
    dst="$MEMORY_DIR/$area.md"
    if [ ! -f "$dst" ] || [ -n "$FORCE" ]; then
        display="$(capitalize_first "$area")"
        sed "s/<Area Name>/$display/g" "$AREA_SRC" > "$dst"
        echo "  created: agent-docs/memory/$area.md"
    else
        echo "  exists:  agent-docs/memory/$area.md (skipped)"
    fi
done

# Rebuild MEMORY.md from profile areas (replace static template placeholders)
{
    # Keep header comment block (lines before first ##)
    head_line=$(grep -n "^## " "$ROOT_DST" | head -1 | cut -d: -f1)
    if [ -n "$head_line" ]; then
        head -n "$((head_line - 1))" "$ROOT_DST"
    fi

    for area in $AREAS; do
        display="$(capitalize_first "$area")"
        hint=""
        if grep -q "^  $area:" "$PROFILE_FILE" 2>/dev/null; then
            # Strip leading spaces, key, colon, optional space, and surrounding quotes
            hint="$(grep "^  $area:" "$PROFILE_FILE" \
                    | sed 's/^  [^:]*: *//' \
                    | sed 's/^"//;s/"$//')"
        fi
        echo "## $display"
        [ -n "$hint" ] && echo "$hint"
        echo "→ [$area.md]($area.md)"
        echo ""
    done

    echo "## Decisions"
    echo "Architecture and design choices with rationale."
    echo "→ [decisions/INDEX.md](decisions/INDEX.md)"
    echo ""
    echo "<!-- Add area entries as the project grows. Remove areas that stay empty. -->"
} > "$ROOT_DST.new"
mv "$ROOT_DST.new" "$ROOT_DST"

# ---------------------------------------------------------------------------
# decisions/INDEX.md
# ---------------------------------------------------------------------------
DECISIONS_INDEX="$MEMORY_DIR/decisions/INDEX.md"
if [ ! -f "$DECISIONS_INDEX" ]; then
    cat > "$DECISIONS_INDEX" << 'DECISIONS_EOF'
# Decisions Index

<!-- One entry per decision file. Newest first. -->
<!-- Format: - [YYYY-MM-DD-slug.md](YYYY-MM-DD-slug.md) — one-line summary -->

<!-- No decisions recorded yet. -->
DECISIONS_EOF
    echo "  created: agent-docs/memory/decisions/INDEX.md"
fi

echo ""
echo "Memory tree bootstrapped for: $PROJECT_NAME"
echo ""
echo "Next steps:"
echo "  1. Collect evidence:  scripts/import-agent-history.sh $TARGET_PROJECT"
echo "  2. Populate memory:   ask the agent to read project-ontology-bootstrap skill"
echo "  3. Cursor symlink (if needed):"
echo "     ln -sf $MEMORY_DIR ~/.cursor/projects/<project-id>/memory"
