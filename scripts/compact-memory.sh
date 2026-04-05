#!/bin/bash
#
# Report memory tree health and flag compaction candidates.
#
# Usage:
#   ./compact-memory.sh [project-dir]
#   ./compact-memory.sh .
#
# Output: line counts, health flags, and a recommended action for each file.
#
# This script ONLY reports — it does not edit files.
# Actual compaction is done by the agent following the memory-compaction skill.
#

set -euo pipefail

TARGET_PROJECT="${1:-.}"
TARGET_PROJECT="$(cd "$TARGET_PROJECT" && pwd)"
MEMORY_DIR="$TARGET_PROJECT/agent-docs/memory"
EVIDENCE_DIR="$TARGET_PROJECT/agent-docs/evidence"

if [ ! -d "$MEMORY_DIR" ]; then
    echo "No memory tree at: $MEMORY_DIR"
    echo "Run: scripts/bootstrap-memory-tree.sh $TARGET_PROJECT"
    exit 1
fi

WARN=0

check_file() {
    local f="$1"
    local lines
    lines=$(wc -l < "$f" 2>/dev/null || echo 0)
    local rel="${f#$MEMORY_DIR/}"
    local action=""

    if [ "$lines" -gt 200 ]; then
        action="CRITICAL: split immediately"
        WARN=1
    elif [ "$lines" -gt 150 ]; then
        action="WARNING: split candidate"
        WARN=1
    elif [ "$lines" -lt 5 ]; then
        action="note: stub or empty — populate or remove"
    fi

    if [ -n "$action" ]; then
        printf "  %-45s %4d lines  [%s]\n" "$rel" "$lines" "$action"
    else
        printf "  %-45s %4d lines\n" "$rel" "$lines"
    fi
}

# ---------------------------------------------------------------------------
echo "Memory tree: $MEMORY_DIR"
echo ""

# Root
ROOT="$MEMORY_DIR/MEMORY.md"
ROOT_LINES=$(wc -l < "$ROOT" 2>/dev/null || echo 0)
printf "MEMORY.md: %d lines" "$ROOT_LINES"
if [ "$ROOT_LINES" -gt 180 ]; then
    echo "  [CRITICAL: over 180 — compact immediately]"
    WARN=1
elif [ "$ROOT_LINES" -gt 150 ]; then
    echo "  [WARNING: approaching 200-line limit]"
    WARN=1
else
    echo "  [ok]"
fi
echo ""

# Area files
echo "Area files:"
find "$MEMORY_DIR" -maxdepth 1 -name "*.md" -not -name "MEMORY.md" | sort | while read -r f; do
    check_file "$f"
done

# Sub-files
SUB_COUNT=$(find "$MEMORY_DIR" -mindepth 2 -name "*.md" | wc -l | tr -d ' ')
if [ "$SUB_COUNT" -gt 0 ]; then
    echo ""
    echo "Sub-topic files:"
    find "$MEMORY_DIR" -mindepth 2 -name "*.md" | sort | while read -r f; do
        check_file "$f"
    done
fi

# Decisions
DEC_COUNT=$(find "$MEMORY_DIR/decisions" -name "*.md" -not -name "INDEX.md" 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "Decisions: $DEC_COUNT recorded"
if [ "$DEC_COUNT" -gt 0 ]; then
    find "$MEMORY_DIR/decisions" -name "*.md" -not -name "INDEX.md" 2>/dev/null | sort | while read -r f; do
        printf "  %s\n" "$(basename "$f")"
    done
fi

# Evidence
echo ""
echo "Evidence (agent-docs/evidence/):"
if [ -d "$EVIDENCE_DIR" ]; then
    find "$EVIDENCE_DIR" -name "*.txt" 2>/dev/null | sort | while read -r f; do
        lines=$(wc -l < "$f" 2>/dev/null || echo 0)
        rel="${f#$TARGET_PROJECT/}"
        printf "  %-45s %4d lines\n" "$rel" "$lines"
    done
else
    echo "  (none — run scripts/import-agent-history.sh to collect)"
fi

# Summary
echo ""
if [ "$WARN" -eq 1 ]; then
    echo "Action needed: ask the agent to read the memory-compaction skill and compact."
else
    echo "Memory tree looks healthy."
fi
