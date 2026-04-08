---
area: cli
updated: 2026-04-08
---

# CLI

## Purpose
Design and implementation of the `agent-knowledge` command-line interface.

## Current State

- Framework: `click` with a `@click.group()` top-level and 11 subcommands.
- Subcommands: init, bootstrap, import, update, doctor, validate, ship, global-sync, graphify-sync, compact, measure-tokens.
- Pattern: thin Python wrappers that parse CLI args, then delegate to bundled shell scripts via `run_bash_script()` / `run_python_script()` from `runtime/shell.py`.
- Common flags: `--dry-run`, `--json`, `--force` propagated via `_add_common_flags()`.
- `--summary-file` on `update` command (hidden) supports hook integration.
- `measure-tokens` uses `context_settings={"allow_interspersed_args": False}` so `--help` and subcommand args pass through to the delegated `measure-token-savings.py` script instead of being consumed by click.
- All user-facing messages in scripts reference `agent-knowledge <subcommand>` instead of `scripts/*.sh` paths.

## Recent Changes

- 2026-04-08: Created CLI with all 11 subcommands.
- 2026-04-08: Fixed `measure-tokens --help` passthrough with `allow_interspersed_args=False`.
- 2026-04-08: Added `--summary-file` to `update` for hook compatibility.
- 2026-04-08: Updated all script messages to reference CLI commands.

## Decisions

- Scripts are invoked via subprocess, not reimplemented in Python. **Why:** The scripts are complex, battle-tested, and self-contained. Rewriting would introduce bugs for no gain. **How to apply:** Only rewrite a script if it fundamentally can't work from the installed package.
- `measure-tokens` passes all args unprocessed to the underlying Python script. **Why:** The script has its own argparse subcommands (compare, log-run, summarize-log) with their own `--help`.

## Open Questions

- None currently.
