import Foundation
import SwiftData

/// Handles syncing provider-sourced game fields from IGDB.
///
/// Two modes:
/// - **Auto-refresh**: on app foreground, refreshes all games whose `lastSyncedAt`
///   is older than `staleThreshold` (default 7 days).
/// - **Manual refresh**: refresh a single game on demand.
///
/// Only provider-sourced fields are updated; user-owned fields are never touched.
@MainActor
final class GameSyncService {

    static let shared = GameSyncService()

    /// Games older than this are considered stale and will auto-refresh.
    let staleThreshold: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    /// Whether a background sync is currently running.
    private(set) var isSyncing = false

    /// Number of games refreshed in the last auto-sync pass.
    private(set) var lastSyncCount = 0

    private init() {}

    // MARK: - Auto-refresh stale games

    /// Refreshes all games with an `externalId` whose data is stale.
    /// Call this when the app comes to the foreground.
    /// - Returns: Games that were in Wishlist, unreleased, and are now released (user may want to move to Backlog).
    func refreshStaleGames(in context: ModelContext) async -> [Game] {
        let cutoff = Date().addingTimeInterval(-staleThreshold)

        let descriptor = FetchDescriptor<Game>(
            predicate: #Predicate<Game> { game in
                game.externalId != nil
            }
        )

        guard let allLinkedGames = try? context.fetch(descriptor) else { return [] }

        let staleGames = allLinkedGames.filter { game in
            guard let synced = game.lastSyncedAt else { return true }
            return synced < cutoff
        }

        guard !staleGames.isEmpty else { return [] }

        return await refreshGames(staleGames, in: context)
    }

    /// Refreshes metadata from IGDB for all games that have an `externalId`.
    /// Use for manual "refresh all" from the Game Catalog.
    /// - Returns: Games that were in Wishlist, unreleased, and are now released (user may want to move to Backlog).
    func refreshAllGames(in context: ModelContext) async -> [Game] {
        let descriptor = FetchDescriptor<Game>(
            predicate: #Predicate<Game> { game in
                game.externalId != nil
            }
        )
        guard let allLinked = try? context.fetch(descriptor), !allLinked.isEmpty else { return [] }
        return await refreshGames(allLinked, in: context)
    }

    private func refreshGames(_ games: [Game], in context: ModelContext) async -> [Game] {
        isSyncing = true
        var refreshed = 0
        var releasedFromWishlist: [Game] = []

        let gameIds = games.compactMap { game -> Int? in
            guard let externalId = game.externalId else { return nil }
            return Int(externalId)
        }
        guard !gameIds.isEmpty else {
            isSyncing = false
            return []
        }

        let idToGame = Dictionary(uniqueKeysWithValues: games.compactMap { game -> (Int, Game)? in
            guard let externalId = game.externalId, let igdbId = Int(externalId) else { return nil }
            return (igdbId, game)
        })

        do {
            let results = try await IGDBClient.shared.fetchGames(ids: gameIds)
            for igdb in results {
                guard let game = idToGame[igdb.id] else { continue }
                let wasUnreleasedWishlist = game.isUnreleased && game.status == .wishlist
                applyIGDBData(igdb, to: game)
                refreshed += 1
                if wasUnreleasedWishlist && !game.isUnreleased {
                    releasedFromWishlist.append(game)
                }
            }
        } catch {
            // Fallback: fetch per-game with limited concurrency to avoid overwhelming the API
            let concurrentLimit = 5
            var index = 0
            while index < games.count {
                let chunkIds = games[index ..< min(index + concurrentLimit, games.count)].compactMap { game -> Int? in
                    guard let externalId = game.externalId, let igdbId = Int(externalId) else { return nil }
                    return igdbId
                }
                await withTaskGroup(of: (Int, IGDBGame?).self) { group in
                    for igdbId in chunkIds {
                        group.addTask {
                            let updated = try? await IGDBClient.shared.fetchGame(id: igdbId)
                            return (igdbId, updated)
                        }
                    }
                    for await (igdbId, updated) in group {
                        guard let updated, let game = idToGame[igdbId] else { continue }
                        let wasUnreleasedWishlist = game.isUnreleased && game.status == .wishlist
                        applyIGDBData(updated, to: game)
                        refreshed += 1
                        if wasUnreleasedWishlist && !game.isUnreleased {
                            releasedFromWishlist.append(game)
                        }
                    }
                }
                index += concurrentLimit
            }
        }

        lastSyncCount = refreshed
        isSyncing = false
        return releasedFromWishlist
    }

    // MARK: - Manual single-game refresh

    /// Refreshes a single game from IGDB. Returns true on success.
    @discardableResult
    func refreshGame(_ game: Game) async -> Bool {
        guard let externalId = game.externalId, let igdbId = Int(externalId) else {
            return false
        }

        do {
            guard let updated = try await IGDBClient.shared.fetchGame(id: igdbId) else {
                return false
            }
            applyIGDBData(updated, to: game)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Apply IGDB data to Game

    /// Maps IGDB response fields onto a Game's provider-sourced properties.
    /// User-owned fields (status, priority, notes, personal rating, estimated hours) are untouched.
    private func applyIGDBData(_ igdb: IGDBGame, to game: Game) {
        if let name = igdb.name {
            game.title = name
        }
        game.platform = igdb.platformNames.joined(separator: ", ")
        game.coverImageURL = igdb.coverURL
        game.genre = igdb.primaryGenre
        game.developer = igdb.developerName
        game.releaseDate = igdb.releaseDate
        game.igdbRating = igdb.totalRating.map { Int($0) }
        game.lastSyncedAt = Date()
        game.updatedAt = Date()
    }

    // MARK: - Helpers

    /// Whether a game's data is considered stale.
    func isStale(_ game: Game) -> Bool {
        guard game.externalId != nil else { return false } // manual entries aren't stale
        guard let synced = game.lastSyncedAt else { return true }
        return Date().timeIntervalSince(synced) > staleThreshold
    }
}
