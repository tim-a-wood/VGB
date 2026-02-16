# Checkpoint — Ship Checklist

Pre-release checklist for App Store submission.

---

## 1. Screenshots

**Required:** 1–10 screenshots per device size. Apple accepts 6.9" (1320 × 2868) and scales down.

### Capture

```bash
# Option A: Automated (builds, seeds, captures all three)
./scripts/capture-app-store-screenshots.sh

# Option B: Manual per screen
# 1. Run app in Simulator (iPhone 16 Pro Max)
# 2. Navigate to screen, run:
./scripts/capture-screenshot.sh 1   # Game Catalog
./scripts/capture-screenshot.sh 2   # Rankings
./scripts/capture-screenshot.sh 3   # Stats
```

### Suggested screens

| # | Screen | Filename | Notes |
|---|--------|----------|-------|
| 1 | Game Catalog | `01-game-catalog.png` | Main backlog with games |
| 2 | Rankings | `02-rankings.png` | Top-rated games |
| 3 | Stats | `03-stats.png` | Charts and gamer profile |
| 4 | Game Detail | `04-game-detail.png` | Optional |
| 5 | Add Game / Search | `05-add-game.png` | Optional |

**Tip:** Seed demo data (`-SeedDemoData`) before capturing so lists look full.

---

## 2. App Store Metadata

### App name
**Checkpoint**

### Subtitle (30 chars max)
```
Track your game backlog
```

### Description (4000 chars max)

```
Checkpoint helps you organize and conquer your video game backlog.

• CATALOG — Add games manually or search IGDB for instant metadata, cover art, and critic scores
• STATUS — Wishlist → Backlog → Playing → Completed: track where each game stands
• PRIORITIES — Drag and drop to rank what to play next
• STATS — Completion rate, genre radar chart, and ratings overview
• RANKINGS — Sort by your personal rating or critic score

Features:
• Search thousands of games via IGDB (Twitch)
• Cover art thumbnails and full metadata
• Filter and sort by status, platform, genre
• Swipe to move games between statuses
• Home screen widget: currently playing + gamer profile
• Dark mode

Your data stays on device. No account required to get started.
```

### Keywords (100 chars max, comma-separated)
```
backlog,games,video games,IGDB,tracker,organize,completion,stats,gaming
```

### What’s New (v1.0)
```
Initial release. Track your game backlog with IGDB metadata, stats, and a home screen widget.
```

### Category
**Primary:** Games  
**Secondary:** Entertainment (optional)

### Age rating
**4+** (no objectionable content)

---

## 3. Privacy & Compliance

- [ ] **Privacy Policy URL** — Required if app collects data. Checkpoint stores data locally; if no collection, a minimal policy or “no data collected” note may suffice per Apple’s guidance.
- [ ] **App Privacy** — Declare no data collection if accurate.
- [ ] **Export compliance** — No encryption beyond HTTPS; typically “No” for export documentation.

---

## 4. Technical

- [ ] **Bundle ID** — `com.timwood.vgb` (or your chosen ID)
- [ ] **Version** — `1.0` (CFBundleShortVersionString)
- [ ] **Build** — `1` (CFBundleVersion); increment for each upload
- [ ] **Twitch/IGDB** — Secrets in `Secrets.xcconfig` (not in repo)
- [ ] **Signing** — Distribution certificate + provisioning profile for App Store

---

## 5. Pre-submission QA

- [ ] Run on physical iPhone
- [ ] Test widget (add/remove, data refresh)
- [ ] Add game via manual entry
- [ ] Add game via IGDB search (requires network)
- [ ] Filter, sort, drag reorder
- [ ] Mark game completed (celebration)
- [ ] Share game
- [ ] Stats and Rankings with/without data
- [ ] Onboarding flow
- [ ] Accessibility: VoiceOver, Dynamic Type
- [ ] Offline: catalog works; IGDB search fails gracefully

---

## 6. App Store Connect

1. Create app record
2. Upload build (Xcode → Archive → Distribute)
3. Add screenshots per device size
4. Fill metadata (name, subtitle, description, keywords)
5. Set age rating, category
6. Submit for review
