import XCTest
@testable import VGB

/// Tests for GenreResolver: theme override, phrase overrides, DB-first priority, Action RPG, and fallbacks.
final class GenreResolverTests: XCTestCase {

    // MARK: - Known genres

    func testKnownGenresContainsExpected() {
        let known = GenreResolver.knownGenres
        XCTAssertTrue(known.contains("Horror"))
        XCTAssertTrue(known.contains("Strategy"))
        XCTAssertTrue(known.contains("RPG"))
        XCTAssertTrue(known.contains("Action RPG"))
        XCTAssertTrue(known.contains("Roguelike"))
        XCTAssertTrue(known.contains("Shooter"))
        XCTAssertTrue(known.contains("Action"))
        XCTAssertTrue(known.contains("Adventure"))
        XCTAssertTrue(known.contains("Other"))
    }

    // MARK: - Theme override (Horror / Survival)

    func testThemeHorrorReturnsHorror() {
        let result = GenreResolver.resolve(name: "Game", summary: nil, genreNames: ["Shooter"], themeNames: ["Horror"])
        XCTAssertEqual(result, "Horror")
    }

    func testThemeSurvivalReturnsHorror() {
        let result = GenreResolver.resolve(name: "Game", summary: nil, genreNames: ["Adventure"], themeNames: ["Survival"])
        XCTAssertEqual(result, "Horror")
    }

    func testThemeSurvivalHorrorReturnsHorror() {
        let result = GenreResolver.resolve(name: "Game", summary: nil, genreNames: [], themeNames: ["Survival horror"])
        XCTAssertEqual(result, "Horror")
    }

    // MARK: - Phrase overrides

    func testPhraseSurvivalHorrorReturnsHorror() {
        let result = GenreResolver.resolve(name: "Resident Evil", summary: "A survival horror game.", genreNames: ["Adventure"], themeNames: [])
        XCTAssertEqual(result, "Horror")
    }

    func testPhraseSoulsLikeReturnsActionRPG() {
        let result = GenreResolver.resolve(name: "Lies of P", summary: "A souls-like action game.", genreNames: ["Action", "Adventure"], themeNames: [])
        XCTAssertEqual(result, "Action RPG")
    }

    func testPhraseRoguelikeReturnsRoguelike() {
        let result = GenreResolver.resolve(name: "Hades", summary: "Roguelike dungeon crawler.", genreNames: ["Action"], themeNames: [])
        XCTAssertEqual(result, "Roguelike")
    }

    func testPhraseTurnBasedStrategyReturnsStrategy() {
        let result = GenreResolver.resolve(name: "Civ VI", summary: "Turn-based strategy game.", genreNames: ["Adventure"], themeNames: [])
        XCTAssertEqual(result, "Strategy")
    }

    func testPhraseFirstPersonShooterReturnsShooter() {
        let result = GenreResolver.resolve(name: "Call of Duty", summary: "First-person shooter.", genreNames: ["Adventure"], themeNames: [])
        XCTAssertEqual(result, "Shooter")
    }

    // MARK: - DB-first priority

    func testSingleGenreReturnsMapped() {
        let result = GenreResolver.resolve(name: "Game", summary: nil, genreNames: ["Shooter"], themeNames: [])
        XCTAssertEqual(result, "Shooter")
    }

    func testMultipleGenresPicksByPriority() {
        // Priority order has Horror before Shooter before RPG before Action before Adventure
        let result = GenreResolver.resolve(name: "Game", summary: nil, genreNames: ["Adventure", "Action", "RPG"], themeNames: [])
        XCTAssertEqual(result, "RPG")
    }

    func testRPGAndActionCombinedReturnsActionRPG() {
        let result = GenreResolver.resolve(name: "Game", summary: nil, genreNames: ["RPG", "Action"], themeNames: [])
        XCTAssertEqual(result, "Action RPG")
    }

    func testRolePlayingMapsToRPG() {
        let result = GenreResolver.resolve(name: "Game", summary: nil, genreNames: ["Role-playing (RPG)"], themeNames: [])
        XCTAssertEqual(result, "RPG")
    }

    // MARK: - No genres

    func testNoGenresNoTextReturnsNil() {
        let result = GenreResolver.resolve(name: nil, summary: nil, genreNames: [], themeNames: [])
        XCTAssertNil(result)
    }

    func testNoGenresWithNameReturnsOther() {
        let result = GenreResolver.resolve(name: "Some Game", summary: nil, genreNames: [], themeNames: [])
        XCTAssertEqual(result, "Other")
    }
}
