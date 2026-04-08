---
area: packaging
updated: 2026-04-08
---

# Packaging

## Purpose
Python packaging strategy for making agent-knowledge pip-installable.

## Current State

- Build backend: `hatchling` via `pyproject.toml`.
- Layout: `src-layout` at `src/agent_knowledge/`.
- Entry point: `agent-knowledge = agent_knowledge.cli:main` in `[project.scripts]`.
- Runtime dependency: `click>=8.0`. Optional: `tiktoken` (for token measurement), `pytest>=7.0` + `build` (dev).
- Non-Python assets (scripts, templates, rules, rules-global, commands, skills, skills-cursor, claude) are bundled into `agent_knowledge/assets/` via `[tool.hatch.build.targets.wheel.force-include]`.
- sdist includes `src/`, all asset dirs, `tests/`, and metadata files via `[tool.hatch.build.targets.sdist.include]`.
- Wheel version: `0.1.0`.

## Recent Changes

- 2026-04-08: Initial packaging created. Chose hatchling over setuptools for simpler asset bundling with force-include.
- 2026-04-08: Added `assets/__init__.py` so hatch correctly includes the assets package marker.

## Decisions

- Chose `hatchling` over `setuptools` because `force-include` cleanly maps repo-root asset directories into the package without MANIFEST.in complexity.
- Chose `src-layout` to avoid import confusion between repo root and installed package.
- Did not use `importlib.resources` -- scripts derive their own paths from SCRIPT_DIR, so a simple `Path(__file__)` approach in `runtime/paths.py` is sufficient.

## Open Questions

- None currently.
