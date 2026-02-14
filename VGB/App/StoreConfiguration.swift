import Foundation
import SwiftData

/// Shared SwiftData store configuration so the main app and widget extension use the same database (App Group).
enum StoreConfiguration {

    /// App Group identifier — must match the entitlement in both the app and widget targets.
    static let appGroupIdentifier = "group.com.timwood.vgb"

    /// URL for the SwiftData store inside the App Group container.
    static var sharedStoreURL: URL? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            print("[VGB Store] App Group container is nil — identifier: \(appGroupIdentifier)")
            return nil
        }
        let url = container.appending(path: "Library/Application Support/default.store")
        print("[VGB Store] Shared store URL: \(url.path)")
        return url
    }

    /// Creates a ModelContainer that uses the shared App Group store, or the default location if the app group is unavailable (e.g. simulator without entitlements).
    @MainActor
    static func sharedContainer() throws -> ModelContainer {
        if let url = sharedStoreURL {
            print("[VGB Store] Using App Group store at: \(url.path)")
            let parent = url.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: parent.path) {
                try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
                print("[VGB Store] Created parent directory for store")
            }
            let config = ModelConfiguration(url: url)
            let container = try ModelContainer(for: Game.self, configurations: config)
            migrateFromLegacyStoreIfNeeded(into: container)
            let count = (try? container.mainContext.fetch(FetchDescriptor<Game>()).count) ?? 0
            print("[VGB Store] sharedContainer() opened — game count: \(count)")
            return container
        }
        print("[VGB Store] No App Group URL — using default container (widget will not see this data)")
        return try ModelContainer(for: Game.self)
    }

    /// One-time migration: if the shared store is empty, copy games from the default (legacy) store.
    @MainActor
    private static func migrateFromLegacyStoreIfNeeded(into sharedContainer: ModelContainer) {
        let sharedContext = sharedContainer.mainContext
        let descriptor = FetchDescriptor<Game>()
        let sharedCount = (try? sharedContext.fetch(descriptor).count) ?? 0
        guard sharedCount == 0 else {
            print("[VGB Store] Migration skipped — shared store already has \(sharedCount) games")
            return
        }
        guard let legacyContainer = try? ModelContainer(for: Game.self),
              let legacyGames = try? legacyContainer.mainContext.fetch(descriptor),
              !legacyGames.isEmpty else {
            print("[VGB Store] Migration skipped — no legacy store or legacy empty")
            return
        }
        print("[VGB Store] Migrating \(legacyGames.count) games from legacy store to App Group store")
        for old in legacyGames {
            let newGame = Game(title: old.title, platform: old.platform, status: old.status, priorityPosition: old.priorityPosition)
            newGame.estimatedHours = old.estimatedHours
            newGame.personalNotes = old.personalNotes
            newGame.personalRating = old.personalRating
            newGame.releaseDate = old.releaseDate
            newGame.coverImageURL = old.coverImageURL
            newGame.igdbRating = old.igdbRating
            newGame.genre = old.genre
            newGame.developer = old.developer
            newGame.externalId = old.externalId
            newGame.lastSyncedAt = old.lastSyncedAt
            newGame.createdAt = old.createdAt
            newGame.updatedAt = old.updatedAt
            sharedContext.insert(newGame)
        }
        try? sharedContext.save()
        print("[VGB Store] Migration complete — saved \(legacyGames.count) games to shared store")
    }
}
