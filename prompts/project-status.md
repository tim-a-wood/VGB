# VGB — Project Status

**Purpose**: Use this file as context (e.g. `@.cursor/prompts/project-status.md`) so the agent knows exactly what exists today and what’s left to build. Update it as you complete work.

**Last updated**: 2026-02-13

---

## Current phase

| Item | Status |
|------|--------|
| Product direction | In progress (backlog tracker concept defined) |
| MVP scope | Locked (includes live metadata; 2-week target flexible) |
| Implementation | Not started |
| Release readiness | Not started |

Details: see **What's implemented** and **What's not implemented** below.

---

## What’s implemented

### Project structure
- Planning docs established under `prompts/`
- App implementation files not created yet

### Assets and UI
- No production UI/assets yet

### Context / docs
- **prompts/project-overview.md** — product vision, constraints, monetization direction.
- **prompts/project-plan.md** — 2-week delivery timeline, tasks, and test strategy.
- **prompts/project-features.md** — feature split between MVP and post-release.
- **prompts/project-context.md** — references for agent grounding.
- **prompts/project-status.md** — implementation source of truth.
- **docs/** — TBD

---

## What’s not implemented

- Xcode project scaffolding
- Data model and persistence layer (including sortOrder, externalId, lastSyncedAt for metadata)
- Backlog list with drag-and-drop reorder and add/edit flows
- Metadata provider integration (search, prefill, manual refresh, stale indicators)
- Filters, sorting, and stats screen
- QA pass and App Store submission setup

Full task checklist: **prompts/project-plan.md**

---

## Key files (for agent reference)

| File | Role | Current state |
|------|------|----------------|
| `prompts/project-overview.md` | Product brief and goals | Updated for VGB backlog tracker |
| `prompts/project-features.md` | Scope guardrails (MVP vs post-release) | Added |
| `prompts/project-plan.md` | Timeline and execution checklist | Updated for 2-week track |
| `prompts/project-status.md` | Current progress snapshot | Updated |

---
