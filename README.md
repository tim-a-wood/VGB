# VGB (Checkpoint)

VGB is an iOS app for gamers to track and prioritize their video game backlog. Display name: **Checkpoint**.

## Current status

- **Phases 1–4 complete** — backlog, IGDB metadata, stats, rankings, onboarding, widget
- **Next:** App icon, device testing, App Store submission
- SwiftUI app target: `VGB` | Widget: `VGBWidgetExtension` | Test target: `VGBTests` | Shared scheme: `VGB`

## Project structure

- `VGB/App/` — app entry, StoreConfiguration, WidgetSummaryStorage
- `VGB/Models/` — `Game.swift`, `GameStatus.swift`, `GameStatus+Color.swift`
- `VGB/Features/Backlog/` — list, add game, game detail, celebration overlay
- `VGB/Features/Stats/` — stats view, radar chart, genre categories
- `VGB/Features/Rankings/` — rankings by user/critic rating
- `VGB/Features/Onboarding/` — first-launch walkthrough
- `VGB/Services/` — IGDB client, sync, Twitch auth
- `VGBWidget/` — home screen widget (small + medium)
- `VGBTests/Unit/` — model, status, filter/sort, IGDB, sync tests
- `prompts/` — planning and status docs
- `docs/` — codebase audit

See:
- `prompts/project-overview.md` for product direction
- `prompts/project-features.md` for MVP vs post-release scope
- `prompts/project-plan.md` for timeline/tasks
- `prompts/project-status.md` for implementation progress

## Open in Xcode

```bash
open VGB.xcodeproj
```

## Build/test from CLI

```bash
xcodebuild -list -project VGB.xcodeproj
xcodebuild -showdestinations -project VGB.xcodeproj -scheme VGB
xcodebuild test -project VGB.xcodeproj -scheme VGB -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO
```

## Project generation

`project.yml` is an XcodeGen spec but **outdated** (missing widget, stats, rankings). The `VGB.xcodeproj` is the source of truth. Do not run `xcodegen generate` without updating `project.yml` first.
