import XCTest
@testable import VGB

/// Tests for IGDB API response models and their convenience computed properties.
final class IGDBModelsTests: XCTestCase {

    // MARK: - JSON Decoding

    func testDecodeFullGameResponse() throws {
        let json = """
        {
            "id": 119133,
            "name": "Elden Ring",
            "cover": { "id": 1, "image_id": "co4jni" },
            "platforms": [
                { "id": 48, "name": "PlayStation 5" },
                { "id": 6, "name": "PC (Microsoft Windows)" }
            ],
            "genres": [
                { "id": 12, "name": "Role-playing (RPG)" }
            ],
            "involved_companies": [
                { "id": 1, "company": { "id": 11, "name": "FromSoftware" }, "developer": true },
                { "id": 2, "company": { "id": 22, "name": "Bandai Namco" }, "developer": false }
            ],
            "first_release_date": 1645660800,
            "total_rating": 95.5,
            "summary": "An action RPG."
        }
        """.data(using: .utf8)!

        let game = try JSONDecoder().decode(IGDBGame.self, from: json)

        XCTAssertEqual(game.id, 119133)
        XCTAssertEqual(game.name, "Elden Ring")
        XCTAssertEqual(game.summary, "An action RPG.")
        XCTAssertEqual(game.firstReleaseDate, 1645660800)
        XCTAssertEqual(game.totalRating, 95.5)
        XCTAssertEqual(game.cover?.imageId, "co4jni")
        XCTAssertEqual(game.platforms?.count, 2)
        XCTAssertEqual(game.genres?.count, 1)
        XCTAssertEqual(game.involvedCompanies?.count, 2)
    }

    func testDecodeMinimalGameResponse() throws {
        let json = """
        { "id": 999, "name": "Unknown Game" }
        """.data(using: .utf8)!

        let game = try JSONDecoder().decode(IGDBGame.self, from: json)

        XCTAssertEqual(game.id, 999)
        XCTAssertEqual(game.name, "Unknown Game")
        XCTAssertNil(game.cover)
        XCTAssertNil(game.platforms)
        XCTAssertNil(game.genres)
        XCTAssertNil(game.involvedCompanies)
        XCTAssertNil(game.firstReleaseDate)
        XCTAssertNil(game.totalRating)
        XCTAssertNil(game.summary)
    }

    func testDecodeGameArray() throws {
        let json = """
        [
            { "id": 1, "name": "Game A" },
            { "id": 2, "name": "Game B" }
        ]
        """.data(using: .utf8)!

        let games = try JSONDecoder().decode([IGDBGame].self, from: json)
        XCTAssertEqual(games.count, 2)
        XCTAssertEqual(games[0].name, "Game A")
        XCTAssertEqual(games[1].name, "Game B")
    }

    // MARK: - Convenience: releaseDate

