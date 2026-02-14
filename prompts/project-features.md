# VGB — Project Features

**Last updated**: 2026-02-13

---

## MVP

- Game backlog list with local persistence
- Add/edit/delete game entries
- Status tracking: `Backlog`, `Playing`, `Completed`, `Dropped`
- Core metadata per game:
  - Title (required)
  - Platform
  - Release Date
  - Priority Order (drag-and-drop ranked list, like a SCRUM backlog)
  - Estimated hours
  - Personal notes
  - Personal rating (0–100)
  - Metacritic score (fetched from provider, read-only)
  - OpenCritic score (fetched from provider, read-only)
- Filter by status and platform
- **Live metadata**: integrate a game metadata provider (e.g., RAWG, IGDB); fetch/prefill on add and support manual refresh; show last-synced / stale indicators so users know when data was updated
- Sort by priority (drag-and-drop rank), rating (Metacritic or OpenCritic), or release date
- Basic stats screen:
  - Total games
  - Completed games
  - Completion rate
- Empty state and simple first-use UX
- Basic accessibility and reliability pass before release

## Post Release

- Community rating (average VGB user rating; requires backend)
- Additional meta data e.g. Related Games (Sequels, Prequels, Remakes, Spiritual Ancestors, etc.)
- Rankings for completed games (all time, by year, by genre etc.)
- Playtime stats (other stats?)
- iCloud sync across devices
- Reminders and nudges for in-progress games
- Advanced analytics (time-to-complete, monthly trend)
- Smart suggestions (next game to play based on priority/time)
- Wishlist and "owned vs unowned" separation
- Import/export and backup options
- Optional social features (share progress snapshots)
- Gameification (e.g., points for games completed or 100%, leaderboards, etc.)
- Monetization experiments (ads and/or premium unlock), only after usage validation
