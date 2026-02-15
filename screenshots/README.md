# App Store Screenshots

Screenshots for App Store Connect. Apple requires 1–10 screenshots per device size.

## Required sizes (iPhone)

| Device | Portrait | Notes |
|--------|----------|-------|
| 6.9" (iPhone 16 Pro Max) | 1320 × 2868 | Primary; Apple scales down |
| 6.5" | 1284 × 2778 | Optional |
| 6.3" (iPhone 16 Pro) | 1206 × 2622 | Optional |
| 5.5" | 1242 × 2208 | Optional |

**Tip:** Providing the largest size (6.9") is enough; Apple scales for smaller devices.

## How to capture

### Option A: Capture script (recommended)

1. Build and run the app in the simulator (iPhone 16 Pro Max recommended).
2. Navigate to the screen you want to capture.
3. Run:
   ```bash
   ./scripts/capture-screenshot.sh 1
   ```
4. Repeat for each screen (use 2, 3, 4… for filenames).
5. Screenshots save to `screenshots/`.

### Option B: Launch with tab (automated)

With the simulator booted and the app installed, **seed demo data once** (50+ AAA games) so screenshots show a full catalog:

```bash
# One-time: mark onboarding complete and seed games
xcrun simctl spawn booted defaults write com.timwood.vgb VGB.hasCompletedOnboarding -bool true
xcrun simctl launch booted com.timwood.vgb -SeedDemoData
# Wait a few seconds, then capture (launch without -SeedDemoData):
```

Then launch on a specific tab and capture:

```bash
xcrun simctl terminate booted com.timwood.vgb 2>/dev/null
xcrun simctl launch booted com.timwood.vgb -ScreenshotTab 0   # 0=Catalog, 1=Rankings, 2=Stats
sleep 3
xcrun simctl io booted screenshot screenshots/01-game-catalog.png
```

### Option C: Manual

1. Run the app in Simulator (iPhone 16 Pro Max).
2. Navigate to the screen.
3. Press **⌘S** in the Simulator window to save a screenshot to Desktop.
4. Copy to `screenshots/` and rename as needed.

### Suggested screens to capture

1. **Game Catalog** — Main backlog view with games
2. **Game Detail** — A game’s detail page
3. **Stats** — Stats screen with charts
4. **Rankings** — Rankings view
5. **Add Game** — Search / add flow (optional)

## File naming

Use descriptive names for App Store Connect, e.g.:
- `01-game-catalog.png`
- `02-game-detail.png`
- `03-stats.png`
- `04-rankings.png`
