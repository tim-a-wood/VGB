# VGB — Project Plan

**Purpose**: Ship v1 of the iOS game backlog tracker with full MVP scope (including live metadata). Timeline is flexible; aim for ~2 weeks but extend as needed to include metadata integration.

**Last updated**: 2026-02-14

---

## Development Timeline

**Current focus:** Phase 4 — Final polish and ship

### Phase 1: Core backlog (foundation)
- [x] Create Xcode project structure for SwiftUI + SwiftData
- [x] Validate scaffold with `xcodebuild` (project lists + placeholder test passes)
- [x] Define `Game` model (title, platform, status, priorityPosition, releaseDate, estimatedHours, personalNotes, personalRating, metacriticScore, openCriticScore, genre, developer, coverImageURL, externalId, lastSyncedAt)
- [x] Build backlog list with empty state and drag-and-drop reorder (priority order)
- [x] Build add/edit game form (manual entry first)
- [x] Implement status updates (`Backlog`, `Playing`, `Completed`, `Dropped`)
- [x] Add core filters (status, platform, genre) and sort (priority, IGDB critic score, release date)
- [x] Add test target scaffold (`VGBTests`) and placeholder test
- [x] Add lightweight unit tests for model + filter/sort behavior (41 tests, 0 failures)

### Phase 2: Live metadata integration (IGDB via Twitch OAuth2)
- [x] Set up Twitch OAuth2 client credentials flow (token fetch + refresh)
- [x] Build IGDB API client (search games, fetch game details); map response to `Game` fields
- [x] Update `Game` model: rename `metacriticScore` → `igdbRating`, remove `openCriticScore` (post-release)
- [x] Add search/lookup on add flow to prefill from IGDB
- [x] Auto-refresh stale games on app foreground (>7 days) + manual per-game refresh button
- [x] Show last-synced / stale indicators in UI (green checkmark vs orange warning)
- [x] Handle offline and API errors gracefully (local data remains source of truth)
- [x] Add unit tests for API response mapping and sync logic (25 new tests; 66 total, 0 failures)

### Phase 3: Enhanced features (bonus — ahead of schedule)
- [x] Add cover art thumbnails to backlog list rows (`AsyncImage`)
- [x] Add text search bar to backlog list (`.searchable` modifier)
- [x] Add "Currently Playing" pinned section at top of backlog list
- [x] Add `Wishlist` status (5th lifecycle state for unowned/unreleased games); auto-badge games with future release dates as "Unreleased"
- [x] Show full cover art header in `GameDetailView`
- [x] Add share game via iOS share sheet
- [x] Add "Completed" celebration (confetti/congratulatory moment on status change)
- [x] Dark mode polish (custom accent color, asset catalog, intentional color palette)
- [x] Add swipe actions on list rows (quick status changes without opening detail)
- [x] Build home screen widget (next-up game / quick stats; small + medium sizes)

### Phase 4: Polish and ship
- [x] Build stats screen (hero ring, status donut, bar charts by status/platform/genre, avg critic for completed, radar chart by genre)
- [x] Add **Rankings** page: ranked list of all RATED games (user rating or critic rating — toggleable)
- [x] Onboarding / first-launch walkthrough (2–3 screens explaining the core loop)
- [x] UX polish (validation, loading/empty states, accessibility pass)
- [x] App icon, launch screen
- [ ] Store-ready screenshots (use `scripts/capture-screenshot.sh` + `screenshots/README.md`)
- [ ] Device testing (one physical iPhone + simulator), fix bugs, performance pass
- [ ] App Store metadata and submit v1

## Recommended next steps

1. App icon and launch screen
2. Device testing (physical iPhone + simulator), fix bugs, performance pass
3. App Store metadata and submit v1

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
  - IGDB API response mapping to `Game` (and lastSyncedAt)
  - Twitch OAuth2 token refresh logic
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
