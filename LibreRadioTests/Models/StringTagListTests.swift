import XCTest
@testable import LibreRadio

final class StringTagListTests: XCTestCase {
    func testEmptyStringReturnsEmptyArray() {
        XCTAssertEqual("".asTagList, [])
    }

    func testSingleTag() {
        XCTAssertEqual("rock".asTagList, ["rock"])
    }

    func testMultipleTags() {
        XCTAssertEqual("rock,pop,jazz".asTagList, ["rock", "pop", "jazz"])
    }

    func testTrimsWhitespace() {
        XCTAssertEqual("rock, pop , jazz".asTagList, ["rock", "pop", "jazz"])
    }

    func testFiltersEmptySegments() {
        XCTAssertEqual(",rock,,pop,".asTagList, ["rock", "pop"])
    }

    func testWhitespaceOnlySegmentsFiltered() {
        XCTAssertEqual("rock, , pop".asTagList, ["rock", "pop"])
    }

    func testPureWhitespaceStringReturnsEmpty() {
        // "   ".split(",") → ["   "], trimmed → [""], filtered → []
        XCTAssertEqual("   ".asTagList, [])
    }

    func testSingleCommaReturnsEmpty() {
        XCTAssertEqual(",".asTagList, [])
    }

    func testPreservesTagCase() {
        XCTAssertEqual("Rock,POP,Jazz".asTagList, ["Rock", "POP", "Jazz"])
    }
}
