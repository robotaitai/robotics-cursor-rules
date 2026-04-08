---
name: decision-recording
description: Record architectural and design decisions as lightweight ADRs in agent-knowledge/Memory/decisions/. Use when an important decision is made, reversed, or when the user asks to preserve rationale.
---

# Decision Recording

Persists the rationale for architectural and design choices so future agents
do not re-litigate settled questions.

---

## When to record a decision

Record when any of these occur:
- A technology, framework, or pattern is chosen over alternatives
- A structural constraint is adopted (e.g., "no ORM", "raw SQL only")
- A previous decision is reversed or superseded
- The user says "remember why we chose X" or "note that we decided not to do Y"

Do NOT record:
- Tactical choices (variable names, minor refactors, formatting)
- Facts that are obvious from reading the code
- Speculative decisions not yet confirmed

---

## Step 1 — Create the decision file

```bash
# In the project directory:
SLUG="<short-hyphenated-title>"
DATE=$(date +%Y-%m-%d)
FILE="agent-knowledge/Memory/decisions/${DATE}-${SLUG}.md"
```

Copy from `templates/memory/decision.template.md` (in the agents-rules repo).
Preserve YAML frontmatter.

---

## Step 2 — Fill in the template

Required fields — keep each one short:

| Field | Content |
|-------|---------|
| **What** | One sentence: what was decided |
| **Why** | Primary driver: constraint, measurement, user preference |
| **Alternatives considered** | 1–3 bullets: what was rejected and why |
| **Consequences** | 1–3 bullets: what this locks in or rules out |

Optional:
- **Superseded by**: link to the reversal decision if this one is no longer active

---

## Step 3 — Link from the relevant area file

In `agent-knowledge/Memory/<area>.md`, add or update the **Decisions** section:

```markdown
## Decisions
→ [2025-01-15-use-raw-sql.md](decisions/2025-01-15-use-raw-sql.md) — chose raw SQL over ORM for control and performance
```

One line per decision. Keep descriptions under 10 words.

---

## Step 4 — Update decisions/INDEX.md

Prepend a line in `agent-knowledge/Memory/decisions/INDEX.md`:

```markdown
- [2025-01-15-use-raw-sql.md](2025-01-15-use-raw-sql.md) — chose raw SQL over ORM
```

Newest first. If the decision reverses an earlier one, add `[reverses YYYY-MM-DD-slug]`.

---

## Step 5 — Update Memory/MEMORY.md if the root summary changed

Keep the root note short. Only update it if the project-level decision summary changed.

---

## Reversing a decision

1. Add `Status: reversed` to the original decision file
2. Add `Superseded by: → [new-decision.md](new-decision.md)` to the original
3. Create a new decision file for the replacement
4. Update `decisions/INDEX.md`: mark the old entry as `~~reversed~~`
5. Update the area file's Decisions section to link the new one

---

## Format reference

```markdown
---
note_type: decision
status: active
date: 2025-01-15
---

# Decision: use-raw-sql

## What
Use raw parameterized SQL instead of an ORM for all database access.

## Why
Need full control over query shape; ORM abstraction adds complexity without benefit
given the team's SQL proficiency.

## Alternatives considered
- **Prisma**: rejected — too much magic, migration model doesn't fit our schema strategy
- **Drizzle**: rejected — adds a dependency and type layer we don't need yet

## Consequences
- All DB access goes through raw SQL + pgtyped-generated types
- No model layer; query files live in packages/server/src/queries/
- New contributors must know SQL
```
