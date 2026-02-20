import XCTest
import SwiftData
@testable import VGB

@MainActor
final class GameModelTests: XCTestCase {

    // MARK: - Init defaults

    func testInitWithTitleOnly() {
        let game = Game(title: "Elden Ring")

        XCTAssertEqual(game.title, "Elden Ring")
        XCTAssertEqual(game.platform, "")
        XCTAssertEqual(game.status, .backlog)
        XCTAssertEqual(game.statusRaw, "Backlog")
        XCTAssertEqual(game.priorityPosition, 0)
    }

    func testInitWithAllParameters() {
        let game = Game(
            title: "Hades",
            platform: "Switch",
            status: .playing,
            priorityPosition: 5
        )

        XCTAssertEqual(game.title, "Hades")
        XCTAssertEqual(game.platform, "Switch")
        XCTAssertEqual(game.status, .playing)
        XCTAssertEqual(game.statusRaw, "Playing")
        XCTAssertEqual(game.priorityPosition, 5)
    }

    // MARK: - Optional defaults

    func testOptionalFieldsDefaultToNil() {
        let game = Game(title: "Test")

        XCTAssertNil(game.estimatedHours)
        XCTAssertNil(game.personalRating)
        XCTAssertNil(game.releaseDate)
        XCTAssertNil(game.coverImageURL)
        XCTAssertNil(game.igdbRating)
        XCTAssertNil(game.genre)
        XCTAssertNil(game.developer)
        XCTAssertNil(game.externalId)
        XCTAssertNil(game.lastSyncedAt)
    }

    func testStringFieldsDefaultToEmpty() {
        let game = Game(title: "Test")

        XCTAssertEqual(game.personalNotes, "")
    }

    // MARK: - Computed status property

    func testStatusGetReturnsCorrectEnum() {
        let game = Game(title: "Test", status: .completed)
        XCTAssertEqual(game.status, .completed)
    }

    func testStatusSetUpdatesRaw() {
        let game = Game(title: "Test")
        XCTAssertEqual(game.status, .backlog)

        game.status = .wishlist
        XCTAssertEqual(game.statusRaw, "Wishlist")
        XCTAssertEqual(game.status, .wishlist)

        game.status = .playing
        XCTAssertEqual(game.statusRaw, "Playing")
        XCTAssertEqual(game.status, .playing)

        game.status = .completed
        XCTAssertEqual(game.statusRaw, "Completed")

        game.status = .dropped
        XCTAssertEqual(game.statusRaw, "Dropped")

        game.status = .backlog
        XCTAssertEqual(game.statusRaw, "Backlog")
    }

    func testInvalidStatusRawFallsBackToBacklog() {
        let game = Game(title: "Test")
        game.statusRaw = "InvalidStatus"
        XCTAssertEqual(game.status, .backlog)
    }

    // MARK: - System-managed fields

    func testIdIsUnique() {
        let game1 = Game(title: "A")
        let game2 = Game(title: "B")
        XCTAssertNotEqual(game1.id, game2.id)
    }

    func testTimestampsAreSet() {
        let before = Date()
        let game = Game(title: "Test")
        let after = Date()

        XCTAssertGreaterThanOrEqual(game.createdAt, before)
        XCTAssertLessThanOrEqual(game.createdAt, after)
        XCTAssertGreaterThanOrEqual(game.updatedAt, before)
        XCTAssertLessThanOrEqual(game.updatedAt, after)
    }

    // MARK: - User-owned field mutation

    func testUserFieldsAreMutable() {
        let game = Game(title: "Test")

        game.estimatedHours = 40.5
        XCTAssertEqual(game.estimatedHours, 40.5)

        game.personalNotes = "Great game"
        XCTAssertEqual(game.personalNotes, "Great game")

        game.personalRating = 85
        XCTAssertEqual(game.personalRating, 85)

        game.priorityPosition = 3
        XCTAssertEqual(game.priorityPosition, 3)
    }

    // MARK: - isUnreleased

    func testIsUnreleasedTrueForFutureDate() {
        let game = Game(title: "Future Game")
        game.releaseDate = Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year from now
        XCTAssertTrue(game.isUnreleased)
    }

