# agent-knowledge

Adaptive, file-based project knowledge for AI coding agents.

## Install

```
pip install agent-knowledge
```

## Quick Start

```
cd your-project
agent-knowledge init
```

That's it. Open Cursor, Claude, or Codex in the repo -- the agent picks up from there.

`init` automatically:
- infers the project slug from the directory name
- creates the external knowledge vault under `~/agent-os/projects/<slug>/`
- creates a `./agent-knowledge` symlink pointing to it
- creates `.agent-project.yaml`, `AGENTS.md`, and the memory tree
- detects Cursor, Claude, and Codex and installs integration bridge files
- sets onboarding status to `pending` so the agent knows to run first-time ingestion

## How It Works

Project knowledge lives **outside** the repo at `~/agent-os/projects/<slug>/`.
Inside the repo, `./agent-knowledge` is a symlink to that external folder.

When an agent opens the repo, it reads `AGENTS.md` and `./agent-knowledge/STATUS.md`.
If onboarding is pending, the agent inspects the project, imports evidence, and
creates curated memory. After that, ongoing maintenance happens automatically.

### Knowledge Structure

| Folder | Purpose | Rule |
|--------|---------|------|
| `Memory/` | Curated, durable facts | Source of truth |
| `Evidence/` | Imported/extracted material | Not curated truth |
| `Outputs/` | Generated views | Never canonical |
| `Sessions/` | Temporary state | Prune aggressively |

## Commands

| Command | What it does |
|---------|-------------|
| `agent-knowledge init` | Set up a project (zero-arg default) |
| `agent-knowledge doctor` | Validate setup and report health |
| `agent-knowledge update` | Sync changes into the knowledge tree |
| `agent-knowledge import` | Import repo history into Evidence/ |
| `agent-knowledge ship` | Validate, sync, commit, push |
| `agent-knowledge bootstrap` | Repair the memory tree |
| `agent-knowledge setup` | Install global Cursor rules and skills |
| `agent-knowledge global-sync` | Import safe local tooling config |
| `agent-knowledge graphify-sync` | Import graph/discovery artifacts |
| `agent-knowledge compact` | Compact memory notes |
| `agent-knowledge measure-tokens` | Estimate context token savings |

All write commands support `--dry-run`. Use `--json` for machine-readable output.

## Custom Knowledge Home

Set the environment variable to change where vaults are stored:

```
export AGENT_KNOWLEDGE_HOME=~/my-knowledge
```

Or pass it once:

```
agent-knowledge init --knowledge-home ~/my-knowledge
```

## Multi-Tool Support

`init` auto-detects which tools are present and installs the right bridge files:

| Tool | Detection | Bridge file |
|------|-----------|-------------|
| Cursor | `.cursor/` exists | `.cursor/hooks.json` (always installed) |
| Claude | `.claude/` or `CLAUDE.md` | `CLAUDE.md` |
| Codex | `.codex/` | `.codex/AGENTS.md` |

Multiple tools in the same repo work fine.

## Obsidian

Open `~/agent-os/projects/<slug>/` (or the parent `~/agent-os/projects/`) as an
Obsidian vault to browse project knowledge with backlinks and graph view.

## Development

```
git clone <repo-url>
cd agent-knowledge
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
pytest tests/ -v
```
