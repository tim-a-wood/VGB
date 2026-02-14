import XCTest
@testable import VGB

/// Tests for GameSyncService staleness logic and IGDB-to-Game mapping.
///
/// Note: These tests cover the pure logic (staleness checks, field mapping).
/// Network calls to IGDB are not tested here — those require integration tests.
@MainActor
final class GameSyncServiceTests: XCTestCase {

    private let service = GameSyncService.shared

    // MARK: - isStale

    func testManualGameIsNeverStale() {
        let game = Game(title: "Manual Game", platform: "PC")
        // No externalId → not stale
        XCTAssertFalse(service.isStale(game))
    }

    func testLinkedGameWithNoSyncDateIsStale() {
        let game = Game(title: "Linked Game")
        game.externalId = "12345"
        game.lastSyncedAt = nil
        XCTAssertTrue(service.isStale(game))
    }

    func testLinkedGameSyncedRecentlyIsNotStale() {
        let game = Game(title: "Fresh Game")
        game.externalId = "12345"
        game.lastSyncedAt = Date() // just now
        XCTAssertFalse(service.isStale(game))
    }

    func testLinkedGameSyncedOneDayAgoIsNotStale() {
        let game = Game(title: "Recent Game")
        game.externalId = "12345"
        game.lastSyncedAt = Date().addingTimeInterval(-1 * 24 * 60 * 60) // 1 day ago
        XCTAssertFalse(service.isStale(game))
    }

    func testLinkedGameSyncedSixDaysAgoIsNotStale() {
        let game = Game(title: "Almost Stale")
        game.externalId = "12345"
        game.lastSyncedAt = Date().addingTimeInterval(-6 * 24 * 60 * 60) // 6 days ago
        XCTAssertFalse(service.isStale(game))
    }

    func testLinkedGameSyncedEightDaysAgoIsStale() {
        let game = Game(title: "Stale Game")
        game.externalId = "12345"
        game.lastSyncedAt = Date().addingTimeInterval(-8 * 24 * 60 * 60) // 8 days ago
        XCTAssertTrue(service.isStale(game))
    }

    func testLinkedGameSyncedExactlySevenDaysAgoIsStale() {
        let game = Game(title: "Boundary Game")
        game.externalId = "12345"
        // Exactly at threshold + 1 second to be clearly over
        game.lastSyncedAt = Date().addingTimeInterval(-(7 * 24 * 60 * 60 + 1))
        XCTAssertTrue(service.isStale(game))
    }

    // MARK: - refreshGame returns false for manual games

    func testRefreshGameReturnsFalseWithoutExternalId() async {
        let game = Game(title: "Manual Only")
        let result = await service.refreshGame(game)
        XCTAssertFalse(result)
    }

    func testRefreshGameReturnsFalseWithInvalidExternalId() async {
        let game = Game(title: "Bad ID")
        game.externalId = "not-a-number"
        let result = await service.refreshGame(game)
        XCTAssertFalse(result)
    }

    // MARK: - Stale threshold value

    func testStaleThresholdIsSevenDays() {
        XCTAssertEqual(service.staleThreshold, 7 * 24 * 60 * 60)
    }
}
