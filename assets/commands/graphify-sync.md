# Graphify Sync

Graphify sync is the optional structural-discovery import flow for graph-style project exports.
It writes through `./agent-knowledge`, but keeps imported graph structure in `Evidence/` and `Outputs/`, not in durable memory.

## Behavior

- detect whether `graphify` or equivalent structural export artifacts are available
- import safe graph/report/json artifacts into `agent-knowledge/Evidence/imports/graphify/`
- generate concise structural summaries under `agent-knowledge/Outputs/graphify/`
- tag imported material with confidence metadata such as `EXTRACTED` or `INFERRED`
- summarize what was imported, what was cached, and what was skipped

## Safety

- optional only; missing graph tooling must not fail the project knowledge system
- use `--dry-run` to preview all writes
- imported graph outputs are evidence first and are not promoted into `Memory/` automatically

## Expected Script Entry Point

```bash
scripts/graphify-sync.sh --project /path/to/project
scripts/graphify-sync.sh --project /path/to/project --source /path/to/graphify-export
scripts/graphify-sync.sh --project /path/to/project --dry-run
```
