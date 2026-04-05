#!/bin/bash
#
# Collect raw project evidence into agent-docs/evidence/.
#
# Usage:
#   ./import-agent-history.sh [project-dir]
#   ./import-agent-history.sh .
#   ./import-agent-history.sh /path/to/project
#
# Outputs (all under agent-docs/evidence/):
#   git-log.txt          last 300 commit messages (oneline)
#   git-log-detail.txt   last 50 commits with body
#   doc-index.txt        all markdown file paths
#   manifests.txt        package/dependency manifests
#   structure.txt        directory tree (depth 3, filtered)
#   existing-docs.txt    content of key doc files (CLAUDE.md, README, AGENTS.md)
#   tasks.txt            content of tasks/ dir if present
#   sessions.txt         session file listing (no content — sessions are ephemeral)
#
# Evidence is RAW — the agent reads it and distills stable facts into memory.
# Never edit evidence files. Re-run this script to refresh.
#

set -euo pipefail

TARGET_PROJECT="${1:-.}"
TARGET_PROJECT="$(cd "$TARGET_PROJECT" && pwd)"
EVIDENCE_DIR="$TARGET_PROJECT/agent-docs/evidence"
DATE="$(date +%Y-%m-%d)"
PROJECT="$(basename "$TARGET_PROJECT")"

mkdir -p "$EVIDENCE_DIR"

header() {
    echo "# Evidence: $1"
    echo "# Extracted: $DATE"
    echo "# Project: $PROJECT"
    echo ""
}

echo "Collecting evidence: $PROJECT"
echo ""

# ---------------------------------------------------------------------------
# Git history
# ---------------------------------------------------------------------------
if git -C "$TARGET_PROJECT" rev-parse --git-dir > /dev/null 2>&1; then
    {
        header "git-log (oneline, last 300)"
        git -C "$TARGET_PROJECT" log --oneline -300
    } > "$EVIDENCE_DIR/git-log.txt"
    echo "  git-log.txt"

    {
        header "git-log-detail (last 50, with body)"
        git -C "$TARGET_PROJECT" log -50 --pretty=format:"----%ncommit %h%nDate:   %ai%nAuthor: %an%n%n%s%n%b"
    } > "$EVIDENCE_DIR/git-log-detail.txt"
    echo "  git-log-detail.txt"

    # Extract unique authors
    {
        header "git-authors"
        git -C "$TARGET_PROJECT" log --pretty=format:"%an <%ae>" | sort -u
    } > "$EVIDENCE_DIR/git-authors.txt"
    echo "  git-authors.txt"
else
    echo "  (skipped git — not a git repo)"
fi

# ---------------------------------------------------------------------------
# Directory structure
# ---------------------------------------------------------------------------
{
    header "structure (depth 3)"
    find "$TARGET_PROJECT" \
        -maxdepth 3 \
        -not -path "*/.git/*" \
        -not -path "*/node_modules/*" \
        -not -path "*/vendor/*" \
        -not -path "*/__pycache__/*" \
        -not -path "*/.venv/*" \
        -not -path "*/dist/*" \
        -not -path "*/.next/*" \
        -not -path "*/build/*" \
        | sort | sed "s|$TARGET_PROJECT/||" | sed "s|^$TARGET_PROJECT$|.|"
} > "$EVIDENCE_DIR/structure.txt"
echo "  structure.txt"

# ---------------------------------------------------------------------------
# Package manifests
# ---------------------------------------------------------------------------
{
    header "manifests"
    MANIFESTS="package.json pyproject.toml Cargo.toml go.mod go.sum build.gradle \
                setup.py setup.cfg requirements.txt CMakeLists.txt Makefile \
                pnpm-workspace.yaml nx.json turbo.json"
    found=0
    for f in $MANIFESTS; do
        if [ -f "$TARGET_PROJECT/$f" ]; then
            echo "=== $f ==="
            # Truncate large files (e.g. go.sum, package-lock)
            if [ "$(wc -l < "$TARGET_PROJECT/$f")" -gt 200 ]; then
                head -60 "$TARGET_PROJECT/$f"
                echo "... (truncated at 60 lines)"
            else
                cat "$TARGET_PROJECT/$f"
            fi
            echo ""
            found=1
        fi
    done
    [ "$found" -eq 0 ] && echo "(no manifests found)"
} > "$EVIDENCE_DIR/manifests.txt"
echo "  manifests.txt"

