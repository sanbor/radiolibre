import XCTest
@testable import LibreRadio

final class AlphabetIndexViewTests: XCTestCase {

    // MARK: - letterIndex(forY:letterCount:)

    func testIndexAtTopReturnsZero() {
        // Y just inside the top padding
        let index = AlphabetIndexView.letterIndex(forY: 5, letterCount: 26)
        XCTAssertEqual(index, 0)
    }

    func testIndexAtBottomReturnsLastIndex() {
        // 26 letters × 16pt + 8pt padding = 424pt total. Last letter center ≈ 420pt
        let index = AlphabetIndexView.letterIndex(forY: 420, letterCount: 26)
        XCTAssertEqual(index, 25)
    }

    func testIndexAboveRangeReturnsNil() {
        let index = AlphabetIndexView.letterIndex(forY: -10, letterCount: 26)
        XCTAssertNil(index)
    }

    func testIndexBelowRangeReturnsNil() {
        let index = AlphabetIndexView.letterIndex(forY: 500, letterCount: 26)
        XCTAssertNil(index)
    }

    func testIndexInMiddleReturnsCorrectIndex() {
        // For 5 letters: total = 5*16+8 = 88. Each letter ≈ 17.6pt.
        // Y = 30 → adjusted = 26 → 26 / (88/5) = 26/17.6 = 1.47 → Int = 1
        let index = AlphabetIndexView.letterIndex(forY: 30, letterCount: 5)
        XCTAssertEqual(index, 1)
    }

    func testZeroLetterCountReturnsNil() {
        let index = AlphabetIndexView.letterIndex(forY: 10, letterCount: 0)
        XCTAssertNil(index)
    }

    func testSingleLetterReturnsZero() {
        // 1 letter: total = 1*16+8 = 24. Y=5 → adjusted=1 → 1/(24/1) = 0.04 → 0
        let index = AlphabetIndexView.letterIndex(forY: 5, letterCount: 1)
        XCTAssertEqual(index, 0)
    }

    func testSingleLetterOutOfRangeReturnsNil() {
        let index = AlphabetIndexView.letterIndex(forY: 30, letterCount: 1)
        XCTAssertNil(index)
    }

    func testExactBoundaryReturnsCorrectIndex() {
        // For 3 letters: total = 3*16+8 = 56. Each letter = 56/3 ≈ 18.67.
        // Y at padding boundary (4) → adjusted = 0 → 0 / 18.67 = 0
        let index = AlphabetIndexView.letterIndex(forY: 4, letterCount: 3)
        XCTAssertEqual(index, 0)
    }
}
