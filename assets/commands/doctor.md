# Doctor

Doctor is the quick troubleshooting entrypoint for a connected project knowledge setup.

## Behavior

- run knowledge validation
- verify the local `./agent-knowledge` pointer and external source-of-truth path
- check project setup files such as `.agent-project.yaml`, `AGENTS.md`, and optional repo-local hooks
- summarize health warnings and the current operational state

## Safety

- read-mostly command
- may refresh `agent-knowledge/STATUS.md` unless `--dry-run` is used

## Expected Script Entry Point

```bash
scripts/doctor.sh --project /path/to/project
```
