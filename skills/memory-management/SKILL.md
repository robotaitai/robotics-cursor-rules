---
name: memory-management
description: Read on session start. Manages persistent memory files across conversations. Use when recording learnings, updating MEMORY.md, creating topic files, or when the session-start hook injects memory context.
---

# Memory Management

Manages the project memory tree. Read this skill at session start.

The memory directory path is provided by the session-start hook
(e.g., `~/.cursor/projects/<project-id>/memory/MEMORY.md`).
For project-shared memory, the canonical location is `agent-docs/memory/MEMORY.md` in the repo,
symlinked to the Cursor memory path.

---

## Tree structure

```
agent-docs/memory/
  MEMORY.md              ← root index — always loaded, max ~200 lines
  <area>.md              ← one file per functional area
  <area>/<subtopic>.md   ← sub-file when an area file exceeds ~150 lines
  decisions/
    INDEX.md             ← decision index, newest first
    YYYY-MM-DD-slug.md   ← one decision record per choice
agent-docs/evidence/
  git-log.txt            ← raw evidence — never edit, re-collect with import script
  ...
```

Evidence (`agent-docs/evidence/`) is separate from curated memory (`agent-docs/memory/`).
Never copy raw evidence into memory. Distill only stable, verified facts.

---

## Profile-adaptive branches

The areas in the memory tree depend on the project profile detected at bootstrap:

| Profile | Initial areas |
|---------|--------------|
| web-app | stack, architecture, conventions, gotchas, integrations |
| robotics | stack, architecture, conventions, gotchas, hardware, simulation |
| ml-platform | stack, architecture, conventions, gotchas, datasets, models |
| hybrid | stack, architecture, conventions, gotchas, deployments |

The profile is recorded in MEMORY.md's header comment.
Add or remove area files as the project grows or shrinks.

---

## Required sections per area node

Every area file uses these sections (from `area.template.md`):

| Section | Content | Updated when |
|---------|---------|--------------|
| **Purpose** | One sentence: what this area covers | At creation; rarely changes |
| **Current State** | Verified facts about what is true now | Every writeback |
| **Recent Changes** | Rolling log, YYYY-MM-DD format, pruned after ~4 weeks | After meaningful changes |
| **Decisions** | Links to `decisions/YYYY-MM-DD-slug.md` | When a decision is recorded |
| **Open Questions** | Unresolved items for future sessions | When a question is identified; removed when resolved |
| **Subtopics** | Links to sub-files | When the area is split |

---

## Reading the tree

1. `MEMORY.md` loads automatically — it is the index only.
2. Identify which area(s) your task touches from the index.
3. Read only those area files — keep context lean.
4. Follow subtopic links only if the specific detail is needed.

---

## Writing to the tree

- **MEMORY.md**: one-line description per area + link. No inline detail.
- **Area file**: all facts for that area, organized by section.
- **Decision file**: one file per architectural decision, linked from the area.

Format for facts: lead with the fact. For lessons: add **Why:** and **How to apply:**.

---

## Bootstrap

If `agent-docs/memory/MEMORY.md` is missing or empty:
→ Read and follow the `project-ontology-bootstrap` skill before any other work.

---

## When to write back

Write to memory when any of these happen:
- A new architectural decision is made
- A pattern or convention is confirmed
- A gotcha is discovered
- A feature area is substantially completed or changed
- A recurring mistake is corrected

Do NOT write:
- In-progress task state → session file only
- Speculative plans → wait until confirmed
- Facts already in git history that are easily re-discoverable

---

## Compaction

When MEMORY.md approaches 200 lines or an area file exceeds ~150 lines:
→ Read and follow the `memory-compaction` skill.

---

## Explicit user requests

- "Remember X" → save it immediately to the relevant area file
- "Forget X" → remove or mark stale in the relevant area file
- "Why did we choose X" → read `decisions/INDEX.md` and the linked decision file
