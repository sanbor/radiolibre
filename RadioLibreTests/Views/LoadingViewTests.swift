import XCTest
import SwiftUI
@testable import RadioLibre

final class LoadingViewTests: XCTestCase {

    @MainActor
    func testLoadingViewDefaultMessage() {
        let view = LoadingView()
        _ = view.body
        XCTAssertEqual(view.message, "Loading...")
    }

    @MainActor
    func testLoadingViewCustomMessage() {
        let view = LoadingView(message: "Discovering stations...")
        _ = view.body
        XCTAssertEqual(view.message, "Discovering stations...")
    }
}
