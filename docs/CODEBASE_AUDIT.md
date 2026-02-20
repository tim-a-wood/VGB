# VGB — Codebase Audit

**Date**: 2026-02-20 (updated)

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
- **Tests**: Unit tests for model, status, filter/sort, IGDB, sync, GenreResolver, RadarGenreCategories, WidgetSummaryBuilder.
- **Secrets**: `Secrets.xcconfig` in `.gitignore`; CI creates placeholder.
- **Documentation**: README, prompts/, docs/ up to date.

---

## Files

- **Swift**: All under `VGB/`, `VGBWidget/`, `VGBTests/` are in use.
- **prompts/**: Planning docs; `prompts/codebase-audit.md` removed (duplicate of this file).
- **user-preferences.md**: Cursor agent preferences; keep.
- **project.yml**: Outdated (no widget, stats, rankings). `VGB.xcodeproj` is source of truth.

---

## Security (2026-02-20)

- **IGDB query**: User search text is sanitized (backslash and double-quote escaped) before inclusion in Apicalypse query body to prevent query injection or malformed requests.
- **Secrets**: Twitch client ID/secret read from `Bundle.main` (injected via `Secrets.xcconfig`); not stored in repo. Tokens kept in memory only in `TwitchAuthManager`.
- **Cover image URLs**: Sourced from IGDB API or demo data (fixed domain); no arbitrary user-supplied URLs rendered.
- **Data validation**: Personal rating and estimated hours clamped in UI (0–100, ≥0).

## Performance (2026-02-20)

- **Sync fallback**: When batch IGDB fetch fails, per-game refresh now runs with limited concurrency (5 at a time) instead of strictly sequential, reducing total wait for large libraries.
- **Image prefetch**: `URLSessionConfiguration.httpMaximumConnectionsPerHost = 4` caps concurrent cover-image requests per host to avoid connection thrashing and potential throttling.
- **Stats/backlog**: Single-pass aggregation and reserved array capacity where appropriate; no change needed for typical library sizes.

## Optional follow-ups

- **Filter/sort extraction**: `displayedGames` in BacklogListView holds all filter/sort logic; optional to extract if more list screens appear.
- **BacklogListView size**: ~930 lines; acceptable; could split by MARK regions if it grows.
