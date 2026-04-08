---
name: session-management
description: Read on session start. Tracks work progress in session files during conversations. Use when recording milestones, decisions, blockers, or when the session-start hook creates a session file.
---

# Session Management

Session files preserve in-progress context through long sessions and help new sessions
resume quickly from prior work.

The session file path is provided by the session-start hook
(e.g., `~/.cursor/projects/<project-id>/sessions/`).
For project-shared session notes, use `agent-knowledge/Sessions/`.

---

## Session vs memory — the key distinction

| Session file | Memory tree |
|-------------|------------|
| Ephemeral — deleted or archived when no longer active | Durable — persists across all sessions |
| Tracks current task progress | Tracks stable project understanding |
| Milestone-oriented log entries | Fact-oriented structured files |
| Private to one conversation thread | Shared across all agents and conversations |
| Write freely, prune aggressively | Write carefully, never speculate |

**Rule**: if a fact belongs to future sessions, it goes in memory. If it only matters for this session, it stays in the session file.

---

## Session file format

Filename: `YYYY-MM-DD-<title-slug>-<UUID>.tmp`
(slug defaults to `session` until the task is clear, then updated)

```markdown
## Current State
[One-line description of current focus]

### Completed
- [Milestone outcomes, not step-by-step details]

### In Progress
- [What is actively being worked on]

### Blockers
- [What is preventing progress]

### Notes for Next Session
- [What to load immediately when resuming]

### Context to Load
- [Which memory areas and files to read on resume]

## Session Log
**HH:MM** - [Milestone outcome in one line]
```

---

## How to update

1. Read the current session file first.
2. If nothing meaningful happened since the last log entry, do not write.
3. If a meaningful milestone occurred, write one checkpoint:
   - Refresh **Current State**
   - Update Completed / In Progress / Blockers
   - Add one timestamped Session Log line
4. Set the session title once the task is clear.
5. Keep entries milestone-oriented — not every tool call.

---

## When NOT to write

- Between sequential tool calls in the same task
- For trivial progress (e.g., reading a file, minor edits)
- When the hook fires but no real milestone occurred

---

## Writeback gate — before closing a session

Before ending a session with meaningful output, check:

**Did this session change durable project understanding?**

If yes — follow the `memory-writeback` rule:
1. Identify the durable fact (decision, pattern, gotcha, lesson)
2. Write it to the relevant `agent-knowledge/Memory/<area>.md`
3. For architectural decisions: use the `decision-recording` skill
4. Once written to memory, remove or summarize it in the session file (avoid duplication)

If no meaningful new project understanding was produced — no writeback needed. State this explicitly:
> Memory writeback: none needed (no new durable facts this session).

Examples that should NOT trigger writeback:
- Progress within one task but no stable new conclusion
- Temporary debugging state
- Notes that only matter to the current conversation
- Evidence review that did not change curated understanding

---

## Session log entry format

```markdown
**HH:MM** - [Milestone outcome in one line]
```

Example:
```markdown
**14:32** - bootstrapped memory tree (hybrid profile, 5 area files created)
**15:10** - backfill complete: stack, architecture, gotchas populated from git history
**15:45** - decision recorded: use-raw-sql (decisions/2025-01-15-use-raw-sql.md)
```
