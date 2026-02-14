# VGB — Project Status

**Purpose**: Use this file as context (e.g. `@.cursor/prompts/project-status.md`) so the agent knows exactly what exists today and what’s left to build. Update it as you complete work.

**Last updated**: 2026-02-13

---

## Current phase

| Item | Status |
|------|--------|
| Product direction | In progress (backlog tracker concept defined) |
| MVP scope | Locked (includes live metadata; 2-week target flexible) |
| Implementation | In progress (Xcode scaffold created) |
| Release readiness | Not started |

Details: see **What's implemented** and **What's not implemented** below.

---

## What’s implemented

### Project structure
- Planning docs under `prompts/`
- Clean app layout:
  - `VGB/App/` — `VGBApp.swift`, `App/Resources/Info.plist`
  - `VGB/Models/` — `Game.swift` (SwiftData @Model), `GameStatus.swift` (enum)
  - `VGB/Features/Backlog/` — `BacklogListView.swift`
  - `VGBTests/Unit/` — `AppScaffoldTests.swift`
- `VGB.xcodeproj` updated to match (shared scheme `VGB`); `project.yml` describes same layout for XcodeGen if used

### Assets and UI
- Placeholder screen: `BacklogListView` (Features → Backlog)
- No production assets yet

### Context / docs
- **prompts/project-overview.md** — product vision, constraints, monetization direction.
- **prompts/project-plan.md** — 2-week delivery timeline, tasks, and test strategy.
- **prompts/project-features.md** — feature split between MVP and post-release.
- **prompts/project-context.md** — references for agent grounding.
- **prompts/project-status.md** — implementation source of truth.
- **README.md** — setup, generation, and CI notes.
- **docs/** — TBD

---

## What’s not implemented

- Wire SwiftData `.modelContainer` in VGBApp
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
| `prompts/project-plan.md` | Timeline and execution checklist | Phase 1 started |
| `prompts/project-status.md` | Current progress snapshot | Updated with scaffold progress |
| `project.yml` | XcodeGen spec (optional regenerate) | Matches folder layout |
| `VGB/Models/Game.swift` | SwiftData domain model | Implemented with user/provider/system field split |
| `VGB/Models/GameStatus.swift` | Status enum | Backlog, Playing, Completed, Dropped |
| `VGB.xcodeproj` | iOS app + tests, shared scheme | Aligned with VGB/App, VGB/Models, VGB/Features, VGBTests/Unit |

---