    func testReleaseDateFromTimestamp() {
        let game = makeGame(firstReleaseDate: 1645660800) // 2022-02-24
        let date = game.releaseDate!
        let components = Calendar(identifier: .gregorian).dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        XCTAssertEqual(components.year, 2022)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 24)
    }

    func testReleaseDateNilWhenMissing() {
        let game = makeGame(firstReleaseDate: nil)
        XCTAssertNil(game.releaseDate)
    }

    // MARK: - Convenience: developerName

    func testDeveloperNamePicksFirstDeveloper() {
        let game = makeGame(companies: [
            IGDBInvolvedCompany(id: 1, company: IGDBCompany(id: 10, name: "Publisher Co"), developer: false),
            IGDBInvolvedCompany(id: 2, company: IGDBCompany(id: 20, name: "Dev Studio"), developer: true),
        ])
        XCTAssertEqual(game.developerName, "Dev Studio")
    }

    func testDeveloperNameNilWhenNoDeveloper() {
        let game = makeGame(companies: [
            IGDBInvolvedCompany(id: 1, company: IGDBCompany(id: 10, name: "Publisher"), developer: false),
        ])
        XCTAssertNil(game.developerName)
    }

    func testDeveloperNameNilWhenNoCompanies() {
        let game = makeGame(companies: nil)
        XCTAssertNil(game.developerName)
    }

    // MARK: - Convenience: primaryGenre

    func testPrimaryGenrePicksByPriority() {
        // When multiple genres exist and text has no signal, resolver uses first DB genre.
        let game = makeGame(genres: [
            IGDBGenre(id: 1, name: "RPG"),
            IGDBGenre(id: 2, name: "Adventure"),
        ])
        XCTAssertEqual(game.primaryGenre, "RPG")
    }

    func testPrimaryGenreNilWhenEmpty() {
        let game = makeGame(genres: [])
        XCTAssertNil(game.primaryGenre)
    }

    func testPrimaryGenreNilWhenMissing() {
        let game = makeGame(genres: nil)
        XCTAssertNil(game.primaryGenre)
    }

    func testPrimaryGenreHorrorFromThemes() {
        let game = makeGame(
            genres: [IGDBGenre(id: 1, name: "Shooter")],
            themes: [IGDBTheme(id: 19, name: "Horror", slug: "horror")]
        )
        XCTAssertEqual(game.primaryGenre, "Horror")
    }

    func testPrimaryGenreHorrorFromSurvivalTheme() {
        let game = makeGame(
            genres: [IGDBGenre(id: 1, name: "Adventure")],
            themes: [IGDBTheme(id: 42, name: "Survival", slug: "survival")]
        )
        XCTAssertEqual(game.primaryGenre, "Horror")
    }

    func testDecodeThemesAsIds() throws {
        let json = """
        {
            "id": 123,
            "name": "Cronos: The New Dawn",
            "themes": [19, 42]
        }
        """.data(using: .utf8)!
        let game = try JSONDecoder().decode(IGDBGame.self, from: json)
        XCTAssertEqual(game.primaryGenre, "Horror")
    }

    func testPrimaryGenreHorrorFromSummary() {
        let game = makeGame(
            genres: [IGDBGenre(id: 1, name: "Shooter")],
            themes: nil,
            summary: "A survival horror game set in a dystopian future."
        )
        XCTAssertEqual(game.primaryGenre, "Horror")
    }

    func testPrimaryGenreFromSummaryOverridesDB() {
        // IGDB often returns Adventure; resolver uses summary to infer RPG (or Action RPG).
        let game = makeGame(
            name: "Elden Ring",
            genres: [IGDBGenre(id: 1, name: "Adventure"), IGDBGenre(id: 2, name: "Action")],
            themes: nil,
            summary: "A souls-like action RPG. Level up your character, explore dungeons, and defeat bosses."
        )
        let g = game.primaryGenre
        XCTAssertTrue(g == "RPG" || g == "Action RPG", "Expected RPG or Action RPG from summary, got \(g ?? "nil")")
    }

    func testPrimaryGenreShooterForMilitaryFPS() {
        // Battlefield-style: military FPS should resolve as Shooter, not RPG.
        let game = makeGame(
            name: "Battlefield 6",
            genres: [IGDBGenre(id: 1, name: "Adventure"), IGDBGenre(id: 2, name: "Action")],
            themes: nil,
            summary: "Experience all-out warfare in a massive first-person shooter. Lead your squad in military combat across huge maps. FPS multiplayer with vehicles and weapons."
        )
        XCTAssertEqual(game.primaryGenre, "Shooter")
    }

    func testPrimaryGenreRPGForOpenWorldRPG() {
        // Skyrim-style: open world RPG should resolve as RPG, not Adventure.
        let game = makeGame(
            name: "The Elder Scrolls V: Skyrim",
            genres: [IGDBGenre(id: 1, name: "Adventure")],
            themes: nil,
            summary: "An open world RPG where you explore a vast land. Complete quests, learn magic, and progress your character. Role-playing with dragons and dungeons."
        )
        XCTAssertEqual(game.primaryGenre, "RPG")
    }

    func testPrimaryGenreStrategyForCiv() {
        // Civilization-style 4x strategy should resolve as Strategy (Other), not RPG.
        let game = makeGame(
            name: "Sid Meier's Civilization VI",
            genres: [IGDBGenre(id: 1, name: "Strategy"), IGDBGenre(id: 2, name: "Turn-based")],
            themes: nil,
            summary: "Build an empire in this 4x turn-based strategy game. Expand, exploit, conquer. Lead your civilization through the ages."
        )
        XCTAssertEqual(game.primaryGenre, "Strategy")
    }

    func testPrimaryGenreStrategyForHeroesOfMightAndMagic() {
        // Heroes of Might and Magic has "magic" but is strategy; should resolve as Strategy (Other), not RPG.
        let game = makeGame(
            name: "Heroes of Might and Magic III",
            genres: [IGDBGenre(id: 1, name: "Adventure"), IGDBGenre(id: 2, name: "RPG")],
            themes: nil,
            summary: "Classic turn-based strategy game. Lead your hero and army across the campaign map. Conquer towns, manage resources, and command units in tactical combat."
        )
        XCTAssertEqual(game.primaryGenre, "Strategy")
    }

    // MARK: - Convenience: platformNames

    func testPlatformNamesJoinsAll() {
        let game = makeGame(platforms: [
            IGDBPlatform(id: 1, name: "PS5"),
            IGDBPlatform(id: 2, name: "PC"),
            IGDBPlatform(id: 3, name: nil), // nil name should be excluded
        ])
        XCTAssertEqual(game.platformNames, ["PS5", "PC"])
    }

    func testPlatformNamesEmptyWhenNil() {
        let game = makeGame(platforms: nil)
        XCTAssertTrue(game.platformNames.isEmpty)
    }

    // MARK: - Convenience: coverURL / thumbnailURL

    func testCoverURLBuildsCorrectly() {
        let game = makeGame(coverImageId: "co4jni")
        XCTAssertEqual(game.coverURL, "https://images.igdb.com/igdb/image/upload/t_cover_big/co4jni.jpg")
    }

    func testThumbnailURLBuildsCorrectly() {
        let game = makeGame(coverImageId: "co4jni")
        XCTAssertEqual(game.thumbnailURL, "https://images.igdb.com/igdb/image/upload/t_thumb/co4jni.jpg")
    }

    func testCoverURLNilWhenNoCover() {
        let game = makeGame(coverImageId: nil)
        XCTAssertNil(game.coverURL)
        XCTAssertNil(game.thumbnailURL)
    }

    // MARK: - Helpers

    /// Creates an IGDBGame with specific fields for testing convenience properties.
    private func makeGame(
        id: Int = 1,
        name: String = "Test Game",
        coverImageId: String? = nil,
        platforms: [IGDBPlatform]? = nil,
        genres: [IGDBGenre]? = nil,
        themes: [IGDBTheme]? = nil,
        companies: [IGDBInvolvedCompany]? = nil,
        firstReleaseDate: Int? = nil,
        totalRating: Double? = nil,
        summary: String? = nil
    ) -> IGDBGame {
        IGDBGame(
            id: id,
            name: name,
            cover: coverImageId.map { IGDBCover(id: 1, imageId: $0) },
            platforms: platforms,
            genres: genres,
            themes: themes,
            involvedCompanies: companies,
            firstReleaseDate: firstReleaseDate,
            totalRating: totalRating,
            summary: summary
        )
    }
}
