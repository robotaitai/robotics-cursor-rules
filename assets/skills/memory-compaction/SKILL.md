---
name: memory-compaction
description: Compact and prune the memory tree when it grows large or stale. Use when Memory/MEMORY.md grows noisy, area files exceed 150 lines, or when explicitly asked to clean up memory.
---

# Memory Compaction

Reorganizes the memory tree to keep it scannable without losing durable facts.

Run this when `compact-memory.sh` reports warnings, or proactively after dense work periods.

---

## Invariants — never violate

- Every durable fact must survive compaction (move or merge, never delete)
- `Memory/MEMORY.md` must stay short and scannable
- Every branch file must be linked from `Memory/MEMORY.md`
- Evidence files are never touched during compaction

---

## Step 1 — Audit

Run the report script first:

```bash
scripts/compact-memory.sh /path/to/project
```

Note which files are flagged as:
- `CRITICAL` (>200 lines) — act immediately
- `WARNING` (>150 lines) — split at next opportunity
- `stub or empty` — populate or remove

---

## Step 2 — Prune stale entries

In each area file, remove or update entries that are:

- **Superseded**: a newer entry contradicts the old one → remove the old, update the new
- **Dead reference**: refers to a path, API, or dependency that no longer exists → remove
- **Speculation never confirmed**: still marked with "might", "probably", "TODO: verify" → remove or move to Open Questions
- **Recent Changes too old**: entries older than ~4 weeks → move stable facts to Current State, drop transient ones

Do not prune:
- Gotchas and lessons (even old ones are valuable if the risk still exists)
- Decision rationale (even for reversed decisions — mark as `Status: reversed`)

---

## Step 3 — Split large area files

If an area file exceeds ~150 lines:

1. Identify the dominant sub-topic that makes it large
2. Create `agent-knowledge/Memory/<area>/<subtopic>.md` using `area.template.md`
3. Move the sub-topic content there
4. Replace the moved section in the area file with:
   ```markdown
   ## Subtopics
   → [subtopic.md](<area>/subtopic.md) — one-line description
   ```
5. Update `Memory/MEMORY.md` if the branch summary needs adjusting

---

## Step 4 — Merge overlapping thin files

If two area files cover the same ground and together are under ~100 lines:

1. Choose the name that better describes the combined scope
2. Merge content, resolving any contradictions (newer wins)
3. Delete the merged file
4. Update `Memory/MEMORY.md` to remove the deleted entry and update the surviving one

---

## Step 5 — Compact Memory/MEMORY.md

The root note must be scannable at a glance. Keep:

```markdown
- one short summary per branch
- markdown links to the branch notes
- only the most useful open questions
```

Remove:
- Areas with empty files that will not be populated
- Duplicate entries

Add:
- Any area files that exist but are not yet linked

---

## Step 6 — Update decisions/INDEX.md

Verify every file in `decisions/` is listed in `decisions/INDEX.md`.
Remove entries for deleted decision files.
Mark superseded decisions with `~~strikethrough~~` or `[reversed]` in the index.

---

## Output checklist

- [ ] `compact-memory.sh` shows no CRITICAL or WARNING flags
- [ ] `Memory/MEMORY.md` is short and readable
- [ ] No area file exceeds 150 lines
- [ ] All area files are linked from `Memory/MEMORY.md`
- [ ] `decisions/INDEX.md` is current
