# VGB — Codebase Audit

**Purpose**: Record of the pre–Phase 4 audit to decide if refactor or rearchitecture was needed. Use as context when planning further changes.

**Date**: 2026-02-14

---

## Verdict

**No rearchitecture needed.** A few small cleanups were recommended and partially applied; nothing blocks Phase 4.

---

## Alignment with project plan

| Plan guideline | Status |
|----------------|--------|
| Keep feature modules small | OK — Backlog is one area (~500 lines in BacklogListView). Readable; no split required before Phase 4. |
| Separate view state from persistence | OK — Views use @Query / modelContext; GameSyncService handles sync; no persistence inside views. |
| Local model as source of truth; provider as enrichment | OK — GameSyncService only updates provider-sourced fields; user-owned fields untouched. |
| Reusable filter/sort helpers | Not done (plan: medium). Filter/sort lives in BacklogListView.displayedGames. Optional later extraction. |

---

## What’s in good shape

- **Structure**: App / Features/Backlog / Models / Services / VGBWidget is clear. No dead code.
- **Domain**: Game and GameStatus well-defined; ownership (user vs provider vs system) is clear.
- **Services**: GameSyncService, IGDBClient, TwitchAuthManager, StoreConfiguration, WidgetSummaryStorage have clear roles.
- **Widget**: App Group UserDefaults first, SwiftData fallback; entitlement and code signing fixed.
- **Tests**: 66 unit tests for model, status, filter/sort, IGDB mapping, sync.

---

## Cleanups applied

- **Status literals**: Replaced string literals `"Backlog"`, `"Completed"`, `"Playing"` with `GameStatus.backlog`, `.completed`, `.playing` in VGBApp.pushWidgetSummary and VGBWidget SwiftData fallback so status logic stays type-safe.

---

## Cleanups recommended (before ship)

- **Debug logging**: Remove or gate behind `#if DEBUG` in StoreConfiguration (print), VGBApp (print), WidgetSummaryStorage (Logger), VGBWidget (Logger). Do during Phase 4 “UX polish” or pre-release.
- **Optional**: Extract `WidgetSummary.from(games: [Game])` and use in both app write and widget SwiftData fallback for a single source of “next up + counts” logic. Low priority.

---

## Explicitly not recommended now

- Splitting BacklogListView into smaller files — acceptable as-is.
- Extracting filter/sort helpers — medium priority in plan; defer until more list-like screens exist.
- Introducing MVVM/Clean/extra layers — current SwiftUI + SwiftData + services is appropriate for scope.
