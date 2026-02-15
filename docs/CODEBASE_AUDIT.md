# VGB — Codebase Audit

**Date**: 2026-02-15 (updated)

---

## Summary

| Category | Finding | Status |
|----------|---------|--------|
| **Dead code** | `statusSections`, `statusSection`, `deleteInSection`, `applyDrop(uuidStrings:...)` | Removed (not present in current codebase) |
| **Debug logging** | `print(...)` in BacklogListView, VGBApp, StoreConfiguration | Gated with `#if DEBUG` |
| **Logger verbosity** | WidgetSummaryStorage, VGBWidget use `.info` for diagnostics | Changed to `.debug` for release |
| **SectionHeaderDropZone** | Unused params after drops-on-headers disabled | Simplified (title, systemImage, color, isExpanded, onToggle only) |

---

## What's in good shape

- **Layout**: App, Features (Backlog, Stats, Rankings, Onboarding), Models, Services, VGBWidget are clear.
- **Game / GameStatus**: Clear ownership (user vs provider vs system); `displayPlatform` and rating logic are consistent.
- **Tests**: Unit tests for model, status, filter/sort, IGDB, sync.
- **Secrets**: `Secrets.xcconfig` in `.gitignore`; CI creates placeholder.
- **Documentation**: README, prompts/, docs/ up to date.

---

## Files

- **Swift**: All under `VGB/`, `VGBWidget/`, `VGBTests/` are in use.
- **prompts/**: Planning docs; `prompts/codebase-audit.md` removed (duplicate of this file).
- **user-preferences.md**: Cursor agent preferences; keep.
- **project.yml**: Outdated (no widget, stats, rankings). `VGB.xcodeproj` is source of truth.

---

## Optional follow-ups

- **Filter/sort extraction**: `displayedGames` in BacklogListView holds all filter/sort logic; optional to extract if more list screens appear.
- **BacklogListView size**: ~930 lines; acceptable; could split by MARK regions if it grows.
