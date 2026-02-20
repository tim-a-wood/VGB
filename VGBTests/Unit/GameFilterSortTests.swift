import XCTest
@testable import VGB

/// Tests the filter and sort logic used by BacklogListView.
///
/// The view applies filters/sorts over plain `[Game]` arrays, so we replicate
/// that logic here to verify correctness without needing a SwiftUI host.
@MainActor
final class GameFilterSortTests: XCTestCase {

    // MARK: - Helpers

    /// Builds a small test catalogue.
    private func makeSampleGames() -> [Game] {
        let gta6 = Game(title: "GTA VI", platform: "PS5", status: .wishlist, priorityPosition: 0)
        gta6.igdbRating = nil
        gta6.genre = "Action"
        gta6.releaseDate = Date(timeIntervalSince1970: 1_893_456_000) // 2029-12-01 (unreleased)

        let elden = Game(title: "Elden Ring", platform: "PS5", status: .playing, priorityPosition: 1)
        elden.igdbRating = 96
        elden.genre = "RPG"
        elden.releaseDate = Date(timeIntervalSince1970: 1_645_660_800) // 2022-02-24

        let hades = Game(title: "Hades", platform: "Switch", status: .completed, priorityPosition: 2)
        hades.igdbRating = 93
        hades.genre = "Roguelike"
        hades.releaseDate = Date(timeIntervalSince1970: 1_600_300_800) // 2020-09-17

        let zelda = Game(title: "Zelda: TotK", platform: "Switch", status: .backlog, priorityPosition: 3)
        zelda.igdbRating = 97
        zelda.genre = "RPG"
        zelda.releaseDate = Date(timeIntervalSince1970: 1_683_849_600) // 2023-05-12

        let cyberpunk = Game(title: "Cyberpunk 2077", platform: "PC", status: .dropped, priorityPosition: 4)
        cyberpunk.igdbRating = 86
        cyberpunk.genre = "RPG"

        return [gta6, elden, hades, zelda, cyberpunk]
    }

    // MARK: - Filter by status

    func testFilterByStatusPlaying() {
        let games = makeSampleGames()
        let result = games.filter { $0.status == .playing }
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Elden Ring")
    }

    func testFilterByStatusCompleted() {
        let games = makeSampleGames()
        let result = games.filter { $0.status == .completed }
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Hades")
    }

    func testFilterByStatusBacklog() {
        let games = makeSampleGames()
        let result = games.filter { $0.status == .backlog }
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Zelda: TotK")
    }

    func testFilterByStatusDropped() {
        let games = makeSampleGames()
        let result = games.filter { $0.status == .dropped }
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Cyberpunk 2077")
    }

