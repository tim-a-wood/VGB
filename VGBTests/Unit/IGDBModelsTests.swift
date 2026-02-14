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

    func testPrimaryGenreReturnsFirst() {
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
        companies: [IGDBInvolvedCompany]? = nil,
        firstReleaseDate: Int? = nil,
        totalRating: Double? = nil
    ) -> IGDBGame {
        IGDBGame(
            id: id,
            name: name,
            cover: coverImageId.map { IGDBCover(id: 1, imageId: $0) },
            platforms: platforms,
            genres: genres,
            involvedCompanies: companies,
            firstReleaseDate: firstReleaseDate,
            totalRating: totalRating,
            summary: nil
        )
    }
}