# ---------------------------------------------------------------------------
# Key doc files (README, CLAUDE.md, AGENTS.md, agent-docs/)
# ---------------------------------------------------------------------------
{
    header "existing-docs"
    DOC_FILES="README.md README.rst CLAUDE.md AGENTS.md .cursorrules \
               agent-docs/memory/MEMORY.md docs/README.md"
    found=0
    for f in $DOC_FILES; do
        fp="$TARGET_PROJECT/$f"
        if [ -f "$fp" ]; then
            echo "=== $f ==="
            if [ "$(wc -l < "$fp")" -gt 300 ]; then
                head -100 "$fp"
                echo "... (truncated at 100 lines)"
            else
                cat "$fp"
            fi
            echo ""
            found=1
        fi
    done
    [ "$found" -eq 0 ] && echo "(no key doc files found)"
} > "$EVIDENCE_DIR/existing-docs.txt"
echo "  existing-docs.txt"

# ---------------------------------------------------------------------------
# Markdown doc index (paths only — too many to include content)
# ---------------------------------------------------------------------------
{
    header "doc-index (paths)"
    find "$TARGET_PROJECT" \
        -name "*.md" \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -not -path "*/vendor/*" \
        | sort | sed "s|$TARGET_PROJECT/||"
} > "$EVIDENCE_DIR/doc-index.txt"
echo "  doc-index.txt"

# ---------------------------------------------------------------------------
# Tasks directory (todo.md, lessons.md)
# ---------------------------------------------------------------------------
{
    header "tasks"
    TASK_FILES="tasks/todo.md tasks/lessons.md tasks/plan.md"
    found=0
    for f in $TASK_FILES; do
        fp="$TARGET_PROJECT/$f"
        if [ -f "$fp" ]; then
            echo "=== $f ==="
            cat "$fp"
            echo ""
            found=1
        fi
    done
    # Also list any other files in tasks/
    if [ -d "$TARGET_PROJECT/tasks" ]; then
        echo "=== tasks/ contents ==="
        ls "$TARGET_PROJECT/tasks/"
        found=1
    fi
    [ "$found" -eq 0 ] && echo "(no tasks/ directory found)"
} > "$EVIDENCE_DIR/tasks.txt"
echo "  tasks.txt"

# ---------------------------------------------------------------------------
# Session files (listing only — content is ephemeral)
# ---------------------------------------------------------------------------
{
    header "sessions (listing only — content is ephemeral)"
    # Cursor sessions
    CURSOR_SESSIONS_GLOB="$HOME/.cursor/projects/*/sessions"
    FOUND_SESSIONS=""
    for d in $CURSOR_SESSIONS_GLOB; do
        if [ -d "$d" ]; then
            # Heuristic: match project name in path
            if echo "$d" | grep -qi "$PROJECT" 2>/dev/null; then
                echo "=== $d ==="
                ls -lt "$d" 2>/dev/null | head -10
                FOUND_SESSIONS="yes"
            fi
        fi
    done
    [ -z "$FOUND_SESSIONS" ] && echo "(no matching Cursor session dirs found)"
} > "$EVIDENCE_DIR/sessions.txt"
echo "  sessions.txt"

# ---------------------------------------------------------------------------
# CI/workflow config (keys to understanding the build)
# ---------------------------------------------------------------------------
{
    header "ci-workflows"
    if [ -d "$TARGET_PROJECT/.github/workflows" ]; then
        for f in "$TARGET_PROJECT/.github/workflows"/*.yml "$TARGET_PROJECT/.github/workflows"/*.yaml; do
            [ -f "$f" ] || continue
            echo "=== .github/workflows/$(basename "$f") ==="
            if [ "$(wc -l < "$f")" -gt 150 ]; then
                head -60 "$f"
                echo "... (truncated)"
            else
                cat "$f"
            fi
            echo ""
        done
    else
        echo "(no .github/workflows found)"
    fi
} > "$EVIDENCE_DIR/ci-workflows.txt"
echo "  ci-workflows.txt"

echo ""
echo "Evidence collected in: agent-docs/evidence/"
echo "Re-run this script to refresh. Evidence files are overwritten on each run."
echo ""
echo "Next step: ask the agent to read history-backfill skill"
echo "and distill stable facts from evidence into agent-docs/memory/"
