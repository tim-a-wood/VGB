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

    struct Summary {
        let nextUpTitle: String?
        let nextUpPlatform: String?
        let totalGames: Int
        let completedGames: Int
        let playingCount: Int
    }

    static func write(nextUpTitle: String?, nextUpPlatform: String?, totalGames: Int, completedGames: Int, playingCount: Int) {
        summaryLogger.info("write() suiteName=\(suiteName)")
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            summaryLogger.error("write() FAILED — UserDefaults(suiteName:) returned nil")
            return
        }
        defaults.set(nextUpTitle, forKey: keyNextUpTitle)
        defaults.set(nextUpPlatform, forKey: keyNextUpPlatform)
        defaults.set(totalGames, forKey: keyTotalGames)
        defaults.set(completedGames, forKey: keyCompletedGames)
        defaults.set(playingCount, forKey: keyPlayingCount)
        defaults.synchronize()
        summaryLogger.info("write() OK — totalGames=\(totalGames) nextUpTitle=\(nextUpTitle ?? "nil") completed=\(completedGames) playing=\(playingCount)")
    }

    static func read() -> Summary? {
        summaryLogger.info("read() suiteName=\(suiteName)")
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            summaryLogger.error("read() FAILED — UserDefaults(suiteName:) returned nil")
            return nil
        }
        guard defaults.object(forKey: keyTotalGames) != nil else {
            summaryLogger.info("read() no data — keyTotalGames never set")
            return nil
        }
        let s = Summary(
            nextUpTitle: defaults.string(forKey: keyNextUpTitle),
            nextUpPlatform: defaults.string(forKey: keyNextUpPlatform),
            totalGames: defaults.integer(forKey: keyTotalGames),
            completedGames: defaults.integer(forKey: keyCompletedGames),
            playingCount: defaults.integer(forKey: keyPlayingCount)
        )
        summaryLogger.info("read() OK — totalGames=\(s.totalGames) nextUpTitle=\(s.nextUpTitle ?? "nil") completed=\(s.completedGames) playing=\(s.playingCount)")
        return s
    }
}
