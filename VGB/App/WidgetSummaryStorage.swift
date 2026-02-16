import Foundation
import os

private let summaryLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.timwood.vgb",
    category: "WidgetSummary"
)

/// Widget summary data shared via App Group UserDefaults so the widget can display it
/// even when the extension cannot access the same SwiftData store.
enum WidgetSummaryStorage {

    private static let suiteName = StoreConfiguration.appGroupIdentifier
    private static let keyNextUpTitle = "widget_nextUpTitle"
    private static let keyNextUpPlatform = "widget_nextUpPlatform"
    private static let keyTotalGames = "widget_totalGames"
    private static let keyCompletedGames = "widget_completedGames"
    private static let keyPlayingCount = "widget_playingCount"
    private static let keyPlayingFirstTitle = "widget_playingFirstTitle"
    private static let keyPlayingFirstPlatform = "widget_playingFirstPlatform"
    private static let keyRadarGenreCounts = "widget_radarGenreCounts"

    struct Summary {
        let nextUpTitle: String?
        let nextUpPlatform: String?
        let totalGames: Int
        let completedGames: Int
        let playingCount: Int
        let playingFirstTitle: String?
        let playingFirstPlatform: String?
        /// Six genre category counts for the radar chart (same order as RadarGenreCategories).
        let radarGenreCounts: [Double]
    }

    static func write(
        nextUpTitle: String?,
        nextUpPlatform: String?,
        totalGames: Int,
        completedGames: Int,
        playingCount: Int,
        playingFirstTitle: String? = nil,
        playingFirstPlatform: String? = nil,
        radarGenreCounts: [Double] = []
    ) {
        summaryLogger.debug("write() suiteName=\(suiteName)")
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            summaryLogger.error("write() FAILED — UserDefaults(suiteName:) returned nil")
            return
        }
        defaults.set(nextUpTitle, forKey: keyNextUpTitle)
        defaults.set(nextUpPlatform, forKey: keyNextUpPlatform)
        defaults.set(totalGames, forKey: keyTotalGames)
        defaults.set(completedGames, forKey: keyCompletedGames)
        defaults.set(playingCount, forKey: keyPlayingCount)
        defaults.set(playingFirstTitle, forKey: keyPlayingFirstTitle)
        defaults.set(playingFirstPlatform, forKey: keyPlayingFirstPlatform)
        let sixCounts = (radarGenreCounts + [Double](repeating: 0, count: 6)).prefix(6).map { $0 }
        defaults.set(sixCounts, forKey: keyRadarGenreCounts)
        defaults.synchronize()
        summaryLogger.debug("write() OK — totalGames=\(totalGames) nextUpTitle=\(nextUpTitle ?? "nil") playingFirst=\(playingFirstTitle ?? "nil")")
    }

    static func read() -> Summary? {
        summaryLogger.debug("read() suiteName=\(suiteName)")
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            summaryLogger.error("read() FAILED — UserDefaults(suiteName:) returned nil")
            return nil
        }
        guard defaults.object(forKey: keyTotalGames) != nil else {
            summaryLogger.debug("read() no data — keyTotalGames never set")
            return nil
        }
        let radarArray = defaults.array(forKey: keyRadarGenreCounts) as? [Double] ?? []
        let s = Summary(
            nextUpTitle: defaults.string(forKey: keyNextUpTitle),
            nextUpPlatform: defaults.string(forKey: keyNextUpPlatform),
            totalGames: defaults.integer(forKey: keyTotalGames),
            completedGames: defaults.integer(forKey: keyCompletedGames),
            playingCount: defaults.integer(forKey: keyPlayingCount),
            playingFirstTitle: defaults.string(forKey: keyPlayingFirstTitle),
            playingFirstPlatform: defaults.string(forKey: keyPlayingFirstPlatform),
            radarGenreCounts: radarArray.count >= 6 ? Array(radarArray.prefix(6)) : radarArray + [Double](repeating: 0, count: max(0, 6 - radarArray.count))
        )
        summaryLogger.debug("read() OK — totalGames=\(s.totalGames) nextUpTitle=\(s.nextUpTitle ?? "nil") completed=\(s.completedGames) playing=\(s.playingCount)")
        return s
    }
}
