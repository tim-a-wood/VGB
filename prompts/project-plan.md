# VGB — Project Plan

**Purpose**: Ship v1 of the iOS game backlog tracker with full MVP scope (including live metadata). Timeline is flexible; aim for ~2 weeks but extend as needed to include metadata integration.

**Last updated**: 2026-02-13

---

## Development Timeline

**Current focus:** Phase 2 — live metadata integration

### Phase 1: Core backlog (foundation)
- [x] Create Xcode project structure for SwiftUI + SwiftData
- [x] Validate scaffold with `xcodebuild` (project lists + placeholder test passes)
- [x] Define `Game` model (title, platform, status, priorityPosition, releaseDate, estimatedHours, personalNotes, personalRating, metacriticScore, openCriticScore, genre, developer, coverImageURL, externalId, lastSyncedAt)
- [x] Build backlog list with empty state and drag-and-drop reorder (priority order)
- [x] Build add/edit game form (manual entry first)
- [x] Implement status updates (`Backlog`, `Playing`, `Completed`, `Dropped`)
- [x] Add core filters (status, platform, genre) and sort (priority, Metacritic, OpenCritic, release date)
- [x] Add test target scaffold (`VGBTests`) and placeholder test
- [x] Add lightweight unit tests for model + filter/sort behavior (41 tests, 0 failures)

### Phase 2: Live metadata integration
- [ ] Choose and integrate a game metadata provider (e.g., RAWG, IGDB); add API client and map response to `Game` fields
- [ ] Add search/lookup on add flow to prefill from provider
- [ ] Implement manual refresh (per game or full list) and persist `lastSyncedAt`
- [ ] Show last-synced / stale indicators in UI (e.g., “Updated 2 days ago” or subtle stale state)
- [ ] Handle offline and API errors gracefully (local data remains source of truth)

### Phase 3: Polish and ship
- [ ] Build simple stats screen (total, completed, completion rate)
- [ ] UX polish (validation, loading/empty states, accessibility pass)
- [ ] App icon, launch screen, store-ready screenshots
- [ ] Device testing (one physical iPhone + simulator), fix bugs, performance pass
- [ ] App Store metadata and submit v1

## Recommended next steps

1. Write unit tests for `Game` model defaults, status transitions, and filter/sort logic to close Phase 1.
2. Research and pick a game metadata API (RAWG, IGDB, or GiantBomb); set up API client.
3. Add search/lookup to the Add Game flow so users can prefill from the provider.
4. Implement manual refresh (per game + full list) and show stale indicators.
5. Reserve final stretch for stats screen, QA, store assets, and submission.

---

## Refactoring to prioritize (before or during implementation)

| Refactor | Why | Priority |
|----------|-----|----------|
| Keep feature modules small from day one | Easier to extend timeline without rewrites | High |
| Separate view state from persistence logic | Easier testing and bug fixes | High |
| Local model as source of truth; provider as enrichment | Sync and offline behavior stay predictable | High |
| Reusable filter/sort helpers | Reduces duplicate list logic | Medium |

---

## Testing strategy
- Unit tests:
  - `Game` model validation and defaults
  - Status transitions and edge cases
  - Filter/sort combinations
  - Metadata mapping from provider response to `Game` (and lastSyncedAt)
- Manual testing:
  - Metadata: search prefill, manual refresh, offline/API failure (local data intact, sensible error UI)
  - Add/edit/delete flows
  - State changes across all statuses
  - Empty state and first-run experience
  - Basic accessibility checks (Dynamic Type, VoiceOver labels on key controls)
- Pre-release checklist:
  - Simulator + physical device pass
  - Crash-free smoke test
  - App Store metadata and screenshots complete
