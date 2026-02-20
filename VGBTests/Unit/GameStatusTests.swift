import XCTest
@testable import VGB

final class GameStatusTests: XCTestCase {

    // MARK: - Cases

    func testAllCasesExist() {
        let cases = GameStatus.allCases
        XCTAssertEqual(cases.count, 5)
        XCTAssertTrue(cases.contains(.wishlist))
        XCTAssertTrue(cases.contains(.backlog))
        XCTAssertTrue(cases.contains(.playing))
        XCTAssertTrue(cases.contains(.completed))
        XCTAssertTrue(cases.contains(.dropped))
    }

    // MARK: - Raw values

    func testRawValues() {
        XCTAssertEqual(GameStatus.wishlist.rawValue, "Wishlist")
        XCTAssertEqual(GameStatus.backlog.rawValue, "Backlog")
        XCTAssertEqual(GameStatus.playing.rawValue, "Playing")
        XCTAssertEqual(GameStatus.completed.rawValue, "Completed")
        XCTAssertEqual(GameStatus.dropped.rawValue, "Dropped")
    }

    func testInitFromRawValue() {
        XCTAssertEqual(GameStatus(rawValue: "Wishlist"), .wishlist)
        XCTAssertEqual(GameStatus(rawValue: "Backlog"), .backlog)
        XCTAssertEqual(GameStatus(rawValue: "Playing"), .playing)
        XCTAssertEqual(GameStatus(rawValue: "Completed"), .completed)
        XCTAssertEqual(GameStatus(rawValue: "Dropped"), .dropped)
    }

    func testInvalidRawValueReturnsNil() {
        XCTAssertNil(GameStatus(rawValue: ""))
        XCTAssertNil(GameStatus(rawValue: "Unknown"))
        XCTAssertNil(GameStatus(rawValue: "backlog")) // case-sensitive
    }

    // MARK: - Lifecycle order

    func testLifecycleOrder() {
        let cases = GameStatus.allCases
        XCTAssertEqual(cases[0], .wishlist)
        XCTAssertEqual(cases[1], .backlog)
        XCTAssertEqual(cases[2], .playing)
        XCTAssertEqual(cases[3], .completed)
        XCTAssertEqual(cases[4], .dropped)
    }

    // MARK: - Identifiable

    func testIdentifiableIdMatchesRawValue() {
        for status in GameStatus.allCases {
            XCTAssertEqual(status.id, status.rawValue)
        }
    }

    // MARK: - availableStatuses

    func testAvailableStatusesForUnreleasedIsWishlistOnly() {
        let statuses = GameStatus.availableStatuses(for: true)
        XCTAssertEqual(statuses, [.wishlist])
    }

    func testAvailableStatusesForReleasedIsAllCases() {
        let statuses = GameStatus.availableStatuses(for: false)
        XCTAssertEqual(statuses.count, 5)
        XCTAssertEqual(statuses, Array(GameStatus.allCases))
    }

    // MARK: - Section metadata

    func testSectionTitlePlayingIsNowPlaying() {
        XCTAssertEqual(GameStatus.playing.sectionTitle, "Now Playing")
    }

    func testSectionIconPlayingIsPlayFill() {
        XCTAssertEqual(GameStatus.playing.sectionIcon, "play.fill")
    }

    // MARK: - Codable round-trip

    func testCodableRoundTrip() throws {
        for status in GameStatus.allCases {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(GameStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }
}
