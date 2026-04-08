# Global Knowledge Sync

Global knowledge sync builds a project-scoped tooling knowledge view from safe,
allowlisted user-level tool surfaces. It still writes through `./agent-knowledge`,
which should resolve to the external project knowledge folder.

## Behavior

- scan allowlisted local configuration sources such as `~/.claude/`, `~/.codex/`, and optional safe Cursor customizations
- skip opaque caches, auth/session surfaces, and suspicious secret-bearing files
- redact sensitive lines before writing evidence
- write redacted imports under `agent-knowledge/Evidence/tooling/`
- write curated summaries under `agent-knowledge/Memory/tooling/`
- update `agent-knowledge/STATUS.md`

## Safety

- use `--dry-run` to preview writes
- reruns should be idempotent
- summaries must report both scanned sources and safety skips

## Expected Script Entry Point

```bash
scripts/global-knowledge-sync.sh --project /path/to/project
scripts/global-knowledge-sync.sh --project /path/to/project --dry-run
```