    func testFilterByStatusWishlist() {
        let games = makeSampleGames()
        let result = games.filter { $0.status == .wishlist }
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "GTA VI")
    }

    func testNoFilterReturnsAll() {
        let games = makeSampleGames()
        XCTAssertEqual(games.count, 5)
    }

    // MARK: - Filter by platform

    func testFilterByPlatformSwitch() {
        let games = makeSampleGames()
        let result = games.filter { $0.platform == "Switch" }
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.title == "Hades" })
        XCTAssertTrue(result.contains { $0.title == "Zelda: TotK" })
    }

    func testFilterByPlatformPS5() {
        let games = makeSampleGames()
        let result = games.filter { $0.platform == "PS5" }
        XCTAssertEqual(result.count, 2) // GTA VI + Elden Ring
    }

    func testFilterByPlatformNoneMatch() {
        let games = makeSampleGames()
        let result = games.filter { $0.platform == "Xbox" }
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Filter by genre

    func testFilterByGenreRPG() {
        let games = makeSampleGames()
        let result = games.filter { $0.genre == "RPG" }
        XCTAssertEqual(result.count, 3) // Elden Ring, Zelda, Cyberpunk
    }

    func testFilterByGenreAction() {
        let games = makeSampleGames()
        let result = games.filter { $0.genre == "Action" }
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "GTA VI")
    }

    func testFilterByGenreRoguelike() {
        let games = makeSampleGames()
        let result = games.filter { $0.genre == "Roguelike" }
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Hades")
    }

    // MARK: - Combined filters

    func testCombinedStatusAndPlatform() {
        let games = makeSampleGames()
        let result = games
            .filter { $0.status == .backlog }
            .filter { $0.platform == "Switch" }
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Zelda: TotK")
    }

    func testCombinedPlatformAndGenre() {
        let games = makeSampleGames()
        let result = games
            .filter { $0.platform == "Switch" }
            .filter { $0.genre == "RPG" }
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Zelda: TotK")
    }

    func testCombinedFiltersNoMatch() {
        let games = makeSampleGames()
        let result = games
            .filter { $0.status == .completed }
            .filter { $0.platform == "PS5" }
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Sort by priority

    func testSortByPriority() {
        let games = makeSampleGames().shuffled()
        let sorted = games.sorted { $0.priorityPosition < $1.priorityPosition }
        XCTAssertEqual(sorted.map(\.title), ["GTA VI", "Elden Ring", "Hades", "Zelda: TotK", "Cyberpunk 2077"])
    }

    // MARK: - Sort by IGDB rating

    func testSortByIGDBRatingDescending() {
        let games = makeSampleGames()
        let sorted = games.sorted { ($0.igdbRating ?? -1) > ($1.igdbRating ?? -1) }
        // Zelda (97) > Elden Ring (96) > Hades (93) > Cyberpunk (86) > GTA VI (nil → -1)
        XCTAssertEqual(sorted.first?.igdbRating, 97)
        XCTAssertEqual(sorted.last?.title, "GTA VI") // nil rating goes last
    }

    func testSortByIGDBRatingNilsGoLast() {
        var games = makeSampleGames()
        let noScore = Game(title: "No Score", platform: "PC")
        games.append(noScore)
        let sorted = games.sorted { ($0.igdbRating ?? -1) > ($1.igdbRating ?? -1) }
        XCTAssertEqual(sorted.last?.title, "No Score")
    }

    // MARK: - Sort by release date

    func testSortByReleaseDateDescending() {
        let games = makeSampleGames()
        let sorted = games.sorted { ($0.releaseDate ?? .distantPast) > ($1.releaseDate ?? .distantPast) }
        // GTA VI (2029) > Zelda (2023) > Elden Ring (2022) > Hades (2020) > Cyberpunk (nil → distantPast)
        XCTAssertEqual(sorted.first?.title, "GTA VI")
        XCTAssertEqual(sorted.last?.title, "Cyberpunk 2077")
    }

    func testSortByReleaseDateNilsGoLast() {
        var games = makeSampleGames()
        let noDate = Game(title: "No Date", platform: "PC")
        games.append(noDate)
        let sorted = games.sorted { ($0.releaseDate ?? .distantPast) > ($1.releaseDate ?? .distantPast) }
        XCTAssertEqual(sorted.last?.title, "No Date")
    }

    // MARK: - Unique platforms / genres extraction

    func testUniquePlatforms() {
        let games = makeSampleGames()
        let platforms = Array(Set(games.map(\.platform).filter { !$0.isEmpty })).sorted()
        XCTAssertEqual(platforms, ["PC", "PS5", "Switch"])
    }

    func testUniqueGenres() {
        let games = makeSampleGames()
        let genres = Array(Set(games.compactMap(\.genre).filter { !$0.isEmpty })).sorted()
        XCTAssertEqual(genres, ["Action", "RPG", "Roguelike"])
    }

    // MARK: - Text search

    func testSearchByTitleCaseInsensitive() {
        let games = makeSampleGames()
        let query = "elden"
        let result = games.filter { $0.title.lowercased().contains(query) }
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Elden Ring")
    }

    func testSearchByPartialTitle() {
        let games = makeSampleGames()
        let query = "zel"
        let result = games.filter { $0.title.lowercased().contains(query) }
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Zelda: TotK")
    }

    func testSearchNoMatch() {
        let games = makeSampleGames()
        let query = "minecraft"
        let result = games.filter { $0.title.lowercased().contains(query) }
        XCTAssertTrue(result.isEmpty)
    }

    func testSearchEmptyStringReturnsAll() {
        let games = makeSampleGames()
        let query = ""
        let result: [Game]
        if query.isEmpty {
            result = games
        } else {
            result = games.filter { $0.title.lowercased().contains(query) }
        }
        XCTAssertEqual(result.count, 5)
    }

    // MARK: - Unreleased badge

    func testUnreleasedGameDetected() {
        let games = makeSampleGames()
        let unreleased = games.filter { $0.isUnreleased }
        // GTA VI (future date) + Cyberpunk (no date) are unreleased
        XCTAssertEqual(unreleased.count, 2)
        XCTAssertTrue(unreleased.contains(where: { $0.title == "GTA VI" }))
        XCTAssertTrue(unreleased.contains(where: { $0.title == "Cyberpunk 2077" }))
    }

    func testReleasedGamesNotFlaggedAsUnreleased() {
        let games = makeSampleGames()
        let released = games.filter { !$0.isUnreleased && $0.releaseDate != nil }
        XCTAssertEqual(released.count, 3) // Elden Ring, Hades, Zelda
    }

    // MARK: - Unique platforms / genres extraction

    func testEmptyPlatformExcludedFromList() {
        let games = [Game(title: "No Platform")]
        let platforms = Array(Set(games.map(\.platform).filter { !$0.isEmpty })).sorted()
        XCTAssertTrue(platforms.isEmpty)
    }

    func testNilGenreExcludedFromList() {
        let games = [Game(title: "No Genre", platform: "PC")]
        let genres = Array(Set(games.compactMap(\.genre).filter { !$0.isEmpty })).sorted()
        XCTAssertTrue(genres.isEmpty)
    }
}
