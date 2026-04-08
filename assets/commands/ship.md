# Ship

Ship is the operational release-prep flow for a connected project repo.

## Behavior

- inspect git status and current branch
- refuse to continue on detached HEAD or merge conflicts
- run detected validation commands for the repo
- run knowledge sync and compaction before commit
- stage repo-local changes
- generate or accept a concise commit message
- commit and push when possible
- optionally open a PR when requested

## Safety

- use `--dry-run` to preview validations, git actions, and knowledge updates
- knowledge updates still run through `./agent-knowledge`; the script does not convert the system into repo-local storage
- if the real knowledge vault lives outside the repo, the script reports that instead of pretending to stage it
- reruns are no-op when nothing changed

## Expected Script Entry Point

```bash
scripts/ship.sh --project /path/to/project
scripts/ship.sh --project /path/to/project --message "chore: ship update"
scripts/ship.sh --project /path/to/project --open-pr --dry-run
```
