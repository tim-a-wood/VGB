import XCTest
@testable import VGB

/// Tests for RadarGenreCategories: labels, categoryIndex, completedCountsByCategory.
final class RadarGenreCategoriesTests: XCTestCase {

    // MARK: - Count and labels

    func testCountIsSix() {
        XCTAssertEqual(RadarGenreCategories.count, 6)
    }

    func testLabelsCount() {
        XCTAssertEqual(RadarGenreCategories.labels.count, 6)
    }

    func testLabelsOrder() {
        let labels = RadarGenreCategories.labels
        XCTAssertEqual(labels[0], "Other")
        XCTAssertEqual(labels[1], "Action & Adventure")
        XCTAssertEqual(labels[2], "Shooter")
        XCTAssertEqual(labels[3], "RPG")
        XCTAssertEqual(labels[4], "Sports & Racing")
        XCTAssertEqual(labels[5], "Horror & Survival")
    }

    func testIconNamesCount() {
        XCTAssertEqual(RadarGenreCategories.iconNames.count, 6)
    }

    // MARK: - categoryIndex

    func testCategoryIndexStrategy() {
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "Strategy"), 0)
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "Real-time strategy"), 0)
    }

    func testCategoryIndexAction() {
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "Action"), 1)
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "Adventure"), 1)
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "Roguelike"), 1)
    }

    func testCategoryIndexShooter() {
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "Shooter"), 2)
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "First-person shooter"), 2)
    }

    func testCategoryIndexRPG() {
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "RPG"), 3)
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "Action RPG"), 3)
    }

    func testCategoryIndexSportsRacing() {
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "Sports"), 4)
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "Racing"), 4)
    }

    func testCategoryIndexHorrorSurvival() {
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "Horror"), 5)
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "Survival"), 5)
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "Survival horror"), 5)
    }

    func testCategoryIndexEmptyReturnsZero() {
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: ""), 0)
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "   "), 0)
    }

    func testCategoryIndexCaseInsensitive() {
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "RPG"), 3)
        XCTAssertEqual(RadarGenreCategories.categoryIndex(for: "rpg"), 3)
    }

    // MARK: - completedCountsByCategory

    func testCompletedCountsByCategoryEmpty() {
        let result = RadarGenreCategories.completedCountsByCategory(from: [])
        XCTAssertEqual(result.count, 6)
        XCTAssertTrue(result.allSatisfy { $0.value == 0 })
    }

    func testCompletedCountsByCategorySingleGenre() {
        let result = RadarGenreCategories.completedCountsByCategory(from: ["RPG", "RPG", "RPG"])
        XCTAssertEqual(result.count, 6)
        let rpgIndex = result.firstIndex { $0.label == "RPG" }!
        XCTAssertEqual(result[rpgIndex].value, 3)
    }

    func testCompletedCountsByCategoryMultipleGenres() {
        let result = RadarGenreCategories.completedCountsByCategory(from: ["Horror", "Shooter", "RPG", "Horror"])
        XCTAssertEqual(result.count, 6)
        let horror = result.first { $0.label == "Horror & Survival" }!
        let shooter = result.first { $0.label == "Shooter" }!
        let rpg = result.first { $0.label == "RPG" }!
        XCTAssertEqual(horror.value, 2)
        XCTAssertEqual(shooter.value, 1)
        XCTAssertEqual(rpg.value, 1)
    }

    func testCompletedCountsByCategoryLabelsMatchOrder() {
        let result = RadarGenreCategories.completedCountsByCategory(from: ["RPG"])
        XCTAssertEqual(result.map(\.label), RadarGenreCategories.labels)
    }
}
