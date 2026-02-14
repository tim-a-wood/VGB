import XCTest
@testable import VGB

final class GameStatusTests: XCTestCase {

    // MARK: - Cases

    func testAllCasesExist() {
        let cases = GameStatus.allCases
        XCTAssertEqual(cases.count, 4)
        XCTAssertTrue(cases.contains(.backlog))
        XCTAssertTrue(cases.contains(.playing))
        XCTAssertTrue(cases.contains(.completed))
        XCTAssertTrue(cases.contains(.dropped))
    }

    // MARK: - Raw values

    func testRawValues() {
        XCTAssertEqual(GameStatus.backlog.rawValue, "Backlog")
        XCTAssertEqual(GameStatus.playing.rawValue, "Playing")
        XCTAssertEqual(GameStatus.completed.rawValue, "Completed")
        XCTAssertEqual(GameStatus.dropped.rawValue, "Dropped")
    }

    func testInitFromRawValue() {
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

    // MARK: - Identifiable

    func testIdentifiableIdMatchesRawValue() {
        for status in GameStatus.allCases {
            XCTAssertEqual(status.id, status.rawValue)
        }
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
