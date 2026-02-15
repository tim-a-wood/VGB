# VGB — Codebase Audit

**Date**: 2026-02-15

---

## Summary

| Category | Finding | Action |
|----------|---------|--------|
| **Dead code** | `statusSections`, `statusSection`, `deleteInSection`, `applyDrop(uuidStrings:...)` never used (game list uses `scrollViewSectionedList` or `List { singleSection }` only) | Remove |
| **Debug logging** | `print(...)` in BacklogListView (RowDropModifier), VGBApp, StoreConfiguration | Wrap in `#if DEBUG` or remove |
| **Unused params** | `SectionHeaderDropZone` still takes `onMoveToCompleted`, `modelContext` but no longer uses them (drops on headers disabled) | Simplify struct |
| **.gitignore** | `Secrets.xcconfig` is ignored; `*.xcconfig` does not match `Secrets.xcconfig.example` (no change needed) | — |

---

## Obsolete / dead code

- **`statusSections`** (BacklogListView) — A full List-based sectioned view (Now Playing, Backlog, etc.) that is **never referenced**. The app uses `scrollViewSectionedList` when showing sections and `List { singleSection }` when filtered. Removed along with:
  - **`statusSection(...)`** — Only used by `statusSections`.
  - **`deleteInSection(games:at:)`** — Only used by `statusSection`.
  - **`applyDrop(uuidStrings:targetStatus:onMoveToCompleted:)`** — Never called; drop logic lives in `RowDropModifier` and `CatalogRowDropDelegate`.

---

## Code smell / tidy

- **Debug prints** — Left in for diagnostics but should not ship. Gated with `#if DEBUG` in:
  - `BacklogListView.swift` (RowDropModifier)
  - `VGBApp.swift` (pushWidgetSummary)
  - `StoreConfiguration.swift` (container / migration)
- **SectionHeaderDropZone** — After disabling drops on headers, `onMoveToCompleted` and `modelContext` are unused; call sites still pass them. Simplified by removing those parameters from the struct and from `sectionBlock` (and the remaining `statusSection` call site before that code was removed).

---

## What’s in good shape

- **Layout**: App, Features (Backlog, Stats), Models, Services, VGBWidget are clear.
- **Game / GameStatus**: Clear ownership (user vs provider vs system); `displayPlatform` and rating logic are consistent.
- **Tests**: Unit tests for model, status, filter/sort, IGDB, sync; `displayPlatform` covered.
- **Secrets**: `Secrets.xcconfig` is in `.gitignore`; CI creates a placeholder.

---

## Files to keep

- All Swift under `VGB/`, `VGBWidget/`, `VGBTests/` are in use except the dead code above.
- `prompts/` and `user-preferences.md` are for Cursor/planning; keep or archive as you prefer.
- `LICENSE.md`, `.github/`, `docs/` are current.

---

## Optional follow-ups

- **Filter/sort extraction**: `displayedGames` in BacklogListView holds all filter/sort logic; optional to extract to a helper or service if more list screens appear.
- **BacklogListView size**: ~1000 lines; acceptable per prior audit; could split by MARK regions into extensions later if it grows.