    func testIsUnreleasedFalseForPastDate() {
        let game = Game(title: "Old Game")
        game.releaseDate = Date(timeIntervalSince1970: 1_645_660_800) // 2022
        XCTAssertFalse(game.isUnreleased)
    }

    func testIsUnreleasedTrueWhenNoDate() {
        let game = Game(title: "No Date")
        XCTAssertTrue(game.isUnreleased)
    }

    // MARK: - displayPlatform

    func testDisplayPlatformReturnsPlatformWhenNoNormalization() {
        let game = Game(title: "Test", platform: "Switch")
        XCTAssertEqual(game.displayPlatform, "Switch")
    }

    func testDisplayPlatformStripsMicrosoftWindows() {
        let game = Game(title: "Test", platform: "PC (Microsoft Windows)")
        XCTAssertEqual(game.displayPlatform, "PC")
    }

    func testDisplayPlatformPlayStationToOneThroughFive() {
        XCTAssertEqual(Game.displayPlatform(from: "PlayStation 5"), "PS5")
        XCTAssertEqual(Game.displayPlatform(from: "PlayStation 4"), "PS4")
        XCTAssertEqual(Game.displayPlatform(from: "PlayStation 3"), "PS3")
        XCTAssertEqual(Game.displayPlatform(from: "PlayStation 2"), "PS2")
        XCTAssertEqual(Game.displayPlatform(from: "PlayStation 1"), "PS1")
    }

    func testDisplayPlatformCombinedString() {
        let game = Game(title: "Test", platform: "PlayStation 5, PC (Microsoft Windows)")
        XCTAssertEqual(game.displayPlatform, "PS5, PC")
    }

    func testDisplayPlatformCollapsesPCMacLinuxWindowsToPC() {
        XCTAssertEqual(Game.displayPlatform(from: "Mac"), "PC")
        XCTAssertEqual(Game.displayPlatform(from: "Linux"), "PC")
        XCTAssertEqual(Game.displayPlatform(from: "Windows"), "PC")
        XCTAssertEqual(Game.displayPlatform(from: "Microsoft Windows"), "PC")
        XCTAssertEqual(Game.displayPlatform(from: "macOS"), "PC")
        let gameMac = Game(title: "Test", platform: "Mac")
        XCTAssertEqual(gameMac.displayPlatform, "PC")
        let gameLinuxMac = Game(title: "Test", platform: "Mac, Linux")
        XCTAssertEqual(gameLinuxMac.displayPlatform, "PC")
        let gamePS5Mac = Game(title: "Test", platform: "PlayStation 5, Mac")
        XCTAssertEqual(gamePS5Mac.displayPlatform, "PS5, PC")
    }

    func testPlatformComponentsSplitsCommaSeparated() {
        let components = Game.platformComponents("PS5, PC, Switch")
        XCTAssertEqual(components, ["PS5", "PC", "Switch"])
    }

    func testPlatformComponentsSplitsPipeSeparated() {
        let components = Game.platformComponents("PS5 | PC")
        XCTAssertEqual(components, ["PS5", "PC"])
    }

    func testPlatformComponentsSplitsSlashSeparated() {
        let components = Game.platformComponents("PS5/PC")
        XCTAssertEqual(components, ["PS5", "PC"])
    }

    func testPlatformComponentsReturnsEmptyForEmptyString() {
        XCTAssertTrue(Game.platformComponents("").isEmpty)
        XCTAssertTrue(Game.platformComponents("   ").isEmpty)
    }

    // MARK: - Provider-sourced field mutation

    func testProviderFieldsAreMutable() {
        let game = Game(title: "Test")

        game.igdbRating = 96
        XCTAssertEqual(game.igdbRating, 96)

        game.genre = "RPG"
        XCTAssertEqual(game.genre, "RPG")

        game.developer = "FromSoftware"
        XCTAssertEqual(game.developer, "FromSoftware")

        let date = Date(timeIntervalSince1970: 1_700_000_000)
        game.releaseDate = date
        XCTAssertEqual(game.releaseDate, date)

        game.coverImageURL = "https://example.com/cover.jpg"
        XCTAssertEqual(game.coverImageURL, "https://example.com/cover.jpg")
    }
}
