# VGB — Project Status

**Purpose**: Use this file as context (e.g. `@prompts/project-status.md`) so the agent knows exactly what exists today and what's left to build. Update it as you complete work.

**Last updated**: 2026-02-15

---

## Codebase audit

Pre-ship audit (2026-02-15): **no rearchitecture needed.** Debug logging gated with `#if DEBUG`; dead code removed. Full notes: **docs/CODEBASE_AUDIT.md**.

---

## Current phase

| Item | Status |
|------|--------|
| Product direction | Done (backlog tracker concept defined) |
| MVP scope | Locked (includes live metadata; 2-week target flexible) |
| Implementation | Phases 1–4 complete; final polish and ship next |
| Release readiness | Not started |

Details: see **What's implemented** and **What's not implemented** below.

---

## What's implemented

### Project structure
- Planning docs under `prompts/`
- Clean app layout:
  - `VGB/App/` — `VGBApp.swift`, `CheckpointHeader.swift`, `StoreConfiguration.swift`, `WidgetSummaryStorage.swift`
  - `VGB/Models/` — `Game.swift` (SwiftData @Model), `GameStatus.swift`, `GameStatus+Color.swift`
  - `VGB/Features/Backlog/` — `BacklogListView.swift`, `AddGameView.swift`, `GameDetailView.swift`, `CelebrationOverlay.swift`
  - `VGB/Features/Stats/` — `StatsView.swift`, `RadarChartView.swift`, `RadarGenreCategories.swift`
  - `VGB/Features/Rankings/` — `RankingsView.swift`
  - `VGB/Features/Onboarding/` — `OnboardingView.swift`
  - `VGB/Services/` — `IGDBClient.swift`, `IGDBModels.swift`, `GameSyncService.swift`, `TwitchAuthManager.swift`, `APIConfig.swift`
  - `VGBWidget/` — widget extension (small + medium)
  - `VGBTests/Unit/` — model, status, filter/sort, IGDB, sync tests
- `VGB.xcodeproj` is source of truth; `project.yml` is outdated (no widget/stats)

### Features (Phase 1)
- **Backlog list** — displays games sorted by priority; supports drag-and-drop reorder
- **Add Game form** — manual entry with title, platform, status, estimated hours, personal rating, notes
- **Game Detail view** — edit status, personal rating, estimated hours, notes; view provider-sourced fields; delete game
- **Status management** — segmented picker for Backlog / Playing / Completed / Dropped
- **Filters** — by status, platform, and genre
- **Sorting** — by priority (drag order), IGDB critic score, release date
- **Empty states** — "No Games Yet" and "No Matches" (with clear-filters action)
- **SwiftData persistence** — `.modelContainer(for: Game.self)` wired in `VGBApp`
- **Full-screen layout** — proper `UILaunchScreen` and `Info.plist` configuration
- **Unit tests** — model, status, filter/sort, IGDB mapping, sync

### Context / docs
- **prompts/project-overview.md** — product vision, constraints, monetization direction
- **prompts/project-plan.md** — delivery timeline, tasks, and test strategy
- **prompts/project-features.md** — feature split between MVP and post-release
- **prompts/project-context.md** — references for agent grounding
- **prompts/project-status.md** — implementation source of truth
- **README.md** — setup, generation, and CI notes

---

## What's not implemented

- App icon, launch screen, store-ready screenshots
- Device testing (physical + simulator), bug fixes, performance pass
- App Store metadata and v1 submission

Full task checklist: **prompts/project-plan.md**

---

## Key files (for agent reference)

| File | Role | Current state |
|------|------|----------------|
| `prompts/project-overview.md` | Product brief and goals | Updated for VGB backlog tracker |
| `prompts/project-features.md` | Scope guardrails (MVP vs post-release) | Added |
| `prompts/project-plan.md` | Timeline and execution checklist | Phase 4 final polish |
| `prompts/project-status.md` | Current progress snapshot | Updated — Phase 1 done |
| `project.yml` | XcodeGen spec (optional regenerate) | Matches folder layout |
| `VGB/Models/Game.swift` | SwiftData domain model | Implemented with user/provider/system field split |
| `VGB/Models/GameStatus.swift` | Status enum | Backlog, Playing, Completed, Dropped |
| `VGB/Features/Backlog/BacklogListView.swift` | Main list with filters/sort | Implemented |
| `VGB/Features/Backlog/AddGameView.swift` | Add game form | Implemented |
| `VGB/Features/Backlog/GameDetailView.swift` | Game detail/edit view | Implemented |
| `VGB.xcodeproj` | iOS app + tests, shared scheme | Aligned with full project layout |

---
