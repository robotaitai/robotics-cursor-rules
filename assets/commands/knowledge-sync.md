# Knowledge Sync

Knowledge sync is the connected-project maintenance flow for the adaptive memory system. It writes through `./agent-knowledge`, which should resolve to the external project knowledge folder.

## Behavior

- inspect current repo changes
- classify touched areas into the right `agent-knowledge/Memory/*.md` branches
- append durable recent-change entries when knowledge meaningfully changed
- optionally record a decision note when explicitly requested
- refresh raw and imported evidence without treating it as curated truth
- update `agent-knowledge/STATUS.md`

## Safety

- use `--dry-run` to preview all file writes
- idempotent reruns should not duplicate recent-change bullets
- sessions and evidence stay separate from durable memory

## Expected Script Entry Point

```bash
scripts/update-knowledge.sh --project /path/to/project
scripts/update-knowledge.sh --project /path/to/project --decision-title "Adopt X"
scripts/update-knowledge.sh --project /path/to/project --dry-run
```
