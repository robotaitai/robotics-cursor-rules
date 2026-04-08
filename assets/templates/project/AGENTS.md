# Agent Knowledge: <project-name>

This project uses **agent-knowledge** for persistent project memory.
All knowledge is accessed through `./agent-knowledge/` (symlink to external vault).

## First-Time Onboarding

Check `./agent-knowledge/STATUS.md`. If `onboarding: pending`:

1. Inspect project structure: manifests, package files, CI/CD config, docs
2. Inspect project-local tool config: `.cursor/`, `.claude/`, `.codex/` if present
3. Review recent git history (last ~50 commits, key branches)
4. Import findings into `Evidence/raw/` using `agent-knowledge import`
5. Create curated notes in `Memory/` for verified, stable facts only
6. Update `./agent-knowledge/STATUS.md`: set `onboarding: complete`

Rules for onboarding:
- Only write confirmed facts to `Memory/` -- never speculate
- Keep raw/extracted material in `Evidence/`, not `Memory/`
- Keep generated views in `Outputs/` -- never treat as canonical truth
- Do NOT redo onboarding if STATUS.md already shows `onboarding: complete`

## Ongoing Maintenance

After onboarding is complete, during normal work:
- Update `Memory/` when stable facts change (decisions, conventions, gotchas)
- Record architectural decisions in `Memory/decisions/`
- Run `agent-knowledge update` after significant changes
- Keep `Evidence/` and `Outputs/` separate from `Memory/`
- Do NOT rebuild the knowledge tree every session

## Knowledge Structure

- `Memory/` -- Curated, durable project knowledge (source of truth)
- `Evidence/` -- Imported/extracted material (not curated truth)
- `Outputs/` -- Generated helper views (never canonical)
- `Sessions/` -- Temporary session state (prune aggressively)
- `STATUS.md` -- Onboarding and maintenance state
- `.agent-project.yaml` -- Project configuration

## Project Config

- `.agent-project.yaml` -- project metadata and sync config
- `.agentknowledgeignore` -- paths to exclude from evidence imports
