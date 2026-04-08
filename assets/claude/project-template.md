# Project: <Name>

<!-- Drop this file at the project root as CLAUDE.md -->
<!-- It is read automatically by Claude Code at the start of every session -->
<!-- Global rules in ~/.claude/CLAUDE.md are also loaded — no need to repeat them here -->

## Stack

- <language/runtime>
- <framework>
- <database>
- <key libraries>

## Key Directories

- `src/` — <description>
- `tests/` — <description>

## Conventions

- <naming conventions>
- <patterns to follow>
- <patterns to avoid>

## What NOT to do

- Do not install <X> — we use <Y> instead
- Do not restructure <X> without asking
- Do not commit secrets — use .env.template as reference

## When unsure

- Search the codebase first. Reuse existing patterns.
- Ask before creating new packages or major abstractions.
- Read docs in `docs/` or `agent-knowledge/` before implementing.

## Shared Memory

Persistent project memory lives at `agent-knowledge/Memory/MEMORY.md`.
The local `agent-knowledge/` path should point to the real dedicated knowledge folder.
Read it at the start of each session. Write back after meaningful changes.

- If `agent-knowledge/Memory/MEMORY.md` is missing: run `scripts/bootstrap-memory-tree.sh .`
- After any architectural decision: use the `decision-recording` skill
- After any meaningful state change: follow the `memory-writeback` rule
- To backfill from git/docs history: run `scripts/import-agent-history.sh .`
