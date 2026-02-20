import XCTest
import SwiftData
@testable import VGB

/// Tests for WidgetSummaryBuilder: make(from:) produces correct nextUp, playing, counts, radar.
@MainActor
final class WidgetSummaryBuilderTests: XCTestCase {

    private func makeGame(title: String, platform: String = "", status: GameStatus, priorityPosition: Int, genre: String? = nil) -> Game {
        let game = Game(title: title, platform: platform, status: status, priorityPosition: priorityPosition)
        game.genre = genre
        return game
    }

    // MARK: - Empty

    func testEmptyGamesSummary() {
        let games: [Game] = []
        let summary = WidgetSummaryBuilder.make(from: games)
        XCTAssertEqual(summary.totalGames, 0)
        XCTAssertEqual(summary.completedGames, 0)
        XCTAssertEqual(summary.playingCount, 0)
        XCTAssertNil(summary.nextUpTitle)
        XCTAssertNil(summary.nextUpPlatform)
        XCTAssertNil(summary.playingFirstTitle)
        XCTAssertNil(summary.playingFirstPlatform)
        XCTAssertEqual(summary.radarGenreCounts.count, 6)
        XCTAssertTrue(summary.radarGenreCounts.allSatisfy { $0 == 0 })
    }

    // MARK: - Next up (first backlog by priority)

    func testNextUpIsFirstBacklog() {
        let backlog1 = makeGame(title: "First Backlog", platform: "PS5", status: .backlog, priorityPosition: 0)
        let backlog2 = makeGame(title: "Second Backlog", platform: "Switch", status: .backlog, priorityPosition: 1)
        let games = [backlog1, backlog2]
        let summary = WidgetSummaryBuilder.make(from: games)
        XCTAssertEqual(summary.nextUpTitle, "First Backlog")
        XCTAssertEqual(summary.nextUpPlatform, "PS5")
    }

    func testNextUpNilWhenNoBacklog() {
        let playing = makeGame(title: "Only Playing", platform: "PC", status: .playing, priorityPosition: 0)
        let summary = WidgetSummaryBuilder.make(from: [playing])
        XCTAssertNil(summary.nextUpTitle)
        XCTAssertNil(summary.nextUpPlatform)
    }

    // MARK: - Playing first (first playing by priority)

    func testPlayingFirstIsFirstPlayingByPriority() {
        let p1 = makeGame(title: "Playing A", platform: "PS5", status: .playing, priorityPosition: 10)
        let p2 = makeGame(title: "Playing B", platform: "Switch", status: .playing, priorityPosition: 5)
        let games = [p1, p2]
        let summary = WidgetSummaryBuilder.make(from: games)
        XCTAssertEqual(summary.playingFirstTitle, "Playing B")
        XCTAssertEqual(summary.playingFirstPlatform, "Switch")
    }

    func testPlayingFirstNilWhenNoPlaying() {
        let backlog = makeGame(title: "Only Backlog", platform: "PC", status: .backlog, priorityPosition: 0)
        let summary = WidgetSummaryBuilder.make(from: [backlog])
        XCTAssertNil(summary.playingFirstTitle)
        XCTAssertNil(summary.playingFirstPlatform)
    }

    // MARK: - Counts

    func testTotalAndCompletedCounts() {
        let completed1 = makeGame(title: "C1", platform: "PS5", status: .completed, priorityPosition: 0)
        let completed2 = makeGame(title: "C2", platform: "PC", status: .completed, priorityPosition: 1)
        let playing = makeGame(title: "P1", platform: "Switch", status: .playing, priorityPosition: 2)
        let games = [completed1, completed2, playing]
        let summary = WidgetSummaryBuilder.make(from: games)
        XCTAssertEqual(summary.totalGames, 3)
        XCTAssertEqual(summary.completedGames, 2)
        XCTAssertEqual(summary.playingCount, 1)
    }

    // MARK: - Radar genre counts

    func testRadarGenreCountsFromCompletedGenres() {
        // WidgetSummaryBuilder uses all games' genres for radar (from WidgetSummaryBuilder: genreStrings = games.compactMap(\.genre))
        let g1 = makeGame(title: "RPG 1", platform: "PS5", status: .backlog, priorityPosition: 0, genre: "RPG")
        let g2 = makeGame(title: "RPG 2", platform: "PC", status: .backlog, priorityPosition: 1, genre: "RPG")
        let g3 = makeGame(title: "Horror", platform: "Switch", status: .backlog, priorityPosition: 2, genre: "Horror")
        let games = [g1, g2, g3]
        let summary = WidgetSummaryBuilder.make(from: games)
        XCTAssertEqual(summary.radarGenreCounts.count, 6)
        let rpgIndex = RadarGenreCategories.labels.firstIndex(of: "RPG")!
        let horrorIndex = RadarGenreCategories.labels.firstIndex(of: "Horror & Survival")!
        XCTAssertEqual(summary.radarGenreCounts[rpgIndex], 2)
        XCTAssertEqual(summary.radarGenreCounts[horrorIndex], 1)
    }

    // MARK: - Empty platform display

    func testEmptyPlatformYieldsNilPlatformInSummary() {
        let game = makeGame(title: "No Platform", platform: "", status: .backlog, priorityPosition: 0)
        let summary = WidgetSummaryBuilder.make(from: [game])
        XCTAssertEqual(summary.nextUpTitle, "No Platform")
        XCTAssertNil(summary.nextUpPlatform)
    }
}
