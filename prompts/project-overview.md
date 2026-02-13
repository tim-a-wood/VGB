# VGB — Project Brief

## Concept
VGB is an iOS app for gamers to track their video game backlog and focus on finishing what they already own. v1 ships with live metadata from an external provider so cover art, release dates, and scores stay up to date.

## Core Mechanic
- Keep a single personal backlog.
- Move games across a simple lifecycle: `Backlog` -> `Playing` -> `Completed` -> `Dropped`.
- Reduce decision fatigue with filters, sorting, and drag-and-drop priority order.
- Track metadata (platform, release date, estimated hours, notes, ratings) with optional refresh from the provider; show when data was last synced.

## Technical Platform
- **Platform**: iOS (iPhone/iPad)
- **Framework**: SwiftUI + SwiftData
- **Development approach**: Coding agent first (Claude Code, Cursor, Codex)
- **Version control**: Git + GitHub
- **Testing**: iOS Simulator + one physical iPhone; unit tests for model and filtering logic; CI on push/PR.

## Monetization Strategy
- **Launch approach**: Free v1 with no ads to maximize speed and reduce integration risk.
- **Post-release option**: Introduce ads or premium unlock only after baseline usage/retention data.
- **Optional**: Premium add-ons (advanced analytics, cloud sync) after v1 validation.


## Required Setup
See setup checklist in `project-plan.md`.

### Software (Total: ~$20-40/month)
- Xcode (free)
- Apple Developer Account ($99/year)
- Cursor or Claude Code ($0-20/month)
- GitHub account (free tier)

## Success Metrics
- Learn iOS app deployment and maintenance strategy through a complete ship cycle.

### Goals
- Ship v1.0 (2-week target is flexible; MVP includes live metadata integration)
- Get 100+ downloads in first month
- Validate demand for a backlog-focused utility app
- Iterate based on user feedback
- Learn iOS development + App Store process
- Build foundation for future apps
- $25-50/month revenue
- A reusable framework for future apps

## Developer Background
- Software developer in aerospace (safety-critical systems, DO-178, model-based design)
- Minimal prior iOS development experience
- Goal: One-man side business, no employees/publishers/customer interaction
- Philosophy: Coding agent first development
- Constraints: Build in evenings/weekends as side gig

## Business Model
- Solo side hustle for bonus income
- Apple handles all payments, refunds, infrastructure
- Minimal human interaction required
- "Build and forget" after launch (update 2-4x/year for iOS compatibility)

---

**Status and timeline:** See `.cursor/prompts/project-status.md` and `.cursor/prompts/project-plan.md`.

## UI/UX
- Fast add flow: search/lookup from metadata provider to prefill, minimal required fields
- One-screen backlog list with clear status badges and drag-and-drop reorder
- Manual refresh and last-synced / stale indicators for metadata
- Simple filters and sort controls
- Lightweight stats view for motivation (completed count, completion rate)
