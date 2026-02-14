# VGB — Project Features

**Last updated**: 2026-02-14

---

## MVP

- Game backlog list with local persistence
- Add/edit/delete game entries
- Status tracking: `Wishlist`, `Backlog`, `Playing`, `Completed`, `Dropped`
  - Wishlist: games you don't own yet or that aren't released; auto-badges games with a future release date as "Unreleased"
  - Lifecycle: Wishlist → Backlog → Playing → Completed / Dropped
- Core metadata per game:
  - Title (required)
  - Platform
  - Release Date
  - Priority Order (drag-and-drop ranked list, like a SCRUM backlog)
  - Estimated hours
  - Personal notes
  - IGDB aggregated critic score (fetched from IGDB, read-only)
  - Personal rating (0–100)
  - Cover art thumbnail (fetched from IGDB)
- Cover art thumbnails in backlog list rows
- Full cover art header in game detail view
- "Currently Playing" pinned section at top of backlog list
- Text search bar on backlog list (find games by name)
- Filter by status, platform, and genre
- **Live metadata**: integrate IGDB via Twitch OAuth2; fetch/prefill on add and support manual refresh; show last-synced / stale indicators so users know when data was updated
- Sort by priority (drag-and-drop rank), critic score, or release date
- Swipe actions on list rows for quick status changes
- Share a game via iOS share sheet
- "Completed" celebration animation when marking a game as completed
- Home screen widget (next-up game / quick stats)
- Dark mode polish (custom accent color, intentional color palette)
- Stats screen (dopamine-focused, charts):
  - **Hero:** Big completion % (circular progress ring) or "X games completed" with subtle animation on appear
  - **Status donut:** Wishlist / Backlog / Playing / Completed / Dropped (existing status colors); optional center label (e.g. completion %)
  - **Bar charts:** Games by status; by platform; by genre (top N)
  - **Quality block:** Average critic score for completed games; optional score distribution
  - **Radar chart (FM-style):** Axes = genres (or top N genres); value = completed count in that genre. Shows "where you've finished games" (e.g. strong in RPG, light in Sports). Single-user for MVP; post-release overlay friend's radar for comparison (social features).
- **Rankings page:** New tab/screen showing a ranking of all games that have a rating. Toggle between **user rating** (personal rating 0–100) and **critic rating** (IGDB); list sorted by the selected rating (highest first).
- Onboarding / first-launch walkthrough (2–3 screens)
- Empty state and simple first-use UX
- Basic accessibility and reliability pass before release

## Post Release

- **Social / comparison:** Compare stats and radar charts with friends (overlay friend's radar on yours; shared completion rates, etc.)
- Community rating (average VGB user rating; requires backend)
- Browse and import from IGDB (popular/trending/new releases discovery)
- Additional meta data e.g. Related Games (Sequels, Prequels, Remakes, Spiritual Ancestors, etc.)
- Rankings for completed games (all time, by year, by genre etc.)
- Playtime stats (other stats?)
- iCloud sync across devices
- Reminders and nudges for in-progress games
- Advanced analytics (time-to-complete, monthly trend)
- Smart suggestions (next game to play based on priority/time)
- Import/export and backup options
- Optional social features (share progress snapshots)
- Gameification (e.g., points for games completed or 100%, leaderboards, etc.)
- OpenCritic score integration (second API source for critic scores)
- Metacritic score integration (conditional — only if revenue and user feedback justify the $149/month RAWG commercial API cost)
- Monetization experiments (ads and/or premium unlock), only after usage validation
