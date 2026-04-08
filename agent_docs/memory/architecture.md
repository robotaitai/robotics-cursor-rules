---
area: architecture
updated: 2026-04-08
---

# Architecture

## Purpose
Core design patterns: path resolution, project config, template system.

## Current State

### Path resolution
- `runtime/paths.py` provides `get_assets_dir()` with dual-mode resolution:
  1. Installed package: `assets/` is sibling of `runtime/` inside `site-packages/agent_knowledge/`.
  2. Dev checkout: falls back to repo root (4 parent levels up from `runtime/paths.py`).
- Marker file for validation: `scripts/lib/knowledge-common.sh`.
- Result is cached in `_cached_assets_dir` for the process lifetime.
- All shell scripts derive `AGENTS_RULES_DIR` from their own `SCRIPT_DIR` (one level up from `scripts/`), making them location-independent regardless of installed vs dev.

### Project config (.agent-project.yaml)
- Version 3 (bumped from 2).
- Removed `framework.repo` field. **Why:** It wrote a fragile site-packages path that would break on package upgrade or reinstall. Scripts don't need it -- they find assets via SCRIPT_DIR.
- `hooks.project_sync_command` and `hooks.graph_sync_command` now reference CLI commands (`agent-knowledge update --project .`) instead of script paths.
- `validate-knowledge.sh` no longer requires `repo` in its required-keys check.

### Hooks template
- `.cursor/hooks.json` template uses `agent-knowledge update --summary-file <path> --project <path>` instead of direct script invocation.

### Global install (install.sh)
- Separate from the pip package. Symlinks rules and skills from the repo checkout into `~/.cursor/rules/` and `~/.cursor/skills/` for developer workflows.
- Calls `claude/scripts/install.sh` for Claude Code global rules.

## Recent Changes

- 2026-04-08: Removed `framework.repo` from `.agent-project.yaml` template (v2 -> v3).
- 2026-04-08: Made `doctor.sh` skip framework repo check when field is empty.
- 2026-04-08: Updated hooks template to use CLI commands.

## Gotchas

- `install-project-links.sh` had a `set -euo pipefail` + trailing `[ "$DRY_RUN" -eq 1 ] && log ...` pattern that caused exit 1 when DRY_RUN=0 because the `[` test returned false. Fixed with explicit `if`.
- System Python on macOS refuses `pip install` with "externally managed" error. Must use a venv.

## Open Questions

- None currently.
