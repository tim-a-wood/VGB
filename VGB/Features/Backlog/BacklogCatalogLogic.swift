import Foundation
import SwiftData

// MARK: - Sort Mode

enum SortMode: String, CaseIterable, Identifiable {
    case priority    = "Priority"
    case criticScore = "Critic Score"
    case releaseDate = "Release Date"

    var id: String { rawValue }
}

// MARK: - Sectioned Display

/// Result of applying search, filters, sort, and sectioning to a list of games.
/// Used by the catalog view to show either sectioned (Now Playing, Backlog, …) or flat list.
struct BacklogSectionedDisplay {
    var displayed: [Game]
    var nowPlaying: [Game]
    var backlog: [Game]
    var wishlist: [Game]
    var completed: [Game]
    var dropped: [Game]
}

// MARK: - Catalog Logic (pure, testable)

/// Pure filter/sort/section logic for the backlog catalog.
/// Single source of truth for "what to show"; no SwiftUI or ModelContext.
enum BacklogCatalogLogic {

    /// Applies search, filters, sort, and buckets games by status in one pass.
    static func sectionedDisplay(
        games: [Game],
        searchText: String,
        filterStatus: GameStatus?,
        filterPlatform: String?,
        filterGenre: String?,
        sortMode: SortMode
    ) -> BacklogSectionedDisplay {
        var result = games

        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { $0.title.lowercased().contains(query) }
        }
        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }
        if let platform = filterPlatform {
            result = result.filter { game in
                Game.platformComponents(game.platform).map { Game.displayPlatform(from: $0) }.contains(platform)
            }
        }
        if let genre = filterGenre {
            result = result.filter { $0.genre == genre }
        }
        switch sortMode {
        case .priority:
            break
        case .criticScore:
            result.sort { ($0.igdbRating ?? -1) > ($1.igdbRating ?? -1) }
        case .releaseDate:
            result.sort { ($0.releaseDate ?? .distantPast) > ($1.releaseDate ?? .distantPast) }
        }

        var nowPlaying: [Game] = []
        var backlog: [Game] = []
        var wishlist: [Game] = []
        var completed: [Game] = []
        var dropped: [Game] = []
        nowPlaying.reserveCapacity(result.count / 5)
        backlog.reserveCapacity(result.count / 5)
        wishlist.reserveCapacity(result.count / 5)
        completed.reserveCapacity(result.count / 5)
        dropped.reserveCapacity(result.count / 5)
        for game in result {
            switch game.status {
            case .playing: nowPlaying.append(game)
            case .backlog: backlog.append(game)
            case .wishlist: wishlist.append(game)
            case .completed: completed.append(game)
            case .dropped: dropped.append(game)
            }
        }
        let sortByRatingThenUpdated: (Game, Game) -> Bool = { g1, g2 in
            let r1 = g1.personalRating ?? -1
            let r2 = g2.personalRating ?? -1
            if r1 != r2 { return r1 > r2 }
            return g1.updatedAt > g2.updatedAt
        }
        completed.sort(by: sortByRatingThenUpdated)
        dropped.sort(by: sortByRatingThenUpdated)

        return BacklogSectionedDisplay(
            displayed: result,
            nowPlaying: nowPlaying,
            backlog: backlog,
            wishlist: wishlist,
            completed: completed,
            dropped: dropped
        )
    }

    /// Unique display platforms across games (for filter menu).
    static func platforms(from games: [Game]) -> [String] {
        let all = games
            .flatMap { Game.platformComponents($0.platform) }
            .map { Game.displayPlatform(from: $0) }
            .filter { !$0.isEmpty }
        return Array(Set(all)).sorted()
    }

    /// Unique genres across games (for filter menu).
    static func genres(from games: [Game]) -> [String] {
        Array(Set(games.compactMap(\.genre).filter { !$0.isEmpty })).sorted()
    }

    /// Status counts in one pass (for summary row).
    static func statusCounts(from games: [Game]) -> [GameStatus: Int] {
        var counts: [GameStatus: Int] = [.playing: 0, .backlog: 0, .wishlist: 0, .completed: 0, .dropped: 0]
        for game in games {
            counts[game.status, default: 0] += 1
        }
        return counts
    }

    /// Whether to show status sections (no status filter and no search).
    static func showStatusSections(filterStatus: GameStatus?, searchText: String) -> Bool {
        filterStatus == nil && searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
