---
area: testing
updated: 2026-04-08
---

# Testing

## Purpose
Test strategy for packaging validation and CLI correctness.

## Current State

- Framework: `pytest` (dev dependency).
- 27 tests across 2 files: `tests/test_packaging.py` and `tests/test_cli.py`.

### test_packaging.py
- Verifies package is importable and `__version__` exists.
- Verifies `get_assets_dir()` resolves without error.
- Checks all bundled scripts, common lib, templates, rules, and commands exist at expected paths under assets.
- Verifies `get_script()` returns valid paths and raises `FileNotFoundError` for missing scripts.

### test_cli.py
- Top-level `--help` and `--version`.
- Parametrized `--help` for all 11 subcommands.
- `init --help` contains `--slug`.
- `init --dry-run` exits 0 and does not create files.
- `doctor --json` output is valid JSON with `"script": "doctor"`.
- Smoke test: `init` in tmp repo -> verifies symlink and `.agent-project.yaml` created -> `doctor --json` returns clean result.
- `measure-tokens` with no args shows help text.

### Running tests
- All tests run via the installed package (`python -m agent_knowledge` or editable install).
- `BIN = [sys.executable, "-m", "agent_knowledge"]` ensures tests use the current Python interpreter.

## Recent Changes

- 2026-04-08: Initial test suite created.

## Open Questions

- None currently.
