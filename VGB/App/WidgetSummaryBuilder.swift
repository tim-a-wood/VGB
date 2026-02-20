import Foundation
import SwiftData

/// Builds widget summary data from a list of games.
/// Shared by the main app (push to UserDefaults) and widget (fallback when UserDefaults empty).
enum WidgetSummaryBuilder {

    /// Builds summary fields from games for widget display.
    static func make(from games: [Game]) -> WidgetSummaryStorage.Summary {
        let nextUp = games.first { $0.status == .backlog }
        let playing = games.filter { $0.status == .playing }.sorted { $0.priorityPosition < $1.priorityPosition }
        let playingFirst = playing.first
        let genreStrings = games.compactMap(\.genre).filter { !$0.isEmpty }
        let radarData = RadarGenreCategories.completedCountsByCategory(from: genreStrings)
        let radarCounts = radarData.map(\.value)

        return WidgetSummaryStorage.Summary(
            nextUpTitle: nextUp?.title,
            nextUpPlatform: nextUp?.platform.isEmpty == false ? nextUp?.displayPlatform : nil,
            totalGames: games.count,
            completedGames: games.filter { $0.status == .completed }.count,
            playingCount: playing.count,
            playingFirstTitle: playingFirst?.title,
            playingFirstPlatform: playingFirst?.platform.isEmpty == false ? playingFirst?.displayPlatform : nil,
            radarGenreCounts: radarCounts
        )
    }
}
