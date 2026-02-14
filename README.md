# VGB

VGB is an iOS app for gamers to track and prioritize their video game backlog.

## Current status

- **Phase 1 features complete** — backlog list, add/edit, status management, filters, sorting, drag-and-drop reorder
- Unit tests and Phase 2 (live metadata) up next
- SwiftUI app target: `VGB` | Test target: `VGBTests` | Shared scheme: `VGB`

## Project structure

- `VGB/App/` — app entry point (`VGBApp.swift`) and resources (`Info.plist`)
- `VGB/Models/` — domain models (`Game.swift`, `GameStatus.swift`)
- `VGB/Features/Backlog/` — backlog list, add game form, game detail view
- `VGBTests/Unit/` — unit tests
- `project.yml` — XcodeGen project spec
- `prompts/` — planning and status docs

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
xcodebuild test -project VGB.xcodeproj -scheme VGB -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' -derivedDataPath .derivedData
```

## Project generation

The Xcode project is generated from `project.yml` (XcodeGen spec).

If `xcodegen` is installed:

```bash
xcodegen generate
```
