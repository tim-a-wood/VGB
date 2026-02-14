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
        let elden = Game(title: "Elden Ring", platform: "PS5", status: .playing, priorityPosition: 0)
        elden.metacriticScore = 96
        elden.openCriticScore = 95
        elden.genre = "RPG"
        elden.releaseDate = Date(timeIntervalSince1970: 1_645_660_800) // 2022-02-24

        let hades = Game(title: "Hades", platform: "Switch", status: .completed, priorityPosition: 1)
        hades.metacriticScore = 93
        hades.openCriticScore = 91
        hades.genre = "Roguelike"
        hades.releaseDate = Date(timeIntervalSince1970: 1_600_300_800) // 2020-09-17

        let zelda = Game(title: "Zelda: TotK", platform: "Switch", status: .backlog, priorityPosition: 2)
        zelda.metacriticScore = 96
        zelda.openCriticScore = 97
        zelda.genre = "RPG"
        zelda.releaseDate = Date(timeIntervalSince1970: 1_683_849_600) // 2023-05-12

        let cyberpunk = Game(title: "Cyberpunk 2077", platform: "PC", status: .dropped, priorityPosition: 3)
        cyberpunk.metacriticScore = 86
        cyberpunk.openCriticScore = 82
        cyberpunk.genre = "RPG"

        return [elden, hades, zelda, cyberpunk]
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

    func testNoFilterReturnsAll() {
        let games = makeSampleGames()
        XCTAssertEqual(games.count, 4)
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
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Elden Ring")
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
        XCTAssertEqual(result.count, 3)
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
        XCTAssertEqual(sorted.map(\.title), ["Elden Ring", "Hades", "Zelda: TotK", "Cyberpunk 2077"])
    }

    // MARK: - Sort by Metacritic

    func testSortByMetacriticDescending() {
        let games = makeSampleGames()
        let sorted = games.sorted { ($0.metacriticScore ?? -1) > ($1.metacriticScore ?? -1) }
        // Elden Ring (96) and Zelda (96) tie, then Hades (93), then Cyberpunk (86)
        XCTAssertEqual(sorted.first?.metacriticScore, 96)
        XCTAssertEqual(sorted.last?.metacriticScore, 86)
    }

    func testSortByMetacriticNilsGoLast() {
        var games = makeSampleGames()
        let noScore = Game(title: "No Score", platform: "PC")
        games.append(noScore)
        let sorted = games.sorted { ($0.metacriticScore ?? -1) > ($1.metacriticScore ?? -1) }
        XCTAssertEqual(sorted.last?.title, "No Score")
    }

    // MARK: - Sort by OpenCritic

    func testSortByOpenCriticDescending() {
        let games = makeSampleGames()
        let sorted = games.sorted { ($0.openCriticScore ?? -1) > ($1.openCriticScore ?? -1) }
        XCTAssertEqual(sorted.first?.title, "Zelda: TotK") // 97
        XCTAssertEqual(sorted.last?.title, "Cyberpunk 2077") // 82
    }

    // MARK: - Sort by release date

    func testSortByReleaseDateDescending() {
        let games = makeSampleGames()
        let sorted = games.sorted { ($0.releaseDate ?? .distantPast) > ($1.releaseDate ?? .distantPast) }
        // Zelda (2023) > Elden Ring (2022) > Hades (2020) > Cyberpunk (nil → distantPast)
        XCTAssertEqual(sorted.first?.title, "Zelda: TotK")
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
        XCTAssertEqual(genres, ["RPG", "Roguelike"])
    }

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
