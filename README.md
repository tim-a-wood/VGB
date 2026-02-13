# VGB

VGB is an iOS app for gamers to track and prioritize their video game backlog.

## Current status

- Project scaffold is in place (`VGB.xcodeproj`)
- SwiftUI app target: `VGB`
- Unit test target: `VGBTests`
- Shared scheme for CI: `VGB`

## Project structure

- `VGB/App/` — app entry and shared app resources
- `VGB/Features/` — feature UI modules (currently backlog)
- `VGBTests/Unit/` — unit tests
- `project.yml` — XcodeGen project spec

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
