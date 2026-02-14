# VGB — Project Status

**Purpose**: Use this file as context (e.g. `@.cursor/prompts/project-status.md`) so the agent knows exactly what exists today and what's left to build. Update it as you complete work.

**Last updated**: 2026-02-14

---

## Codebase audit

Pre–Phase 4 audit (2026-02-14): **no rearchitecture needed.** Plan alignment is good (view vs persistence, local model as source of truth, feature layout). Applied: status literals replaced with `GameStatus` in widget summary logic. Recommended before ship: remove or gate debug logging. Full notes: **prompts/codebase-audit.md**.

---

## Current phase

| Item | Status |
|------|--------|
| Product direction | Done (backlog tracker concept defined) |
| MVP scope | Locked (includes live metadata; 2-week target flexible) |
| Implementation | Phase 1 complete (41 tests passing); Phase 2 next |
| Release readiness | Not started |

Details: see **What's implemented** and **What's not implemented** below.

---

## What's implemented

### Project structure
- Planning docs under `prompts/`
- Clean app layout:
  - `VGB/App/` — `VGBApp.swift`, `App/Resources/Info.plist`
  - `VGB/Models/` — `Game.swift` (SwiftData @Model), `GameStatus.swift` (enum)
  - `VGB/Features/Backlog/` — `BacklogListView.swift`, `AddGameView.swift`, `GameDetailView.swift`
  - `VGBTests/Unit/` — `AppScaffoldTests.swift`, `GameModelTests.swift`, `GameStatusTests.swift`, `GameFilterSortTests.swift`
- `VGB.xcodeproj` updated to match (shared scheme `VGB`); `project.yml` describes same layout for XcodeGen if used

### Features (Phase 1)
- **Backlog list** — displays games sorted by priority; supports drag-and-drop reorder
- **Add Game form** — manual entry with title, platform, status, estimated hours, personal rating, notes
- **Game Detail view** — edit status, personal rating, estimated hours, notes; view provider-sourced fields; delete game
- **Status management** — segmented picker for Backlog / Playing / Completed / Dropped
- **Filters** — by status, platform, and genre
- **Sorting** — by priority (drag order), Metacritic score, OpenCritic score, release date
- **Empty states** — "No Games Yet" and "No Matches" (with clear-filters action)
- **SwiftData persistence** — `.modelContainer(for: Game.self)` wired in `VGBApp`
- **Full-screen layout** — proper `UILaunchScreen` and `Info.plist` configuration
- **Unit tests** — 41 tests across 4 suites (model defaults, status transitions, filter/sort, codable)

### Context / docs
- **prompts/project-overview.md** — product vision, constraints, monetization direction
- **prompts/project-plan.md** — delivery timeline, tasks, and test strategy
- **prompts/project-features.md** — feature split between MVP and post-release
- **prompts/project-context.md** — references for agent grounding
- **prompts/project-status.md** — implementation source of truth
- **README.md** — setup, generation, and CI notes

---

## What's not implemented

- Metadata provider integration — API client, search/prefill, manual refresh, stale indicators (Phase 2)
- Stats screen (Phase 3)
- QA pass, app icon, launch screen, App Store submission (Phase 3)

Full task checklist: **prompts/project-plan.md**

---

## Key files (for agent reference)

| File | Role | Current state |
|------|------|----------------|
| `prompts/project-overview.md` | Product brief and goals | Updated for VGB backlog tracker |
| `prompts/project-features.md` | Scope guardrails (MVP vs post-release) | Added |
| `prompts/project-plan.md` | Timeline and execution checklist | Phase 1 complete |
| `prompts/project-status.md` | Current progress snapshot | Updated — Phase 1 done |
| `project.yml` | XcodeGen spec (optional regenerate) | Matches folder layout |
| `VGB/Models/Game.swift` | SwiftData domain model | Implemented with user/provider/system field split |
| `VGB/Models/GameStatus.swift` | Status enum | Backlog, Playing, Completed, Dropped |
| `VGB/Features/Backlog/BacklogListView.swift` | Main list with filters/sort | Implemented |
| `VGB/Features/Backlog/AddGameView.swift` | Add game form | Implemented |
| `VGB/Features/Backlog/GameDetailView.swift` | Game detail/edit view | Implemented |
| `VGB.xcodeproj` | iOS app + tests, shared scheme | Aligned with full project layout |

---
